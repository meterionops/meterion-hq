# Meterion Project Execution Runtime v1

Status: PER-1 VERIFIED — Fresh Critic READY
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
  - returns the existing identical run even if canonical Project State has advanced since that run was created
  - rejects a same-key replay when run limits differ
  - rejects stale Project State for new runs.

- `control_room_validate_project_graph_v1`
  - verifies graph existence, non-empty node set and acyclic topology.

- `control_room_get_project_work_graph_v1`
  - returns bounded Work Unit + Graph Run + Run Envelope + Nodes + Edges.

- `control_room_refresh_project_graph_v1`
  - computes dependency-satisfied ready nodes
  - maps session/human-gate nodes to waiting states
  - updates `action_space` and `resume_from` in the existing Run Envelope
  - closes Graph Run and Work Unit when all work terminates
  - fails closed with explicit `action_budget_exhausted`, `retry_budget_exhausted` or `node_attempt_budget_exhausted` stop reasons instead of leaving a non-runnable graph in WAITING.

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
- rollback regression with `max_actions=1` materialized `FAILED/BLOCKED` + `action_budget_exhausted`, cleared action/resume surfaces and rejected the second node start
- rollback regression with `max_retries=0` materialized `FAILED/BLOCKED` + `retry_budget_exhausted`, cleared the resume cursor and rejected a retry
- rollback regression advanced Project State inside the transaction and proved an identical pre-existing run still replays idempotently
- same run key with changed run limits was rejected as `graph_run_limits_conflict`
- all six PER-1 functions deny EXECUTE to `anon` and `authenticated`
- all six PER-1 functions allow EXECUTE to `service_role`
- all four PER-1 tables have RLS enabled and no anon/authenticated table privilege.

Supabase Performance Advisor initially identified the new composite Work Unit foreign key as lacking a covering index. The index was added and the PER-1 warning is no longer present.

Existing unrelated Control Room advisor notices remain outside PER-1 scope.

Fresh Critic verdict: **READY**. No PER-1 BLOCKER or MATERIAL finding remains after the budget-stop and post-state-advance idempotency patches.

PER-1 has production-verification for `stop` and `retry` execution behavior. The broader failure-policy vocabulary (`fallback`, `skip`, `repair`, `escalate`) is retained as typed contract space for later runtime milestones and is not claimed as fully orchestrated behavior in PER-1.

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


## PER-2 — Runtime & Resume Hardening

Status: IMPLEMENTED — verification candidate  
Date: 2026-09-29

PER-2 extends PER-1 rather than introducing another runtime.

### Objective

A bounded project graph may be interrupted during execution without losing its verified checkpoint, silently duplicating side effects, or requiring the Owner to reconstruct runtime state manually.

### Runtime version boundary

PER-2 Graph Runs use `runtime_version = 2`.

PER-1 read APIs remain compatible, but PER-1 mutation/refresh RPCs explicitly reject runtime-version-2 graphs. PER-2 mutation must use the v2 lease/idempotency path.

### Node lease

PER-2 adds to each graph node:

- `execution_token`
- `lease_expires_at`
- `heartbeat_at`
- `execution_epoch`
- `interruption_count`
- `last_recovered_at`
- `recovery_policy`
- durable `wait_context` / `wait_started_at`.

Lease time uses PostgreSQL `clock_timestamp()`, not transaction-stable `now()`.

A READY node must be claimed before execution. Claiming:

- consumes one existing Run Envelope action
- increments attempt count
- creates a new execution epoch
- returns a lease token
- records an idempotent transition-ledger entry.

A VERIFYING node can be claimed separately for verification/reconciliation without consuming a second execution action or incrementing attempt count.

### Recovery policy

`recovery_policy` is one of:

- `retry` — safe work may return to READY after stale execution, subject to max attempts
- `reconcile` — writes do not automatically re-run; stale execution moves to VERIFYING so the external effect is checked first
- `owner_gate` — stale execution waits for Owner resolution
- `fail` — stale execution fails closed.

Default derivation:

- bounded/external writes -> `reconcile`
- Owner/human gate -> `owner_gate`
- other work -> `retry`.

### Stale execution and wake

`control_room_refresh_project_graph_v2` detects an expired active lease and changes the Run Envelope to:

- graph: `waiting`
- envelope: `paused`
- `stop_reason = stale_execution_wake_required`.

`control_room_wake_project_graph_v2` is the bounded recovery entrypoint.

It:

- requeues safe retry-policy execution
- resumes VERIFYING without replaying execute
- converts interrupted write work into reconciliation
- makes Owner-gated interruption explicit
- fails closed when recovery policy/attempt budget requires it
- records exceptions and transition history
- is idempotent by `wake_key`.

### Idempotent transition ledger

`control_room_project_graph_node_transitions_v2` records:

- transition key
- request hash
- transition kind
- from/to states
- phase
- lease token
- request and response evidence.

Reusing the same transition key with the identical request is an idempotent replay.

Reusing the key with different content is rejected as `transition_key_conflict`.

This covers claim, heartbeat, state transitions, retry and wake recovery.

### Durable waits

`chatgpt_session` nodes persist:

- `waiting_session`
- `wait_context.reason = chatgpt_session_required`
- `wait_started_at`
- `resume_from`.

Human/Owner gates persist the corresponding `waiting_owner` state.

A wait must be explicitly released to READY through the v2 transition path before claim.

### Exception/read model

`control_room_project_graph_exceptions_v1` persists recovery exceptions with severity, details and resolution.

`control_room_get_project_graph_runtime_v2` returns:

- the PER-1 Work Unit / Graph Run / Run Envelope / Nodes / Edges
- runtime version
- stale-active count
- open exception count
- transition count
- exception history.

### Security

The new runtime tables are RLS-enabled and expose no anon/authenticated table privilege.

The new runtime RPCs are executable by `service_role` only.

Transition and wake ledgers are append-only for service_role. Exception rows allow select/insert/update for resolution.

### Regression evidence before production canary

Rollback regressions verify:

- a verified predecessor is not replayed after a later node is interrupted
- stale execution is detected before wake
- safe read-only work is requeued exactly once
- write interruption enters reconciliation rather than execution replay
- verification/reconciliation claim does not consume another execution action
- session and Owner waits persist explicit reason/time/resume state
- explicit retry consumes the existing retry budget
- claim/retry/wake replay is idempotent
- changed content under the same transition key is rejected
- PER-1 mutation RPCs cannot mutate PER-2 graphs
- no regression rows remain after rollback.

### PER-2 Definition of Done

PER-2 is READY only when a persistent production canary proves:

1. a verified node remains completed across a later interruption;
2. an expired RUNNING lease is detected as stale;
3. wake resumes from the interrupted node, not from graph start;
4. a bounded-write interruption enters reconcile and does not execute twice;
5. a VERIFYING interruption resumes verification without consuming a second execute action;
6. session/Owner waits remain durable;
7. transition/wake idempotency prevents duplicate state changes;
8. runtime exceptions are inspectable and resolve when the node completes;
9. Project State is not advanced until the milestone is independently verified.
