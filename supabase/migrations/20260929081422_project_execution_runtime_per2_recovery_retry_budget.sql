-- PER-2 stale execution retry recovery must consume the canonical Run Envelope retry budget.

CREATE OR REPLACE FUNCTION public.control_room_wake_project_graph_v2(p_run_key text, p_wake_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $$
declare
  v_graph public.control_room_project_graph_runs_v1%rowtype;
  v_envelope public.control_room_run_envelopes%rowtype;
  v_existing public.control_room_project_graph_wakes_v2%rowtype;
  v_node public.control_room_project_graph_nodes_v1%rowtype;
  v_request jsonb;
  v_request_hash text;
  v_recovered jsonb := '[]'::jsonb;
  v_recovery_mode text;
  v_to_status text;
  v_exception_key text;
  v_transition_key text;
  v_transition_request jsonb;
  v_transition_response jsonb;
  v_response jsonb;
  v_runtime jsonb;
begin
  if p_wake_key is null or btrim(p_wake_key) = '' or char_length(p_wake_key) > 240 then
    raise exception 'invalid_wake_key' using errcode = 'P0001';
  end if;

  v_request := jsonb_build_object(
    'kind','wake',
    'run_key',p_run_key,
    'wake_key',p_wake_key
  );
  v_request_hash := md5(v_request::text);

  select * into v_graph
  from public.control_room_project_graph_runs_v1
  where run_key = p_run_key
  for update;

  if not found then
    raise exception 'graph_run_not_found' using errcode = 'P0001';
  end if;

  if v_graph.runtime_version <> 2 then
    raise exception 'graph_runtime_version_mismatch:expected=2,actual=%',
      v_graph.runtime_version using errcode = 'P0001';
  end if;

  select * into v_envelope
  from public.control_room_run_envelopes
  where run_key = p_run_key
  for update;

  if not found then
    raise exception 'run_envelope_not_found' using errcode = 'P0001';
  end if;

  select * into v_existing
  from public.control_room_project_graph_wakes_v2
  where graph_run_key = p_run_key
    and wake_key = p_wake_key;

  if found then
    if v_existing.request_hash <> v_request_hash then
      raise exception 'wake_key_conflict' using errcode = 'P0001';
    end if;

    return public.control_room_get_project_graph_runtime_v2(p_run_key)
      || jsonb_build_object(
        'wake', v_existing.response,
        'idempotent_wake_replay', true
      );
  end if;

  if v_graph.status in ('completed','cancelled') then
    v_response := jsonb_build_object(
      'wake_key',p_wake_key,
      'recovered_nodes','[]'::jsonb,
      'terminal',true
    );

    insert into public.control_room_project_graph_wakes_v2(
      graph_run_key,wake_key,request_hash,response
    ) values (
      p_run_key,p_wake_key,v_request_hash,v_response
    );

    return public.control_room_get_project_graph_runtime_v2(p_run_key)
      || jsonb_build_object(
        'wake',v_response,
        'idempotent_wake_replay',false
      );
  end if;

  for v_node in
    select *
    from public.control_room_project_graph_nodes_v1
    where graph_run_key = p_run_key
      and status in ('running','verifying')
      and execution_token is not null
      and lease_expires_at is not null
      and lease_expires_at <= clock_timestamp()
    order by node_index, node_key
    for update
  loop
    if v_node.status = 'verifying' then
      v_recovery_mode := 'resume_verification';
      v_to_status := 'verifying';

      update public.control_room_project_graph_nodes_v1
      set
        execution_token = null,
        heartbeat_at = null,
        lease_expires_at = null,
        interruption_count = interruption_count + 1,
        last_recovered_at = clock_timestamp(),
        evidence = evidence || jsonb_build_object(
          'last_recovery',
          jsonb_build_object(
            'mode',v_recovery_mode,
            'execution_epoch',v_node.execution_epoch,
            'recovered_at',now()
          )
        ),
        updated_at = now()
      where id = v_node.id;

      v_exception_key := 'stale-verification:' || v_node.node_key || ':' || v_node.execution_epoch::text;

      insert into public.control_room_project_graph_exceptions_v1(
        graph_run_key,node_id,exception_key,code,severity,status,details
      ) values (
        p_run_key,
        v_node.id,
        v_exception_key,
        'stale_verification_interrupted',
        'warning',
        'open',
        jsonb_build_object(
          'node_key',v_node.node_key,
          'execution_epoch',v_node.execution_epoch,
          'recovery_mode',v_recovery_mode
        )
      )
      on conflict (graph_run_key, exception_key) do nothing;

    elsif v_node.recovery_policy = 'retry' then
      if v_node.attempt_count < v_node.max_attempts then
        if v_envelope.max_retries is not null
           and v_envelope.retries_used >= v_envelope.max_retries then
          v_recovery_mode := 'retry_budget_exhausted';
          v_to_status := 'failed';

          update public.control_room_project_graph_nodes_v1
          set
            status = 'failed',
            execution_token = null,
            heartbeat_at = null,
            lease_expires_at = null,
            interruption_count = interruption_count + 1,
            last_recovered_at = clock_timestamp(),
            completed_at = now(),
            evidence = evidence || jsonb_build_object(
              'last_recovery',
              jsonb_build_object(
                'mode',v_recovery_mode,
                'execution_epoch',v_node.execution_epoch,
                'recovered_at',now()
              )
            ),
            updated_at = now()
          where id = v_node.id;

          v_exception_key := 'stale-retry-budget:' || v_node.node_key || ':' || v_node.execution_epoch::text;

          insert into public.control_room_project_graph_exceptions_v1(
            graph_run_key,node_id,exception_key,code,severity,status,details
          ) values (
            p_run_key,
            v_node.id,
            v_exception_key,
            'stale_execution_retry_budget_exhausted',
            'blocker',
            'open',
            jsonb_build_object(
              'node_key',v_node.node_key,
              'execution_epoch',v_node.execution_epoch,
              'retries_used',v_envelope.retries_used,
              'max_retries',v_envelope.max_retries
            )
          )
          on conflict (graph_run_key, exception_key) do nothing;
        else
          perform public.control_room_checkpoint_run_v1(
            p_run_key,
            v_graph.project_id,
            null,
            'active',
            0,
            0,
            1,
            0,
            null,
            null,
            null,
            null,
            v_node.node_key,
            null
          );

          v_envelope.retries_used := v_envelope.retries_used + 1;
          v_recovery_mode := 'requeue';
          v_to_status := 'ready';

          update public.control_room_project_graph_nodes_v1
          set
            status = 'ready',
            execution_token = null,
            heartbeat_at = null,
            lease_expires_at = null,
            interruption_count = interruption_count + 1,
            last_recovered_at = clock_timestamp(),
            evidence = evidence || jsonb_build_object(
              'last_recovery',
              jsonb_build_object(
                'mode',v_recovery_mode,
                'execution_epoch',v_node.execution_epoch,
                'recovered_at',now(),
                'retry_budget_consumed',true
              )
            ),
            updated_at = now()
          where id = v_node.id;

          v_exception_key := 'stale-requeue:' || v_node.node_key || ':' || v_node.execution_epoch::text;

          insert into public.control_room_project_graph_exceptions_v1(
            graph_run_key,node_id,exception_key,code,severity,status,details,resolved_at,resolution
          ) values (
            p_run_key,
            v_node.id,
            v_exception_key,
            'stale_execution_requeued',
            'info',
            'resolved',
            jsonb_build_object(
              'node_key',v_node.node_key,
              'execution_epoch',v_node.execution_epoch,
              'recovery_mode',v_recovery_mode,
              'retry_budget_consumed',true
            ),
            now(),
            jsonb_build_object('reason','safe_retry_policy')
          )
          on conflict (graph_run_key, exception_key) do nothing;
        end if;
      else
        v_recovery_mode := 'attempt_budget_exhausted';
        v_to_status := 'failed';

        update public.control_room_project_graph_nodes_v1
        set
          status = 'failed',
          execution_token = null,
          heartbeat_at = null,
          lease_expires_at = null,
          interruption_count = interruption_count + 1,
          last_recovered_at = clock_timestamp(),
          completed_at = now(),
          evidence = evidence || jsonb_build_object(
            'last_recovery',
            jsonb_build_object(
              'mode',v_recovery_mode,
              'execution_epoch',v_node.execution_epoch,
              'recovered_at',now()
            )
          ),
          updated_at = now()
        where id = v_node.id;

        v_exception_key := 'stale-attempt-budget:' || v_node.node_key || ':' || v_node.execution_epoch::text;

        insert into public.control_room_project_graph_exceptions_v1(
          graph_run_key,node_id,exception_key,code,severity,status,details
        ) values (
          p_run_key,
          v_node.id,
          v_exception_key,
          'stale_execution_attempt_budget_exhausted',
          'blocker',
          'open',
          jsonb_build_object(
            'node_key',v_node.node_key,
            'execution_epoch',v_node.execution_epoch,
            'attempt_count',v_node.attempt_count,
            'max_attempts',v_node.max_attempts
          )
        )
        on conflict (graph_run_key, exception_key) do nothing;
      end if;

    elsif v_node.recovery_policy = 'reconcile' then
      v_recovery_mode := 'reconcile';
      v_to_status := 'verifying';

      update public.control_room_project_graph_nodes_v1
      set
        status = 'verifying',
        execution_token = null,
        heartbeat_at = null,
        lease_expires_at = null,
        interruption_count = interruption_count + 1,
        last_recovered_at = clock_timestamp(),
        evidence = evidence || jsonb_build_object(
          'last_recovery',
          jsonb_build_object(
            'mode',v_recovery_mode,
            'execution_epoch',v_node.execution_epoch,
            'recovered_at',now()
          )
        ),
        updated_at = now()
      where id = v_node.id;

      v_exception_key := 'stale-reconcile:' || v_node.node_key || ':' || v_node.execution_epoch::text;

      insert into public.control_room_project_graph_exceptions_v1(
        graph_run_key,node_id,exception_key,code,severity,status,details
      ) values (
        p_run_key,
        v_node.id,
        v_exception_key,
        'stale_execution_reconcile',
        'material',
        'open',
        jsonb_build_object(
          'node_key',v_node.node_key,
          'execution_epoch',v_node.execution_epoch,
          'authority_class',v_node.authority_class,
          'recovery_mode',v_recovery_mode
        )
      )
      on conflict (graph_run_key, exception_key) do nothing;

    elsif v_node.recovery_policy = 'owner_gate' then
      v_recovery_mode := 'owner_gate';
      v_to_status := 'waiting_owner';

      update public.control_room_project_graph_nodes_v1
      set
        status = 'waiting_owner',
        execution_token = null,
        heartbeat_at = null,
        lease_expires_at = null,
        interruption_count = interruption_count + 1,
        last_recovered_at = clock_timestamp(),
        wait_context = jsonb_build_object(
          'reason','stale_execution_owner_gate',
          'execution_epoch',v_node.execution_epoch
        ),
        wait_started_at = now(),
        evidence = evidence || jsonb_build_object(
          'last_recovery',
          jsonb_build_object(
            'mode',v_recovery_mode,
            'execution_epoch',v_node.execution_epoch,
            'recovered_at',now()
          )
        ),
        updated_at = now()
      where id = v_node.id;

      v_exception_key := 'stale-owner-gate:' || v_node.node_key || ':' || v_node.execution_epoch::text;

      insert into public.control_room_project_graph_exceptions_v1(
        graph_run_key,node_id,exception_key,code,severity,status,details
      ) values (
        p_run_key,
        v_node.id,
        v_exception_key,
        'stale_execution_owner_gate',
        'material',
        'open',
        jsonb_build_object(
          'node_key',v_node.node_key,
          'execution_epoch',v_node.execution_epoch,
          'recovery_mode',v_recovery_mode
        )
      )
      on conflict (graph_run_key, exception_key) do nothing;

    else
      v_recovery_mode := 'fail_closed';
      v_to_status := 'failed';

      update public.control_room_project_graph_nodes_v1
      set
        status = 'failed',
        execution_token = null,
        heartbeat_at = null,
        lease_expires_at = null,
        interruption_count = interruption_count + 1,
        last_recovered_at = clock_timestamp(),
        completed_at = now(),
        evidence = evidence || jsonb_build_object(
          'last_recovery',
          jsonb_build_object(
            'mode',v_recovery_mode,
            'execution_epoch',v_node.execution_epoch,
            'recovered_at',now()
          )
        ),
        updated_at = now()
      where id = v_node.id;

      v_exception_key := 'stale-fail-closed:' || v_node.node_key || ':' || v_node.execution_epoch::text;

      insert into public.control_room_project_graph_exceptions_v1(
        graph_run_key,node_id,exception_key,code,severity,status,details
      ) values (
        p_run_key,
        v_node.id,
        v_exception_key,
        'stale_execution_failed_closed',
        'blocker',
        'open',
        jsonb_build_object(
          'node_key',v_node.node_key,
          'execution_epoch',v_node.execution_epoch,
          'recovery_mode',v_recovery_mode
        )
      )
      on conflict (graph_run_key, exception_key) do nothing;
    end if;

    v_transition_key := 'wake:' || md5(
      p_wake_key || ':' || v_node.node_key || ':' || v_node.execution_epoch::text
    );

    v_transition_request := jsonb_build_object(
      'kind','wake_recovery',
      'wake_key',p_wake_key,
      'node_key',v_node.node_key,
      'execution_epoch',v_node.execution_epoch,
      'from_status',v_node.status,
      'to_status',v_to_status,
      'recovery_mode',v_recovery_mode
    );

    v_transition_response := jsonb_build_object(
      'node_key',v_node.node_key,
      'from_status',v_node.status,
      'to_status',v_to_status,
      'recovery_mode',v_recovery_mode,
      'execution_epoch',v_node.execution_epoch
    );

    insert into public.control_room_project_graph_node_transitions_v2(
      graph_run_key,
      node_id,
      transition_key,
      request_hash,
      transition_kind,
      from_status,
      to_status,
      phase,
      lease_token,
      request,
      response
    )
    values(
      p_run_key,
      v_node.id,
      v_transition_key,
      md5(v_transition_request::text),
      'wake_recovery',
      v_node.status,
      v_to_status,
      v_recovery_mode,
      v_node.execution_token,
      v_transition_request,
      v_transition_response
    )
    on conflict (graph_run_key, transition_key) do nothing;

    v_recovered := v_recovered || jsonb_build_array(v_transition_response);
  end loop;

  v_runtime := public.control_room_refresh_project_graph_v2(p_run_key);

  v_response := jsonb_build_object(
    'wake_key',p_wake_key,
    'recovered_nodes',v_recovered,
    'recovered_count',jsonb_array_length(v_recovered)
  );

  insert into public.control_room_project_graph_wakes_v2(
    graph_run_key,wake_key,request_hash,response
  )
  values(
    p_run_key,p_wake_key,v_request_hash,v_response
  );

  return v_runtime
    || jsonb_build_object(
      'wake',v_response,
      'idempotent_wake_replay',false
    );
end;
$$;
