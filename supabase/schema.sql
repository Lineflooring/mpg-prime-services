-- =====================================================================
-- MPG Prime Services — backend completo (Supabase, proyecto del grupo)
-- Pegar TODO el archivo en: Supabase Dashboard → SQL Editor → New query → Run
--
-- ANTES DE EJECUTAR — 1 solo cambio:
--   Busca  PON-AQUI-TU-CLAVE  (línea de mpg_panel_config) y sustitúyela por
--   la clave del panel que te entregó Muse. Es la clave que pedirán el
--   panel interno (panel.html) y el motor de avisos de vencimiento.
--
-- Qué crea:
--   · Tablas mpg_services_leads / mpg_services_subs / mpg_services_sub_attempts
--   · Bucket PRIVADO de Storage "sub-docs" (documentos de subcontratistas)
--   · RLS: el sitio público (clave publishable) SOLO puede insertar/leer nada.
--     Las lecturas del panel van por funciones RPC con clave (p_key),
--     mismo patrón que la Tabela de Schedule de Line Flooring.
-- =====================================================================

-- ---------- TABLAS ----------
create table if not exists public.mpg_services_leads (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  tipo        text,            -- calculadora | contacto | inversor | presupuesto
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
  oficios     text,            -- lista separada por comas (multi-select del formulario)
  zonas       text,
  email       text,
  telefono    text,
  estado      text not null default 'PENDIENTE',
  aprobado    boolean not null default false,   -- revisión del panel: PENDIENTE / APROBADO
  vencimientos jsonb,          -- {rea, rc, ss, hacienda, prl, alta} fechas de vencimiento (YYYY-MM-DD)
  documentos   jsonb,          -- {rea: {path, nombre}, rc: {...}, ...} rutas en el bucket sub-docs
  idioma      text
);
alter table public.mpg_services_subs add column if not exists aprobado boolean not null default false;
alter table public.mpg_services_subs add column if not exists documentos jsonb;

create table if not exists public.mpg_services_sub_attempts (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  empresa     text,
  email       text,
  preguntas_fallidas text,     -- claves del Paso 0 respondidas "No"
  idioma      text
);

-- ---------- CONFIG DEL PANEL (clave de acceso) ----------
create table if not exists public.mpg_panel_config (
  k text primary key,
  v text not null
);
alter table public.mpg_panel_config enable row level security;
-- Sin policies: nadie lee/escribe por REST. Solo las funciones de abajo (definer).

insert into public.mpg_panel_config (k, v)
values ('panel_key', 'PON-AQUI-TU-CLAVE')
on conflict (k) do nothing;
-- Si ya ejecutaste esto antes y quieres cambiar la clave:
-- update public.mpg_panel_config set v = 'TU-NUEVA-CLAVE' where k = 'panel_key';

-- ---------- RLS: SOLO INSERT ANÓNIMO EN TABLAS ----------
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

-- ---------- STORAGE: BUCKET PRIVADO DE DOCUMENTOS ----------
insert into storage.buckets (id, name, public)
values ('sub-docs', 'sub-docs', false)
on conflict (id) do nothing;

-- Subida anónima SOLO a este bucket (el formulario público). Sin lectura anónima.
drop policy if exists "anon upload sub-docs" on storage.objects;
create policy "anon upload sub-docs" on storage.objects
  for insert to anon with check (bucket_id = 'sub-docs');

-- Lectura SOLO con la cabecera x-panel-key correcta (la usa el panel interno
-- para descargar documentos; la clave nunca viaja en el código del sitio).
drop policy if exists "panel read sub-docs" on storage.objects;
create policy "panel read sub-docs" on storage.objects
  for select to anon using (
    bucket_id = 'sub-docs'
    and exists (
      select 1 from public.mpg_panel_config c
      where c.k = 'panel_key'
        and c.v = ((current_setting('request.headers', true)::jsonb) ->> 'x-panel-key')
    )
  );

-- ---------- FUNCIONES DEL PANEL (RPC con clave, patrón Tabela de Schedule) ----------
create or replace function public.mpg_check_key(p_key text)
returns boolean
language sql security definer set search_path = public
as $$
  select exists (select 1 from public.mpg_panel_config where k = 'panel_key' and v = p_key and p_key <> '' and p_key <> 'PON-AQUI-TU-CLAVE');
$$;

create or replace function public.mpg_panel_leads(p_key text)
returns setof public.mpg_services_leads
language plpgsql security definer set search_path = public
as $$
begin
  if not public.mpg_check_key(p_key) then raise exception 'unauthorized'; end if;
  return query select * from public.mpg_services_leads order by created_at desc limit 500;
end;
$$;

create or replace function public.mpg_panel_subs(p_key text)
returns setof public.mpg_services_subs
language plpgsql security definer set search_path = public
as $$
begin
  if not public.mpg_check_key(p_key) then raise exception 'unauthorized'; end if;
  return query select * from public.mpg_services_subs order by created_at desc limit 500;
end;
$$;

create or replace function public.mpg_panel_attempts(p_key text)
returns setof public.mpg_services_sub_attempts
language plpgsql security definer set search_path = public
as $$
begin
  if not public.mpg_check_key(p_key) then raise exception 'unauthorized'; end if;
  return query select * from public.mpg_services_sub_attempts order by created_at desc limit 500;
end;
$$;

create or replace function public.mpg_panel_set_aprobado(p_key text, p_id bigint, p_val boolean)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if not public.mpg_check_key(p_key) then raise exception 'unauthorized'; end if;
  update public.mpg_services_subs set aprobado = p_val where id = p_id;
end;
$$;

create or replace function public.mpg_panel_set_lead_estado(p_key text, p_id bigint, p_estado text)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if not public.mpg_check_key(p_key) then raise exception 'unauthorized'; end if;
  update public.mpg_services_leads set estado = p_estado where id = p_id;
end;
$$;

grant execute on function public.mpg_panel_leads(text) to anon;
grant execute on function public.mpg_panel_subs(text) to anon;
grant execute on function public.mpg_panel_attempts(text) to anon;
grant execute on function public.mpg_panel_set_aprobado(text, bigint, boolean) to anon;
grant execute on function public.mpg_panel_set_lead_estado(text, bigint, text) to anon;

-- =====================================================================
-- FIN. Después de ejecutar:
--  1) El sitio empieza a guardar leads/registros al instante.
--  2) Panel interno: https://lineflooring.github.io/mpg-prime-services/panel.html
--     (pedirá la clave que pusiste arriba).
--  3) Motor de vencimientos: lee con la misma clave vía mpg_panel_subs.
-- =====================================================================
