---
title: Public Snapshot Contract v1
doc_type: spec
project_key: cityos
domain_key: specs
status: active
---

# Public Snapshot Contract v1

## Purpose

This specification defines the **public API contract** for CityOS snapshots.

It describes:
- the exact structure returned to frontend clients
- the required and optional fields
- deterministic guarantees
- stability expectations

This contract is the **external boundary** of CityOS.

---

## Scope

Applies to:
- public snapshot endpoints (e.g. `/public/snapshot`)
- all frontend consumers (web, apps)

Does not apply to:
- ingest pipeline
- canonical data
- internal admin APIs
- snapshot builder internals

---

## Source of Truth

The snapshot contract is produced by:

- Snapshot Builder (see `snapshot-builder.md`)

Rules:
- frontend MUST rely only on this contract
- no frontend-side inference from hidden fields
- no dependence on internal schemas

---

## Top-Level Structure

```json
{
  "generated_at": "ISO timestamp",
  "modules": {
    "<module_key>": [Event]
  }
}
