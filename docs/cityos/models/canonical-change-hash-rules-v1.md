---
title: Canonical Change Hash Rules v1
doc_type: spec
project_key: cityos
domain_key: models
status: active
---

# Canonical Change Hash Rules v1

## Purpose

This document defines how `change_hash` is computed for canonical events in CityOS.

The purpose of `change_hash` is to detect meaningful event content changes without confusing identity with change tracking.

It is used for:
- change detection across ingest runs
- snapshot freshness and update logic
- operational diagnostics
- "changed recently" style signals

It is NOT used for:
- canonical identity
- deduplication keys
- primary database identity

---

## Core Principle

`change_hash` answers:

👉 "Has the meaningful publishable content of this event changed?"

It must ignore:
- volatile fields
- ingestion noise
- tracking parameters
- timestamp churn caused by sync

It must capture:
- meaningful event content changes
- meaningful scheduling changes
- meaningful location or venue changes
- meaningful visibility/lifecycle changes when relevant to output

---

## Separation from Identity

`canonical_key` and `change_hash` are separate by design.

### `canonical_key`
Answers:
- is this the same event?

### `change_hash`
Answers:
- has this event materially changed?

Invariant:
- a record may keep the same `canonical_key` while its `change_hash` changes
- a `change_hash` change must never redefine identity

---

## Determinism Requirement

For the same canonical event field values and normalization rules:

- `change_hash` MUST be identical
- it must not depend on database row order
- it must not depend on ingest timing
- it must not depend on non-normalized source artifacts

No randomness is allowed.

---

## Hash Construction Model

`change_hash` is computed from a normalized payload containing only approved change-bearing fields.

Recommended conceptual formula:

```text
change_hash = hash(normalized_change_payload)

Recommended hash algorithms:

sha1
sha256 truncated
any stable deterministic hashing scheme

The exact algorithm is less important than:

field stability
normalization consistency
version clarity
Change Hash Versioning

Every change_hash must be computed using an explicit ruleset version.

Recommended field:

change_hash_version

Example:

canonical-change-hash.v1

Rule:

change hash logic must not change silently
if participating fields or normalization rules change, version must change too
Included Fields

The following fields SHOULD participate in change_hash in v1.

1. Core Content
title

Include:

yes

Reason:

primary publishable identity-facing content
subtitle

Include:

yes, if present

Reason:

meaningful display content
description

Include:

no by default in v1

Reason:

often noisy
highly volatile
often HTML-cleanup dependent

Exception:

may be introduced in a later version if normalized safely and proven useful
language

Include:

no by default

Reason:

secondary metadata
not usually meaningful enough to drive change churn
2. Time
starts_at

Include:

yes

Reason:

one of the most meaningful event changes
ends_at

Include:

yes

Reason:

meaningful schedule change if present
timezone

Include:

yes

Reason:

affects time interpretation
all_day

Include:

yes

Reason:

changes presentation and scheduling semantics
date_precision

Include:

yes

Reason:

switching from date-only to datetime is meaningful
3. Venue and Location
venue_id

Include:

yes

Reason:

strongest location anchor
venue_name

Include:

yes only if venue_id is null

Reason:

fallback meaningful location anchor
location_label

Include:

yes only if venue_id is null and venue_name is weak or null

Reason:

fallback location representation
city_key

Include:

yes

Reason:

city assignment is materially significant
area_key

Include:

yes

Reason:

can affect snapshot selection and city-level presentation
address_street

Include:

no by default
address_postal_code

Include:

no by default
coordinates_lat

Include:

no by default
coordinates_lng

Include:

no by default

Reason:

too granular
often derived
can churn without meaningful user-facing change
4. Links and Media
detail_url

Include:

yes, normalized

Reason:

often the primary stable event page
if the main event page changes meaningfully, this may matter
ticket_url

Include:

no by default

Reason:

commercial URL churn is common
query params and ticket provider changes cause noise
image_url

Include:

no by default

Reason:

not core event truth
presentation-only in v1
5. Classification
category_key

Include:

yes

Reason:

can materially affect downstream presentation and filtering
tags

Include:

no by default

Reason:

often noisy and unstable
source mapping quality varies
audience_key

Include:

no by default

Reason:

useful but not strong enough in v1 to justify churn
6. Lifecycle and Visibility
event_status

Include:

yes

Reason:

cancellation/postponement/activation is a meaningful change
visibility

Include:

yes

Reason:

affects publishability directly
visibility_reason_code

Include:

no by default

Reason:

useful for diagnostics but too implementation-specific for primary change detection
is_publishable

Include:

no

Reason:

derived from other included fields
including it would duplicate meaning
Excluded Fields

The following fields MUST NOT participate in change_hash in v1:

canonical_id
canonical_key
identity_version
source_key
source_type
source_event_id
ticket_url
image_url
address_street
address_postal_code
coordinates_lat
coordinates_lng
language
tags
audience_key
visibility_reason_code
is_publishable
provenance_source_run_id
provenance_adapter_key
provenance_mapping_version
provenance_canonicalization_version
raw_fingerprint
field_sources
diagnostics_flags
first_seen_at
last_seen_at
created_at
updated_at

These are excluded because they are:

identity fields
derived fields
provenance fields
operational timestamps
noisy or weak fields
Normalization Rules

Before hashing, included fields must be normalized consistently.

Text Normalization

For included text fields:

trim leading/trailing whitespace
collapse internal repeated whitespace
normalize empty string to null
lowercase only where semantically appropriate
Lowercasing rule

Use lowercasing for:

URL host normalization
machine keys where applicable

Do NOT blindly lowercase:

user-facing titles
subtitles

Reason:

preserve semantic fidelity while still avoiding accidental formatting noise
URL Normalization

For included URL fields such as detail_url:

lowercase host
normalize protocol policy consistently
remove fragments
remove tracking/query params not part of stable event identity
remove trailing slash consistently

Rule:

detail_url must be normalized the same way as defined by identity rules where relevant
Null Handling

The change payload must represent nulls consistently.

Examples:

empty string → null
missing optional field → null
absent array → empty array only if that field participates

No ambiguous null/empty-string distinction is allowed.

Field Fallback Rules

When stronger fields are missing, fallback fields may participate.

Location fallback chain

Use:

venue_id
else venue_name
else location_label

Only the strongest available location anchor should participate.

This prevents redundant churn when multiple weak location fields coexist.

Payload Shape

Recommended conceptual payload structure before hashing:

{
  "title": "Example Show",
  "subtitle": null,
  "starts_at": "2026-04-18T19:00:00+03:00",
  "ends_at": null,
  "timezone": "Europe/Helsinki",
  "all_day": false,
  "date_precision": "datetime",
  "location_anchor": {
    "type": "venue_id",
    "value": "venue_tavastia_001"
  },
  "city_key": "helsinki",
  "area_key": "kamppi",
  "detail_url": "https://tavastia.fi/events/example-show",
  "category_key": "music",
  "event_status": "active",
  "visibility": "allowed"
}

Only normalized values should be included.

Canonical Ordering Rule

When serializing the change payload:

object key ordering must be stable
array ordering must be stable if arrays are ever included
same payload must always serialize identically

Recommended approach:

sort object keys deterministically before hashing
What Counts as a Meaningful Change

The following SHOULD change change_hash:

title changes materially
event start time changes
event end time changes
all-day status changes
venue anchor changes
city assignment changes
category changes
event status changes
visibility changes
detail page URL changes materially
What Does NOT Count as a Meaningful Change

The following SHOULD NOT change change_hash in v1:

sync timestamps update
provenance updates
raw fingerprint updates
mapping version changes alone
ticket provider query param changes
image URL changes
tag order or noisy metadata churn
diagnostics flag changes
whitespace-only non-meaningful drift after normalization
Collision Tolerance

Different canonical events may theoretically produce identical change_hash.

This is acceptable because:

change_hash is not identity
it is only a content change detector

No uniqueness constraint is required on change_hash.

Recompute Rules

change_hash should be recomputed when:

any included field changes
normalization rules change
change hash version changes

It does not need recomputation for:

excluded field updates only
Operational Use Rules
Allowed uses
detect meaningful updates
trigger snapshot refresh logic
power "changed recently" indicators
compare prior and current canonical content
Forbidden uses
event identity
deduplication
cross-source matching
primary record lookup
Debuggability Requirement

System should be able to explain why change_hash changed.

Recommended debug support:

previous normalized change payload
next normalized change payload
field-by-field diff
change hash version used

This is especially important for reducing false-positive churn.

Example Included Payload

Given this canonical event:

{
  "title": "Example Show",
  "subtitle": null,
  "starts_at": "2026-04-18T19:00:00+03:00",
  "ends_at": null,
  "timezone": "Europe/Helsinki",
  "all_day": false,
  "date_precision": "datetime",
  "venue_id": "venue_tavastia_001",
  "venue_name": "Tavastia",
  "location_label": "Tavastia, Helsinki",
  "city_key": "helsinki",
  "area_key": "kamppi",
  "detail_url": "https://tavastia.fi/events/example-show?utm_source=test",
  "category_key": "music",
  "event_status": "active",
  "visibility": "allowed",
  "ticket_url": "https://tickets.example.com/show-123?session=abc",
  "updated_at": "2026-04-10T07:00:00Z"
}

Normalized change payload becomes:

{
  "title": "Example Show",
  "subtitle": null,
  "starts_at": "2026-04-18T19:00:00+03:00",
  "ends_at": null,
  "timezone": "Europe/Helsinki",
  "all_day": false,
  "date_precision": "datetime",
  "location_anchor": {
    "type": "venue_id",
    "value": "venue_tavastia_001"
  },
  "city_key": "helsinki",
  "area_key": "kamppi",
  "detail_url": "https://tavastia.fi/events/example-show",
  "category_key": "music",
  "event_status": "active",
  "visibility": "allowed"
}

Notice:

ticket_url is excluded
tracking params are removed from detail_url
updated_at is excluded
venue_name and location_label are ignored because stronger venue_id exists
Invariants

The following must always hold:

change_hash is deterministic.
change_hash is not identity.
Only approved normalized fields may participate.
Volatile operational fields must be excluded.
Derived fields should not duplicate included raw meaning.
Change hash logic version must be explicit.
Same canonical payload must always yield same change_hash.
Open Questions

The following may be refined later:

Should normalized description be included in v2?
Should audience classification participate in some projects?
Should tags be included once taxonomy stabilizes?
Should detail_url remain included if URL churn proves noisy?
Should area_key be optional for projects without area-level UX?
Summary

Canonical Change Hash Rules v1 defines how CityOS detects meaningful event content changes without confusing change tracking with identity.

Key decisions:

use a normalized approved payload
include meaningful publishable fields only
exclude volatile, diagnostic, and provenance fields
prefer strong location anchors
version the rules explicitly

This keeps change detection stable, explainable, and resistant to noise.
