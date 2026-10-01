begin;

do $$
declare
  v_project_key text := 'ai-company-os';
  v_other_project_key text;
  v_project_id uuid;
  v_other_project_id uuid;
  v_version integer;
  v_other_fingerprint_before text;
  v_fingerprint_before text;
  v_fingerprint_after text;
  v_sequence_before bigint;
  v_sequence_after bigint;
  v_event jsonb;
  v_state jsonb;
  v_changes integer;
begin
  select p.id, coalesce(t.state_version, 0), t.tracking_fingerprint
  into v_project_id, v_version, v_fingerprint_before
  from public.control_room_project_tracking_v1 t
  join public.control_room_projects p on p.id=t.id
  where t.project_key=v_project_key;

  if v_project_id is null then
    raise exception 'tracking_test_project_missing';
  end if;

  select t.project_key, t.id, t.tracking_fingerprint
  into v_other_project_key, v_other_project_id, v_other_fingerprint_before
  from public.control_room_project_tracking_v1 t
  where t.project_key <> v_project_key
  order by t.project_key
  limit 1;

  select coalesce(max(sequence), 0)
  into v_sequence_before
  from public.control_room_tracking_change_feed_v1;

  v_state := public.control_room_patch_project_state_v1(
    v_project_key,
    v_version,
    jsonb_build_object(
      'current_focus', 'Tracking Sync v1 rollback verification',
      'next_best_action', 'Rollback after tracking projection proof',
      'source_type', 'test',
      'source_ref', 'project_tracking_sync_v1',
      'verified_at', now()
    )
  );

  select tracking_fingerprint
  into v_fingerprint_after
  from public.control_room_project_tracking_v1
  where project_key=v_project_key;

  if v_fingerprint_after is not distinct from v_fingerprint_before then
    raise exception 'tracking_fingerprint_did_not_change_after_state_commit';
  end if;

  v_event := public.control_room_append_project_event_v1(
    v_project_key,
    jsonb_build_object(
      'event_type', 'tracking_sync_v1_test_verified',
      'summary', 'Tracking Sync v1 rollback canary',
      'importance', 'normal',
      'source_type', 'test',
      'source_ref', 'project_tracking_sync_v1',
      'metadata', jsonb_build_object('tracking_class','milestone')
    )
  );

  if not exists (
    select 1
    from public.control_room_project_tracking_v1 t,
         lateral jsonb_array_elements(t.recent_material_events) e
    where t.project_key=v_project_key
      and e->>'event_type'='tracking_sync_v1_test_verified'
  ) then
    raise exception 'tracking_recent_event_missing';
  end if;

  if not exists (
    select 1
    from public.control_room_project_tracking_v1 t,
         lateral jsonb_array_elements(t.recent_milestones) e
    where t.project_key=v_project_key
      and e->>'event_type'='tracking_sync_v1_test_verified'
  ) then
    raise exception 'tracking_milestone_missing';
  end if;

  select coalesce(max(sequence), 0)
  into v_sequence_after
  from public.control_room_tracking_change_feed_v1;

  if v_sequence_after <= v_sequence_before then
    raise exception 'tracking_change_feed_not_advanced';
  end if;

  select count(*)
  into v_changes
  from public.control_room_get_tracking_changes_v1(v_sequence_before, 100)
  where project_key=v_project_key
    and change_kind in ('project_state','material_event');

  if v_changes < 2 then
    raise exception 'tracking_change_feed_missing_expected_changes:%', v_changes;
  end if;

  if v_other_project_id is not null and (
    select tracking_fingerprint
    from public.control_room_project_tracking_v1
    where id=v_other_project_id
  ) is distinct from v_other_fingerprint_before then
    raise exception 'unrelated_project_tracking_fingerprint_changed';
  end if;

  if not exists (
    select 1
    from public.control_room_get_project_tracking_surface_v1(null, null, null)
    where project_key=v_project_key
  ) then
    raise exception 'tracking_surface_missing_project';
  end if;

  if public.control_room_get_project_tracking_v1(v_project_key) is null then
    raise exception 'tracking_project_rpc_missing';
  end if;
end
$$;

rollback;
