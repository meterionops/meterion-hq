---
title: Snapshot Builder Spec
doc_type: spec
project_key: cityos
domain_key: specs
status: active
---

# Snapshot Builder Spec

## Purpose

The Snapshot Builder is responsible for transforming canonical events into a deterministic, curated, and API-ready snapshot.

It is the final stage between:
- Canonical data (ingest layer)
- Public API (frontend consumption)

---

## Responsibilities

The Snapshot Builder must:

1. Select relevant events within a defined time window
2. Apply visibility and quality filters
3. Deduplicate across sources
4. Apply module-specific selection rules
5. Produce a deterministic output snapshot
6. Guarantee stable ordering

---

## Inputs

### Source

- `canonical_events` (source-scoped)
- Optional:
  - `item_overrides`
  - `manual events`
  - `source metadata`

### Required fields per event

- `canonical_key`
- `title`
- `starts_at`
- `source_id`
- `location` (if available)

---

## Time Window

Default window:

- Start: `now`
- End: `now + N days` (configurable per module)

Examples:

- today → same day
- weekend → next Sat–Sun
- next7days → 7 days
- sportsPicks → 21 days

---

## Filtering Rules

Events must pass all:

### 1. Time validity
- `starts_at >= now`
- within module window

### 2. Visibility
- `visibility = allowed`
- exclude:
  - blocked
  - hidden
  - invalid

### 3. Data completeness
Minimum required:

- title exists
- valid date
- (optional but preferred)
  - location
  - ticket_url

---

## Deduplication

Deduplication occurs AFTER filtering.

### Rule

Group by:

- `canonical_key`

Within each group:

- Keep highest priority event

### Priority order

1. Manual override
2. Higher quality source
3. Earliest ingest (stable fallback)

---

## Module System

Snapshot is built per module.

Each module defines:

- time window
- filters
- limits
- sorting

### Supported module types (v1)

#### 1. time_bucket

Examples:

- today
- weekend
- next7days

Config:

```json
{
  "window_days": 7,
  "limit": 20
}
2. keyword_query

Examples:

nightlife
family
free

Config:

{
  "keywords": ["club", "dj", "party"],
  "limit": 10
}
3. newest
newest events first
{
  "limit": 10
}
4. static
manual selection only
Sorting

Sorting must be deterministic.

Default:

starts_at ASC
canonical_key ASC

No randomness allowed.

Limits

Each module defines:

limit (max items)

Global safety caps:

max events per module: 50
max total snapshot size: bounded
Output Structure
{
  "generated_at": "...",
  "modules": {
    "today": [...],
    "weekend": [...],
    "next7days": [...],
    "sportsPicks": [...]
  }
}

Each event must include:

id (canonical_key)
title
starts_at
location (if available)
ticket_url (if available)
Determinism (CRITICAL)

Given same input → must produce identical output.

No:

randomness
unstable sorting
time-dependent drift inside same run
Error Handling

If module fails:

skip module
log error
continue snapshot

If no events:

return empty array (never null)
Observability

Snapshot Builder must expose:

input count
filtered count
deduped count
final count

Optional debug:

dropped reasons
duplicate groups
Constraints
Must NOT modify ingest pipeline
Must NOT mutate canonical data
Must remain pure transformation layer
Invariants
Deterministic output
Stable ordering
No silent data mutation
Source-scoped canonical model respected
Future Extensions (NOT v1)
personalization
ranking ML
cross-city merging
dynamic scoring

These are explicitly out of scope for v1.
