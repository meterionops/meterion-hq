begin;

create table if not exists public.control_room_operators (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'operator' check (role in ('owner','operator','read_only')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.control_room_operators enable row level security;

-- Deliberately no anon/authenticated policies. The MCP resource server validates
-- the user token first, then performs this authorization lookup with its
-- server-side admin client. The table never becomes a user-facing directory.
revoke all on table public.control_room_operators from public, anon, authenticated;
grant select on table public.control_room_operators to service_role;

comment on table public.control_room_operators is
  'Private allow-list for authenticated Control Room MCP operators. Empty by default; no OAuth user gains Control Room access until explicitly enrolled.';

commit;
