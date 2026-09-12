# Meterion Control Room — Connector API v1

Status: IMPLEMENTED / SERVICE CREDENTIAL REQUIRED FOR EXTERNAL CALLERS
Date: 2026-09-12

## Purpose

Provide one narrow server-side endpoint for ChatGPT, Work or other trusted Meterion workers to read and update Control Room without exposing direct database credentials or raw table mutation.

The API is intentionally action-based and small.

## Endpoint

Supabase Edge Function:

`control-room-api-v1`

Authentication:

- service-to-service only;
- caller sends a valid Supabase **secret API key** in the `apikey` header;
- the Edge Function is deployed with platform `verify_jwt=false` because service API keys are not user JWTs;
- function code validates the secret API key with Supabase server auth before any handler logic runs;
- direct table access for anon/authenticated remains unavailable.

No secret key is committed to GitHub or stored in Control Room tables.

## Request shape

All calls use `POST` with JSON.

### `get_project_state`

```json
{
  "action": "get_project_state",
  "project_key": "maistio"
}
```

### `list_projects`

```json
{
  "action": "list_projects",
  "portfolio_class": "CORE",
  "lifecycle_status": "active"
}
```

Filters are optional.

### `get_owner_attention`

```json
{
  "action": "get_owner_attention"
}
```

### `update_project_state`

```json
{
  "action": "update_project_state",
  "project_key": "maistio",
  "expected_version": 3,
  "state": {
    "phase": "Data foundation / pre-frontend",
    "current_focus": "Close remaining core data gaps",
    "last_material_result": "Freshness batch completed",
    "next_best_action": "Resolve remaining review queue",
    "blocked": false,
    "autonomy_state": "can_continue",
    "autonomy_reason": "Approved data-completion work remains",
    "founder_attention_required": false,
    "founder_gate": "none",
    "confidence": "high",
    "verified_at": "2026-09-12T10:00:00Z",
    "source_type": "chatgpt",
    "source_ref": "work-batch-reference"
  }
}
```

The optimistic version requirement prevents stale workers from overwriting newer state.

### `append_project_event`

```json
{
  "action": "append_project_event",
  "project_key": "cala-europe",
  "event": {
    "event_type": "material_progress",
    "summary": "Croatia enrichment wave completed",
    "importance": "normal",
    "source_type": "work",
    "source_ref": "work-batch-reference"
  }
}
```

## Response shape

Success:

```json
{
  "ok": true,
  "action": "get_project_state",
  "data": {},
  "request_id": "uuid"
}
```

Error:

```json
{
  "ok": false,
  "code": "state_version_conflict",
  "request_id": "uuid"
}
```

Important status mappings:

- `400` invalid input
- `404` unknown project
- `409` optimistic state-version conflict
- `413` request too large
- `500` unexpected bounded connector/RPC failure

Auth failures are rejected before business logic.

## Security boundaries

The connector deliberately does **not** expose:

- arbitrary SQL
- arbitrary table reads
- project identity/classification mutation
- secrets
- Supabase service-role credentials
- direct access to Maistio/Cala/Rail/RFQ project databases

Owner-controlled fields remain outside operational state writes:

- goal
- success definition
- portfolio class
- lifecycle status
- canonical constraints

## ChatGPT operating pattern

For a request such as `jatka Maistiota`:

1. call `get_project_state(maistio)`;
2. inspect deeper source-system truth only if the next work requires it;
3. do the bounded work;
4. call `update_project_state` with the version originally read;
5. append a material event only if the result is useful for future orientation.

If the update returns `409 state_version_conflict`, re-read current state and reconcile before writing.

## External credential gate

The function can be deployed and operated internally now. To wire an external ChatGPT plugin/connector or another external worker to this endpoint, configure a Supabase secret API key in that caller's secure credential store.

This is a credential/configuration step, not a data-model change. Never paste or commit the secret key into GitHub, prompts or Control Room state.
