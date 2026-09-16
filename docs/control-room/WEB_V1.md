# Meterion Control Room — Web v1

Status: ACCEPTED / LIVE
Date: 2026-09-16

## Purpose

Web v1 puts the accepted Control Room UI contract in front of the Owner without depending on the blocked ChatGPT Business full-MCP rollout.

It remains a quiet operating picture, not a project-management product.

## Live surface

Browser-facing URL:

`https://meterion-control-room-web.onrender.com/`

Backend/auth endpoint:

`https://cavvdvxicadgfftbziao.supabase.co/functions/v1/control-room-web-v1`

Supabase hosted Edge Functions intentionally rewrite `text/html` GET responses to `text/plain` unless a custom domain is used. Therefore the browser UI is rendered through a tiny Render proxy while Supabase remains the authentication, authorization and private data boundary.

The Render host contains no service-role key and no Control Room source credential. It only:

- fetches the public HTML shell from the Edge Function using `?render_proxy=1` and returns it as `text/html`;
- forwards same-origin browser POST requests to the Edge Function;
- preserves the browser Authorization bearer when present.

## Implemented views

Web v1 implements the four accepted primary views only:

1. Today
2. Projects
3. AI Company OS
4. System

Project detail is an orientation / resume-anywhere packet rather than a workspace.

There are no task, Kanban, agent-map, analytics-wall, calendar, CRM or workflow-builder surfaces.

## Authentication model

First Owner bootstrap is intentionally bounded:

1. browser loads the UI through the Render host;
2. the UI submits the email through the same Render origin, which proxies the request to the Edge Function;
3. the Edge Function checks `control_room_login_allowlist` server-side before asking Supabase Auth to send a magic link;
4. the magic link uses the canonical Supabase Edge Function URL as its approved redirect target;
5. the Edge Function redirects browser GETs to the Render UI; the browser preserves the Supabase Auth URL fragment so the Supabase JS client can establish the session on the Render page;
6. TOTP enrollment/challenge is mandatory and the resulting session must reach AAL2;
7. only then may the server activate the first `control_room_operators` row;
8. first-operator activation is allowed only while there are zero active operators; later users cannot self-enroll through this bootstrap path.

The browser receives only the publishable Supabase key and its own user session. It never receives the Supabase secret/service-role key.

## Read boundary

Private reads require all of:

- valid Supabase Auth user session;
- email still present and active in `control_room_login_allowlist`;
- AAL2 session;
- active `control_room_operators` membership.

The authenticated web gateway exposes read actions only and forwards the accepted read contract to `control-room-api-v2`:

- `get_today`
- `get_projects`
- `get_projects_overview`
- `get_project_state`
- `get_owner_attention`
- `get_state_reconciliation`

No state or registry mutation is exposed by Web v1.

## UI behavior

Today renders only non-empty `needs_you`, `working_now` and `changed_materially` sections. Projects separates confirmed active portfolio, active-but-unclassified and unconfirmed identities. AI Company OS remains a separate top-level Meterion system/project. System shows state reconciliation, Founder Attention count and runtime status without becoming an observability dashboard.

## Security boundary

The Render host is deliberately credentialless. The service-role/secret key exists only inside Supabase server-side execution. Browser private reads still terminate at the Edge Function, which validates session, allow-list, AAL2 and operator membership before calling API v2.

Responses are `no-store`; framing is denied; camera/microphone/geolocation are disabled; the browser shell retains a restrictive CSP.

## Deployment record

Canonical UI implementation: `supabase/functions/control-room-web-v1/index.ts`

Canonical Render bridge entrypoint: `supabase/functions/control-room-web-v1/render-entry.ts`

Render host: `services/control-room-web-proxy/server.mjs`

Render service:

- name: `meterion-control-room-web`
- id: `srv-dal60fjl550s73ak4740`
- region: Frankfurt
- public URL: `https://meterion-control-room-web.onrender.com/`

The first Render deploy `dep-dal60g3l550s73ak487g` reached `live` on 2026-09-16.

Supabase `control-room-web-v1` version 4 is the accepted Render-bridge deployment. Direct browser GETs to the Supabase function redirect to the Render UI; `?render_proxy=1` remains available for the credentialless Render server to retrieve the HTML shell.

## Acceptance evidence

Web v1 passed first-owner end-to-end acceptance on 2026-09-16.

Verified runtime state:

- exactly one intended Supabase Auth user exists;
- exactly one active Control Room operator exists with role `owner`;
- exactly one TOTP factor is verified;
- the browser session reports `AAL2 · private`;
- Today, Projects, AI Company OS and System all rendered successfully through the private gateway;
- the Owner credential gate was cleared in Control Room state v24.

The accepted surface now replaces the bootstrap-pending state. Ongoing work returns to state freshness, lifecycle reconciliation and resume-anywhere quality rather than authentication setup.

ChatGPT MCP remains a separate integration and is not required for Web v1 acceptance.
