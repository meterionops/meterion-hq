---
title: Models Index
doc_type: guide
project_key: cityos
domain_key: models
status: active
---

# Models Index

## Purpose

This index lists the core data models used inside CityOS.

Models define the internal data structures that power the system across ingest, processing, and API layers.

---

## What belongs here

Model documents should define:

- canonical data structures
- field-level definitions
- normalization rules
- identity rules
- data invariants
- boundaries between system layers

---

## Current documents

### 1. Canonical Event Model
Path: `docs/cityos/models.md`

Defines:
- canonical event structure
- required vs optional fields
- identity rules (`canonical_key`)
- normalization rules
- boundaries (no cross-source merge at this layer)

---

## Reading order

Recommended order:

1. `models.md`

---

## What does NOT belong here

Do not place these here:

- implementation behavior → use `specs`
- operational workflows → use `playbooks`
- documentation standards → use `onboarding`
- high-level architecture → root / architecture docs
