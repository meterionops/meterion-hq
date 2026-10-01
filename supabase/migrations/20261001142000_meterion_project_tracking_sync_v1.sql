begin;

-- Meterion Project Tracking Sync v1
--
-- Canonical project coordination truth remains in Control Room.
-- Tracking surfaces are derived read models plus an append-only change feed.
-- No source-system/project data is duplicated here.

create table if not exists public.control_room_tracking_change_feed_v1 (
  sequence bigint generated always as identity primary key,
  project_id uuid not null references public.control_room_projects(id) on delete cascade,
  change_kind text not null check (
    change_kind in ('baseline','project_identity','project_state','material_event','connection')
  ),
  source_table text not null check (char_length(source_table) between 1 and 200),
  source_id text,
  occurred_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object')
);

create index if not exists control_room_tracking_feed_project_sequence_idx
  on public.control_room_tracking_change_feed_v1(project_id, sequence desc);

create index if not exists control_room_tracking_feed_occurred_idx
  on public.control_room_tracking_change_feed_v1(occurred_at desc);

alter table public.control_room_tracking_change_feed_v1 enable row level security;
revoke all on public.control_room_tracking_change_feed_v1 from public, anon, authenticated;
grant select, insert on public.control_room_tracking_change_feed_v1 to service_role;

create or replace function public.control_room_record_tracking_change_v1(
  p_project_id uuid,
  p_change_kind text,
  p_source_table text,
  p_source_id text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns bigint
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_sequence bigint;
begin
  if p_project_id is null then
    raise exception 'tracking_project_required' using errcode = 'P0001';
  end if;

  if p_change_kind not in ('baseline','project_identity','project_state','material_event','connection') then
    raise exception 'invalid_tracking_change_kind' using errcode = 'P0001';
  end if;

  if nullif(btrim(p_source_table),'') is null then
    raise exception 'tracking_source_table_required' using errcode = 'P0001';
  end if;

  if p_metadata is null or jsonb_typeof(p_metadata) <> 'object' then
    raise exception 'tracking_metadata_object_required' using errcode = 'P0001';
  end if;

  insert into public.control_room_tracking_change_feed_v1(
    project_id, change_kind, source_table, source_id, metadata
  )
  values(
    p_project_id,
    p_change_kind,
    btrim(p_source_table),
    nullif(btrim(p_source_id),''),
    p_metadata
  )
  returning sequence into v_sequence;

  return v_sequence;
end;
$$;

create or replace function public.control_room_tracking_state_insert_v1()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.control_room_record_tracking_change_v1(
    new.project_id,
    'project_state',
    'control_room_project_state_versions',
    new.id::text,
    jsonb_build_object(
      'state_version', new.version,
      'verified_at', new.verified_at,
      'source_type', new.source_type,
      'source_ref', new.source_ref
    )
  );
  return new;
end;
$$;

create or replace function public.control_room_tracking_event_insert_v1()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.control_room_record_tracking_change_v1(
    new.project_id,
    'material_event',
    'control_room_project_events',
    new.id::text,
    jsonb_build_object(
      'event_type', new.event_type,
      'importance', new.importance,
      'occurred_at', new.occurred_at,
      'source_type', new.source_type,
      'source_ref', new.source_ref
    )
  );
  return new;
end;
$$;

create or replace function public.control_room_tracking_project_change_v1()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.control_room_record_tracking_change_v1(
    new.id,
    'project_identity',
    'control_room_projects',
    new.id::text,
    jsonb_build_object(
      'project_key', new.project_key,
      'portfolio_class', new.portfolio_class,
      'lifecycle_status', new.lifecycle_status,
      'operating_mode', new.operating_mode,
      'updated_at', new.updated_at
    )
  );
  return new;
end;
$$;

create or replace function public.control_room_tracking_connection_change_v1()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_project_id uuid;
  v_source_id text;
  v_operation text;
begin
  v_project_id := coalesce(new.project_id, old.project_id);
  v_source_id := coalesce(new.id, old.id)::text;
  v_operation := lower(tg_op);

  perform public.control_room_record_tracking_change_v1(
    v_project_id,
    'connection',
    'control_room_project_connections',
    v_source_id,
    jsonb_build_object(
      'operation', v_operation,
      'connection_type', coalesce(new.connection_type, old.connection_type),
      'external_ref', coalesce(new.external_ref, old.external_ref)
    )
  );

  return coalesce(new, old);
end;
$$;

drop trigger if exists control_room_tracking_state_insert_v1
  on public.control_room_project_state_versions;
create trigger control_room_tracking_state_insert_v1
after insert on public.control_room_project_state_versions
for each row execute function public.control_room_tracking_state_insert_v1();

drop trigger if exists control_room_tracking_event_insert_v1
  on public.control_room_project_events;
create trigger control_room_tracking_event_insert_v1
after insert on public.control_room_project_events
for each row execute function public.control_room_tracking_event_insert_v1();

drop trigger if exists control_room_tracking_project_insert_v1
  on public.control_room_projects;
create trigger control_room_tracking_project_insert_v1
after insert on public.control_room_projects
for each row execute function public.control_room_tracking_project_change_v1();

drop trigger if exists control_room_tracking_project_update_v1
  on public.control_room_projects;
create trigger control_room_tracking_project_update_v1
after update of
  name, goal, success_definition, portfolio_class, lifecycle_status,
  canonical_constraints, state_authority, primary_workspace, operating_mode
on public.control_room_projects
for each row
when (
  old.name is distinct from new.name
  or old.goal is distinct from new.goal
  or old.success_definition is distinct from new.success_definition
  or old.portfolio_class is distinct from new.portfolio_class
  or old.lifecycle_status is distinct from new.lifecycle_status
  or old.canonical_constraints is distinct from new.canonical_constraints
  or old.state_authority is distinct from new.state_authority
  or old.primary_workspace is distinct from new.primary_workspace
  or old.operating_mode is distinct from new.operating_mode
)
execute function public.control_room_tracking_project_change_v1();

drop trigger if exists control_room_tracking_connection_change_v1
  on public.control_room_project_connections;
create trigger control_room_tracking_connection_change_v1
after insert or update or delete on public.control_room_project_connections
for each row execute function public.control_room_tracking_connection_change_v1();

create or replace view public.control_room_project_tracking_v1
with (security_invoker = true)
as
select
  s.*,
  1::integer as tracking_schema_version,
  p.updated_at as project_updated_at,
  cs.created_at as state_committed_at,
  ev.latest_material_event_id,
  ev.material_event_count,
  coalesce(ev.recent_material_events, '[]'::jsonb) as recent_material_events,
  coalesce(ms.recent_milestones, '[]'::jsonb) as recent_milestones,
  cx.latest_connection_at,
  greatest(
    p.updated_at,
    coalesce(cs.created_at, '-infinity'::timestamptz),
    coalesce(ev.latest_material_event_at, '-infinity'::timestamptz),
    coalesce(cx.latest_connection_at, '-infinity'::timestamptz)
  ) as tracking_changed_at,
  md5(concat_ws(
    '|',
    p.project_key,
    p.updated_at::text,
    coalesce(cs.version, 0)::text,
    coalesce(cs.created_at::text, ''),
    coalesce(ev.latest_material_event_id::text, ''),
    coalesce(ev.latest_material_event_at::text, ''),
    coalesce(cx.latest_connection_at::text, '')
  )) as tracking_fingerprint
from public.control_room_projects_surface_v3 s
join public.control_room_projects p on p.id = s.id
left join public.control_room_project_current_v2 cs on cs.project_id = p.id
left join lateral (
  select
    (array_agg(x.id order by x.occurred_at desc, x.created_at desc))[1] as latest_material_event_id,
    max(x.occurred_at) as latest_material_event_at,
    count(*)::integer as material_event_count,
    jsonb_agg(
      jsonb_build_object(
        'id', x.id,
        'event_type', x.event_type,
        'summary', x.summary,
        'importance', x.importance,
        'occurred_at', x.occurred_at,
        'source_type', x.source_type,
        'source_ref', x.source_ref
      )
      order by x.occurred_at desc, x.created_at desc
    ) filter (where x.recent_rank <= 12) as recent_material_events
  from (
    select
      e.*,
      row_number() over(order by e.occurred_at desc, e.created_at desc) as recent_rank
    from public.control_room_project_events e
    where e.project_id = p.id
  ) x
) ev on true
left join lateral (
  select jsonb_agg(
    jsonb_build_object(
      'id', x.id,
      'event_type', x.event_type,
      'summary', x.summary,
      'importance', x.importance,
      'occurred_at', x.occurred_at,
      'source_type', x.source_type,
      'source_ref', x.source_ref
    )
    order by x.occurred_at desc, x.created_at desc
  ) as recent_milestones
  from (
    select e.*
    from public.control_room_project_events e
    where e.project_id = p.id
      and (
        e.metadata ->> 'tracking_class' = 'milestone'
        or e.event_type ~* '(verified|locked|completed|merged|deployed|activated|live)$'
      )
    order by e.occurred_at desc, e.created_at desc
    limit 12
  ) x
) ms on true
left join lateral (
  select max(c.updated_at) as latest_connection_at
  from public.control_room_project_connections c
  where c.project_id = p.id
) cx on true;

revoke all on public.control_room_project_tracking_v1 from public, anon, authenticated;
grant select on public.control_room_project_tracking_v1 to service_role;

create or replace function public.control_room_get_project_tracking_v1(
  p_project_key text
)
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select to_jsonb(t)
  from public.control_room_project_tracking_v1 t
  where t.project_key = p_project_key;
$$;

create or replace function public.control_room_get_project_tracking_surface_v1(
  p_portfolio_class text default null,
  p_lifecycle_status text default null,
  p_changed_since timestamptz default null
)
returns setof public.control_room_project_tracking_v1
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select *
  from public.control_room_project_tracking_v1
  where (p_portfolio_class is null or portfolio_class = p_portfolio_class)
    and (p_lifecycle_status is null or lifecycle_status = p_lifecycle_status)
    and (p_changed_since is null or tracking_changed_at > p_changed_since)
  order by
    case portfolio_class
      when 'CORE' then 0
      when 'EXPERIMENT' then 1
      when 'AUTOPILOT' then 2
      when 'MAINTENANCE' then 3
      when 'VAULT' then 4
      when 'SYSTEM' then 5
      else 6
    end,
    name;
$$;

create or replace function public.control_room_get_tracking_changes_v1(
  p_after_sequence bigint default 0,
  p_limit integer default 100
)
returns table (
  sequence bigint,
  project_key text,
  change_kind text,
  source_table text,
  source_id text,
  occurred_at timestamptz,
  metadata jsonb,
  tracking_fingerprint text
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    f.sequence,
    p.project_key,
    f.change_kind,
    f.source_table,
    f.source_id,
    f.occurred_at,
    f.metadata,
    t.tracking_fingerprint
  from public.control_room_tracking_change_feed_v1 f
  join public.control_room_projects p on p.id = f.project_id
  join public.control_room_project_tracking_v1 t on t.id = f.project_id
  where f.sequence > greatest(coalesce(p_after_sequence, 0), 0)
  order by f.sequence
  limit least(greatest(coalesce(p_limit, 100), 1), 500);
$$;

revoke all on function public.control_room_get_project_tracking_v1(text)
  from public, anon, authenticated;
revoke all on function public.control_room_get_project_tracking_surface_v1(text,text,timestamptz)
  from public, anon, authenticated;
revoke all on function public.control_room_get_tracking_changes_v1(bigint,integer)
  from public, anon, authenticated;

grant execute on function public.control_room_get_project_tracking_v1(text)
  to service_role;
grant execute on function public.control_room_get_project_tracking_surface_v1(text,text,timestamptz)
  to service_role;
grant execute on function public.control_room_get_tracking_changes_v1(bigint,integer)
  to service_role;

-- One baseline change per existing project so a new consumer can start from a
-- durable Meterion-wide cursor without fabricating historical state changes.
insert into public.control_room_tracking_change_feed_v1(
  project_id, change_kind, source_table, source_id, metadata
)
select
  p.id,
  'baseline',
  'control_room_projects',
  p.id::text,
  jsonb_build_object(
    'project_key', p.project_key,
    'state_version', coalesce(s.version, 0),
    'baseline_at', now()
  )
from public.control_room_projects p
left join public.control_room_project_current_v2 s on s.project_id = p.id
where not exists (
  select 1
  from public.control_room_tracking_change_feed_v1 f
  where f.project_id = p.id
    and f.change_kind = 'baseline'
    and f.source_table = 'control_room_projects'
);

commit;
