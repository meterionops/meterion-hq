begin;
do $$ declare k text; c public.control_room_project_connections%rowtype; v integer; begin
 select * into c from control_room_project_connections where id='9d1698c4-291a-4c26-b84f-a7b42f80b161';
 select version into v from control_room_project_current_v2 where project_id=c.project_id;
 perform control_room_create_project_work_graph_v1('digital-studio','qa-office-team-rollback-20261013','qa-office-team-rollback-20261013',v,
 jsonb_build_object('objective','Rollback-only integration test','scope_contract',jsonb_build_object('action','save_internal_preparation','target_key','tarjousvalmis','source_hash','qa','source_brief',c.metadata->'office_incubator'->'brands'->0->'build_brief','connection_id',c.id::text),'metadata',jsonb_build_object('office_team',jsonb_build_object('schema_version',1,'run_key','qa-office-team-rollback-20261013'))),
 '[{"node_key":"observe","node_type":"code","execution_mode":"deterministic_code"},{"node_key":"propose","node_type":"worker","execution_mode":"server_executable","required_capability":"analysis.generate"},{"node_key":"analyse","node_type":"worker","execution_mode":"server_executable","required_capability":"analysis.generate"},{"node_key":"decide","node_type":"code","execution_mode":"deterministic_code"},{"node_key":"execute","node_type":"code","execution_mode":"deterministic_code","authority_class":"bounded_write"},{"node_key":"verify","node_type":"verifier","execution_mode":"deterministic_code"}]'::jsonb,
 '[{"from":"observe","to":"propose"},{"from":"propose","to":"analyse"},{"from":"analyse","to":"decide"},{"from":"decide","to":"execute"},{"from":"execute","to":"verify"}]'::jsonb,'{"max_actions":6,"max_jev_calls":null,"max_retries":0,"max_spend_microusd":200000}'::jsonb);
 foreach k in array array['observe','propose','analyse','decide'] loop
 perform control_room_transition_project_graph_node_v1('qa-office-team-rollback-20261013',k,'ready','running');
 perform control_room_transition_project_graph_node_v1('qa-office-team-rollback-20261013',k,'running','completed','{"qa":true}'::jsonb);
 end loop;
 perform control_room_transition_project_graph_node_v1('qa-office-team-rollback-20261013','execute','ready','running');
 perform control_room_save_incubator_team_artifact_v1('qa-office-team-rollback-20261013','{"target_key":"tarjousvalmis","source_hash":"qa","action":"save_internal_preparation","artifact_status":"proposed","analysis":{"approve":true},"provider_runs":[{"qa":true},{"qa":true}]}'::jsonb);
 perform control_room_transition_project_graph_node_v1('qa-office-team-rollback-20261013','execute','running','completed','{"qa":true}'::jsonb);
 perform control_room_transition_project_graph_node_v1('qa-office-team-rollback-20261013','verify','ready','running');
 perform control_room_transition_project_graph_node_v1('qa-office-team-rollback-20261013','verify','running','completed','{"qa":true}'::jsonb);
 if not exists(select 1 from control_room_project_graph_runs_v1 where run_key='qa-office-team-rollback-20261013' and status='completed') then raise exception 'qa_graph_not_completed'; end if;
 if (select count(*) from control_room_project_graph_nodes_v1 where graph_run_key='qa-office-team-rollback-20261013' and status='completed')<>6 then raise exception 'qa_six_nodes_required'; end if;
end $$;
rollback;
