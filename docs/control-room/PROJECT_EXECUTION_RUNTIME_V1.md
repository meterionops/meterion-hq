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

Status: VERIFIED — Fresh Critic READY  
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


### PER-2 Fresh Critic verification

Verdict: **READY**.

Authoritative evidence:

- final persistent run: `per2-canary-v3-20260929`
- Work Unit: `per2-interruption-canary-v3`
- source Project State: v5
- runtime version: 2
- Graph Run: `completed`
- Work Unit: `completed`
- Run Envelope: `completed`
- six of six nodes completed
- `actions_used = 7`
- `retries_used = 1`
- `spend_microusd = 0`
- `resume_from = null`
- `action_space = []`
- final verified checkpoint contains all six nodes
- open runtime exception count: 0.

Observed interruption behavior:

- `verified-first` stayed completed at attempt 1 / interruption 0 while later work was interrupted.
- `interrupted-read` expired in RUNNING, wake requeued only that node, consumed exactly one canonical Run Envelope retry, then completed at attempt 2 / interruption 1.
- `interrupted-write` expired in RUNNING and moved to `VERIFYING/reconcile`; reconciliation did not consume a second execute action and the material exception resolved on completion.
- `verify-interrupted` expired after RUNNING -> VERIFYING; wake resumed verification, not execution, and did not consume an execute action or retry.
- `session-wait` persisted `waiting_session` with explicit wait reason/time/resume cursor and completed after explicit release.
- `owner-wait` persisted `waiting_owner` with explicit wait reason/time/resume cursor. Its release was synthetic canary evidence only and did not represent external business approval.
- claim, heartbeat, transition, retry and wake replay semantics were regression-tested for idempotency.
- changed content under an existing transition key is rejected.
- PER-1 mutation RPCs reject runtime-version-2 graphs.

Retry-budget patch discovered by Fresh Critic:

The first implementation allowed a stale safe-retry requeue to use another node attempt without consuming the canonical Run Envelope retry budget. Fresh Critic classified that as material because PER-1 had already locked Run Envelope as the sole retry-budget owner.

The patch in migration `20260929081422_project_execution_runtime_per2_recovery_retry_budget.sql` now:

- consumes one Run Envelope retry for stale `recovery_policy=retry` requeue;
- fails closed when `max_retries` is exhausted;
- records `stale_execution_retry_budget_exhausted` as a blocker exception;
- does not consume retries for VERIFYING resume or write reconciliation because those paths do not execute the side effect again.

Repository regression proves `max_retries=0` blocks stale execution requeue and leaves `retries_used=0`.

Canary provenance:

- `per2-canary-20260929` failed because its non-interrupt predecessor was accidentally given a 5-second lease shorter than connector roundtrip. Runtime correctly detected the stale lease and failed closed at max attempts. The exception is retained but resolved as a superseded harness misconfiguration.
- `per2-canary-v2-20260929` proved interruption/reconcile/verification/wait semantics but predates the recovery retry-budget patch.
- `per2-canary-v3-20260929` is the final verification run after all material patches.

Security and regression perimeter:

- all PER-2 RPCs deny EXECUTE to `anon` and `authenticated` and allow `service_role`;
- PER-2 runtime tables expose no anon/authenticated table privileges;
- transition and wake ledgers are append-only for service_role;
- the PER-2 FK advisor finding was fixed;
- remaining Supabase advisor notices predate PER-2 and are outside this milestone;
- `supabase/tests/project_execution_runtime_per2.sql` passes and rolls back all regression data;
- canonical Project State remained v5 throughout implementation and verification.

PER-2 is ready for material project-state commit.


## PER-3 — Governed Dispatch & Capability Routing

Status: VERIFIED — Fresh Critic READY  
Date: 2026-09-29

PER-3 connects PER-2 `action_space` to explicitly declared bounded execution. It does not create a scheduler and it does not add external provider dispatch.

### Objective

A PER-2 graph node with `required_capability` can resolve to a project-authorized capability and a bounded executor, pass authority/budget checks before execution, execute exactly once under the existing PER-2 lease/idempotency state machine, and persist result/evidence back to the node.

### Registry model

PER-3 adds:

- `control_room_execution_executors_v1`
  - declares bounded executor keys
  - executor kind is currently restricted to `builtin`
  - declares supported execution modes and an authority ceiling.

- `control_room_execution_capabilities_v1`
  - maps a capability key to one declared executor
  - declares supported execution modes/phases and an authority ceiling
  - stores input/output contracts as metadata for the capability contract.

- `control_room_project_capability_bindings_v1`
  - explicitly authorizes a capability for a project
  - has its own authority ceiling
  - disabled/missing bindings fail closed.

- `control_room_project_graph_dispatches_v1`
  - durable dispatch ledger
  - unique `(graph_run_key, dispatch_key)`
  - stores request hash, route, executor, phase, status, input, result, evidence and error code.

All registry tables are migration-managed. Runtime service_role has read-only access to executor/capability/binding registries and bounded insert/update access to the dispatch ledger.

### Resolution path

`control_room_resolve_project_graph_dispatch_v1` evaluates, before node claim:

1. runtime version and graph/run state;
2. session/human-gate waits;
3. dispatchable node phase;
4. Run Envelope action budget for execute phase;
5. required capability existence/status;
6. project capability binding existence/status;
7. executor existence/status;
8. execution-mode compatibility;
9. phase compatibility;
10. node authority against capability, project binding and executor ceilings.

Only `route_status=dispatchable` may proceed to claim.

Rejected/waiting resolution consumes no action and no node attempt.

### Dispatch path

`control_room_dispatch_project_graph_node_v1`:

- serializes the same dispatch key with an advisory transaction lock;
- replays an identical prior dispatch without re-execution;
- rejects the same dispatch key with changed request content;
- records rejected/waiting preflight attempts durably;
- for a dispatchable route, calls PER-2 `claim`;
- executes only a closed-set builtin executor;
- completes/fails the node through PER-2 `transition`;
- writes capability/executor/phase evidence into the node;
- stores the final result/evidence in the dispatch ledger.

PER-2 remains the owner of node leases, attempts, action usage, retry usage, recovery and checkpoints.

### First bounded capability

Capability:

`control_room.project_state.read`

Executor:

`control_room.project_state.read.v1`

Properties:

- read-only
- zero external spend
- no external credentials
- server-executable / deterministic-code compatible
- execute phase only
- bound initially to `ai-company-os`
- returns the canonical Control Room Project State for the graph's own project.

The builtin executor uses a closed CASE-style implementation. Arbitrary function names are not executed.

### Explicit waits and fail-closed behavior

- `chatgpt_session` -> `waiting_session`; no server claim
- `human_gate` / `owner_gate` -> `waiting_owner`; no server claim
- missing/disabled capability -> rejected; no claim
- missing/disabled project binding -> rejected; no claim
- unsupported mode/phase -> rejected; no claim
- authority ceiling exceeded -> rejected; no claim
- exhausted action budget -> rejected before claim; PER-2 claim remains the atomic second budget check.

### Security boundary

PER-3 tables are RLS-enabled and expose no anon/authenticated table privileges.

All PER-3 RPCs are executable only by `service_role`.

The capability/executor/binding registries are not runtime-writable by service_role.

### Non-goals

PER-3 does not implement:

- external provider adapters
- provider credential storage
- broad/cross-provider dispatch
- parallel worker scheduling
- background scheduling
- browser/client dispatch
- arbitrary SQL/function execution
- a second authority or budget ledger.

### Verification candidate evidence

Rollback regressions prove:

- declared capability -> executor resolution
- successful dispatch writes result/evidence to the node
- successful dispatch consumes exactly one existing Run Envelope action
- identical dispatch replay consumes no second action
- changed request under the same dispatch key is rejected
- unregistered capability rejection consumes zero action/attempt
- authority rejection consumes zero action/attempt
- session/Owner work stays explicit wait
- disabled project binding rejects before claim
- pre-consumed action budget rejects before claim
- arbitrary builtin executor keys are rejected
- service-role-only privilege boundary
- rollback leaves zero test residue.

Persistent canary and Fresh Critic are still required before PER-3 is VERIFIED.


### Fresh Critic material patch — direct executor bypass closed

Fresh Critic found that the initial PER-3 implementation exposed the builtin executor helper itself as a service-role RPC. A service-role caller could therefore invoke the executor without going through capability binding, authority checks, Run Envelope action accounting or the dispatch ledger.

Migration `20260929093007_project_execution_runtime_per3_executor_boundary.sql` closes that path:

- builtin execution is now inlined inside `control_room_dispatch_project_graph_node_v1`;
- the standalone `control_room_execute_builtin_capability_v1` function is dropped;
- the only executable runtime entrypoint that can perform a PER-3 capability is the governed dispatch RPC;
- repository regression asserts that the standalone executor RPC does not exist.

This preserves the intended boundary: registry resolution may be read separately, but execution cannot bypass dispatch.


### PER-3 Fresh Critic verification

Verdict: **READY**.

Final persistent canary:

- Graph Run: `per3-canary-v2-20260929`
- Work Unit: `per3-capability-canary-v2`
- source Project State: v6
- runtime version: 2
- capability: `control_room.project_state.read`
- executor: `control_room.project_state.read.v1`
- Graph Run: `completed`
- Work Unit: `completed`
- Run Envelope: `completed`
- nodes completed: 1/1
- `actions_used = 1`
- `retries_used = 0`
- `spend_microusd = 0`
- `resume_from = null`
- `action_space = []`
- dispatch ledger rows: 1
- completed dispatches: 1
- rejected/waiting/failed dispatches: 0
- open runtime exceptions: 0.

Observed governed-dispatch behavior:

- READY node exposed `required_capability=control_room.project_state.read` in the existing PER-2 action space.
- Resolution found the active ai-company-os project binding, capability and bounded executor.
- Authority was read-only at node, binding, capability and executor boundaries.
- Dispatch claim consumed exactly one canonical Run Envelope action and one node attempt.
- The executor returned canonical ai-company-os Project State version 6.
- Result and evidence were persisted on the PER-2 node and in the dispatch ledger.
- An identical dispatch-key/request replay returned idempotently and did not consume another action or attempt.
- The final checkpoint contains the completed `read-project-state` node.
- Canonical Project State remained v6 throughout implementation and verification.

Negative/regression evidence:

- unregistered capability -> rejected before claim, action/attempt usage unchanged
- authority above capability ceiling -> rejected before claim
- disabled project binding -> rejected before claim
- exhausted action budget -> rejected before claim
- ChatGPT-session work -> explicit `waiting_session`, no server claim
- human/Owner work -> explicit `waiting_owner`, no server claim
- changed input under an existing dispatch key -> `dispatch_key_conflict`
- rollback regression leaves zero Work Units, Graph Runs and dispatch rows
- standalone executor RPC does not exist after the Fresh Critic boundary patch.

Security:

- PER-3 tables are RLS-enabled.
- `anon` and `authenticated` have no table privileges on the PER-3 registry/dispatch tables.
- PER-3 runtime RPCs deny EXECUTE to `anon` and `authenticated`.
- `service_role` has SELECT-only registry access and bounded dispatch-ledger write access.
- capability execution is inlined behind the governed dispatch RPC; there is no separately callable executor helper.
- no PER-3 missing-FK advisor finding remains.

Advisor notices outside this milestone:

- existing unindexed FKs on `control_room_run_envelopes.project_id` and `control_room_work_batches.event_id` predate PER-3;
- unused-index notices on newly created PER-3 indexes are informational immediately after creation;
- RLS-with-no-policy notices are expected for internal service-role-only tables with no anon/auth grants;
- the project-level leaked-password-protection warning predates PER-3.

Fresh Critic found one material issue before READY: the initial standalone builtin executor helper could be called directly by service_role and bypass dispatch governance. Migration `20260929093007_project_execution_runtime_per3_executor_boundary.sql` removed that helper and moved the closed-set builtin execution into the governed dispatch RPC. Full regression and the final persistent canary were rerun after the patch.

PER-3 is ready for merge and material Project State commit.


## PER-4 — Provider Adapter Bridge

Status: VERIFIED — Fresh Critic READY

PER-4 extends the verified PER-3 capability/executor boundary to one replaceable external provider adapter without introducing a second scheduler, retry ledger, authority source or credential store.

### Locked execution shape

```text
PER-2 READY node
  -> PER-3 capability + project binding + authority/budget preflight
  -> PER-4 provider adapter resolution
  -> durable awaiting_provider handoff
  -> provider claim immediately before invocation
       -> PER-2 claim owns action + attempt + lease
  -> connector-managed provider call
  -> provider finish
       -> PER-2 transition owns completed/failed state
  -> result/evidence persisted in the existing dispatch/node runtime
```

PER-4 deliberately stops before automated worker pickup. During the canary, Project Operator acts as the bounded provider worker between `claim` and `finish`. PER-5 may automate that pickup without changing the adapter contract.

### Provider adapter registry

New registry:

`control_room_execution_provider_adapters_v1`

It declares:

- adapter key
- provider key
- invocation mode
- credential mode
- status
- allowed operations
- descriptive metadata.

The first adapter is:

`github.connector.read.v1`

Properties:

- provider: GitHub
- invocation mode: `chatgpt_connector`
- credential mode: `connector_managed`
- allowed operation: `get_repo`
- read-only
- zero direct provider spend in the canary.

The executor registry now supports `provider_adapter` in addition to `builtin`. Provider executors must bind to a declared adapter + operation.

### First provider capability

Capability:

`github.repository.read`

Executor:

`github.repository.read.v1`

Initial project binding:

`ai-company-os`

Canary repository allowlist:

`meterionops/meterion-hq`

The capability is read-only, execute-phase only and initially bound only to the AI Company OS project.

### Credential boundary

Provider credentials never enter Graph Run, Node, Dispatch input/result/evidence or Project State.

The adapter records only:

`credential_mode=connector_managed`

Authentication remains inside the connected GitHub provider.

Provider input is closed-world:

- required: `repository_full_name`
- no additional fields
- repository must match the project binding allowlist.

Secret-bearing dispatch input is rejected before a dispatch ledger row or action claim is created.

Provider result/evidence is also closed-world. For the first GitHub capability, success and failure payloads have separate bounded contracts. Unexpected fields, repository mismatches, adapter/operation/invocation mismatches or secret-bearing result/evidence fail closed before node completion.

PER-2 runtime coordination tokens remain internal runtime state and are not provider credentials.

### Handoff / claim / finish

`control_room_dispatch_project_graph_node_v1`

For a provider executor:

- runs existing PER-3 preflight first;
- resolves the provider adapter and operation;
- validates/normalizes input;
- creates one durable `awaiting_provider` dispatch;
- creates a stable `provider_invocation_key`;
- consumes zero actions and zero node attempts.

`control_room_claim_project_graph_provider_dispatch_v1`

Immediately before provider invocation:

- revalidates the PER-3 route;
- revalidates adapter status/operation;
- revalidates normalized provider input;
- calls the existing PER-2 node claim;
- therefore PER-2 remains the canonical owner of action budget, attempt budget and lease;
- persists the provider claim identity.

`control_room_finish_project_graph_provider_dispatch_v1`

After provider invocation:

- requires the active PER-2 lease token;
- validates bounded provider result/evidence;
- completes or fails through the existing PER-2 node transition;
- stores the result/evidence in the existing node and dispatch ledger;
- replays identical finish requests idempotently;
- rejects changed content under the same finish identity.

### Recovery

Provider failure does not create a PER-4 retry mechanism.

A normal provider error:

`provider failure -> PER-2 failed node -> PER-2 retry -> new dispatch/claim`

A lost provider worker / expired lease:

`PER-2 wake -> canonical retry budget -> node requeued -> old executing provider dispatch reconciled to failed -> new dispatch/claim`

`control_room_sync_provider_dispatch_on_node_recovery_v1` exists only to keep the provider dispatch ledger aligned with a PER-2 recovery that already happened. It does not decide retry policy or consume retry budget itself.

### Security boundary

- provider adapter registry is RLS-enabled;
- anon/authenticated have no provider-adapter table privileges;
- provider bridge RPCs deny anon/authenticated execution;
- service_role has read-only registry access and the existing bounded dispatch-ledger runtime writes;
- connector credentials remain outside Postgres;
- provider inputs/results/evidence are schema-bounded before persistence/completion;
- no client/browser provider dispatch was added.

### Applied migrations

- `20260929121557_project_execution_runtime_per4_provider_adapter_bridge.sql`
- `20260929121946_project_execution_runtime_per4_provider_result_idempotency.sql`
- `20260929122213_project_execution_runtime_per4_provider_recovery_boundary.sql`
- `20260929122551_project_execution_runtime_per4_provider_secret_boundary.sql`
- `20260929124302_project_execution_runtime_per4_secret_scanner_precision.sql`

The repository copies are synchronized to the exact applied Supabase migration statements.

### Regression evidence

`supabase/tests/project_execution_runtime_per4.sql` is rollback-only and proves:

- provider handoff resolves the declared adapter/operation;
- prepare consumes zero action/attempt budget;
- prepare replay is idempotent;
- changed request under the same dispatch key fails closed;
- claim consumes exactly one canonical PER-2 action and attempt;
- claim replay is idempotent;
- finish completes through PER-2 transition;
- finish replay is idempotent;
- provider credential-shaped material is absent from dispatch input/result/evidence;
- secret-bearing input is rejected before dispatch persistence/claim;
- project repository allowlist is enforced;
- adapter state is revalidated immediately before invocation;
- unexpected provider output is rejected before completion;
- provider failure uses the existing PER-2 retry budget/path;
- expired provider execution is recovered by the existing PER-2 wake/retry path;
- rollback leaves zero PER-4 test Work Units, Graph Runs and dispatches.

The PER-3 regression was made state-version independent and passes after PER-4.

### Persistent real-provider canary

Graph Run:

`per4-provider-canary-20260929`

Work Unit:

`per4-provider-canary`

Source Project State:

v7

Real provider path:

`github.repository.read -> github.repository.read.v1 -> github.connector.read.v1 -> GitHub get_repo`

Observed result:

- GitHub connector returned repository metadata for `meterionops/meterion-hq`;
- default branch: `main`;
- graph: `completed`;
- Work Unit: `completed`;
- Run Envelope: `completed`;
- nodes: 1/1 completed;
- actions used: 1;
- node attempts: 1;
- retries used: 0;
- spend: 0;
- dispatch ledger rows: 1;
- completed provider dispatches: 1;
- open exceptions: 0;
- provider input/result/evidence contain no provider credential material;
- identical prepare and finish replay without a second provider action;
- canonical Project State remained v7.

### Explicit non-goals

PER-4 does not implement:

- automatic provider-worker pickup
- background provider workers
- parallel scheduling
- cross-provider fan-out
- provider credential/vault infrastructure
- provider writes
- external side-effect authority
- a new retry system
- a new budget system.

Fresh Critic, final branch regression, repository review and merge are still required before PER-4 is VERIFIED.


### PER-4 final post-migration canary

The earlier `per4-provider-canary-20260929` remains as audit history and is superseded by the final post-migration canary.

Final Graph Run:

`per4-provider-canary-v2-20260929`

Final Work Unit:

`per4-provider-canary-v2`

This canary was created and executed after all five applied PER-4 migrations, including the secret-scanner precision migration.

Observed current-runtime evidence:

- source Project State: v7
- real provider: connected GitHub provider
- capability: `github.repository.read`
- executor: `github.repository.read.v1`
- adapter: `github.connector.read.v1`
- operation: `get_repo`
- repository: `meterionops/meterion-hq`
- returned default branch: `main`
- Graph Run: `completed`
- Work Unit: `completed`
- Run Envelope: `completed`
- nodes: 1/1 completed
- `actions_used = 1`
- node `attempt_count = 1`
- `retries_used = 0`
- `spend_microusd = 0`
- dispatch rows: 1
- completed dispatches: 1
- open exceptions: 0
- provider credential scan: false for dispatch input, result and evidence
- prepare/claim/finish replay idempotently
- canonical Project State remained v7.

The original provider canary is marked `superseded_by=per4-provider-canary-v2-20260929`; it is retained rather than deleted so the hardening history remains auditable.


### PER-4 Fresh Critic verification

Verdict: **READY**.

Audit boundary:

- objective: add one replaceable provider adapter behind the verified PER-3 governed dispatch boundary;
- preserve: PER-2 remains canonical for action/attempt/retry/lease/recovery; PER-3 remains canonical for capability/project binding/authority routing;
- non-goals: automatic workers, broad parallelism, cross-provider fan-out, provider writes and provider credential infrastructure.

Strongest evidence:

- branch regressions PASS in dependency order: PER-2, PER-3, PER-4;
- PER-4 rollback suite leaves zero Work Units, Graph Runs and dispatch rows;
- all five PER-4 migration files are byte-identical to the corresponding applied Supabase migration statements;
- final post-migration persistent canary `per4-provider-canary-v2-20260929` completed through the real connected GitHub provider;
- canary result identifies `meterionops/meterion-hq` with default branch `main`;
- handoff consumed zero action/attempt budget;
- provider claim consumed exactly one PER-2 action and one node attempt;
- final graph / Work Unit / Run Envelope are completed;
- `actions_used=1`, `attempt_count=1`, `retries_used=0`, `spend_microusd=0`;
- one provider dispatch exists and is completed;
- open runtime exceptions: 0;
- provider credential scanner is false for dispatch input, result and evidence;
- prepare/claim/finish replay idempotently;
- provider failure regression uses the existing PER-2 retry path;
- expired provider-worker regression uses the existing PER-2 wake/retry path and reconciles the old provider dispatch;
- provider adapter registry is RLS-enabled and anon/authenticated have no table privileges;
- provider runtime RPCs deny anon/authenticated execution and allow only service_role;
- provider adapter registry is SELECT-only to service_role;
- only one provider-finish assertion function overload remains.

Advisor review:

- no new PER-4 missing-FK or exposed-access finding;
- RLS-with-no-policy notices are expected for internal service-role-only tables that have no anon/auth grants;
- unused-index notices on newly created provider indexes are informational immediately after creation;
- existing unindexed FKs on `control_room_run_envelopes.project_id` and `control_room_work_batches.event_id` predate PER-4;
- the project-level leaked-password-protection warning predates PER-4 and is outside this milestone.

Fresh Critic found no remaining BLOCKER or MATERIAL issue.

PER-4 is ready for merge and material Project State commit.
