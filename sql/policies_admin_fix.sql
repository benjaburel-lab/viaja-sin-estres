-- ============================================================
-- POLICIES_ADMIN_FIX.SQL
-- Corrección de seguridad RLS — V1
--
-- NOTA: Este archivo fue el parche inicial para la vulnerabilidad
-- de usuarios autenticados.
-- HA SIDO SUPERADO Y CONSOLIDADO EN:
--   sql/policies_production.sql (y policies.sql)
-- que incluye además las políticas corregidas de Supabase Storage
-- y la función de validación de documentos públicos.
-- Se conserva aquí únicamente como referencia histórica.
-- ============================================================


-- ──────────────────────────────────────────────────────────────
-- 1. Eliminar las políticas admin anteriores (permisivas)
-- ──────────────────────────────────────────────────────────────
drop policy if exists "admin_full_access_viajes"      on viajes;
drop policy if exists "admin_full_access_actividades" on actividades;
drop policy if exists "admin_full_access_traslados"   on traslados;
drop policy if exists "admin_full_access_archivos"    on archivos;
drop policy if exists "admin_full_access_avisos"      on avisos;


-- ──────────────────────────────────────────────────────────────
-- 2. Función helper: es_admin()
--    Retorna true solo si el JWT tiene app_metadata.role = 'admin'
--    SECURITY DEFINER no es necesario aquí porque solo lee el JWT.
-- ──────────────────────────────────────────────────────────────
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
  'Retorna true únicamente si el JWT del usuario autenticado tiene
   app_metadata.role = "admin".

   Cómo configurarlo en Supabase:
     Dashboard → Authentication → Users → (usuario de Mauro)
     → botón "Edit" → campo app_metadata → ingresar:
     { "role": "admin" }
     → guardar.

   Los usuarios NO pueden modificar su propio app_metadata desde
   el cliente. Solo puede cambiarse con la service_role key o
   desde el Dashboard.';

grant execute on function es_admin() to authenticated;


-- ──────────────────────────────────────────────────────────────
-- 3. Nuevas políticas admin: solo role = 'admin'
-- ──────────────────────────────────────────────────────────────
create policy "admin_viajes"
  on viajes for all
  to authenticated
  using    (es_admin())
  with check (es_admin());

create policy "admin_actividades"
  on actividades for all
  to authenticated
  using    (es_admin())
  with check (es_admin());

create policy "admin_traslados"
  on traslados for all
  to authenticated
  using    (es_admin())
  with check (es_admin());

create policy "admin_archivos"
  on archivos for all
  to authenticated
  using    (es_admin())
  with check (es_admin());

create policy "admin_avisos"
  on avisos for all
  to authenticated
  using    (es_admin())
  with check (es_admin());
