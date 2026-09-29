create or replace function public.control_room_transition_project_graph_node_v1(
  p_run_key text,
  p_node_key text,
  p_expected_status text,
  p_new_status text,
  p_result jsonb default null,
  p_evidence jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_node public.control_room_project_graph_nodes_v1%rowtype;
  v_graph public.control_room_project_graph_runs_v1%rowtype;
  v_work_unit_key text;
  v_checkpoint jsonb;
begin
  if p_evidence is null or jsonb_typeof(p_evidence) <> 'object' then
    raise exception 'evidence_object_required' using errcode = 'P0001';
  end if;
  if p_result is not null and jsonb_typeof(p_result) <> 'object' then
    raise exception 'result_object_required' using errcode = 'P0001';
  end if;

  select * into v_node
  from public.control_room_project_graph_nodes_v1
  where graph_run_key = p_run_key
    and node_key = p_node_key
  for update;

  if not found then
    raise exception 'graph_node_not_found' using errcode = 'P0001';
  end if;

  if v_node.status <> p_expected_status then
    raise exception 'node_status_conflict:expected=%,actual=%',
      p_expected_status, v_node.status using errcode = 'P0001';
  end if;

  if not (
    (v_node.status = 'ready' and p_new_status in ('running','waiting_session','waiting_owner','skipped','cancelled'))
    or (v_node.status = 'waiting_session' and p_new_status in ('ready','cancelled'))
    or (v_node.status = 'waiting_owner' and p_new_status in ('ready','cancelled'))
    or (v_node.status = 'running' and p_new_status in ('verifying','completed','failed','waiting_session','waiting_owner'))
    or (v_node.status = 'verifying' and p_new_status in ('completed','failed'))
  ) then
    raise exception 'invalid_node_transition:%->%', v_node.status, p_new_status using errcode = 'P0001';
  end if;

  if p_new_status = 'running' and v_node.attempt_count >= v_node.max_attempts then
    raise exception 'node_attempt_budget_exhausted' using errcode = 'P0001';
  end if;

  if p_new_status = 'running' then
    select * into v_graph
    from public.control_room_project_graph_runs_v1
    where run_key = p_run_key;

    perform public.control_room_checkpoint_run_v1(
      p_run_key,
      v_graph.project_id,
      null,
      'active',
      1,
      0,
      0,
      0,
      null,
      null,
      null,
      null,
      p_node_key,
      null
    );
  end if;

  update public.control_room_project_graph_nodes_v1
  set
    status = p_new_status,
    attempt_count = attempt_count + case when p_new_status = 'running' then 1 else 0 end,
    result = case when p_result is not null then p_result else result end,
    evidence = evidence || p_evidence,
    started_at = case when p_new_status = 'running' then coalesce(started_at, now()) else started_at end,
    completed_at = case when p_new_status in ('completed','failed','skipped','cancelled') then now() else completed_at end,
    updated_at = now()
  where id = v_node.id;

  if p_new_status = 'completed' then
    select w.work_unit_key into v_work_unit_key
    from public.control_room_project_graph_runs_v1 g
    join public.control_room_project_work_units_v1 w on w.id = g.work_unit_id
    where g.run_key = p_run_key;

    select jsonb_build_object(
      'work_unit_key', v_work_unit_key,
      'graph_run_key', p_run_key,
      'completed_nodes', coalesce(
        jsonb_agg(node_key order by node_index, node_key)
          filter (where status = 'completed'),
        '[]'::jsonb
      ),
      'last_completed_node', p_node_key,
      'checkpointed_at', now()
    )
    into v_checkpoint
    from public.control_room_project_graph_nodes_v1
    where graph_run_key = p_run_key;

    update public.control_room_run_envelopes
    set last_verified_checkpoint = v_checkpoint, updated_at = now()
    where run_key = p_run_key;
  end if;

  return public.control_room_refresh_project_graph_v1(p_run_key);
end;
$$;

revoke all on function public.control_room_transition_project_graph_node_v1(text,text,text,text,jsonb,jsonb)
  from public, anon, authenticated;
grant execute on function public.control_room_transition_project_graph_node_v1(text,text,text,text,jsonb,jsonb)
  to service_role;
