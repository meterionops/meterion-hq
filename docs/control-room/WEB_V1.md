# Meterion Control Room — Web v1

Status: DEPLOYED / FIRST OWNER BOOTSTRAP PENDING
Date: 2026-09-16

## Purpose

Web v1 puts the accepted Control Room UI contract in front of the Owner without depending on the blocked ChatGPT Business full-MCP rollout.

It remains a quiet operating picture, not a project-management product.

## Live surface

Supabase Edge Function:

`control-room-web-v1`

Live URL:

`https://cavvdvxicadgfftbziao.supabase.co/functions/v1/control-room-web-v1`

The function is deployed with `verify_jwt=false` only because the same endpoint must handle pre-authentication magic-link initiation. All private reads implement their own user-session, AAL2 and operator checks before reaching Control Room data.

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

1. the browser submits an email to the web function;
2. the function checks `control_room_login_allowlist` server-side before asking Supabase Auth to send a magic link;
3. the magic link returns to the same Supabase-origin web function, avoiding a new external Auth redirect dependency;
4. Supabase Auth establishes the user session only after possession of the allow-listed email is proven;
5. TOTP enrollment/challenge is mandatory and the resulting session must reach AAL2;
6. only then may the server activate the first `control_room_operators` row;
7. first-operator activation is allowed only while there are zero active operators; later users cannot self-enroll through this bootstrap path.

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

### Today

Renders only non-empty `needs_you`, `working_now` and `changed_materially` sections. An empty Today is treated as a healthy state.

### Projects

Separates confirmed active portfolio, active-but-unclassified and unconfirmed identities. It uses truth-quality counts rather than productivity KPIs.

### AI Company OS

Shows AI Company OS as one Meterion top-level system/project. It does not import or expose AI Company OS companies as Meterion projects.

### System

Shows state reconciliation, Founder Attention count, API/web status and the current Control Room operating state without becoming an observability dashboard.

## Security headers

The web response is `no-store`, denies framing, disables camera/microphone/geolocation, uses a restrictive Content Security Policy and allows network connections only to the same Supabase origin and the pinned Supabase JS module CDN required by the browser auth client.

## Deployment record

Canonical source branch: `control-room-web-v1`

Canonical implementation commit: `116e1e8fa059c7434a5929c0422671f4d897e6ae`

Supabase function deployment: `control-room-web-v1` version 1.

The deployed Edge Function entrypoint imports the canonical implementation from the exact GitHub commit above, so the deployed source is pinned rather than following a moving branch.

## Remaining acceptance step

There were zero Auth users and zero Control Room operators at deployment time.

The remaining end-to-end acceptance step therefore requires the Owner to open the live URL, authenticate with the already allow-listed Owner email, enroll/verify TOTP and allow the bounded first-operator bootstrap to complete.

After that first login we must verify:

- exactly one intended Auth user exists;
- exactly one active Owner operator exists;
- the session reached AAL2;
- Today and Projects can read through the private gateway;
- unauthenticated callers still cannot read Control Room data;
- no secret/service-role credential is present in browser-delivered configuration.

ChatGPT MCP remains a separate integration and is not required for Web v1 acceptance.
