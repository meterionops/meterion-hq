begin;

-- Tracking Sync v1 security hardening.
-- Trigger helpers live in public because Meterion Control Room has no private schema,
-- but they are internal implementation details and must never be callable through RPC.

revoke all on function public.control_room_record_tracking_change_v1(uuid,text,text,text,jsonb)
  from public, anon, authenticated;
revoke all on function public.control_room_tracking_state_insert_v1()
  from public, anon, authenticated;
revoke all on function public.control_room_tracking_event_insert_v1()
  from public, anon, authenticated;
revoke all on function public.control_room_tracking_project_change_v1()
  from public, anon, authenticated;
revoke all on function public.control_room_tracking_connection_change_v1()
  from public, anon, authenticated;

-- The helper insert remains usable by trigger execution and service-role mediated
-- database paths; no direct client grant is introduced.
grant execute on function public.control_room_record_tracking_change_v1(uuid,text,text,text,jsonb)
  to service_role;

commit;
