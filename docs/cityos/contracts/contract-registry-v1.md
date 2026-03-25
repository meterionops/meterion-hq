---
title: CityOS Contract Registry v1
doc_type: spec
project_key: cityos
domain_key: contracts
status: active
---

# CityOS Contract Registry v1

## Purpose

This document defines the load-bearing contract structure of CityOS v1.

It acts as the single entrypoint to all core system contracts.

All contracts listed here are defined in docs/cityos and are the source of truth.

---

## Core Principle

Contracts define:
- what data flows between system layers
- what guarantees each layer provides

Contracts do NOT define:
- implementation details
- parsing logic
- heuristics

---

## Contract Layers

CityOS contracts are organized into the following layers:

---

## 1. Canonical Layer

Defines the internal truth model of events.

- Canonical Event Model v1  
  → `docs/cityos/models/canonical-event-model-v1.md`

- Canonical Identity Rules v1  
  → `docs/cityos/models/canonical-identity-rules-v1.md`

---

## 2. Policy Layer

Defines which events are allowed to exist in output.

- Visibility Policy Contract v1  
  → `docs/cityos/contracts/visibility-policy-contract-v1.md`

---

## 3. Snapshot Layer

Defines how canonical events are transformed into delivery snapshots.

- Snapshot Builder Contract v1  
  → `docs/cityos/contracts/snapshot-builder-contract-v1.md`

---

## 4. Delivery Layer

Defines how data is exposed to frontend consumers.

- Public API Contract v1  
  → `docs/cityos/contracts/public-api-contract-v1.md`

---

## 5. System Invariants

Defines rules that must never be broken.

- System Invariants  
  → `docs/cityos/system-invariants.md`

---

## Contract Flow


Ingest → Canonical → Visibility → Snapshot → Public API


Each layer must:
- respect upstream contracts
- not redefine previous layer semantics

---

## Important Rules

- Contracts are defined only in docs/cityos
- CityOS UI renders contracts but does not define them
- No contract may exist only in UI
- No silent contract drift is allowed

---

## Usage

When working on CityOS:

- If modifying system behavior → update contract first
- If debugging → locate the relevant contract layer
- If uncertain → start from this registry

---

## Status

- Active
- Authoritative contract map for CityOS v1
