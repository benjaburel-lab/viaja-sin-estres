-- ============================================================
-- SCHEMA.SQL
-- Plataforma de gestión de viajes — Mauro Yakas
-- Ejecutar PRIMERO, en el SQL Editor de Supabase
-- ============================================================

-- Extensión necesaria para gen_random_uuid()
create extension if not exists pgcrypto;

-- ============================================================
-- TABLA: viajes
-- ============================================================
create table viajes (
  id                  uuid primary key default gen_random_uuid(),
  codigo              text not null unique,
  titulo              text not null,
  destino             text not null,
  fecha_inicio        date not null,
  fecha_fin           date not null,
  descripcion         text,
  imagen_principal    text,               -- path en bucket 'imagenes'
  info_importante     text,
  activo              boolean not null default true,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),

  constraint chk_fechas_validas check (fecha_fin >= fecha_inicio),
  constraint chk_codigo_formato check (codigo ~ '^[A-Z0-9]{2,6}-[A-Z0-9]{4,8}$'),
  constraint chk_titulo_no_vacio check (length(trim(titulo)) > 0)
);

comment on table viajes is 'Cada viaje es un registro independiente accesible por código público único.';
comment on column viajes.codigo is 'Código único tipo BAR-8F42K, usado en el link y QR públicos.';
comment on column viajes.activo is 'Si es false, el viaje deja de ser visible para viajeros aunque el link/código siga existiendo.';

create index idx_viajes_codigo on viajes (codigo);
create index idx_viajes_activo on viajes (activo);

-- ============================================================
-- TABLA: actividades (itinerario)
-- ============================================================
create table actividades (
  id            uuid primary key default gen_random_uuid(),
  viaje_id      uuid not null references viajes(id) on delete cascade,
  dia           int not null,
  fecha         date,
  hora          time,
  titulo        text not null,
  descripcion   text,
  lugar         text,
  orden         int not null default 0,
  created_at    timestamptz not null default now(),

  constraint chk_dia_positivo check (dia >= 1),
  constraint chk_actividad_titulo check (length(trim(titulo)) > 0)
);

create index idx_actividades_viaje_id on actividades (viaje_id);
create index idx_actividades_orden on actividades (viaje_id, dia, orden);

-- ============================================================
-- TABLA: traslados
-- ============================================================
create table traslados (
  id            uuid primary key default gen_random_uuid(),
  viaje_id      uuid not null references viajes(id) on delete cascade,
  tipo          text not null,             -- 'vuelo' | 'bus' | 'combi' | 'auto' | 'otro'
  origen        text not null,
  destino       text not null,
  fecha         date,
  hora          time,
  detalle       text,
  orden         int not null default 0,
  created_at    timestamptz not null default now(),

  constraint chk_traslado_tipo check (tipo in ('vuelo','bus','combi','auto','tren','barco','otro'))
);

create index idx_traslados_viaje_id on traslados (viaje_id);

-- ============================================================
-- TABLA: archivos (PDFs / imágenes adicionales)
-- ============================================================
create table archivos (
  id              uuid primary key default gen_random_uuid(),
  viaje_id        uuid not null references viajes(id) on delete cascade,
  tipo            text not null,           -- 'pdf' | 'imagen'
  nombre          text not null,
  path_storage    text not null,           -- path dentro del bucket
  bucket          text not null default 'documentos',
  es_privado      boolean not null default false,   -- preparado para V2
  orden           int not null default 0,
  created_at      timestamptz not null default now(),

  constraint chk_archivo_tipo check (tipo in ('pdf','imagen')),
  constraint chk_archivo_bucket check (bucket in ('imagenes','documentos')),
  constraint uq_path_storage unique (bucket, path_storage)
);

comment on column archivos.es_privado is 'V1: siempre false (lectura pública). V2: si es true, solo el admin autenticado puede leerlo.';

create index idx_archivos_viaje_id on archivos (viaje_id);
create index idx_archivos_privado on archivos (es_privado);

-- ============================================================
-- TABLA: avisos
-- ============================================================
create table avisos (
  id            uuid primary key default gen_random_uuid(),
  viaje_id      uuid not null references viajes(id) on delete cascade,
  mensaje       text not null,
  created_at    timestamptz not null default now(),

  constraint chk_aviso_mensaje check (length(trim(mensaje)) > 0)
);

create index idx_avisos_viaje_id on avisos (viaje_id);

-- ============================================================
-- TRIGGER: actualizar updated_at automáticamente en viajes
-- ============================================================
create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_viajes_updated_at
  before update on viajes
  for each row
  execute function set_updated_at();
