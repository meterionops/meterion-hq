begin;

-- Control Room Operating Mode v1
-- Owner authority: OWNER_RECONCILIATION_V4.md / 2026-09-17.
-- Separates strategic portfolio class from the kind of work currently required.

alter table public.control_room_projects
  add column if not exists operating_mode text not null default 'unconfirmed';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'control_room_projects_operating_mode_check'
      and conrelid = 'public.control_room_projects'::regclass
  ) then
    alter table public.control_room_projects
      add constraint control_room_projects_operating_mode_check
      check (operating_mode in ('build','operate','idea','delivery','paused','system','unconfirmed'));
  end if;
end
$$;

-- Owner-confirmed operating-mode baseline.
update public.control_room_projects
set operating_mode = case project_key
  when 'meterion-control-room' then 'system'
  when 'calendar-platform' then 'operate'
  when 'yritystiedot' then 'operate'
  when 'nordic-bottle-index' then 'operate'
  when 'korvauskirje' then 'operate'
  when 'lomakone' then 'operate'
  when 'microapps-factory' then 'idea'
  when 'foreign-contractor-finland' then 'idea'
  when 'sprinkler-water-tank-site' then 'delivery'
  when 'volaire' then 'paused'
  when 'pelovio' then 'paused'
  when 'avoinna' then 'paused'
  when 'digiapu247' then 'paused'
  when 'ai-company-os' then 'build'
  when 'maistio' then 'build'
  when 'cala-europe' then 'build'
  when 'sprinkler-rfq-platform' then 'build'
  when 'rail-atlas' then 'build'
  when 'folio' then 'build'
  when 'house-of-flores' then 'build'
  when 'fire-sprinkler-hub' then 'build'
  else operating_mode
end,
updated_at = now();

-- Owner explicitly removed Namorada from Control Room entirely.
-- Child state/event/connection rows cascade with the registry row.
delete from public.control_room_projects
where project_key = 'namorada';

-- Extend Projects v2 without changing the canonical state model.
-- New fields are appended so existing consumers retain their column order.
create or replace view public.control_room_projects_surface_v2
with (security_invoker = true)
as
select
  s.*,
  (s.portfolio_class <> 'UNCONFIRMED') as classification_verified,
  (s.lifecycle_status <> 'unconfirmed') as lifecycle_verified,
  case
    when s.portfolio_class = 'SYSTEM' then 'system'
    when s.lifecycle_status = 'active' and s.portfolio_class = 'UNCONFIRMED' then 'active_unclassified'
    when s.lifecycle_status = 'active' then 'active_portfolio'
    when s.lifecycle_status = 'unconfirmed' then 'unconfirmed_identity'
    else 'inactive'
  end as projects_section,
  case
    when s.lifecycle_status = 'active' and s.state_freshness in ('stale','missing') then true
    else false
  end as state_quality_exception,
  array_remove(array[
    case when s.portfolio_class = 'UNCONFIRMED' then 'classification_unconfirmed'::text end,
    case when s.lifecycle_status = 'unconfirmed' then 'lifecycle_unconfirmed'::text end,
    case when s.state_freshness = 'missing' then 'state_missing'::text end,
    case when s.state_freshness = 'stale' then 'state_stale'::text end
  ], null) as verification_flags,
  coalesce(c.connection_count, 0)::integer as connection_count,
  c.primary_connection_type,
  c.primary_connection_label,
  c.primary_connection_ref,
  c.primary_connection_url,
  p.operating_mode,
  (p.operating_mode = 'operate') as published_operating
from public.control_room_project_summary_v2 s
join public.control_room_projects p on p.id = s.id
left join lateral (
  select
    count(*)::integer as connection_count,
    (array_agg(pc.connection_type order by pc.is_primary desc, pc.created_at asc))[1] as primary_connection_type,
    (array_agg(pc.label order by pc.is_primary desc, pc.created_at asc))[1] as primary_connection_label,
    (array_agg(pc.external_ref order by pc.is_primary desc, pc.created_at asc))[1] as primary_connection_ref,
    (array_agg(pc.url order by pc.is_primary desc, pc.created_at asc))[1] as primary_connection_url
  from public.control_room_project_connections pc
  where pc.project_id = s.id
) c on true;

create or replace view public.control_room_projects_overview_v2
with (security_invoker = true)
as
select
  count(*)::integer as total_registered,
  count(*) filter (where projects_section = 'active_portfolio')::integer as active_portfolio_count,
  count(*) filter (where projects_section = 'active_unclassified')::integer as active_unclassified_count,
  count(*) filter (where projects_section = 'unconfirmed_identity')::integer as unconfirmed_identity_count,
  count(*) filter (where projects_section = 'inactive')::integer as inactive_count,
  count(*) filter (where projects_section = 'system')::integer as system_count,
  count(*) filter (where state_quality_exception)::integer as active_state_quality_exception_count,
  count(*) filter (where state_freshness = 'missing')::integer as missing_state_count,
  count(*) filter (where founder_attention_required)::integer as owner_attention_count,
  coalesce(sum(connection_count), 0)::integer as connection_count,
  count(*) filter (where lifecycle_status = 'active' and operating_mode = 'operate')::integer as operating_count,
  count(*) filter (where lifecycle_status = 'active' and operating_mode = 'build')::integer as build_count,
  count(*) filter (where operating_mode = 'idea')::integer as idea_count,
  count(*) filter (where operating_mode = 'delivery')::integer as delivery_count
from public.control_room_projects_surface_v2;

-- Keep Resume Anywhere aware of whether a project is build work or published operation.
create or replace function public.control_room_get_resume_packet_v1(p_project_key text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_project_id uuid;
  v_operating_mode text;
  v_state jsonb;
  v_connections jsonb;
  v_events jsonb;
  v_reconciliation jsonb;
  v_work_mode text;
begin
  select id, operating_mode
  into v_project_id, v_operating_mode
  from public.control_room_projects
  where project_key = p_project_key;

  if v_project_id is null then
    raise exception 'project_not_found';
  end if;

  v_state := public.control_room_get_project_state_v2(p_project_key);

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'type', c.connection_type,
        'label', c.label,
        'external_ref', c.external_ref,
        'url', c.url,
        'is_primary', c.is_primary
      ) order by c.is_primary desc, c.connection_type, c.label
    ),
    '[]'::jsonb
  )
  into v_connections
  from public.control_room_project_connections c
  where c.project_id = v_project_id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'event_type', e.event_type,
        'summary', e.summary,
        'importance', e.importance,
        'occurred_at', e.occurred_at,
        'source_type', e.source_type,
        'source_ref', e.source_ref
      ) order by e.occurred_at desc
    ),
    '[]'::jsonb
  )
  into v_events
  from (
    select event_type, summary, importance, occurred_at, source_type, source_ref
    from public.control_room_project_events
    where project_id = v_project_id
      and importance in ('normal','high','critical')
    order by occurred_at desc
    limit 5
  ) e;

  select jsonb_build_object(
    'state_freshness', r.state_freshness,
    'state_age_hours', r.state_age_hours,
    'verified_at', r.verified_at,
    'target_refresh_hours', r.target_refresh_hours,
    'refresh_mode', r.refresh_mode,
    'refresh_due', r.refresh_due,
    'safe_to_auto_refresh', r.safe_to_auto_refresh,
    'reconciliation_priority', r.reconciliation_priority,
    'reconciliation_reason', r.reconciliation_reason,
    'primary_connection_type', r.primary_connection_type,
    'primary_connection_label', r.primary_connection_label,
    'primary_connection_ref', r.primary_connection_ref,
    'primary_connection_url', r.primary_connection_url
  )
  into v_reconciliation
  from public.control_room_state_reconciliation_v1 r
  where r.project_key = p_project_key;

  v_work_mode := case
    when coalesce((v_state ->> 'founder_attention_required')::boolean, false) then 'stop_for_owner'
    when v_state ->> 'autonomy_state' = 'owner_needed' then 'stop_for_owner'
    when v_state ->> 'lifecycle_status' in ('paused','completed','archived') then 'do_not_resume_without_reactivation'
    when v_state ->> 'autonomy_state' = 'waiting' then 'verify_dependency_before_work'
    when v_state ->> 'autonomy_state' = 'inactive' then 'idle_until_requested'
    else 'continue_from_next_best_action'
  end;

  return jsonb_build_object(
    'packet_version', 1,
    'project', v_state,
    'operating_mode', v_operating_mode,
    'work_mode', v_work_mode,
    'reconciliation', coalesce(v_reconciliation, '{}'::jsonb),
    'connections', v_connections,
    'recent_material_events', v_events
  );
end;
$$;

revoke all on function public.control_room_get_resume_packet_v1(text) from public, anon, authenticated;
grant execute on function public.control_room_get_resume_packet_v1(text) to service_role;

comment on column public.control_room_projects.operating_mode is
  'Owner-controlled work-mode dimension: build, operate, idea, delivery, paused, system or unconfirmed. Separate from portfolio class and lifecycle.';
comment on view public.control_room_projects_surface_v2 is
  'Projects v2 read model with portfolio status, source summary and explicit build-vs-operate operating mode.';
comment on view public.control_room_projects_overview_v2 is
  'Compact Projects v2 counts including published/operating versus build work.';
comment on function public.control_room_get_resume_packet_v1(text) is
  'Compact Resume Anywhere packet with operating mode, current project state, freshness/source pointers, work mode and recent material events.';

commit;
