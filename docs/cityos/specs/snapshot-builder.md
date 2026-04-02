---
title: Snapshot Builder Spec
doc_type: spec
project_key: cityos
domain_key: specs
status: active
---

# Snapshot Builder Spec

## Purpose

The Snapshot Builder transforms canonical events into a **deterministic, curated, and API-ready snapshot**.

It is the final stage between:
- canonical data (ingest layer)
- public API (frontend consumption)

The Snapshot Builder is a **pure transformation layer**:
- no side effects
- no mutation of source data
- no decision logic beyond defined rules

---

## Responsibilities

The Snapshot Builder MUST:

1. Select relevant events within a defined time window
2. Apply visibility and quality filters
3. Deduplicate across sources
4. Apply module-specific selection rules
5. Produce a deterministic output snapshot
6. Guarantee stable ordering

---

## Inputs

### Source tables

- `canonical_events` (source-scoped, primary input)

Optional:
- `item_overrides`
- manual events
- source metadata

---

### Required fields per event

- `canonical_key`
- `title`
- `starts_at`
- `source_id`

Optional but recommended:
- `location`
- `ticket_url`

---

## Time Window

Default window:

- Start: `now`
- End: `now + N days` (module-specific)

### Examples

- today → same day
- weekend → next Sat–Sun
- next7days → 7 days
- sportsPicks → 21 days

---

## Filtering Rules

All events MUST pass:

### 1. Time validity

- `starts_at >= now`
- within module window

---

### 2. Visibility

- `visibility = allowed`

Exclude:
- blocked
- hidden
- invalid

---

### 3. Data completeness

Minimum required:

- title exists
- valid `starts_at`

Optional but preferred:
- location
- ticket_url

---

## Deduplication

Deduplication occurs **after filtering**.

### Grouping key

- `canonical_key`

---

### Selection rule

Within each group, keep **one event only** based on priority:

1. manual override
2. higher quality source
3. earliest ingest (stable fallback)

---

## Module System

Snapshot is built per module.

Each module defines:

- time window
- filters
- limits
- sorting

---

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
