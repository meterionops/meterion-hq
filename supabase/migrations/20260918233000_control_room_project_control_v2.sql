begin;

alter table public.control_room_project_state_versions
  add column if not exists current_build text,
  add column if not exists definition_of_done text,
  add column if not exists next_gate text,
  add column if not exists gate_status text not null default 'none',
  add column if not exists next_autonomous_run text,
  add column if not exists stop_gates jsonb not null default '[]'::jsonb,
  add column if not exists locked_decisions jsonb not null default '[]'::jsonb,
  add column if not exists last_jev_decision text,
  add column if not exists last_jev_confidence numeric;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'control_room_state_gate_status_check'
  ) then
    alter table public.control_room_project_state_versions
      add constraint control_room_state_gate_status_check
      check (gate_status in ('none','open','passed','blocked','investigate'));
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'control_room_state_stop_gates_array_check'
  ) then
    alter table public.control_room_project_state_versions
      add constraint control_room_state_stop_gates_array_check
      check (jsonb_typeof(stop_gates) = 'array');
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'control_room_state_locked_decisions_array_check'
  ) then
    alter table public.control_room_project_state_versions
      add constraint control_room_state_locked_decisions_array_check
      check (jsonb_typeof(locked_decisions) = 'array');
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'control_room_state_jev_confidence_check'
  ) then
    alter table public.control_room_project_state_versions
      add constraint control_room_state_jev_confidence_check
      check (last_jev_confidence is null or (last_jev_confidence >= 0 and last_jev_confidence <= 1));
  end if;
end
$$;

create or replace view public.control_room_project_current_v2
with (security_invoker = true)
as
select distinct on (s.project_id)
  s.*
from public.control_room_project_state_versions s
order by s.project_id, s.version desc;

create or replace view public.control_room_project_summary_v3
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
  p.operating_mode,
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
  s.current_build,
  s.definition_of_done,
  s.next_gate,
  s.gate_status,
  s.next_autonomous_run,
  s.stop_gates,
  s.locked_decisions,
  s.last_jev_decision,
  s.last_jev_confidence,
  (s.id is null) as state_missing,
  case
    when s.id is null or s.verified_at is null then 'missing'
    when s.verified_at >= now() - interval '24 hours' then 'fresh'
    when s.verified_at >= now() - interval '72 hours' then 'aging'
    else 'stale'
  end as state_freshness,
  case
    when s.verified_at is null then null::numeric
    else round(extract(epoch from now() - s.verified_at) / 3600.0, 1)
  end as state_age_hours,
  e.event_type as latest_event_type,
  e.summary as latest_event_summary,
  e.importance as latest_event_importance,
  e.occurred_at as latest_event_at,
  e.source_type as latest_event_source_type,
  e.source_ref as latest_event_source_ref,
  coalesce(e.occurred_at >= now() - interval '72 hours', false) as recent_material_change,
  cf.url as project_control_file_url,
  cf.external_ref as project_control_file_ref
from public.control_room_projects p
left join public.control_room_project_current_v2 s on s.project_id = p.id
left join lateral (
  select pe.event_type, pe.summary, pe.importance, pe.occurred_at, pe.source_type, pe.source_ref
  from public.control_room_project_events pe
  where pe.project_id = p.id
  order by pe.occurred_at desc, pe.created_at desc
  limit 1
) e on true
left join lateral (
  select pc.url, pc.external_ref
  from public.control_room_project_connections pc
  where pc.project_id = p.id
    and pc.connection_type = 'drive'
    and pc.metadata ->> 'role' = 'project_control'
  order by pc.updated_at desc, pc.created_at desc
  limit 1
) cf on true;

create or replace function public.control_room_get_project_state_v3(p_project_key text)
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select to_jsonb(x)
  from public.control_room_project_summary_v3 x
  where x.project_key = p_project_key;
$$;

create or replace view public.control_room_projects_surface_v3
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
    case when s.portfolio_class = 'UNCONFIRMED' then 'classification_unconfirmed' end,
    case when s.lifecycle_status = 'unconfirmed' then 'lifecycle_unconfirmed' end,
    case when s.state_freshness = 'missing' then 'state_missing' end,
    case when s.state_freshness = 'stale' then 'state_stale' end
  ], null) as verification_flags,
  coalesce(c.connection_count, 0) as connection_count,
  c.primary_connection_type,
  c.primary_connection_label,
  c.primary_connection_ref,
  c.primary_connection_url,
  (s.operating_mode = 'operate') as published_operating
from public.control_room_project_summary_v3 s
left join lateral (
  select
    count(*)::integer as connection_count,
    (array_agg(pc.connection_type order by pc.is_primary desc, pc.created_at))[1] as primary_connection_type,
    (array_agg(pc.label order by pc.is_primary desc, pc.created_at))[1] as primary_connection_label,
    (array_agg(pc.external_ref order by pc.is_primary desc, pc.created_at))[1] as primary_connection_ref,
    (array_agg(pc.url order by pc.is_primary desc, pc.created_at))[1] as primary_connection_url
  from public.control_room_project_connections pc
  where pc.project_id = s.id
) c on true;

create or replace function public.control_room_get_projects_surface_v3(
  p_projects_section text default null,
  p_portfolio_class text default null,
  p_state_freshness text default null
)
returns setof public.control_room_projects_surface_v3
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select *
  from public.control_room_projects_surface_v3
  where (p_projects_section is null or projects_section = p_projects_section)
    and (p_portfolio_class is null or portfolio_class = p_portfolio_class)
    and (p_state_freshness is null or state_freshness = p_state_freshness)
  order by
    case projects_section
      when 'active_portfolio' then 0
      when 'active_unclassified' then 1
      when 'unconfirmed_identity' then 2
      when 'inactive' then 3
      when 'system' then 4
      else 5
    end,
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

create or replace function public.control_room_append_project_state_v2(
  p_project_key text,
  p_expected_version integer,
  p_state jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_project public.control_room_projects%rowtype;
  v_current_version integer;
  v_new_version integer;
  v_row public.control_room_project_state_versions%rowtype;
  v_stop_gates jsonb;
  v_locked_decisions jsonb;
begin
  if p_state is null or jsonb_typeof(p_state) <> 'object' then
    raise exception 'state_object_required' using errcode = 'P0001';
  end if;

  v_stop_gates := coalesce(p_state -> 'stop_gates', '[]'::jsonb);
  v_locked_decisions := coalesce(p_state -> 'locked_decisions', '[]'::jsonb);

  if jsonb_typeof(v_stop_gates) <> 'array' or jsonb_typeof(v_locked_decisions) <> 'array' then
    raise exception 'control_arrays_required' using errcode = 'P0001';
  end if;

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
    confidence, verified_at, source_type, source_ref,
    current_build, definition_of_done, next_gate, gate_status, next_autonomous_run,
    stop_gates, locked_decisions, last_jev_decision, last_jev_confidence
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
    nullif(p_state->>'source_ref',''),
    nullif(p_state->>'current_build',''),
    nullif(p_state->>'definition_of_done',''),
    nullif(p_state->>'next_gate',''),
    coalesce(nullif(p_state->>'gate_status',''), 'none'),
    nullif(p_state->>'next_autonomous_run',''),
    v_stop_gates,
    v_locked_decisions,
    nullif(p_state->>'last_jev_decision',''),
    nullif(p_state->>'last_jev_confidence','')::numeric
  )
  returning * into v_row;

  return to_jsonb(v_row);
end;
$$;

create or replace function public.control_room_get_resume_packet_v2(p_project_key text)
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

  v_state := public.control_room_get_project_state_v3(p_project_key);

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'type', c.connection_type,
        'label', c.label,
        'external_ref', c.external_ref,
        'url', c.url,
        'is_primary', c.is_primary,
        'metadata', c.metadata
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
    'packet_version', 2,
    'project', v_state,
    'operating_mode', v_operating_mode,
    'work_mode', v_work_mode,
    'reconciliation', coalesce(v_reconciliation, '{}'::jsonb),
    'connections', v_connections,
    'recent_material_events', v_events
  );
end;
$$;

revoke all on public.control_room_project_current_v2 from anon, authenticated;
revoke all on public.control_room_project_summary_v3 from anon, authenticated;
revoke all on public.control_room_projects_surface_v3 from anon, authenticated;

revoke all on function public.control_room_get_project_state_v3(text) from public, anon, authenticated;
revoke all on function public.control_room_get_projects_surface_v3(text,text,text) from public, anon, authenticated;
revoke all on function public.control_room_append_project_state_v2(text,integer,jsonb) from public, anon, authenticated;
revoke all on function public.control_room_get_resume_packet_v2(text) from public, anon, authenticated;

grant execute on function public.control_room_get_project_state_v3(text) to service_role;
grant execute on function public.control_room_get_projects_surface_v3(text,text,text) to service_role;
grant execute on function public.control_room_append_project_state_v2(text,integer,jsonb) to service_role;
grant execute on function public.control_room_get_resume_packet_v2(text) to service_role;

commit;
