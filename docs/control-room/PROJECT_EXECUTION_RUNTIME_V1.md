# Meterion Project Execution Runtime v1

Status: PER-1 IMPLEMENTED — verification candidate
Date: 2026-09-29

## Objective

Meterion Project Execution Runtime (PER) makes normal Meterion projects resumable, graph-executable work without turning those projects into AI Companies and without moving canonical project truth out of Control Room.

PER sits between Project Operator semantics and later execution capabilities:

```text
Project Master / Project Contract
        |
        v
Project Operator
        |
        v
Control Room Project State
        |
        v
PER Work Unit + Graph Run
        |
        v
Nodes / Edges / Checkpoints
        |
        v
later: governed execution bridge / workers / providers
```

PER-1 establishes only the execution contracts and persistence boundary.

## Locked ownership boundaries

### Canonical project truth

Remains in:

- `control_room_project_state_versions`
- `control_room_project_current_v2`
- project source systems such as GitHub, Supabase, Drive and production runtime.

A Work Unit records the Project State version from which it was compiled. It does not copy or replace canonical Project State.

### Run budget and checkpoint truth

Remains in:

- `control_room_run_envelopes`

PER-1 does not introduce a second action, retry, Jev-call or spend ledger.

Starting a graph node consumes one existing run-envelope action. Retrying a failed node consumes one existing run-envelope retry.

### AI Company execution

AI Company execution remains Company-scoped in the AI Company OS execution kernel.

Normal Meterion projects are not represented as AI Companies and PER-1 does not reuse or mutate `company_execution_*` tables.

## PER-1 contracts

### Work Unit

Table:

`control_room_project_work_units_v1`

A Work Unit is one bounded project outcome.

It stores:

- stable `work_unit_key`
- source Project State version
- objective
- Definition of Done contract
- scope contract
- preserve contract
- non-goals
- stop gates
- immutable contract hash
- lifecycle status
- metadata.

Statuses:

- `planned`
- `active`
- `waiting`
- `completed`
- `failed`
- `cancelled`

### Graph Run

Table:

`control_room_project_graph_runs_v1`

A Graph Run is one compiled execution graph for a Work Unit.

It:

- references the existing `control_room_run_envelopes.run_key`
- belongs to exactly one project and Work Unit
- carries graph/compiler version
- carries a contract hash
- does not own budgets.

Statuses:

- `planned`
- `active`
- `waiting`
- `verifying`
- `completed`
- `failed`
- `cancelled`

### Node

Table:

`control_room_project_graph_nodes_v1`

A Node has one bounded job and typed execution boundaries.

Node types:

- `worker`
- `tool`
- `code`
- `verifier`
- `router`
- `join`
- `human_gate`

Execution modes:

- `server_executable`
- `chatgpt_session`
- `human_gate`
- `deterministic_code`

Failure policies:

- `retry`
- `fallback`
- `skip`
- `repair`
- `escalate`
- `stop`

Authority classes:

- `read_only`
- `prepare`
- `bounded_write`
- `external_write`
- `owner_gate`

Node states:

`pending -> ready -> running -> verifying -> completed`

Waiting/terminal branches:

- `waiting_dependency`
- `waiting_session`
- `waiting_owner`
- `failed`
- `skipped`
- `cancelled`

Each node also has:

- action kind
- purpose
- optional required capability
- input/output/verification contracts
- max attempts
- timeout
- stable idempotency key
- result
- append-style evidence object
- attempt count.

### Edge

Table:

`control_room_project_graph_edges_v1`

An edge is a real dependency, not an “and then”.

Kinds:

- `data`
- `control`
- `authority`
- `success`
- `failure`
- `verification`

Required upstream states:

- `completed`
- `failed`
- `terminal`

Composite foreign keys guarantee both edge endpoints belong to the same Graph Run.

Graph validation rejects cycles.

## PER-1 runtime functions

- `control_room_create_project_work_graph_v1`
  - binds compilation to an exact Project State version
  - persists Work Unit, Run Envelope, Graph Run, Nodes and Edges atomically
  - validates acyclic topology
  - supports contract-hash idempotent replay
  - rejects stale Project State.

- `control_room_validate_project_graph_v1`
  - verifies graph existence, non-empty node set and acyclic topology.

- `control_room_get_project_work_graph_v1`
  - returns bounded Work Unit + Graph Run + Run Envelope + Nodes + Edges.

- `control_room_refresh_project_graph_v1`
  - computes dependency-satisfied ready nodes
  - maps session/human-gate nodes to waiting states
  - updates `action_space` and `resume_from` in the existing Run Envelope
  - closes Graph Run and Work Unit when all work terminates.

- `control_room_transition_project_graph_node_v1`
  - enforces allowed state transitions with optimistic expected-state semantics
  - starting a node consumes one existing run action
  - completed nodes advance the verified checkpoint.

- `control_room_retry_project_graph_node_v1`
  - allows retry only for retry/repair/fallback policies
  - enforces node max attempts
  - consumes the existing run retry budget.

All PER-1 tables are RLS-enabled and explicitly revoked from `public`, `anon` and `authenticated`.

All PER-1 RPCs are executable only by `service_role`.

This is intentionally fail-closed. No browser/client PER write surface exists in PER-1.

## Verified canary

Project:

`ai-company-os`

Work Unit:

`per1-persistence-canary`

Graph Run:

`per1-canary-20260929`

Source Project State version:

`4`

Graph:

```text
recover-state
     |
     v
persist-contracts
     |
     v
retry-canary
     |
     v
verify-resume
```

Observed result:

- 1 Work Unit persisted
- 1 Graph Run persisted
- 4 Nodes persisted
- 3 Edges persisted
- graph validation: valid, no cycle
- only dependency-satisfied node became READY
- first verified completion checkpointed `recover-state`
- next resume cursor advanced to `persist-contracts`
- controlled retry node failed once, paused the graph, then retried
- Run Envelope `retries_used` advanced from 0 to 1
- retry node attempt count reached 2
- next resume cursor advanced to `verify-resume`
- verifier used `RUNNING -> VERIFYING -> COMPLETED`
- all four nodes completed
- Work Unit: `completed`
- Graph Run: `completed`
- Run Envelope: `completed`
- `action_space=[]`
- `resume_from=null`
- `actions_used=5`
- `retries_used=1`
- `spend_microusd=0`
- final checkpoint contains all four completed nodes
- identical create request returned `idempotent_replay=true`
- canonical Project State remained version 4 throughout the graph run.

Negative verification:

- source Project State version 3 was rejected while current was 4
- stale rejection left zero Work Units, Graph Runs and Run Envelopes
- cyclic graph was rejected with `graph_cycle_detected`
- cycle rejection left zero Work Units, Graph Runs and Run Envelopes
- rollback regression with `max_actions=1` rejected the second node start
- rollback regression with `max_retries=0` rejected a retry
- all six PER-1 functions deny EXECUTE to `anon` and `authenticated`
- all six PER-1 functions allow EXECUTE to `service_role`
- all four PER-1 tables have RLS enabled and no anon/authenticated table privilege.

Supabase Performance Advisor initially identified the new composite Work Unit foreign key as lacking a covering index. The index was added and the PER-1 warning is no longer present.

Existing unrelated Control Room advisor notices remain outside PER-1 scope.

## Preserve

PER-1 does not change:

- Project Master ownership
- Project State schema semantics
- `complete_work_batch` as material end-of-work Project State commit
- AI Company execution kernel
- Company authority/budget ledgers
- AI Company OS Owner UI
- provider credentials or capabilities
- external authority.

## Non-goals for PER-1

Not implemented here:

- provider dispatch
- parallel worker execution
- artifact registry
- new scheduler
- graph visualization
- autonomous creation of the next Work Unit
- broad session-bound connector execution.

## Next milestone

PER-2 — Runtime & Resume hardening.

PER-2 should extend the PER-1 foundation rather than create another runtime:

- crash/restart recovery for RUNNING/VERIFYING nodes
- stale lease / timeout semantics where execution needs them
- durable session-required handoff
- explicit human-gate resume
- stronger transition idempotency
- runtime exception/read model
- bounded wake/resume entrypoint
- regression proof that interruption resumes from the latest verified checkpoint without duplicate side effects.

Provider dispatch, broad parallel execution and cross-provider execution remain later milestones.
