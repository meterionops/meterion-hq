# Meterion Control Room — ChatGPT MCP Integration v1

Status: MCP SERVER + CONSENT UI DEPLOYED / OAUTH SERVER ENABLEMENT REQUIRED
Date: 2026-09-12

## Target experience

A new ChatGPT conversation can say:

> jatka Maistiota

ChatGPT reads current state from Meterion Control Room, uses the deeper project source only when necessary, performs the bounded work, and writes back a new state version/material event when useful.

For portfolio orientation:

> mitä minun pitää tehdä tänään?

ChatGPT calls the Control Room `get_today` MCP tool instead of reconstructing priorities from chat history.

## Architecture

```text
ChatGPT custom MCP app
        |
        | OAuth 2.1 bearer token
        v
control-room-mcp-v1
        |
        | private operator allow-list
        v
Meterion Control Room RPC/read-model layer
        |
        +--> current project state
        +--> Today
        +--> Owner attention
        +--> append-only state/event writes
```

Project databases remain authoritative for detailed domain data.

## Deployed services

### MCP resource server

`https://cavvdvxicadgfftbziao.supabase.co/functions/v1/control-room-mcp-v1`

Supabase Edge Function status: deployed.

It implements six stable tools:

- `get_project_state`
- `list_projects`
- `get_today`
- `get_owner_attention`
- `update_project_state`
- `append_project_event`

The first four are annotated read-only. State/event writes are internal, non-destructive and do not expose arbitrary SQL.

### Authorization / consent UI

Base:

`https://cavvdvxicadgfftbziao.supabase.co/functions/v1/control-room-auth-ui`

Recommended authorization page:

`https://cavvdvxicadgfftbziao.supabase.co/functions/v1/control-room-auth-ui/consent`

The page uses only the project's publishable Supabase key. No service secret is shipped to the browser.

The consent UI supports:

- email magic-link sign-in
- OAuth request details
- approve / deny
- sign-out

### Authorization server

Issuer expected by the MCP resource server:

`https://cavvdvxicadgfftbziao.supabase.co/auth/v1`

The MCP resource server publishes protected-resource metadata pointing clients to this issuer.

## Defense in depth

A valid Supabase user token alone is insufficient.

The authenticated user must also exist as an active row in:

`public.control_room_operators`

The table is private, has RLS enabled, has no anon/authenticated policies, and is empty at initial deployment.

This means enabling OAuth does **not** automatically grant Control Room access to anyone who can sign in.

## Manual Supabase OAuth gate

The current Supabase connector does not expose the cloud Auth/OAuth configuration mutation APIs needed for this step. Complete these settings in the Meterion Control Room Supabase dashboard.

### 1. URL Configuration

In **Authentication → URL Configuration** set:

**Site URL**

`https://cavvdvxicadgfftbziao.supabase.co/functions/v1/control-room-auth-ui`

Add an allowed redirect URL covering the consent page used by magic-link login:

`https://cavvdvxicadgfftbziao.supabase.co/functions/v1/control-room-auth-ui/**`

### 2. OAuth Server

In **Authentication → OAuth Server**:

- Enable OAuth 2.1 Server
- Authorization Path: `/consent`
- Enable Dynamic Client Registration

Dynamic registration is appropriate here because ChatGPT is the MCP OAuth client and can register itself during connection setup.

Do not request `openid` for v1. The MCP connection only needs the standard default/email OAuth scope and user access tokens; this avoids introducing an OIDC signing-key dependency into the first proof.

### 3. First operator bootstrap

Initial state intentionally contains:

- `auth.users`: 0 users at implementation time
- `control_room_operators`: 0 active operators at implementation time

On the first ChatGPT OAuth flow:

1. use the consent UI to send yourself a sign-in link;
2. open the magic link in the same browser and return to the consent request;
3. **before final end-to-end MCP access is considered complete**, explicitly enroll that newly authenticated Supabase user as `owner` in `control_room_operators`;
4. approve the ChatGPT OAuth request.

The operator enrollment is an explicit security boundary. Do not implement automatic first-user-is-owner behavior.

## ChatGPT setup after Supabase OAuth is enabled

For ChatGPT Business developer mode:

1. Enable Developer Mode for the workspace admin/owner account.
2. Open Workspace/User Settings → Apps → Create.
3. Use the MCP endpoint:
   `https://cavvdvxicadgfftbziao.supabase.co/functions/v1/control-room-mcp-v1`
4. Select OAuth when prompted.
5. Run Scan Tools.
6. Complete the Supabase authorization flow.
7. Keep the app as a draft until the six-tool surface has passed end-to-end verification.

Do not publish the app to the workspace before the resume-anywhere proof has passed.

## First acceptance test

### Read path

In a fresh chat with the draft Control Room app enabled:

> jatka Maistiota

Expected:

1. ChatGPT calls `get_project_state(project_key="maistio")`.
2. It receives the current version/source/focus/next action.
3. It consults the Maistio source system only if the next work requires deeper truth.
4. It does not ask the user to restate Maistio history.

### Write path

After a meaningful bounded work batch:

1. ChatGPT calls `update_project_state` using the version it originally read.
2. If the state changed concurrently, the tool returns `state_version_conflict` and ChatGPT re-reads before writing.
3. ChatGPT calls `append_project_event` only for material orientation value.

### Today path

In a fresh chat:

> mitä minun pitää tehdä tänään?

Expected:

- ChatGPT calls `get_today` first;
- only real Founder gates / relevant active state changes are surfaced;
- stale/unknown state is not silently represented as current truth.

## Security acceptance criteria

The integration is accepted only when all are true:

- unauthenticated MCP requests receive an OAuth challenge;
- OAuth discovery resolves to the dedicated Meterion Control Room Supabase Auth issuer;
- a valid but non-enrolled user cannot use Control Room tools;
- an enrolled owner can list/read projects;
- owner-controlled project fields remain unavailable to MCP state writes;
- stale state writes fail with `state_version_conflict`;
- no Supabase secret API key is stored in ChatGPT, GitHub or browser code;
- no Maistio/Cala/Rail/RFQ source database is duplicated into Control Room.

## What remains manual

Only the cloud OAuth enablement/configuration and first operator identity bootstrap are currently manual. The MCP server, bounded tool surface, consent UI, private operator table, persistence layer and source-backed state are already implemented.
