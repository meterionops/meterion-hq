-- PER-1 fail-closed budget stop semantics.

CREATE OR REPLACE FUNCTION public.control_room_refresh_project_graph_v1(p_run_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $
declare
  v_graph public.control_room_project_graph_runs_v1%rowtype;
  v_envelope public.control_room_run_envelopes%rowtype;
  v_action_space jsonb;
  v_resume_from text;
  v_status text;
  v_envelope_status text;
  v_stop_reason text;
  v_total integer;
  v_success_terminal integer;
  v_cancelled integer;
  v_plain_stop_failed integer;
  v_attempt_exhausted integer;
  v_retry_budget_exhausted integer;
  v_active integer;
  v_ready integer;
  v_waiting_session integer;
  v_waiting_owner integer;
  v_action_budget_exhausted boolean := false;
begin
  select * into v_graph
  from public.control_room_project_graph_runs_v1
  where run_key = p_run_key
  for update;

  if not found then
    raise exception 'graph_run_not_found' using errcode = 'P0001';
  end if;

  select * into v_envelope
  from public.control_room_run_envelopes
  where run_key = p_run_key
  for update;

  if not found then
    raise exception 'run_envelope_not_found' using errcode = 'P0001';
  end if;

  update public.control_room_project_graph_nodes_v1 n
  set
    status = case
      when not exists (
        select 1
        from public.control_room_project_graph_edges_v1 e
        join public.control_room_project_graph_nodes_v1 src
          on src.graph_run_key = e.graph_run_key
         and src.id = e.from_node_id
        where e.graph_run_key = p_run_key
          and e.to_node_id = n.id
          and not (
            (e.required_status = 'completed' and src.status = 'completed')
            or (e.required_status = 'failed' and src.status = 'failed')
            or (e.required_status = 'terminal' and src.status in ('completed','failed','skipped','cancelled'))
          )
      )
      then case n.execution_mode
        when 'human_gate' then 'waiting_owner'
        when 'chatgpt_session' then 'waiting_session'
        else 'ready'
      end
      else 'waiting_dependency'
    end,
    updated_at = now()
  where n.graph_run_key = p_run_key
    and n.status in ('pending','waiting_dependency');

  select
    count(*),
    count(*) filter (where status in ('completed','skipped')),
    count(*) filter (where status = 'cancelled'),
    count(*) filter (
      where status = 'failed'
        and failure_policy = 'stop'
        and not exists (
          select 1 from public.control_room_project_graph_edges_v1 e
          where e.graph_run_key = p_run_key
            and e.from_node_id = n.id
            and e.required_status in ('failed','terminal')
        )
    ),
    count(*) filter (
      where status = 'failed'
        and failure_policy in ('retry','repair','fallback')
        and attempt_count >= max_attempts
        and not exists (
          select 1 from public.control_room_project_graph_edges_v1 e
          where e.graph_run_key = p_run_key
            and e.from_node_id = n.id
            and e.required_status in ('failed','terminal')
        )
    ),
    count(*) filter (
      where status = 'failed'
        and failure_policy in ('retry','repair','fallback')
        and attempt_count < max_attempts
        and v_envelope.max_retries is not null
        and v_envelope.retries_used >= v_envelope.max_retries
        and not exists (
          select 1 from public.control_room_project_graph_edges_v1 e
          where e.graph_run_key = p_run_key
            and e.from_node_id = n.id
            and e.required_status in ('failed','terminal')
        )
    ),
    count(*) filter (where status in ('ready','running','verifying')),
    count(*) filter (where status = 'ready'),
    count(*) filter (where status = 'waiting_session'),
    count(*) filter (where status = 'waiting_owner')
  into
    v_total, v_success_terminal, v_cancelled, v_plain_stop_failed,
    v_attempt_exhausted, v_retry_budget_exhausted, v_active, v_ready,
    v_waiting_session, v_waiting_owner
  from public.control_room_project_graph_nodes_v1 n
  where graph_run_key = p_run_key;

  if v_total = 0 then
    raise exception 'graph_requires_nodes' using errcode = 'P0001';
  end if;

  v_action_budget_exhausted :=
    v_ready > 0
    and v_envelope.max_actions is not null
    and v_envelope.actions_used >= v_envelope.max_actions;

  if v_plain_stop_failed > 0 then
    v_status := 'failed';
    v_stop_reason := 'graph_failed';
  elsif v_attempt_exhausted > 0 then
    v_status := 'failed';
    v_stop_reason := 'node_attempt_budget_exhausted';
  elsif v_retry_budget_exhausted > 0 then
    v_status := 'failed';
    v_stop_reason := 'retry_budget_exhausted';
  elsif v_action_budget_exhausted then
    v_status := 'failed';
    v_stop_reason := 'action_budget_exhausted';
  elsif v_success_terminal = v_total then
    v_status := 'completed';
    v_stop_reason := null;
  elsif v_success_terminal + v_cancelled = v_total and v_cancelled > 0 then
    v_status := 'cancelled';
    v_stop_reason := 'graph_cancelled';
  elsif v_active > 0 then
    v_status := 'active';
    v_stop_reason := null;
  else
    v_status := 'waiting';
    v_stop_reason := case
      when v_waiting_owner > 0 then 'waiting_owner'
      when v_waiting_session > 0 then 'waiting_session'
      else null
    end;
  end if;

  if v_status = 'active' then
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'node_key', node_key,
          'node_type', node_type,
          'execution_mode', execution_mode,
          'required_capability', required_capability,
          'authority_class', authority_class
        )
        order by node_index, node_key
      ),
      '[]'::jsonb
    )
    into v_action_space
    from public.control_room_project_graph_nodes_v1
    where graph_run_key = p_run_key
      and status = 'ready';
  else
    v_action_space := '[]'::jsonb;
  end if;

  v_resume_from := null;

  if v_status = 'active' then
    select node_key into v_resume_from
    from public.control_room_project_graph_nodes_v1
    where graph_run_key = p_run_key and status = 'ready'
    order by node_index, node_key
    limit 1;
  elsif v_status = 'waiting' then
    select node_key into v_resume_from
    from public.control_room_project_graph_nodes_v1 n
    where n.graph_run_key = p_run_key
      and n.status = 'failed'
      and n.attempt_count < n.max_attempts
      and n.failure_policy in ('retry','repair','fallback')
      and (v_envelope.max_retries is null or v_envelope.retries_used < v_envelope.max_retries)
      and not exists (
        select 1 from public.control_room_project_graph_edges_v1 e
        where e.graph_run_key = p_run_key
          and e.from_node_id = n.id
          and e.required_status in ('failed','terminal')
      )
    order by node_index, node_key
    limit 1;

    if v_resume_from is null then
      select node_key into v_resume_from
      from public.control_room_project_graph_nodes_v1
      where graph_run_key = p_run_key
        and status in ('waiting_session','waiting_owner')
      order by
        case status when 'waiting_session' then 0 else 1 end,
        node_index,
        node_key
      limit 1;
    end if;
  end if;

  update public.control_room_project_graph_runs_v1
  set
    status = v_status,
    started_at = coalesce(started_at, case when v_status <> 'planned' then now() else null end),
    completed_at = case
      when v_status in ('completed','failed','cancelled') then coalesce(completed_at, now())
      else null
    end,
    updated_at = now()
  where run_key = p_run_key;

  update public.control_room_project_work_units_v1
  set
    status = case v_status
      when 'active' then 'active'
      when 'waiting' then 'waiting'
      when 'verifying' then 'active'
      when 'completed' then 'completed'
      when 'failed' then 'failed'
      when 'cancelled' then 'cancelled'
      else status
    end,
    completed_at = case
      when v_status in ('completed','failed','cancelled') then coalesce(completed_at, now())
      else null
    end,
    updated_at = now()
  where id = v_graph.work_unit_id;

  v_envelope_status := case v_status
    when 'active' then 'active'
    when 'waiting' then 'paused'
    when 'verifying' then 'active'
    when 'completed' then 'completed'
    when 'failed' then 'blocked'
    when 'cancelled' then 'paused'
    else 'active'
  end;

  update public.control_room_run_envelopes
  set
    status = v_envelope_status,
    action_space = v_action_space,
    resume_from = v_resume_from,
    stop_reason = v_stop_reason,
    updated_at = now()
  where run_key = p_run_key;

  return public.control_room_get_project_work_graph_v1(p_run_key);
end;
$;

CREATE OR REPLACE FUNCTION public.control_room_transition_project_graph_node_v1(p_run_key text, p_node_key text, p_expected_status text, p_new_status text, p_result jsonb DEFAULT NULL::jsonb, p_evidence jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $
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
    where run_key = p_run_key
    for update;

    if not found then
      raise exception 'graph_run_not_found' using errcode = 'P0001';
    end if;

    if v_graph.status in ('completed','failed','cancelled') then
      raise exception 'graph_run_not_executable:%', v_graph.status using errcode = 'P0001';
    end if;

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
$;

revoke all on function public.control_room_refresh_project_graph_v1(text) from public, anon, authenticated;
revoke all on function public.control_room_transition_project_graph_node_v1(text,text,text,text,jsonb,jsonb) from public, anon, authenticated;
grant execute on function public.control_room_refresh_project_graph_v1(text) to service_role;
grant execute on function public.control_room_transition_project_graph_node_v1(text,text,text,text,jsonb,jsonb) to service_role;
