begin;

create or replace function public.control_room_get_today_v1()
returns setof public.control_room_today_v1
language sql
security definer
set search_path = public
as $$
  select * from public.control_room_today_v1;
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
  if p_state is null or jsonb_typeof(p_state) <> 'object' then
    raise exception 'state_object_required' using errcode = 'P0001';
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
  v_summary text;
  v_row public.control_room_project_events%rowtype;
begin
  if p_event is null or jsonb_typeof(p_event) <> 'object' then
    raise exception 'event_object_required' using errcode = 'P0001';
  end if;

  v_summary := nullif(btrim(p_event->>'summary'), '');
  if v_summary is null then
    raise exception 'event_summary_required' using errcode = 'P0001';
  end if;

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
    v_summary,
    coalesce(nullif(p_event->>'importance',''), 'normal'),
    coalesce((p_event->>'occurred_at')::timestamptz, now()),
    coalesce(nullif(p_event->>'source_type',''), 'manual'),
    nullif(p_event->>'source_ref',''),
    coalesce(p_event->'metadata', '{}'::jsonb)
  )
  returning * into v_row;

  return to_jsonb(v_row);
end;
$$;

revoke all on function public.control_room_get_today_v1() from public, anon, authenticated;
grant execute on function public.control_room_get_today_v1() to service_role;

revoke all on function public.control_room_append_project_state_v1(text, integer, jsonb) from public, anon, authenticated;
grant execute on function public.control_room_append_project_state_v1(text, integer, jsonb) to service_role;

revoke all on function public.control_room_append_project_event_v1(text, jsonb) from public, anon, authenticated;
grant execute on function public.control_room_append_project_event_v1(text, jsonb) to service_role;

commit;
