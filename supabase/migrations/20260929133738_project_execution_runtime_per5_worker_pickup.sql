
begin;

create or replace function public.control_room_claim_next_project_graph_provider_dispatch_v1(
  p_project_key text,
  p_worker_key text,
  p_supported_adapter_keys text[],
  p_lease_seconds integer default null
)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_dispatch public.control_room_project_graph_dispatches_v1%rowtype;
  v_claim jsonb;
  v_claim_key text;
begin
  if p_project_key is null
     or p_project_key !~ '^[a-z0-9][a-z0-9-]*$' then
    raise exception 'invalid_project_key' using errcode='P0001';
  end if;

  if p_worker_key is null
     or btrim(p_worker_key)=''
     or char_length(p_worker_key)>200
     or p_worker_key !~ '^[A-Za-z0-9][A-Za-z0-9._:-]*$' then
    raise exception 'invalid_worker_key' using errcode='P0001';
  end if;

  if p_supported_adapter_keys is null
     or cardinality(p_supported_adapter_keys)=0 then
    raise exception 'supported_adapter_keys_required' using errcode='P0001';
  end if;

  if exists (
    select 1
    from unnest(p_supported_adapter_keys) k
    where k is null
       or k !~ '^[a-z0-9][a-z0-9._-]{1,199}$'
  ) then
    raise exception 'invalid_supported_adapter_key' using errcode='P0001';
  end if;

  if p_lease_seconds is not null
     and (p_lease_seconds<1 or p_lease_seconds>86400) then
    raise exception 'invalid_lease_seconds' using errcode='P0001';
  end if;

  select d.* into v_dispatch
  from public.control_room_project_graph_dispatches_v1 d
  join public.control_room_project_graph_runs_v1 g
    on g.run_key=d.graph_run_key
  join public.control_room_project_graph_nodes_v1 n
    on n.graph_run_key=d.graph_run_key
   and n.id=d.node_id
  join public.control_room_projects p
    on p.id=d.project_id
  join public.control_room_run_envelopes r
    on r.run_key=d.graph_run_key
  where p.project_key=p_project_key
    and d.status='awaiting_provider'
    and d.provider_adapter_key=any(p_supported_adapter_keys)
    and d.provider_invocation_key is not null
    and g.status='active'
    and n.status='ready'
    and r.status='active'
  order by d.created_at asc,d.id asc
  for update of d skip locked
  limit 1;

  if not found then
    return jsonb_build_object(
      'claimed',false,
      'worker_key',p_worker_key,
      'reason','no-awaiting-provider'
    );
  end if;

  v_claim_key :=
    'per5-auto:' ||
    md5(
      v_dispatch.graph_run_key || ':' ||
      v_dispatch.dispatch_key || ':' ||
      v_dispatch.provider_invocation_key
    );

  v_claim := public.control_room_claim_project_graph_provider_dispatch_v1(
    v_dispatch.graph_run_key,
    v_dispatch.dispatch_key,
    v_claim_key,
    p_lease_seconds
  );

  update public.control_room_project_graph_dispatches_v1
  set
    evidence=evidence || jsonb_build_object(
      'worker_pickup',jsonb_build_object(
        'worker_key',p_worker_key,
        'claim_key',v_claim_key,
        'picked_at',clock_timestamp()
      )
    ),
    updated_at=now()
  where id=v_dispatch.id;

  return v_claim || jsonb_build_object(
    'claimed',true,
    'worker_pickup',jsonb_build_object(
      'worker_key',p_worker_key,
      'claim_key',v_claim_key,
      'graph_run_key',v_dispatch.graph_run_key,
      'dispatch_key',v_dispatch.dispatch_key
    )
  );
end
$$;

revoke all on function public.control_room_claim_next_project_graph_provider_dispatch_v1(
  text,text,text[],integer
) from public,anon,authenticated,service_role;
grant execute on function public.control_room_claim_next_project_graph_provider_dispatch_v1(
  text,text,text[],integer
) to service_role;

commit;