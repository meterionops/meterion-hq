begin;

CREATE OR REPLACE FUNCTION public.control_room_sync_provider_dispatch_on_node_recovery_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
begin
  if old.execution_token is not null
     and new.execution_token is null
     and old.status in ('running','verifying')
     and new.status in ('ready','failed')
     and new.last_recovered_at is not null
     and new.last_recovered_at is distinct from old.last_recovered_at
     and new.evidence ? 'last_recovery' then

    update public.control_room_project_graph_dispatches_v1
    set
      status='failed',
      error_code=case
        when new.status='ready' then 'provider_execution_interrupted_requeued'
        else 'provider_execution_interrupted_failed'
      end,
      evidence=evidence || jsonb_build_object(
        'provider_recovery',jsonb_build_object(
          'from_node_status',old.status,
          'to_node_status',new.status,
          'execution_epoch',old.execution_epoch,
          'interruption_count',new.interruption_count,
          'recovered_at',clock_timestamp()
        )
      ),
      response=response || jsonb_build_object(
        'status','failed',
        'provider_recovery',jsonb_build_object(
          'node_status',new.status,
          'execution_epoch',old.execution_epoch
        )
      ),
      execution_token=null,
      completed_at=coalesce(completed_at,clock_timestamp()),
      updated_at=now()
    where graph_run_key=new.graph_run_key
      and node_id=new.id
      and provider_adapter_key is not null
      and status='executing'
      and execution_token=old.execution_token;
  end if;

  return new;
end
$function$;

revoke all on function public.control_room_sync_provider_dispatch_on_node_recovery_v1() from public,anon,authenticated,service_role;

commit;