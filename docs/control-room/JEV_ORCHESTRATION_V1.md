# Meterion Control Room — Jev Orchestration v1

Status: ACTIVE
Date: 2026-09-20

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

It does not copy:
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

Live migration:
`20260919095921_control_room_jev_orchestration_v1`

The migration is now also stored in the Meterion Control Room repository.

See also:
- `docs/control-room/CLOSED_LOOP_V1.md`
- `control_room_complete_work_batch_v1`
- `control_room_get_resume_packet_v1`.
