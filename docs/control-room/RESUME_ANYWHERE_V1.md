# Meterion Control Room — Resume Anywhere v1

Status: IMPLEMENTED READ MODEL / v1.1
Date: 2026-09-16

## Purpose

Resume Anywhere lets a new work session orient from Control Room before it deep-fetches GitHub, Supabase, Lovable or another source system.

The packet answers, in one bounded read:

- what project is this?
- what is the current operating phase and focus?
- what materially happened most recently?
- what should happen next?
- may AI continue, should it verify a dependency, wait for an explicit work request, or stop for the Owner?
- how fresh is the state?
- which source system should be opened next if deeper truth is required?

It is deliberately not a transcript, task history, document store or copy of source-system payloads.

## Canonical RPC

`control_room_get_resume_packet_v1(project_key)`

The packet contains:

- `packet_version`
- `project` — the current Project State v2 surface
- `work_mode`
- `reconciliation` — freshness, refresh cadence and primary-source pointer
- `connections` — bounded source links/identifiers only
- `recent_material_events` — at most five recent normal/high/critical events

## Work modes

### `continue_from_next_best_action`

The project is active and the current state says AI may continue. Start from `project.next_best_action`, then deep-fetch the primary source only when the work requires more detail than the packet provides.

### `verify_dependency_before_work`

The current state is `waiting`. Check the named dependency/source before continuing. Do not turn waiting into Founder attention unless the dependency actually requires Founder authority.

### `idle_until_requested`

The project lifecycle is active, but `autonomy_state=inactive`. This is common for quiet MAINTENANCE work: the project still exists in the active portfolio, but AI should not create background work merely because it is technically possible. An explicit Owner work request may resume the project from its recorded state.

### `stop_for_owner`

The state requires Founder attention or `autonomy_state=owner_needed`. Respect `founder_gate` and `founder_attention_reason`; do not route around the gate.

### `do_not_resume_without_reactivation`

The project lifecycle is paused, completed or archived. Preserve state and source pointers, but do not restart work merely because a new chat mentioned the project. Reactivation is an Owner lifecycle decision.

## Deep-fetch rule

Control Room is the orientation layer, not detailed truth. A session should deepen into the primary source when:

- state freshness is due/stale/missing;
- the next action requires exact source rows/code/files;
- the packet explicitly says a dependency must be verified;
- a production mutation needs current precondition checks.

Otherwise, do not repeatedly reload source systems just to restate already-current Control Room state.

## Security and scope

The RPC is server-only. EXECUTE is revoked from `public`, `anon` and `authenticated`, and granted to `service_role`.

The packet includes only project-level summaries, connection references and short event summaries. It does not expose source credentials, raw customer data, full messages, secrets or copied source tables.

## Integration sequence

1. Use this RPC as the canonical resume packet for server-side Control Room consumers.
2. Expose it through the private API/web gateway when the next UI/API pass is made.
3. When ChatGPT Business full-MCP discovery is available, add a bounded `get_resume_packet` tool instead of making ChatGPT stitch resume context from several calls.

Until MCP rollout is available, Web v1 remains fully functional with the existing Project State detail; this read model is the stable server-side contract for the later resume integration.
