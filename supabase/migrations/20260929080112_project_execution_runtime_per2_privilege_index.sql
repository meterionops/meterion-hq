create index if not exists control_room_project_graph_exceptions_v1_node_idx
  on public.control_room_project_graph_exceptions_v1(graph_run_key, node_id);

revoke all on public.control_room_project_graph_node_transitions_v2 from service_role;
revoke all on public.control_room_project_graph_exceptions_v1 from service_role;
revoke all on public.control_room_project_graph_wakes_v2 from service_role;

grant select, insert on public.control_room_project_graph_node_transitions_v2 to service_role;
grant select, insert, update on public.control_room_project_graph_exceptions_v1 to service_role;
grant select, insert on public.control_room_project_graph_wakes_v2 to service_role;
