# Meterion Control Room — Closed Loop v1

Status: ACTIVE
Date: 2026-09-19

## Purpose

Closed Loop v1 keeps Control Room current when ChatGPT or another authorized operator completes a substantial autonomous work batch.

The loop is:

1. Read Resume Anywhere / current Project State.
2. Work inside the locked Project Control scope.
3. Use Jev only if a high-impact uncertainty boundary is reached.
4. Verify the actual result from source systems.
5. Commit one atomic work batch to Control Room.
6. The next session resumes from the new state.

## Default end-of-batch rule

Use `complete_work_batch` as the default Control Room write only when all are true:

- the work batch was substantial enough to change future orientation;
- the work completed successfully or reached a materially new verified state;
- execution remained inside the locked project scope;
- no unresolved Stop Gate blocks continuation;
- the state patch and event summary are backed by current source evidence.

Routine prompts, tiny edits, API calls and granular work rows are not work batches.

## Atomic write contract

Database RPC:

`control_room_complete_work_batch_v1(project_key, expected_version, batch_key, state_patch, event, jev_result?)`

It performs in one transaction:

- safe merge of the supplied state patch into the current versioned Project State;
- append of one material Project Event;
- optional persistence of Jev decision/confidence into Project State;
- optional structured Jev metadata on the event;
- durable work-batch record.

## Idempotency

`batch_key` is unique per project.

Retrying the same key returns the previously committed result with:

`idempotent_replay = true`

It must not create a new state version or duplicate material event.

## Optimistic concurrency

The caller supplies `expected_version`.

If project state changed after the caller read it, the write fails with `state_version_conflict`.

The caller must re-read current state and reconcile instead of overwriting newer state.

## Safe patching

`control_room_patch_project_state_v1` merges supplied fields with current Project State before appending a new version.

Unspecified Project Control fields therefore remain intact.

Closed Loop writes cannot mutate Owner-controlled project identity fields such as:

- goal
- portfolio class
- lifecycle
- canonical project constraints

Those live outside Project State.

## Jev

Jev is optional per batch.

When used, persist a bounded result:

- gate
- decision
- confidence
- result_type
- optional concise rationale

Do not store full Jev prompts or raw working context in Control Room.

## API / MCP

Control Room API v2 exposes:

- get_resume_packet
- update_project_state (safe patch)
- complete_work_batch

Control Room MCP exposes the same closed-loop primitives for authorized ChatGPT clients.

## Activation evidence

2026-09-19:

- database migration applied successfully;
- API deployed successfully;
- MCP deployed successfully;
- real work batch committed as Project State v33 + one material event;
- replay of identical batch key returned the same state version and event id with no duplicate write;
- Jev decision capture committed and verified in Project State v34 and event metadata;
- final bounded-default activation gate: Jev Noul 0.85 → PASS.

## Operating principle

Read once.
Work from source truth.
Use Jev at uncertainty boundaries.
Verify reality.
Commit one bounded work batch.
Resume from Control Room next time.
