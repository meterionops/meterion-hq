begin;

alter table public.control_room_operators
  add column if not exists require_mfa boolean not null default true;

create table if not exists public.control_room_oauth_clients (
  client_id text primary key,
  name text not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.control_room_oauth_clients enable row level security;
revoke all on table public.control_room_oauth_clients from public, anon, authenticated;
grant select on table public.control_room_oauth_clients to service_role;

comment on table public.control_room_oauth_clients is
  'Private allow-list of OAuth client IDs permitted to call Meterion Control Room MCP. Client IDs are not secrets, but only active allow-listed clients are accepted.';

create table if not exists public.control_room_login_allowlist (
  email text primary key,
  active boolean not null default true,
  require_mfa boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint control_room_login_allowlist_email_normalized
    check (email = lower(btrim(email)) and position('@' in email) > 1)
);

alter table public.control_room_login_allowlist enable row level security;
revoke all on table public.control_room_login_allowlist from public, anon, authenticated;
grant select on table public.control_room_login_allowlist to service_role;

comment on table public.control_room_login_allowlist is
  'Private pre-authentication email allow-list used by the Control Room authorization UI. Empty means no email may initiate the normal login flow.';

create table if not exists public.control_room_mcp_audit_log (
  id bigint generated always as identity primary key,
  occurred_at timestamptz not null default now(),
  user_id uuid references auth.users(id) on delete set null,
  client_id text,
  tool_name text not null,
  project_key text,
  http_status integer,
  outcome text not null default 'invoked'
    check (outcome in ('invoked','success','error','denied')),
  error_code text,
  metadata jsonb not null default '{}'::jsonb
    check (jsonb_typeof(metadata) = 'object')
);

create index if not exists control_room_mcp_audit_log_occurred_at_idx
  on public.control_room_mcp_audit_log (occurred_at desc);

create index if not exists control_room_mcp_audit_log_user_id_idx
  on public.control_room_mcp_audit_log (user_id, occurred_at desc);

create index if not exists control_room_mcp_audit_log_client_id_idx
  on public.control_room_mcp_audit_log (client_id, occurred_at desc);

alter table public.control_room_mcp_audit_log enable row level security;
revoke all on table public.control_room_mcp_audit_log from public, anon, authenticated;
grant select, insert on table public.control_room_mcp_audit_log to service_role;

grant usage, select on sequence public.control_room_mcp_audit_log_id_seq to service_role;

comment on table public.control_room_mcp_audit_log is
  'Private append-only operational audit log for authenticated Control Room MCP tool calls. Never store bearer tokens, secrets or raw request bodies here.';

commit;
