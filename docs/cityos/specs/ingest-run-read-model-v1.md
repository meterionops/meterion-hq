---
title: Ingest Run Read Model v1
doc_type: spec
project_key: cityos
domain_key: specs
status: active
---

# Ingest Run Read Model v1

## Purpose

This specification defines the **normalized, factual read model** for ingest runs in CityOS.

CityOS exposes:
- deterministic execution facts
- bounded, machine-readable fields
- UI-consumable normalized data

CityOS does **not**:
- make decisions
- classify issues for repair
- apply Pertti logic

This read model is the **single source of truth** for:
- Suoritukset (Execution History)
- Run Detail Drawer
- future read-only integrations

---

## Scope

Applies to:
- ingest runs stored in `ops_runs`
- normalized fields inside `ops_runs.meta`
- all UI/read consumers of ingest data

Does not apply to:
- scheduler logic
- retry worker internals
- source repair logic
- Pertti triage or decision-making
- non-ingest run types

---

## Source of Truth

Primary source:
- `ops_runs`
- `ops_runs.meta` (normalized fields)

Rules:
- Consumers MUST prefer normalized fields
- Legacy inference is allowed only as fallback
- Free-text fields (e.g. `error`) are not primary data sources

---

## Required Normalized Fields

These fields MUST be written for every new ingest run.

### Coverage

- `processed_count` (number)
  - Number of sources processed

- `total_count` (number)
  - Total eligible sources

- `processed_ratio` (number)
  - processed_count / total_count

---

### Failure classification

- `hard_fail_count` (number)
  - Non-transient failures (parser, config, logic)

- `timeout_count` (number)
  - Sources that timed out

- `retry_enqueued_count` (number)
  - Sources sent to retry queue

- `skipped_count` (number)
  - Explicitly skipped sources

---

### Run state

- `run_outcome` (string enum)
  - Final factual outcome of the run

- `retry_state` (string enum)
  - State of retry processing

---

## Optional Fields (Bounded)

These fields are optional and MUST remain bounded.

- `failed_source_keys_sample` (string[])
- `timeout_source_keys_sample` (string[])

Rules:
- MUST be capped (e.g. first N items)
- MUST NOT grow unbounded
- MUST NOT contain full history

---

## Enum Definitions

### run_outcome

- `running`
- `success`
- `partial`
- `failed`
- `cleanup`
- `unknown`

Definition:
- Purely factual execution result
- No interpretation or recommendation

---

### retry_state

- `none`
- `pending`
- `active`
- `exhausted`
- `unknown`

Definition:
- Describes retry queue state only
- Does not imply success likelihood

---

## Legacy Fallback Rules

For older runs without normalized fields:

- `processed_count`
  → fallback to legacy fields if safely derivable

- `retry_state`
  → show `unknown`

- `run_outcome`
  → may be inferred conservatively from status/error

Rules:
- Normalized fields ALWAYS override fallback logic
- Fallback must not invent new facts

---

## Bounded Meta Rule

`ops_runs.meta` MUST remain bounded.

Allowed:
- counts
- enums
- ratios
- small samples

Not allowed:
- unbounded arrays
- full per-source logs
- growing history blobs

Principle:
- meta = summary
- detailed data must live elsewhere

---

## Consumer Expectations

All consumers MUST:

- use a shared extraction layer (single helper)
- prefer normalized fields
- avoid duplicating parsing logic
- avoid reading free-text error fields when structured data exists

Applies to:
- Suoritukset table
- Run Detail Drawer
- future integrations

---

## Non-Goals

This spec does NOT define:

- decision logic
- prioritization
- repair actions
- retry algorithms
- Pertti contracts
- source diagnostics

CityOS remains:
→ factual
→ deterministic
→ non-decisioning

---

## Example Shape

```json
{
  "processed_count": 29,
  "total_count": 41,
  "processed_ratio": 0.71,
  "hard_fail_count": 2,
  "timeout_count": 6,
  "retry_enqueued_count": 6,
  "skipped_count": 0,
  "run_outcome": "partial",
  "retry_state": "pending"
}
