begin;

create table if not exists public.control_room_work_batches (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.control_room_projects(id) on delete cascade,
  batch_key text not null check (char_length(batch_key) between 1 and 200),
  expected_version integer not null check (expected_version >= 0),
  state_version integer,
  event_id uuid references public.control_room_project_events(id) on delete set null,
  jev_used boolean not null default false,
  result jsonb,
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (project_id, batch_key)
);

create index if not exists control_room_work_batches_project_time_idx
  on public.control_room_work_batches(project_id, created_at desc);

alter table public.control_room_work_batches enable row level security;

revoke all on table public.control_room_work_batches from anon, authenticated;

create or replace function public.control_room_patch_project_state_v1(
  p_project_key text,
  p_expected_version integer,
  p_state_patch jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $patch$
declare
  v_project_id uuid;
  v_current_state jsonb;
  v_merged_state jsonb;
begin
  if p_state_patch is null or jsonb_typeof(p_state_patch) <> 'object' then
    raise exception 'state_patch_object_required' using errcode = 'P0001';
  end if;

  select id into v_project_id
  from public.control_room_projects
  where project_key = p_project_key;

  if v_project_id is null then
    raise exception 'project_not_found:%', p_project_key using errcode = 'P0001';
  end if;

  select to_jsonb(s) into v_current_state
  from public.control_room_project_current_v2 s
  where s.project_id = v_project_id;

  v_merged_state := coalesce(v_current_state, '{}'::jsonb) || p_state_patch;

  return public.control_room_append_project_state_v2(
    p_project_key,
    p_expected_version,
    v_merged_state
  );
end;
$patch$;

create or replace function public.control_room_complete_work_batch_v1(
  p_project_key text,
  p_expected_version integer,
  p_batch_key text,
  p_state_patch jsonb,
  p_event jsonb,
  p_jev_result jsonb default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_project_id uuid;
  v_claim_id uuid;
  v_existing_result jsonb;
  v_current_state jsonb;
  v_merged_state jsonb;
  v_event_payload jsonb;
  v_event_metadata jsonb;
  v_state jsonb;
  v_event jsonb;
  v_result jsonb;
  v_jev_decision text;
  v_jev_confidence numeric;
begin
  if p_project_key is null or p_project_key !~ '^[a-z0-9][a-z0-9-]*$' then
    raise exception 'invalid_project_key' using errcode = 'P0001';
  end if;

  if p_expected_version is null or p_expected_version < 0 then
    raise exception 'invalid_expected_version' using errcode = 'P0001';
  end if;

  if p_batch_key is null or btrim(p_batch_key) = '' or char_length(p_batch_key) > 200 then
    raise exception 'invalid_batch_key' using errcode = 'P0001';
  end if;

  if p_state_patch is null or jsonb_typeof(p_state_patch) <> 'object' then
    raise exception 'state_patch_object_required' using errcode = 'P0001';
  end if;

  if p_event is null or jsonb_typeof(p_event) <> 'object' then
    raise exception 'event_object_required' using errcode = 'P0001';
  end if;

  if nullif(btrim(p_event->>'summary'),'') is null then
    raise exception 'event_summary_required' using errcode = 'P0001';
  end if;

  if p_jev_result is not null and jsonb_typeof(p_jev_result) <> 'object' then
    raise exception 'jev_result_object_required' using errcode = 'P0001';
  end if;

  select id into v_project_id
  from public.control_room_projects
  where project_key = p_project_key;

  if v_project_id is null then
    raise exception 'project_not_found:%', p_project_key using errcode = 'P0001';
  end if;

  insert into public.control_room_work_batches (
    project_id, batch_key, expected_version, jev_used
  )
  values (
    v_project_id, p_batch_key, p_expected_version, p_jev_result is not null
  )
  on conflict (project_id, batch_key) do nothing
  returning id into v_claim_id;

  if v_claim_id is null then
    select result into v_existing_result
    from public.control_room_work_batches
    where project_id = v_project_id
      and batch_key = p_batch_key;

    if v_existing_result is null then
      raise exception 'work_batch_in_progress' using errcode = 'P0001';
    end if;

    return v_existing_result || jsonb_build_object('idempotent_replay', true);
  end if;

  select to_jsonb(s) into v_current_state
  from public.control_room_project_current_v2 s
  where s.project_id = v_project_id;

  v_merged_state := coalesce(v_current_state, '{}'::jsonb) || p_state_patch;

  if p_jev_result is not null then
    v_jev_decision := nullif(btrim(p_jev_result->>'decision'), '');
    if v_jev_decision is null then
      raise exception 'jev_decision_required' using errcode = 'P0001';
    end if;

    if p_jev_result ? 'confidence' and p_jev_result->>'confidence' is not null then
      begin
        v_jev_confidence := (p_jev_result->>'confidence')::numeric;
      exception when others then
        raise exception 'invalid_jev_confidence' using errcode = 'P0001';
      end;

      if v_jev_confidence < 0 or v_jev_confidence > 1 then
        raise exception 'invalid_jev_confidence' using errcode = 'P0001';
      end if;
    end if;

    v_merged_state := v_merged_state || jsonb_build_object(
      'last_jev_decision', v_jev_decision,
      'last_jev_confidence', v_jev_confidence
    );
  end if;

  v_state := public.control_room_patch_project_state_v1(
    p_project_key,
    p_expected_version,
    v_merged_state
  );

  v_event_metadata := coalesce(p_event->'metadata', '{}'::jsonb);
  if jsonb_typeof(v_event_metadata) <> 'object' then
    raise exception 'event_metadata_object_required' using errcode = 'P0001';
  end if;

  v_event_metadata := v_event_metadata || jsonb_build_object(
    'work_batch_key', p_batch_key,
    'state_version', (v_state->>'version')::integer
  );

  if p_jev_result is not null then
    v_event_metadata := v_event_metadata || jsonb_build_object('jev', p_jev_result);
  end if;

  v_event_payload := p_event || jsonb_build_object('metadata', v_event_metadata);

  v_event := public.control_room_append_project_event_v1(
    p_project_key,
    v_event_payload
  );

  v_result := jsonb_build_object(
    'ok', true,
    'batch_key', p_batch_key,
    'idempotent_replay', false,
    'state', v_state,
    'event', v_event,
    'jev', p_jev_result
  );

  update public.control_room_work_batches
  set
    state_version = (v_state->>'version')::integer,
    event_id = (v_event->>'id')::uuid,
    result = v_result,
    completed_at = now()
  where id = v_claim_id;

  return v_result;
end;
$$;

revoke all on function public.control_room_patch_project_state_v1(text,integer,jsonb)
  from public, anon, authenticated;
revoke all on function public.control_room_complete_work_batch_v1(text,integer,text,jsonb,jsonb,jsonb)
  from public, anon, authenticated;

grant execute on function public.control_room_patch_project_state_v1(text,integer,jsonb)
  to service_role;
grant execute on function public.control_room_complete_work_batch_v1(text,integer,text,jsonb,jsonb,jsonb)
  to service_role;

commit;
