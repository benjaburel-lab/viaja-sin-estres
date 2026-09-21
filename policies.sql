-- ============================================================
-- POLICIES.SQL
-- Políticas RLS consolidadas, funciones de seguridad y Storage
-- Proyecto: Viajar Sin Estrés (Mauro Yakas)
--
-- ORDEN DE INSTALACIÓN EN SUPABASE (SQL EDITOR):
--   1. schema.sql                  (Estructura de tablas, índices y triggers)
--   2. policies.sql                (Seguridad RLS, RPCs y Storage)
--      [o alternativamente sql/policies_production.sql, que es idéntico]
--   3. seed.sql                    (Opcional: datos de prueba)
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. ACTIVAR ROW LEVEL SECURITY (RLS) EN TODAS LAS TABLAS
-- Sin políticas explícitas para el rol 'anon', queda bloqueado
-- todo acceso directo (SELECT/INSERT/UPDATE/DELETE = 0 filas).
-- ────────────────────────────────────────────────────────────
alter table viajes      enable row level security;
alter table actividades enable row level security;
alter table traslados   enable row level security;
alter table archivos    enable row level security;
alter table avisos      enable row level security;

-- ────────────────────────────────────────────────────────────
-- 2. FUNCIÓN DE VERIFICACIÓN DE ADMINISTRADOR: es_admin()
-- Verifica si el JWT del usuario autenticado tiene el rol 'admin'
-- en app_metadata. Este valor solo puede asignarse desde el
-- Dashboard de Supabase o mediante service_role.
-- ────────────────────────────────────────────────────────────
create or replace function es_admin()
returns boolean
language sql
stable
set search_path = public
as $$
  select coalesce(
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin',
    false
  );
$$;

comment on function es_admin is
  'Retorna true únicamente si el usuario autenticado tiene app_metadata.role = "admin".';

grant execute on function es_admin() to authenticated;

-- ────────────────────────────────────────────────────────────
-- 3. POLÍTICAS DE TABLAS PARA EL ADMINISTRADOR
-- Solo usuarios con app_metadata.role = 'admin' pueden operar
-- sobre las tablas (SELECT, INSERT, UPDATE, DELETE).
-- Usuarios autenticados comunes NO tienen permisos.
-- ────────────────────────────────────────────────────────────
drop policy if exists "admin_full_access_viajes"      on viajes;
drop policy if exists "admin_viajes"                  on viajes;
create policy "admin_viajes"
  on viajes for all
  to authenticated
  using    (es_admin())
  with check (es_admin());

drop policy if exists "admin_full_access_actividades" on actividades;
drop policy if exists "admin_actividades"             on actividades;
create policy "admin_actividades"
  on actividades for all
  to authenticated
  using    (es_admin())
  with check (es_admin());

drop policy if exists "admin_full_access_traslados"   on traslados;
drop policy if exists "admin_traslados"               on traslados;
create policy "admin_traslados"
  on traslados for all
  to authenticated
  using    (es_admin())
  with check (es_admin());

drop policy if exists "admin_full_access_archivos"    on archivos;
drop policy if exists "admin_archivos"                on archivos;
create policy "admin_archivos"
  on archivos for all
  to authenticated
  using    (es_admin())
  with check (es_admin());

drop policy if exists "admin_full_access_avisos"      on avisos;
drop policy if exists "admin_avisos"                  on avisos;
create policy "admin_avisos"
  on avisos for all
  to authenticated
  using    (es_admin())
  with check (es_admin());

-- ────────────────────────────────────────────────────────────
-- 4. FUNCIÓN RPC: ACCESO PÚBLICO DEL VIAJERO POR CÓDIGO
-- Única puerta de entrada para consultar datos de un viaje sin login.
-- SECURITY DEFINER: Se ejecuta con privilegios del creador para
-- poder leer las tablas protegidas por RLS.
-- ────────────────────────────────────────────────────────────
create or replace function obtener_viaje_publico(p_codigo text)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_viaje viajes%rowtype;
  v_resultado json;
begin
  -- Busca el viaje exacto por código, solo si está marcado como activo.
  select * into v_viaje
  from viajes
  where codigo = p_codigo
    and activo = true;

  if not found then
    return null;
  end if;

  -- Arma el JSON agregando únicamente los hijos de este viaje.
  select json_build_object(
    'id', v_viaje.id,
    'codigo', v_viaje.codigo,
    'titulo', v_viaje.titulo,
    'destino', v_viaje.destino,
    'fecha_inicio', v_viaje.fecha_inicio,
    'fecha_fin', v_viaje.fecha_fin,
    'descripcion', v_viaje.descripcion,
    'imagen_principal', v_viaje.imagen_principal,
    'info_importante', v_viaje.info_importante,
    'actividades', (
      select coalesce(json_agg(a order by a.dia, a.orden), '[]'::json)
      from actividades a
      where a.viaje_id = v_viaje.id
    ),
    'traslados', (
      select coalesce(json_agg(t order by t.orden), '[]'::json)
      from traslados t
      where t.viaje_id = v_viaje.id
    ),
    'archivos', (
      select coalesce(json_agg(
        json_build_object(
          'id', f.id,
          'tipo', f.tipo,
          'nombre', f.nombre,
          'path_storage', f.path_storage,
          'bucket', f.bucket,
          'orden', f.orden
        ) order by f.orden
      ), '[]'::json)
      from archivos f
      where f.viaje_id = v_viaje.id
        and f.es_privado = false   -- Los archivos privados nunca se exponen aquí
    ),
    'avisos', (
      select coalesce(json_agg(av order by av.created_at desc), '[]'::json)
      from avisos av
      where av.viaje_id = v_viaje.id
    )
  ) into v_resultado;

  return v_resultado;
end;
$$;

comment on function obtener_viaje_publico is
  'Retorna la información pública de un viaje activo. No expone archivos privados ni viajes inactivos.';

grant execute on function obtener_viaje_publico(text) to anon;
grant execute on function obtener_viaje_publico(text) to authenticated;

-- ────────────────────────────────────────────────────────────
-- 5. FUNCIÓN VALIDACIÓN DE STORAGE: archivo_publico_permitido()
-- Permite verificar de forma segura si un archivo de Storage
-- corresponde a un documento público de un viaje activo.
-- SECURITY DEFINER: Permite validar sin exponer la tabla archivos
-- al rol anónimo ni relajar RLS.
-- ────────────────────────────────────────────────────────────
create or replace function archivo_publico_permitido(p_bucket text, p_path text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  return exists (
    select 1
    from archivos a
    inner join viajes v on v.id = a.viaje_id
    where a.bucket = p_bucket
      and a.path_storage = p_path
      and a.es_privado = false
      and v.activo = true
  );
end;
$$;

comment on function archivo_publico_permitido is
  'Valida si un path de Storage corresponde a un archivo no privado de un viaje activo.';

grant execute on function archivo_publico_permitido(text, text) to anon;
grant execute on function archivo_publico_permitido(text, text) to authenticated;

-- ────────────────────────────────────────────────────────────
-- 6. POLÍTICAS DE STORAGE (storage.objects)
-- Buckets: 'imagenes' y 'documentos'
-- ────────────────────────────────────────────────────────────

-- --- Limpiar políticas previas de storage si existieran ---
drop policy if exists "imagenes_lectura_publica"                  on storage.objects;
drop policy if exists "imagenes_escritura_admin"                 on storage.objects;
drop policy if exists "imagenes_update_admin"                    on storage.objects;
drop policy if exists "imagenes_delete_admin"                    on storage.objects;
drop policy if exists "documentos_lectura_publica_si_no_privado" on storage.objects;
drop policy if exists "documentos_lectura_publica"               on storage.objects;
drop policy if exists "documentos_lectura_admin_total"           on storage.objects;
drop policy if exists "documentos_escritura_admin"               on storage.objects;
drop policy if exists "documentos_update_admin"                  on storage.objects;
drop policy if exists "documentos_delete_admin"                  on storage.objects;

-- --- BUCKET: imagenes ---
-- Lectura pública para banners e imágenes de viajes
create policy "imagenes_lectura_publica"
  on storage.objects for select
  to public
  using (bucket_id = 'imagenes');

-- Solo el administrador puede subir, modificar o borrar imágenes
create policy "imagenes_escritura_admin"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'imagenes' and es_admin());

create policy "imagenes_update_admin"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'imagenes' and es_admin());

create policy "imagenes_delete_admin"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'imagenes' and es_admin());

-- --- BUCKET: documentos ---
-- Lectura pública: SOLO para archivos no privados asociados a un viaje activo
create policy "documentos_lectura_publica"
  on storage.objects for select
  to public
  using (
    bucket_id = 'documentos'
    and archivo_publico_permitido('documentos', name)
  );

-- Lectura administrador: acceso a todos los documentos (públicos y privados)
create policy "documentos_lectura_admin_total"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'documentos' and es_admin());

-- Solo el administrador puede subir, modificar o borrar documentos
create policy "documentos_escritura_admin"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'documentos' and es_admin());

create policy "documentos_update_admin"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'documentos' and es_admin());

create policy "documentos_delete_admin"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'documentos' and es_admin());
