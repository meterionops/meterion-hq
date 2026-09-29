begin;

CREATE OR REPLACE FUNCTION public.control_room_provider_payload_has_secret_keys_v1(p_payload jsonb)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public', 'pg_temp'
AS $$
  with recursive walk(key_name, value) as (
    select null::text, p_payload
    where p_payload is not null

    union all

    select child.key_name, child.value
    from walk w
    cross join lateral (
      select e.key as key_name, e.value
      from jsonb_each(w.value) e
      where jsonb_typeof(w.value)='object'

      union all

      select null::text as key_name, a.value
      from jsonb_array_elements(w.value) a
      where jsonb_typeof(w.value)='array'
    ) child
  )
  select exists (
    select 1
    from walk
    where key_name is not null
      and (
        lower(key_name) ~ '(^|_)(token|secret|password|authorization|api[_-]?key|apikey|private[_-]?key|cookie|bearer)($|_)'
        or lower(key_name) in ('credential','credentials')
      )
  )
$$;

revoke all on function public.control_room_provider_payload_has_secret_keys_v1(jsonb)
  from public,anon,authenticated,service_role;
grant execute on function public.control_room_provider_payload_has_secret_keys_v1(jsonb)
  to service_role;

commit;