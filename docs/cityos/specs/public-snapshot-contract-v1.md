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
Fields
generated_at
Type: string (ISO timestamp)
Description: time when snapshot was generated
modules
Type: object
Key: module_key (string)
Value: array of Event objects

Example:

{
  "modules": {
    "today": [...],
    "weekend": [...],
    "next7days": [...]
  }
}
Event Object

Each event MUST follow this structure:

{
  "id": "string",
  "title": "string",
  "starts_at": "ISO timestamp",
  "location": "string | null",
  "ticket_url": "string | null"
}
Required fields
id
canonical identifier (maps to canonical_key)
title
display name
starts_at
ISO datetime
Optional fields
location
may be null
ticket_url
may be null
Guarantees
Determinism

Given identical input:

snapshot MUST be identical
ordering MUST be stable
Ordering

Within each module:

starts_at ASC
id ASC

No randomness allowed.

Completeness
modules MUST always exist
modules MAY be empty arrays
modules MUST NOT be null
Null Handling
optional fields MUST be null if unavailable
never omit required fields
Limits
max events per module: 50
total snapshot size: bounded
Error Handling

If snapshot generation partially fails:

return available modules
omit failed modules
never return invalid structure
Versioning

This is v1 of the snapshot contract.

Rules:

additive changes only
no breaking changes without version bump
new optional fields allowed
existing fields must remain stable
Consumer Expectations

Frontend MUST:

treat this as the only data contract
not rely on internal fields or assumptions
handle empty modules gracefully
handle null optional fields
Non-Goals

This contract does NOT define:

personalization
ranking logic
filtering logic
source attribution
debug information
Example
{
  "generated_at": "2026-04-02T10:00:00Z",
  "modules": {
    "today": [
      {
        "id": "event_123",
        "title": "Live DJ Night",
        "starts_at": "2026-04-02T21:00:00Z",
        "location": "Helsinki",
        "ticket_url": "https://..."
      }
    ],
    "weekend": []
  }
}
Invariants
stable structure
deterministic output
no hidden fields
no backend leakage
