# Meterion Control Room — UI v1

Status: IMPLEMENTATION SPEC
Date: 2026-09-15

## Product role

Control Room is a quiet operating picture and control surface for Meterion. It is not the place where project work itself happens.

Mental model:

- ChatGPT / Work = workbench
- source systems = canonical detailed truth
- Control Room = cross-project state + Founder attention + resume-anywhere control plane

The UI must therefore optimize for orientation and exceptions, not activity volume.

## Navigation

Only four primary views:

1. Today
2. Projects
3. AI Company OS
4. System

No top-level Tasks, Agents, Analytics, Calendar, Inbox, Kanban or Automations views.

## Global shell

Desktop:

- narrow left navigation
- Meterion Control Room wordmark
- Today / Projects / AI Company OS / System
- compact connection/freshness status at the bottom
- main content max width suitable for reading, not dashboard-wall density

Mobile:

- compact top bar
- four-view navigation via a simple sheet or bottom navigation
- preserve information priority; do not reduce Today to a generic card feed

Global visual character:

- restrained operational interface
- light neutral background
- dark text
- one quiet Meterion accent
- status colors only when they carry meaning
- generous whitespace
- thin dividers rather than excessive cards
- monospaced treatment only for technical refs/versions, not body copy
- no gradients, glassmorphism, neon agent animations or “mission control” theatrics

## Today

Primary question:

> Where does the Owner need to intervene, what is truly working now, and what materially changed?

Source:

`control_room_get_today_v2()`

Sections are rendered only when non-empty:

### Needs you

`today_section = needs_you`

Show:

- project name
- concrete reason
- Founder gate
- what the action unlocks
- last verified/source freshness
- one primary action: open project detail / source

This section always appears first.

Do not show an abstract priority score.

### Working now

`today_section = working_now`

Show only meaningful active execution batches, not projects that merely `can_continue`.

### Changed materially

`today_section = changed_materially`

Show concise event summary + time/source. Avoid changelog noise.

### Empty state

A nearly empty Today is a success state.

Use calm copy such as:

> Nothing needs your attention right now.

Do not manufacture recommendations merely to fill the screen.

## Projects

Purpose:

Show the whole Meterion portfolio truth without becoming a project-management tool.

Sources:

- `control_room_get_projects_overview_v2()`
- `control_room_get_projects_surface_v2(...)`

Header summary should be compact, e.g.:

- 5 confirmed active portfolio projects
- 1 active unclassified
- 11 identities awaiting lifecycle confirmation
- 0 active state-quality exceptions

These are truth-quality descriptors, not productivity KPIs.

### Active portfolio

Group by confirmed portfolio class:

- CORE
- EXPERIMENT
- AUTOPILOT
- MAINTENANCE
- VAULT

Each row shows only:

- project name
- goal (short)
- phase
- current focus
- next best action
- autonomy state
- freshness
- Founder Attention indicator if applicable
- primary source link

Do not show task counts, percentages complete, sprint velocity or fabricated health scores.

### Active but unclassified

Separate small section. This is a valid state, not an error.

Do not silently choose a portfolio class.

### Needs confirmation

Collapsed/secondary section for `unconfirmed_identity`.

Show identity + kind + source connections + verification flags. These are registered identities, not automatically active projects.

### Inactive

Hidden behind an explicit filter. Includes paused/completed/archived records.

### System

Meterion Control Room itself is shown separately from portfolio projects.

## Project detail

Source:

`control_room_get_project_state_v2(project_key)`

The page is an orientation packet, not a project workspace.

Order:

1. Name + portfolio/lifecycle
2. Goal / success definition
3. Current phase
4. Current focus
5. Latest material result
6. Next best action
7. Blocker
8. Autonomy state + reason
9. Founder Attention + gate + unlocks
10. Verification: freshness, confidence, verified time, source
11. Canonical constraints
12. Source connections

Optional material-event timeline may show the last few sparse events only.

Primary CTA should be “Continue work” / “Open source” rather than “Create task”.

## AI Company OS

Purpose:

Provide one compact cross-system summary and deep link without replicating AI Company OS.

Show:

- AI Company OS Control Room state
- phase / current focus / next best action
- latest material result
- freshness
- direct link to the actual AI Company OS product/repository as available

Boundary copy may state:

> AI Company OS manages AI-native companies. Control Room only tracks AI Company OS as one Meterion top-level system/project.

Do not surface AI Company OS internal AI Companies as Meterion projects here.

## System

Purpose:

Quiet operational diagnostics, not a primary work surface.

Show:

### State quality

Source:

`control_room_get_state_reconciliation_v1(...)`

- refresh due count
- stale/missing states
- source mode
- safe-to-auto-refresh flag

### Connections

- source connection health/known refs
- Control Room Supabase
- API v2 status
- ChatGPT MCP status: waiting on Business full-MCP rollout

### Security / exceptions

Show only actionable material issues. Example current exception:

- Sprinkler RFQ production discovery-access hardening waiting for explicit production-mutation approval

### API / runtime

Compact, technical, secondary:

- current API version
- state/event model version
- latest verified sync

Do not turn System into a huge observability product.

## Authentication and security boundary

The browser must never receive:

- Supabase service-role / secret API key
- Control Room connector credentials
- source-system service credentials

UI architecture:

`browser -> authenticated Control Room web server -> control-room-api-v2 -> private Control Room Supabase`

User authentication should use Control Room Supabase Auth with:

1. allow-listed email
2. authenticated session
3. mandatory TOTP MFA / AAL2 for operators
4. active `control_room_operators` membership

Current first Owner email is already stored in `control_room_login_allowlist`; there are currently no Auth users or operators, so UI implementation must include a bounded first-operator bootstrap flow rather than assuming an existing account.

The first-operator bootstrap must never allow arbitrary sign-up to become an operator. Eligibility must be checked server-side against the private login allow-list, and operator activation should require AAL2.

## Server data boundary

Use `control-room-api-v2` for the application-facing server read/write contract.

The web server stores the Control Room Supabase secret only in its server environment.

Normal browser requests use an HttpOnly application/session cookie or equivalent authenticated server session. Do not embed the API secret in client JavaScript, public environment variables or HTML.

## Loading/error behavior

- Show stale/freshness information rather than pretending a source is current.
- If a project source fails, preserve last verified state and mark the source diagnostic; do not zero out the project.
- A Control Room API error should render a bounded error state with request reference, not fall back to chat memory.
- No optimistic UI for Founder gates or project-state writes unless version conflict handling is explicit.

## Interaction rules

- One-click source links when safe.
- No drag-and-drop portfolio classification in v1.
- No inline editing of Owner-controlled fields in v1.
- Operational state writes, if added, must retain `expected_version` optimistic concurrency.
- Founder Attention actions must show exactly what is being approved and what it unlocks.

## Initial implementation scope

Build only:

- secure shell + authentication boundary
- Today
- Projects + project detail
- AI Company OS summary
- System diagnostics

Read-only first is acceptable for Today/Projects if it gets the operational picture in front of the Owner safely. The only required mutation for initial access is bounded operator bootstrap/authentication.

## Explicit non-goals

Do not build in UI v1:

- task creation
- Kanban
- comments/chat
- agent animation/map
- workflow builder
- generic analytics dashboard
- document editor
- CRM
- calendars
- full source-system data explorer
- portfolio auto-classification

## Acceptance criteria

UI v1 is ready when:

1. a permitted Owner can authenticate with MFA without exposing server credentials;
2. Today renders only the sparse v2 sections and correctly shows a real `needs_you` gate;
3. Projects distinguishes confirmed portfolio, active-unclassified and unconfirmed identities;
4. project detail can serve as a resume-anywhere packet;
5. System exposes stale/missing source-state quality and material security exceptions;
6. AI Company OS remains semantically separate;
7. no task-manager semantics are introduced;
8. no service-role/secret key is present in browser-delivered code or configuration;
9. empty/healthy states are intentionally quiet;
10. the interface remains useful on mobile.