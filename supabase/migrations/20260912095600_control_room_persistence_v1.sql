begin;

create extension if not exists pgcrypto;

create table if not exists public.control_room_projects (
  id uuid primary key default gen_random_uuid(),
  project_key text not null unique check (project_key ~ '^[a-z0-9][a-z0-9-]*$'),
  name text not null,
  kind text not null check (kind in ('product','platform','internal_system','client_operation','data_asset','candidate')),
  goal text,
  success_definition text,
  portfolio_class text not null default 'UNCONFIRMED' check (portfolio_class in ('CORE','EXPERIMENT','AUTOPILOT','MAINTENANCE','VAULT','SYSTEM','UNCONFIRMED')),
  lifecycle_status text not null default 'unconfirmed' check (lifecycle_status in ('active','paused','completed','archived','unconfirmed')),
  canonical_constraints jsonb not null default '[]'::jsonb check (jsonb_typeof(canonical_constraints) = 'array'),
  state_authority text not null default 'control_room' check (state_authority in ('control_room','external_system','manual')),
  primary_workspace text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.control_room_project_state_versions (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.control_room_projects(id) on delete cascade,
  version integer not null check (version > 0),
  phase text,
  current_focus text,
  last_material_result text,
  next_best_action text,
  blocked boolean not null default false,
  blocker_summary text,
  autonomy_state text not null default 'can_continue' check (autonomy_state in ('working','can_continue','waiting','owner_needed','inactive')),
  autonomy_reason text,
  founder_attention_required boolean not null default false,
  founder_gate text not null default 'none' check (founder_gate in ('none','strategic_decision','credential','legal_commercial','external_communication','contract','customer_data','production_mutation','spend','live_money')),
  founder_attention_reason text,
  founder_attention_unlocks text,
  confidence text not null default 'medium' check (confidence in ('low','medium','high')),
  verified_at timestamptz not null default now(),
  source_type text not null default 'manual',
  source_ref text,
  created_at timestamptz not null default now(),
  unique (project_id, version),
  check ((founder_attention_required and founder_gate <> 'none') or (not founder_attention_required)),
  check ((not blocked) or blocker_summary is not null)
);

create index if not exists control_room_state_project_version_idx
  on public.control_room_project_state_versions(project_id, version desc);

create index if not exists control_room_state_attention_idx
  on public.control_room_project_state_versions(founder_attention_required, verified_at desc);

create table if not exists public.control_room_project_events (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.control_room_projects(id) on delete cascade,
  event_type text not null,
  summary text not null,
  importance text not null default 'normal' check (importance in ('low','normal','high','critical')),
  occurred_at timestamptz not null default now(),
  source_type text not null default 'manual',
  source_ref text,
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz not null default now()
);

create index if not exists control_room_events_project_time_idx
  on public.control_room_project_events(project_id, occurred_at desc);

create table if not exists public.control_room_project_connections (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.control_room_projects(id) on delete cascade,
  connection_type text not null check (connection_type in ('chatgpt','github','supabase','lovable','production','drive','ai_company_os','other')),
  label text,
  external_ref text,
  url text,
  is_primary boolean not null default false,
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (project_id, connection_type, external_ref)
);

alter table public.control_room_projects enable row level security;
alter table public.control_room_project_state_versions enable row level security;
alter table public.control_room_project_events enable row level security;
alter table public.control_room_project_connections enable row level security;

-- No anon/authenticated policies in v1. Runtime access is through bounded server-side functions / service role.

create or replace view public.control_room_project_current_v1
with (security_invoker = true)
as
select distinct on (s.project_id)
  s.*
from public.control_room_project_state_versions s
order by s.project_id, s.version desc;

create or replace view public.control_room_project_summary_v1
with (security_invoker = true)
as
select
  p.id,
  p.project_key,
  p.name,
  p.kind,
  p.goal,
  p.success_definition,
  p.portfolio_class,
  p.lifecycle_status,
  p.canonical_constraints,
  p.state_authority,
  p.primary_workspace,
  s.version as state_version,
  s.phase,
  s.current_focus,
  s.last_material_result,
  s.next_best_action,
  s.blocked,
  s.blocker_summary,
  s.autonomy_state,
  s.autonomy_reason,
  s.founder_attention_required,
  s.founder_gate,
  s.founder_attention_reason,
  s.founder_attention_unlocks,
  s.confidence,
  s.verified_at,
  s.source_type,
  s.source_ref,
  (s.id is null) as state_missing
from public.control_room_projects p
left join public.control_room_project_current_v1 s on s.project_id = p.id;

create or replace view public.control_room_owner_attention_v1
with (security_invoker = true)
as
select *
from public.control_room_project_summary_v1
where founder_attention_required = true
  and lifecycle_status = 'active'
order by
  case portfolio_class when 'CORE' then 0 when 'EXPERIMENT' then 1 when 'AUTOPILOT' then 2 when 'MAINTENANCE' then 3 else 4 end,
  verified_at desc nulls last;

create or replace view public.control_room_today_v1
with (security_invoker = true)
as
select *
from public.control_room_project_summary_v1
where lifecycle_status = 'active'
order by
  case when founder_attention_required then 0 else 1 end,
  case portfolio_class when 'CORE' then 0 when 'EXPERIMENT' then 1 when 'AUTOPILOT' then 2 when 'MAINTENANCE' then 3 when 'SYSTEM' then 4 else 5 end,
  case when blocked then 0 else 1 end,
  verified_at desc nulls last,
  name;

create or replace function public.control_room_get_project_state_v1(p_project_key text)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select to_jsonb(x)
  from public.control_room_project_summary_v1 x
  where x.project_key = p_project_key;
$$;

create or replace function public.control_room_list_projects_v1(
  p_portfolio_class text default null,
  p_lifecycle_status text default null
)
returns setof public.control_room_project_summary_v1
language sql
security definer
set search_path = public
as $$
  select *
  from public.control_room_project_summary_v1
  where (p_portfolio_class is null or portfolio_class = p_portfolio_class)
    and (p_lifecycle_status is null or lifecycle_status = p_lifecycle_status)
  order by
    case portfolio_class when 'CORE' then 0 when 'EXPERIMENT' then 1 when 'AUTOPILOT' then 2 when 'MAINTENANCE' then 3 when 'SYSTEM' then 4 else 5 end,
    name;
$$;

create or replace function public.control_room_get_owner_attention_v1()
returns setof public.control_room_owner_attention_v1
language sql
security definer
set search_path = public
as $$
  select * from public.control_room_owner_attention_v1;
$$;

create or replace function public.control_room_append_project_state_v1(
  p_project_key text,
  p_expected_version integer,
  p_state jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_project public.control_room_projects%rowtype;
  v_current_version integer;
  v_new_version integer;
  v_row public.control_room_project_state_versions%rowtype;
begin
  select * into v_project
  from public.control_room_projects
  where project_key = p_project_key
  for update;

  if not found then
    raise exception 'project_not_found:%', p_project_key using errcode = 'P0001';
  end if;

  select coalesce(max(version), 0) into v_current_version
  from public.control_room_project_state_versions
  where project_id = v_project.id;

  if p_expected_version is distinct from v_current_version then
    raise exception 'state_version_conflict:expected=% current=%', p_expected_version, v_current_version using errcode = 'P0001';
  end if;

  v_new_version := v_current_version + 1;

  insert into public.control_room_project_state_versions (
    project_id, version, phase, current_focus, last_material_result, next_best_action,
    blocked, blocker_summary, autonomy_state, autonomy_reason,
    founder_attention_required, founder_gate, founder_attention_reason, founder_attention_unlocks,
    confidence, verified_at, source_type, source_ref
  ) values (
    v_project.id,
    v_new_version,
    nullif(p_state->>'phase',''),
    nullif(p_state->>'current_focus',''),
    nullif(p_state->>'last_material_result',''),
    nullif(p_state->>'next_best_action',''),
    coalesce((p_state->>'blocked')::boolean, false),
    nullif(p_state->>'blocker_summary',''),
    coalesce(nullif(p_state->>'autonomy_state',''), 'can_continue'),
    nullif(p_state->>'autonomy_reason',''),
    coalesce((p_state->>'founder_attention_required')::boolean, false),
    coalesce(nullif(p_state->>'founder_gate',''), 'none'),
    nullif(p_state->>'founder_attention_reason',''),
    nullif(p_state->>'founder_attention_unlocks',''),
    coalesce(nullif(p_state->>'confidence',''), 'medium'),
    coalesce((p_state->>'verified_at')::timestamptz, now()),
    coalesce(nullif(p_state->>'source_type',''), 'manual'),
    nullif(p_state->>'source_ref','')
  )
  returning * into v_row;

  return to_jsonb(v_row);
end;
$$;

create or replace function public.control_room_append_project_event_v1(
  p_project_key text,
  p_event jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_project_id uuid;
  v_row public.control_room_project_events%rowtype;
begin
  select id into v_project_id
  from public.control_room_projects
  where project_key = p_project_key;

  if v_project_id is null then
    raise exception 'project_not_found:%', p_project_key using errcode = 'P0001';
  end if;

  insert into public.control_room_project_events (
    project_id, event_type, summary, importance, occurred_at, source_type, source_ref, metadata
  ) values (
    v_project_id,
    coalesce(nullif(p_event->>'event_type',''), 'material_change'),
    p_event->>'summary',
    coalesce(nullif(p_event->>'importance',''), 'normal'),
    coalesce((p_event->>'occurred_at')::timestamptz, now()),
    coalesce(nullif(p_event->>'source_type',''), 'manual'),
    nullif(p_event->>'source_ref',''),
    coalesce(p_event->'metadata', '{}'::jsonb)
  )
  returning * into v_row;

  if v_row.summary is null or btrim(v_row.summary) = '' then
    raise exception 'event_summary_required' using errcode = 'P0001';
  end if;

  return to_jsonb(v_row);
end;
$$;

revoke all on table public.control_room_projects from anon, authenticated;
revoke all on table public.control_room_project_state_versions from anon, authenticated;
revoke all on table public.control_room_project_events from anon, authenticated;
revoke all on table public.control_room_project_connections from anon, authenticated;
revoke all on public.control_room_project_current_v1 from anon, authenticated;
revoke all on public.control_room_project_summary_v1 from anon, authenticated;
revoke all on public.control_room_owner_attention_v1 from anon, authenticated;
revoke all on public.control_room_today_v1 from anon, authenticated;

revoke all on function public.control_room_get_project_state_v1(text) from public, anon, authenticated;
revoke all on function public.control_room_list_projects_v1(text, text) from public, anon, authenticated;
revoke all on function public.control_room_get_owner_attention_v1() from public, anon, authenticated;
revoke all on function public.control_room_append_project_state_v1(text, integer, jsonb) from public, anon, authenticated;
revoke all on function public.control_room_append_project_event_v1(text, jsonb) from public, anon, authenticated;

grant execute on function public.control_room_get_project_state_v1(text) to service_role;
grant execute on function public.control_room_list_projects_v1(text, text) to service_role;
grant execute on function public.control_room_get_owner_attention_v1() to service_role;
grant execute on function public.control_room_append_project_state_v1(text, integer, jsonb) to service_role;
grant execute on function public.control_room_append_project_event_v1(text, jsonb) to service_role;

insert into public.control_room_projects (
  project_key, name, kind, goal, portfolio_class, lifecycle_status, state_authority, primary_workspace, canonical_constraints
) values
  ('meterion-control-room','Meterion Control Room','internal_system','Maintain a lightweight, reliable cross-project operating picture of Meterion and minimize Founder coordination overhead.','SYSTEM','active','control_room','meterionops/meterion-hq',jsonb_build_array('Thin coordination layer only','No task-manager sprawl','Do not duplicate source-system truth')),
  ('ai-company-os','AI Company OS','internal_system','Operate the governed system for creating and running AI-native companies.','CORE','active','external_system','meterionops/ai-company-os',jsonb_build_array('External Meterion projects are not AI Companies','Company Factory remains the canonical AI Company creation path')),
  ('maistio','Maistio','product','Launch a Helsinki-first restaurant discovery product built on the Local Discovery Graph.','CORE','active','control_room','chatgpt + supabase + lovable',jsonb_build_array('Restaurants first','Bars, nightlife and events remain later verticals')),
  ('cala-europe','Cala Europe','product','Build a Europe-first beach discovery and practical beach intelligence product.','CORE','active','control_room','chatgpt + supabase + lovable',jsonb_build_array('Core product must not depend on paid APIs')),
  ('sprinkler-rfq-platform','Sprinkler RFQ Platform','product','Discover and qualify European sprinkler/fire-protection opportunities and relevant commercial counterparties.','CORE','active','control_room','chatgpt + github + data pipelines',jsonb_build_array('Do not country-lock counterparties from historical activity','Respect project exclusion rules')),
  ('rail-atlas','Rail Atlas / Junamatkailusivusto','product','Build a global train-travel discovery product centered on memorable train experiences and journeys.','CORE','active','control_room','chatgpt + supabase + lovable','[]'::jsonb),
  ('folio','Folio','product','Build Finnish-company intelligence, competitor monitoring and decision support while reusing existing Meterion company data where appropriate.','UNCONFIRMED','active','control_room','chatgpt + prototype + data sources',jsonb_build_array('Do not create a competing company master-data source to Yritystiedot'))
on conflict (project_key) do update set
  name = excluded.name,
  kind = excluded.kind,
  goal = excluded.goal,
  portfolio_class = excluded.portfolio_class,
  lifecycle_status = excluded.lifecycle_status,
  state_authority = excluded.state_authority,
  primary_workspace = excluded.primary_workspace,
  canonical_constraints = excluded.canonical_constraints,
  updated_at = now();

insert into public.control_room_project_connections (project_id, connection_type, label, external_ref, is_primary)
select p.id, 'supabase', 'Meterion Control Room Supabase', 'cavvdvxicadgfftbziao', true
from public.control_room_projects p
where p.project_key = 'meterion-control-room'
on conflict (project_id, connection_type, external_ref) do nothing;

commit;
