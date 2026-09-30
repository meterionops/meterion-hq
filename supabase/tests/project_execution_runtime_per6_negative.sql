-- PER-6 focused failure-path regression. Fixture mutations are rolled back.
begin;
do $$
declare v_state integer; v_result jsonb; v_d record; v_rejected boolean; v_cfg jsonb; v_mode text;
begin
 v_state:=(public.control_room_get_project_state_v3('ai-company-os')->>'state_version')::integer;
 perform public.control_room_create_project_work_graph_v2('ai-company-os','per6-negative','per6-negative',v_state,
 '{"objective":"PER-6 isolated regression","scope_contract":{"per6":{"max_parallel_nodes":2}}}'::jsonb,
 '[{"node_key":"read-a","node_type":"tool","action_kind":"github.repository.read","required_capability":"github.repository.read","execution_mode":"server_executable","authority_class":"read_only","failure_policy":"retry","max_attempts":2,"timeout_seconds":600,"input_contract":{"dispatch_input":{"repository_full_name":"meterionops/meterion-hq"}}},{"node_key":"read-b","node_type":"tool","action_kind":"github.repository.read","required_capability":"github.repository.read","execution_mode":"server_executable","authority_class":"read_only","failure_policy":"retry","max_attempts":2,"timeout_seconds":600,"input_contract":{"dispatch_input":{"repository_full_name":"meterionops/meterion-hq"}}},{"node_key":"read-c","node_type":"tool","action_kind":"github.repository.read","required_capability":"github.repository.read","execution_mode":"server_executable","authority_class":"read_only","failure_policy":"retry","max_attempts":2,"timeout_seconds":600,"input_contract":{"dispatch_input":{"repository_full_name":"meterionops/meterion-hq"}}},{"node_key":"join-state","node_type":"tool","action_kind":"control_room.project_state.read","required_capability":"control_room.project_state.read","execution_mode":"server_executable","authority_class":"read_only","failure_policy":"retry","max_attempts":2,"timeout_seconds":600,"input_contract":{}}]'::jsonb,'[{"from":"read-a","to":"join-state"},{"from":"read-b","to":"join-state"},{"from":"read-c","to":"join-state"}]'::jsonb,'{"max_actions":8,"max_retries":2,"max_spend_microusd":0}'::jsonb);

 -- Missing/invalid opt-in is rejected before preparing work.
 for v_cfg in select value from jsonb_array_elements('[{},{"per6":{"max_parallel_nodes":0}},{"per6":{"max_parallel_nodes":5}},{"per6":{"max_parallel_nodes":"2"}},{"per6":null}]'::jsonb) loop
  update public.control_room_project_work_units_v1 set scope_contract=v_cfg where work_unit_key='per6-negative';
  v_rejected:=false;
  begin perform public.control_room_schedule_project_graph_ready_v1('per6-negative');
  exception when others then if sqlerrm in ('per6_contract_required','invalid_per6_parallel_contract') then v_rejected:=true; else raise; end if; end;
  if not v_rejected then raise exception 'invalid_contract_accepted:%',v_cfg; end if;
 end loop;
 update public.control_room_project_work_units_v1 set scope_contract='{"per6":{"max_parallel_nodes":2}}' where work_unit_key='per6-negative';
 -- A forged readiness status cannot bypass the shared dependency check.
 update public.control_room_project_graph_nodes_v1 set status='ready' where graph_run_key='per6-negative' and node_key='join-state';
 v_rejected:=false;
 begin perform public.control_room_claim_project_graph_node_v2('per6-negative','join-state','bad-dependency',60);
 exception when others then if sqlerrm='per6_dependencies_not_ready' then v_rejected:=true; else raise; end if; end;
 if not v_rejected then raise exception 'dependency_guard_bypassed'; end if;
 update public.control_room_project_graph_nodes_v1 set status='waiting_dependency' where graph_run_key='per6-negative' and node_key='join-state';
 -- Every direct claim rejects session/human modes and elevated authority.
 foreach v_mode in array array['chatgpt_session','human_gate'] loop
  update public.control_room_project_graph_nodes_v1 set execution_mode=v_mode where graph_run_key='per6-negative' and node_key='read-a';
  v_rejected:=false;
  begin perform public.control_room_claim_project_graph_node_v2('per6-negative','read-a','bad-mode',60);
  exception when others then if sqlerrm='per6_node_not_read_only_executable' then v_rejected:=true; else raise; end if; end;
  if not v_rejected then raise exception 'mode_guard_bypassed'; end if;
 end loop;
 update public.control_room_project_graph_nodes_v1 set execution_mode='server_executable',authority_class='bounded_write' where graph_run_key='per6-negative' and node_key='read-a';
 v_rejected:=false;
 begin perform public.control_room_claim_project_graph_node_v2('per6-negative','read-a','bad-authority',60);
 exception when others then if sqlerrm='per6_node_not_read_only_executable' then v_rejected:=true; else raise; end if; end;
 if not v_rejected then raise exception 'authority_guard_bypassed'; end if;
 update public.control_room_project_graph_nodes_v1 set authority_class='read_only' where graph_run_key='per6-negative' and node_key='read-a';
 if (select actions_used from public.control_room_run_envelopes where run_key='per6-negative')<>0 then raise exception 'rejected_claim_spent'; end if;
 -- Provider failure + explicit PER-2 retry generates a fresh attempt dispatch key.
 perform public.control_room_schedule_project_graph_ready_v1('per6-negative');
 select * into v_d from public.control_room_project_graph_dispatches_v1 where graph_run_key='per6-negative' and node_id=(select id from public.control_room_project_graph_nodes_v1 where graph_run_key='per6-negative' and node_key='read-a');
 perform public.control_room_claim_project_graph_provider_dispatch_v1('per6-negative',v_d.dispatch_key,'retry-first-claim',60);
 select * into v_d from public.control_room_project_graph_dispatches_v1 where graph_run_key='per6-negative' and dispatch_key=v_d.dispatch_key;
 perform public.control_room_finish_project_graph_provider_dispatch_v1('per6-negative',v_d.dispatch_key,'expected-failure',v_d.execution_token,false,'{"repository_full_name":"meterionops/meterion-hq"}'::jsonb,jsonb_build_object('provider','github','adapter_key','github.connector.read.v1','operation','get_repo','credential_mode','connector_managed','provider_invocation_key',v_d.provider_invocation_key,'source_ref','github:repository:meterionops/meterion-hq','returned_by','connected_github_provider'),'expected test failure');
 perform public.control_room_retry_project_graph_node_v2('per6-negative','read-a','explicit-retry','{}'::jsonb);
 perform public.control_room_schedule_project_graph_ready_v1('per6-negative');
 if (select count(*) from public.control_room_project_graph_dispatches_v1 where graph_run_key='per6-negative' and node_id=v_d.node_id)<>2 then raise exception 'retry_identity_not_new'; end if;
 if (select retries_used from public.control_room_run_envelopes where run_key='per6-negative')<>1 then raise exception 'retry_accounting'; end if;
 if (select actions_used from public.control_room_run_envelopes where run_key='per6-negative')<>1 then raise exception 'preparation_spent_retry_action'; end if;
end $$;
rollback;
select count(*) as residue from public.control_room_project_graph_runs_v1 where run_key='per6-negative';