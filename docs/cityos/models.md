---
title: Canonical Event Model
doc_type: spec
project_key: cityos
domain_key: models
status: active
---

# Canonical Event Model

## Purpose

The Canonical Event Model defines the stable internal event representation used across CityOS.

Its purpose is to ensure that:
- ingest outputs can be normalized into a shared structure
- source-specific quirks do not leak into downstream systems
- snapshot builder, APIs, and admin tools operate on a predictable model

The canonical model is an internal system contract.

---

## Role in the pipeline

The canonical event sits between:

- ingest / extraction
- public snapshot / API output

Pipeline order:

1. source fetch
2. extraction / mapping
3. canonical event creation
4. visibility / governance
5. snapshot builder
6. public API

---

## Core principles

### 1. Source-scoped identity

Canonical events are source-scoped.

A canonical event belongs to one source and must not assume cross-source identity merging at canonical layer.

Cross-source deduplication happens later, in snapshot logic.

### 2. Deterministic structure

Given the same source data, canonical mapping must produce the same canonical event structure.

No random IDs or unstable ordering.

### 3. Loss-minimizing normalization

Normalize enough for downstream consistency, but do not throw away meaningful source information unnecessarily.

### 4. Safe defaults

Missing optional fields are allowed.
Missing required fields should block publication eligibility, not silently corrupt the model.

---

## Required fields

These fields must exist for a canonical event record to be valid.

- `tenant_id`
- `source_id`
- `canonical_key`
- `title`
- `starts_at`

---

## Canonical field definitions

### Identity

#### `canonical_key`
Stable source-scoped identifier for the event.

Rules:
- must be deterministic
- must be unique within source
- should not depend on volatile fields
- should remain stable across re-runs if event identity is unchanged

Good inputs:
- source detail URL
- source event ID
- stable normalized title + date + venue combination

Avoid:
- fetch timestamp
- random UUID
- temporary counters

---

### Ownership / scope

#### `tenant_id`
The tenant this event belongs to.

#### `source_id`
The source that produced the canonical event.

#### `application_id`
Optional application/system scope if used by the platform.

---

### Content fields

#### `title`
Human-readable event title.

Rules:
- trimmed
- no HTML
- preserve meaning
- should not include obvious boilerplate if removable safely

#### `description`
Optional long-form description.

Rules:
- may be null
- preserve meaningful content
- sanitized / normalized text preferred

---

### Time fields

#### `starts_at`
Primary event start datetime.

Rules:
- must be parseable
- stored in canonical datetime format
- source timezone handling must be deterministic

#### `ends_at`
Optional end datetime.

May be null if unknown.

#### `all_day`
Optional boolean.
Use only when the source clearly implies all-day semantics.

---

### Location fields

#### `venue_name`
Optional venue name.

#### `location_text`
Optional human-readable location string.

#### `address_text`
Optional normalized address text.

#### `area`
Optional city/area classification used downstream for relevance and filtering.

---

### Link fields

#### `source_url`
Primary source detail URL.

This is strongly preferred when available.

#### `ticket_url`
Optional ticket / booking URL.

Must not be required for canonical validity unless a downstream module explicitly requires it.

---

### Classification fields

#### `category`
Optional normalized content category.

#### `tags`
Optional normalized tag list.

Rules:
- tags should be useful, not noisy
- avoid duplicating every keyword from the description
- tags may come from source or mapping heuristics

---

### State / governance fields

#### `visibility`
Publication eligibility state.

Typical values are governed outside this spec, but the canonical layer must support visibility decisions such as:
- allowed
- hidden
- blocked
- out_of_scope

#### `quality_score`
Optional numeric quality signal if used.

#### `change_hash`
Stable hash used to detect meaningful changes.

Rules:
- exclude volatile fields
- include only fields that represent meaningful content/state change

---

## Optional raw preservation

The system may preserve source-derived fields for debugging and audit, such as:

- raw title
- raw date text
- raw venue text
- raw payload snapshot

These must not replace canonical normalized fields.

---

## Normalization rules

### Text normalization
- trim whitespace
- collapse excessive spacing
- remove obvious HTML artifacts when safe
- preserve user-visible meaning

### URL normalization
- canonicalize when safe
- remove clearly irrelevant tracking params if platform policy requires
- do not over-normalize distinct URLs into the same value without evidence

### Date normalization
- parse to stable timestamp representation
- use deterministic timezone handling
- ambiguous dates should be flagged upstream, not silently guessed if the guess is unsafe

---

## Publication eligibility vs canonical validity

These are not the same.

### Canonical validity
Means the record is structurally valid for storage.

### Publication eligibility
Means the record is good enough to appear in snapshot / API.

Example:
- valid canonical record
- but hidden from snapshot because missing location or blocked by visibility policy

---

## Deduplication boundary

Canonical layer does NOT do cross-source merge.

It may:
- maintain stable per-source identity
- support later deduplication via canonical_key and normalized fields

But it must not:
- collapse events from different sources into one canonical record

Cross-source dedupe belongs to snapshot/publication layer.

---

## Invariants

The Canonical Event Model must preserve these invariants:

1. canonical events are source-scoped
2. canonical_key is deterministic
3. required fields are always present
4. volatile fields do not define identity
5. canonical layer does not perform cross-source merge
6. downstream systems can rely on stable field meanings

---

## Anti-patterns

Avoid these:

### 1. Random IDs
Do not generate identity from run-specific randomness.

### 2. Source-specific field leakage
Do not make downstream systems interpret many source-specific shapes directly.

### 3. Overloaded fields
Do not store venue, time, and category meaning in one generic text field.

### 4. Silent destructive normalization
Do not throw away meaningful source information without explicit reason.

### 5. Cross-source merge at canonical layer
Do not merge two sources into one canonical event here.

---

## Example minimal canonical event

```json
{
  "tenant_id": "helsinki",
  "source_id": "source_123",
  "canonical_key": "events/example-show-2026-03-25",
  "title": "Example Show",
  "starts_at": "2026-03-25T19:00:00+02:00",
  "venue_name": "Example Venue",
  "source_url": "https://example.com/events/example-show",
  "visibility": "allowed"
}
