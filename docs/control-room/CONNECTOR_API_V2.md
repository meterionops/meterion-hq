# Meterion Control Room — Connector API v2

Status: implementation candidate on `control-room-api-v2`.

## Purpose

Expose the current Control Room read models to trusted Meterion server-side callers while preserving the bounded write contract.

API v2 is separate from `control-room-api-v1` so the existing MCP/OAuth experiments do not have to change while the ChatGPT Business full-MCP rollout remains unavailable.

## Endpoint

Supabase Edge Function:

`control-room-api-v2`

Authentication remains service-to-service only through Supabase secret API-key validation in the function wrapper. No browser should receive this secret.

## Read actions

### `get_project_state`

Uses `control_room_get_project_state_v2` and returns state freshness + latest material-event context.

```json
{
  "action": "get_project_state",
  "project_key": "maistio"
}
```

### `get_projects`

Uses the Projects v2 surface.

```json
{
  "action": "get_projects",
  "projects_section": "active_portfolio",
  "portfolio_class": "CORE",
  "state_freshness": "fresh"
}
```

All filters are optional.

### `get_projects_overview`

Returns compact portfolio-truth counts from `control_room_get_projects_overview_v2()`.

```json
{
  "action": "get_projects_overview"
}
```

### `get_today`

Returns sparse Today v2 (`needs_you`, `working_now`, `changed_materially`).

```json
{
  "action": "get_today"
}
```

### `get_owner_attention`

Returns the existing explicit Founder Attention queue.

```json
{
  "action": "get_owner_attention"
}
```

### `get_state_reconciliation`

Returns State Reconciliation v1.

```json
{
  "action": "get_state_reconciliation",
  "due_only": true,
  "portfolio_class": "CORE"
}
```

`due_only` defaults to true. `portfolio_class` is optional.

## Write actions

Writes intentionally remain on the existing versioned RPCs.

### `update_project_state`

Requires `expected_version` and appends a new operational state version.

### `append_project_event`

Appends a sparse material event.

API v2 still does not expose project identity/classification/lifecycle mutation.

## UI operating pattern

A future Control Room server-rendered UI can use API v2 as follows:

- Today → `get_today`
- Projects header → `get_projects_overview`
- Projects list → `get_projects`
- Project detail → `get_project_state`
- System freshness diagnostics → `get_state_reconciliation`
- Founder exception drawer → `get_owner_attention`

The browser must not call this service directly with a Supabase secret API key. A UI deployment must use a server-side boundary or a separate user-authenticated API layer.

## Compatibility

`control-room-api-v1` remains unchanged and deployed.

API v2 is additive and uses the latest read models:

- Today v2
- Projects v2
- State Reconciliation v1

The existing MCP bridge can remain frozen until ChatGPT exposes the required full-MCP tool-discovery flow.