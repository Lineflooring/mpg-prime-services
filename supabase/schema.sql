-- MPG Prime Services — tablas de captación (Supabase, proyecto del grupo)
-- Pegar y ejecutar en: Supabase Dashboard → SQL Editor → New query → Run
-- El sitio ya intenta insertar en estas tablas desde el primer día:
-- si no existen, los envíos se guardan igual en Netlify Forms (destino principal).

create table if not exists public.mpg_services_leads (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  tipo        text,            -- calculadora | contacto | inversor
  nombre      text,
  email       text,
  whatsapp    text,
  empresa     text,
  servicio    text,
  ciudad      text,
  m2          numeric,
  extras      text,
  total_estimado numeric,
  mensaje     text,
  idioma      text,
  estado      text not null default 'nuevo'  -- nuevo | contactado | presupuesto | ganado | perdido
);

create table if not exists public.mpg_services_subs (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  razon_social text,
  cif_nif     text,
  num_rea     text,
  responsable text,
  oficios     text,
  zonas       text,
  email       text,
  telefono    text,
  estado      text not null default 'PENDIENTE',  -- PENDIENTE | VERDE | AMBAR | ROJO
  vencimientos jsonb,          -- {rea, rc, ss, hacienda, prl, alta} fechas de vencimiento
  idioma      text
  -- Los archivos viven en Netlify Forms (formulario subcontratista-registro)
  -- y, en la fase siguiente, en el bucket privado de Supabase Storage.
);

create table if not exists public.mpg_services_sub_attempts (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  empresa     text,
  email       text,
  preguntas_fallidas text,     -- claves del Paso 0 respondidas "No"
  idioma      text
);

-- RLS: el sitio (clave publicable/anon) solo puede INSERTAR. Nadie lee desde el sitio.
alter table public.mpg_services_leads enable row level security;
alter table public.mpg_services_subs enable row level security;
alter table public.mpg_services_sub_attempts enable row level security;

drop policy if exists "anon insert leads" on public.mpg_services_leads;
create policy "anon insert leads" on public.mpg_services_leads
  for insert to anon with check (true);

drop policy if exists "anon insert subs" on public.mpg_services_subs;
create policy "anon insert subs" on public.mpg_services_subs
  for insert to anon with check (true);

drop policy if exists "anon insert attempts" on public.mpg_services_sub_attempts;
create policy "anon insert attempts" on public.mpg_services_sub_attempts
  for insert to anon with check (true);
