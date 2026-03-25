---
title: Snapshot Winner Selection Rules v1
doc_type: spec
project_key: cityos
domain_key: contracts
status: active
---

# Snapshot Winner Selection Rules v1

## Purpose

This document defines how CityOS selects a single representative event (“winner”) from multiple canonical events that refer to the same real-world event.

This process happens at snapshot time.

It ensures:
- no duplicate events in output
- consistent user experience
- deterministic behavior across runs
- explainable selection logic

---

## Core Principle

Winner selection answers:

👉 “Which version of this event should be shown?”

It does NOT:
- change canonical storage
- merge canonical records
- alter identity

It only selects a representative for delivery.

---

## Separation of Concerns

### Canonical Layer
- stores source-scoped truth

### Snapshot Layer
- groups equivalent events
- selects one winner per group

### Public API
- exposes winner only

---

## Definitions

### Merge Group

A merge group is a set of canonical events that are considered to represent the same real-world event.

Input:
- canonical events (multiple sources)

Output:
- one winner event

---

### Winner

The canonical event selected for display in snapshot output.

All other events in the group are considered:
- suppressed
- not visible in final output

---

## Determinism Requirement

Winner selection MUST be deterministic.

For same:
- canonical inputs
- grouping logic
- configuration

The winner MUST be identical.

No randomness allowed.

---

## Group Formation (Input Requirement)

Winner selection assumes that events are already grouped.

Grouping may be based on:
- shared venue_id
- time proximity
- title similarity
- other matching logic

This document does NOT define grouping rules.

---

## Selection Strategy

Winner selection is based on a **scoring + priority system**.

Each candidate event is evaluated against selection criteria.

The highest-ranked candidate is selected.

---

## Selection Criteria (Priority Order)

Evaluation must follow this order:

---

## 1. Visibility and Validity (Hard Filter)

Exclude events that are not eligible:

- visibility ≠ allowed
- event_status ≠ active (unless explicitly allowed)
- missing required fields (e.g. starts_at)

Only eligible candidates proceed.

---

## 2. Strong Identity Anchors

Prefer events with stronger identity anchors.

Priority:

1. has stable `detail_url`
2. has `source_event_id`
3. has composite identity only

Rationale:
- stronger identity → more reliable representation

---

## 3. Venue Confidence

Prefer events with stronger venue anchoring.

Priority:

1. has `venue_id`
2. has normalized `venue_name`
3. only has weak `location_label`

Rationale:
- venue_id → best cross-source anchor

---

## 4. Time Precision

Prefer more precise time data.

Priority:

1. `date_precision = datetime`
2. `date_precision = date`
3. `date_precision = unknown`

Rationale:
- precise time improves UX and sorting

---

## 5. Content Completeness

Prefer richer event records.

Score higher if:
- has `description`
- has `image_url`
- has `ticket_url`
- has `category_key`

Rationale:
- better UX quality

---

## 6. Source Priority (Optional)

If configured, prefer certain sources.

Example:
- official venue site > aggregator
- ticket platform > scraped blog

Source priority must be:
- explicit
- deterministic
- configurable per tenant if needed

---

## 7. Recency of Observation

Prefer events that are recently confirmed.

Priority:

- higher `last_seen_at`

Rationale:
- fresher data is more reliable

Constraint:
- must not override stronger identity/venue rules

---

## 8. Stable Tie-breaker

If all above are equal:

Use deterministic fallback:

1. earliest `updated_at`
2. alphabetical `source_key`
3. lexical `canonical_key`

This guarantees stability.

---

## Scoring Model (Conceptual)

Winner selection can be implemented as:

- rule-based priority system (recommended)
- or weighted scoring

Example conceptual score:

```text
score =
  + identity_strength
  + venue_strength
  + time_precision
  + content_completeness
  + source_priority
  + freshness

BUT:

👉 final implementation MUST remain deterministic and explainable

Forbidden Criteria

The following MUST NOT influence winner selection:

random values
ingestion order
database row order
change_hash alone
raw scrape timing noise
unstable metrics
Winner Selection Output

For each merge group:

Output:

selected canonical event (winner)
optional metadata:
{
  "winner": "canonical_key",
  "losers": ["canonical_key_2", "canonical_key_3"],
  "reason": "venue_id + better completeness"
}

This metadata may be:

internal only
or exposed in debug mode
Stability Requirement

Small non-meaningful changes must NOT flip the winner.

Example:

ticket_url change
image_url change
whitespace in title

Winner must remain stable unless:

meaningful content changes
stronger candidate appears
Change Handling

Winner may change when:

new source with better data appears
venue resolution improves
time precision improves
canonical data changes meaningfully

When winner changes:

this must be explainable
should be traceable via change logs
Debuggability Requirement

System must be able to explain:

why a winner was selected
why others were rejected

Minimum debug info:

candidate list
per-criterion evaluation
final decision reason
Example

Merge group:

[
  {
    "source_key": "tavastia",
    "venue_id": "venue_001",
    "date_precision": "datetime",
    "detail_url": "...",
    "description": "full"
  },
  {
    "source_key": "ticketmaster",
    "venue_id": null,
    "date_precision": "date",
    "detail_url": "...",
    "description": null
  }
]

Winner:

→ tavastia event

Reason:

has venue_id
has full datetime
richer content
Invariants

The following must always hold:

Exactly one winner per merge group
Winner selection is deterministic
Winner does not modify canonical data
Winner does not redefine identity
Only eligible events participate
Tie-breaking is explicit and stable
Winner selection is explainable
Out of Scope for v1

This document does NOT define:

merge group formation logic
personalization
recommendation ranking
UI layout decisions
multi-winner scenarios
Open Questions
Should source priority be global or tenant-specific?
Should completeness be weighted differently per module?
Should ticket_url presence ever be required for certain modules?
Should image availability influence homepage modules more strongly?
Summary

Snapshot Winner Selection Rules v1 defines how CityOS selects a single representative event from multiple source-scoped canonical events.

Key decisions:

canonical remains source-scoped
snapshot selects a winner, not merge
selection is deterministic
selection prioritizes identity, venue, precision, and completeness
selection must be explainable

This ensures consistent, high-quality event output.
