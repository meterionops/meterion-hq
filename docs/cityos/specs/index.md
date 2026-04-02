---
title: Specs Index
doc_type: guide
project_key: cityos
domain_key: specs
status: active
---

# Specs Index

## Purpose

This index lists the technical specifications under the `specs` domain.

Specs define **stable, deterministic system behavior and contracts** that:
- backend implementations must follow
- UI must consume consistently
- integrations can rely on without ambiguity

Specs are **factual and non-decisioning**.

---

## What belongs here

Specs should define:

- system behavior
- processing rules
- selection rules
- invariants at component level
- deterministic contracts for implementation
- normalized data contracts shared across backend and UI

---

## What does NOT belong here

Do not place these here:

- operational repair instructions → use `playbooks`
- onboarding / writing guidance → use `onboarding`
- high-level architecture overviews → use `architecture`
- decision logic or prioritization → not part of CityOS (future Pertti layer)

---

## Available Specs

### 1. Snapshot Builder Spec
Path: `docs/cityos/specs/snapshot-builder.md`

Defines:
- snapshot builder responsibilities
- filtering
- deduplication boundary
- module logic
- deterministic output rules

---

### 2. Ingest Run Read Model v1
Path: `docs/cityos/specs/ingest-run-read-model-v1.md`

Defines:
- normalized factual structure for ingest runs (`ops_runs.meta`)
- coverage metrics (processed / total / ratio)
- failure classification (hard fail vs timeout vs retry)
- run outcome and retry state enums
- bounded meta rules (no unbounded arrays)

Used by:
- Suoritukset (Execution History)
- Run Detail Drawer
- future read-only integrations

Key property:
- single source of truth for ingest run facts
- no UI-side inference required

---

## Reading order

Recommended order:

1. `snapshot-builder.md`
2. `ingest-run-read-model-v1.md`

---

## Design principles

All specs in this domain must follow:

- deterministic outputs
- explicit contracts (no implicit behavior)
- bounded data structures
- no reliance on free-text parsing
- separation of facts (CityOS) from decisions (future Pertti layer)

---

## Evolution notes

- New specs should extend the system through **clear contracts**, not hidden logic
- Backward compatibility should be maintained where possible via fallback rules
- Any new normalized field must:
  - be bounded
  - have a clear definition
  - not duplicate existing facts
