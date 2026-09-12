# Meterion Control Room — Persistence & Read Model v1

Status: READY FOR IMPLEMENTATION
Date: 2026-09-12

## Goal

Persist only the small amount of state Control Room actually needs while keeping project source systems authoritative for their own detailed data.

Control Room is a coordination layer, not a second project-management database.

## Security decision

`meterionops/meterion-hq` is currently a **public GitHub repository**.

Therefore:

- architecture, schemas and non-secret contracts may live here;
- mutable operational project state must **not** be stored here by default;
- credentials, private URLs, customer data, internal commercial details and live execution state must never be committed here;
- runtime state should live in a private persistence layer.

Recommended private runtime store for v1: a dedicated Supabase project for Meterion Control Room.

GitHub remains the durable source for architecture and explicit Owner decisions. Supabase becomes the canonical runtime source for current project state, material events and system connections.

## Minimal data model

Only four runtime entities exist in v1.

### 1. `control_room_projects`

Owner-controlled identity and classification.

Fields:

- `id`
- `project_key`
- `name`
- `kind`
- `goal`
- `success_definition`
- `portfolio_class`
- `lifecycle_status`
- `canonical_constraints`
- `state_authority`
- `primary_workspace`
- `created_at`
- `updated_at`

AI operational updates must not mutate Owner-controlled fields through the state-update API.

### 2. `control_room_project_state_versions`

Append-only operational state history.

Fields:

- `project_id`
- `version`
- `phase`
- `current_focus`
- `last_material_result`
- `next_best_action`
- blocker fields
- autonomy state
- Founder-attention fields
- confidence
- verification timestamp
- source provenance
- `created_at`

Every meaningful update creates a new version. Current state is derived, not overwritten.

This provides optimistic concurrency:

```text
read version 17
→ do work
→ append expected_version=17
→ new version 18
```

If another worker already created version 18, the write fails with `state_version_conflict`; the worker must re-read and reconcile instead of silently overwriting newer truth.

### 3. `control_room_project_events`

Append-only material events.

Examples:

- meaningful data-completion wave
- major milestone
- blocker introduced or removed
- decision made
- important anomaly
- external validation signal
- production launch

Do not log routine prompts, API calls, commits or individual enrichment rows.

Rule:

> If the event would not change the Founder’s understanding of the project, it probably does not belong in Control Room.

### 4. `control_room_project_connections`

Pointers to source systems only.

Connection types:

- `chatgpt`
- `github`
- `supabase`
- `lovable`
- `production`
- `drive`
- `ai_company_os`
- `other`

No passwords, tokens, service-role keys or other secrets are stored here.

## Read models

### `control_room_project_current_v1`

One current state per project, derived from the highest state version.

### `control_room_project_summary_v1`

Joins project identity with current operational state.

This is the default surface for ChatGPT and the Projects page.

### `control_room_owner_attention_v1`

Only projects whose current state has `founder_attention_required = true`.

This drives the top of Today.

### `control_room_today_v1`

Active/current projects ordered primarily by:

1. Founder attention required
2. CORE status
3. blocker state
4. most recent meaningful verification/update

This is a read model, not a new truth source.

## Operational enums

### Autonomy state

- `working`
- `can_continue`
- `waiting`
- `owner_needed`
- `inactive`

### Founder gate

- `none`
- `strategic_decision`
- `credential`
- `legal_commercial`
- `external_communication`
- `contract`
- `customer_data`
- `production_mutation`
- `spend`
- `live_money`

Normal uncertainty or a routine next step is not automatically a Founder gate.

### Confidence

- `low`
- `medium`
- `high`

Confidence is separate from freshness.

## Freshness

Each state carries `verified_at`.

Control Room must not turn stale state into false certainty.

Recommended presentation:

- recently verified → normal
- stale → explicit `state may be stale`
- unknown → `unknown`, never guessed from old activity

Exact stale thresholds may later be project-specific. Do not hardcode a single business-wide threshold into the data model.

## Write authority

### Owner-controlled

Only explicit Owner actions may change:

- `goal`
- `success_definition`
- `portfolio_class`
- `lifecycle_status`
- `canonical_constraints`

### AI-operational

AI may update through a bounded state-write function:

- `phase`
- `current_focus`
- `last_material_result`
- `next_best_action`
- blocker
- autonomy state
- Founder-attention request
- confidence / verification provenance

AI may append material events.

## Stable API / RPC surface v1

Keep the integration deliberately small:

```text
control_room_get_project_state_v1(project_key)
control_room_list_projects_v1(portfolio_class?, lifecycle_status?)
control_room_append_project_state_v1(project_key, expected_version, state)
control_room_append_project_event_v1(project_key, event)
control_room_get_owner_attention_v1()
```

The first ChatGPT integration should use these stable operations rather than raw table mutation.

## ChatGPT workflow

At the start of substantial work:

1. resolve the project key;
2. fetch current Control Room state;
3. use source systems for deeper truth only when the task requires it;
4. if state is stale or conflicts with source truth, reconcile before proceeding.

At the end of a meaningful work batch:

1. append a new project state version if the project state materially changed;
2. append a material event only when useful for future orientation;
3. do not change Owner-controlled project identity/classification;
4. do not create an artificial Founder gate just to ask whether to continue.

## Why not GitHub-only state

GitHub works well for architecture and checkpoints, but not as the sole live state store because:

- the current Meterion HQ repository is public;
- per-work-batch commits would create noisy history;
- multiple concurrent workers need safe state-version conflict handling;
- a Today UI needs efficient private reads;
- source-system connections may include internal references even when they contain no credentials.

## Why not a large platform database

Control Room does not need copies of Maistio restaurants, Cala beaches, RFQ opportunities, Calendar content or AI Company OS internal company data.

Those remain in their source systems.

Control Room stores only coordination truth.

## Acceptance criteria

Persistence v1 is successful when:

- a project can be resumed from its current state without reading full chat history;
- concurrent updates cannot silently overwrite one another;
- Today can be generated from the read model;
- Owner-controlled portfolio decisions cannot be changed by operational AI writes;
- no project source database is duplicated;
- no secrets are stored in Control Room;
- runtime state remains private.
