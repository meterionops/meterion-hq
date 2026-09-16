begin;

-- Resume Anywhere v1
--
-- One compact server-side packet for orienting a new work session before it
-- deep-fetches source systems. This deliberately contains project-level state,
-- source pointers and a short material-event tail only; it is not a transcript,
-- task history or copy of source-system data.

create or replace function public.control_room_get_resume_packet_v1(p_project_key text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_project_id uuid;
  v_state jsonb;
  v_connections jsonb;
  v_events jsonb;
  v_reconciliation jsonb;
  v_work_mode text;
begin
  select id
  into v_project_id
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
      )
      order by c.is_primary desc, c.connection_type, c.label
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
      )
      order by e.occurred_at desc
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
    when v_state ->> 'autonomy_state' = 'waiting' then 'verify_dependency_before_work'
    when v_state ->> 'autonomy_state' = 'inactive' then 'do_not_resume_without_reactivation'
    when v_state ->> 'lifecycle_status' in ('paused','completed','archived') then 'do_not_resume_without_reactivation'
    else 'continue_from_next_best_action'
  end;

  return jsonb_build_object(
    'packet_version', 1,
    'project', v_state,
    'work_mode', v_work_mode,
    'reconciliation', coalesce(v_reconciliation, '{}'::jsonb),
    'connections', v_connections,
    'recent_material_events', v_events
  );
end;
$$;

revoke all on function public.control_room_get_resume_packet_v1(text) from public, anon, authenticated;
grant execute on function public.control_room_get_resume_packet_v1(text) to service_role;

comment on function public.control_room_get_resume_packet_v1(text) is
  'Compact Resume Anywhere packet: current project state, freshness/source pointers and up to five recent material events. No source payload copying.';

commit;
