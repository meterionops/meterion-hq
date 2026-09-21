# Meterion Control Room — Jev Orchestration v1

Status: ACTIVE — AI COMPANY OS BRIDGE VERIFIED
Date: 2026-09-21

## Purpose

Control Room owns the persistent run budget and resume state for project-bound autonomous work.

AI Company OS System One / Jev must bind to this state rather than creating a parallel run-budget database.

## Canonical run envelope

Table:
`control_room_run_envelopes`

Each `run_key` can track:

### Limits
- `max_actions`
- `max_jev_calls`
- `max_retries`
- `max_spend_microusd`

### Usage
- `actions_used`
- `jev_calls_used`
- `retries_used`
- `spend_microusd`

### Resume state
- `last_verified_checkpoint`
- `action_space`
- `context_filter`
- `candidate_ranking`
- `resume_from`
- `stop_reason`.

Statuses:
- active
- paused
- blocked
- completed.

## Checkpoint

RPC:
`control_room_checkpoint_run_v1`

The checkpoint RPC is atomic and enforces the current envelope.

It refuses:
- negative usage deltas;
- action-budget overflow;
- Jev-call-budget overflow;
- retry-budget overflow;
- spend-budget overflow;
- unexpected run-status transitions when an expected status is supplied.

A checkpoint can simultaneously persist:
- verified checkpoint;
- fresh action space;
- context-filter snapshot;
- candidate-ranking snapshot;
- resume cursor;
- stop reason.

## Resume

RPC:
`control_room_get_run_resume_v1(run_key)`

Returns:
- run status;
- limits;
- usage;
- latest verified checkpoint;
- current action space;
- current context filter;
- current candidate ranking;
- resume cursor;
- stop reason;
- updated_at.

Rule:

> A resumed run starts from the last verified checkpoint, not from the beginning.

## End-of-run commit

`control_room_complete_work_batch_v1` remains the canonical end-of-run project-state commit.

Run checkpoints are operational continuity.
`complete_work_batch` is the material project-state commit.

Do not replace one with the other.

## System One integration

AI Company OS `system-one-decision-service-v1` may persist an optional `control_room_run_key` on its decision binding.

The decision binding is an audit reference only.

It does not become the source of truth for:
- action budget;
- Jev budget;
- retry budget;
- spend budget;
- checkpoints;
- project state.

A project-bound orchestrator should:

```
Control Room resume
  -> verify remaining envelope
  -> build current context/action space
  -> System One typed decision
  -> Control Room checkpoint (+1 Jev call, snapshots)
  -> deterministic execution gate
  -> verify result
  -> checkpoint
  -> complete_work_batch when material work batch ends
```

### Fail-closed bridge contract

AI Company OS now prechecks the supplied resume snapshot before a project-bound provider call:
- run key must match;
- run must be active;
- Jev-call usage and ceiling must be valid;
- one additional Jev call must fit inside the envelope.

After a successful System One decision, AI Company OS emits a checkpoint proposal. The proposal may only add:
- +1 Jev call;
- 0 actions;
- 0 retries;
- 0 spend;
- current context/action/ranking snapshots.

Control Room remains the system that atomically accepts or rejects the checkpoint.

AI Company OS records only:
- supplied resume snapshot as audit evidence;
- checkpoint proposal;
- checkpoint acknowledgement state.

It does not create a second budget ledger.

### Verified bridge canary — 2026-09-21

Control Room run:
`aicos.system-one.bridge.canary.v1`

Envelope:
- max actions 1;
- max Jev calls 2;
- max retries 0;
- max spend 0.

Observed:
- first System One Choice: allowed, checkpoint 0/2 -> 1/2;
- second System One Choice: allowed, checkpoint 1/2 -> 2/2;
- third System One request: rejected before TypeSafe with `control_room_jev_budget_exceeded`;
- rejected request created no AI capability route request, provider runtime run, or System One binding;
- action usage stayed 0;
- retry usage stayed 0;
- spend stayed 0;
- two successful checkpoint proposals were acknowledged applied;
- run was closed `completed`.

This verifies that Control Room's Jev-call ceiling is an execution-time gate, not dashboard metadata.

## Unknown external-call outcome

An unknown external effect is not a retry signal.

Required behavior:
1. persist/reconcile the unknown state;
2. stop automatic replay of the same external action;
3. verify the provider/source of truth;
4. resume only after effect state is known or a bounded owner decision is required.

## Authority

Control Room budgets are ceilings, not authority grants.

System One / Jev:
- cannot expand the envelope;
- cannot grant external-action authority;
- cannot grant credentials;
- cannot approve production mutation;
- cannot bypass Founder / Stop Gates.

Normal execution layers remain authoritative.

## Repository / live truth

Control Room orchestration migration:
`20260919095921_control_room_jev_orchestration_v1`

AI Company OS bridge migration:
`20260921041130_system_one_control_room_bridge_v1`

See also:
- `docs/control-room/CLOSED_LOOP_V1.md`
- `control_room_complete_work_batch_v1`
- `control_room_get_resume_packet_v1`
- AI Company OS `docs/integrations/system-one-decision-service-v1.md`.
