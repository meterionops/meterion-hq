# Canonical Event Model v1

## Purpose

Canonical Event Model v1 defines the stable internal representation of an event inside CityOS.

Its purpose is to ensure that:
- ingest output can be normalized into a consistent structure
- event identity is deterministic
- downstream systems do not depend on source-specific shapes
- snapshot builder operates on a stable event model
- merge and visibility decisions are explainable and auditable

This model is the contract between:
- ingest layer
- canonical layer
- snapshot layer

## Design Goals

The model must be:

- Deterministic  
  Same source input and same normalization rules must produce the same canonical event.

- Source-aware  
  Canonical events are created from source-specific ingest results and retain traceability to origin.

- Stable  
  Downstream layers must not need to understand source-specific parser behavior.

- Observable  
  Field origin, normalization status, and merge reasoning must be inspectable.

- Safe  
  Missing or weak fields must not silently create incorrect identity or unsafe merges.

## Non-Goals

Canonical Event Model v1 does not define:
- frontend rendering rules
- ranking or recommendation logic
- editorial curation logic
- final homepage module selection
- cross-city product strategy

Those belong to snapshot, delivery, and product layers.

---

## Canonical Event Definition

A canonical event is the normalized internal record representing one source-originated event candidate that has passed ingest mapping and canonical transformation.

In v1, canonical events are **source-scoped**.

This means:
- one source produces its own canonical events
- two different sources may describe the same real-world event
- cross-source unification is not performed inside canonical storage
- cross-source merge or dedupe may happen later in snapshot logic

This rule keeps ingest and canonical layers stable and prevents unsafe early merges.

---

## Identity Model

## Core Rule

Canonical identity in v1 is based on:

- tenant scope
- source scope
- deterministic event key derived from normalized event identity inputs

### Identity Formula

A canonical event must be uniquely identified by:

- `tenant_id`
- `source_key`
- `canonical_key`

### Canonical Key Principle

`canonical_key` must be deterministic and derived from the best available stable identity fields.

Preferred identity inputs:

1. normalized source event URL or source-native event identifier
2. normalized event title
3. normalized event start time
4. normalized venue or location label

### Identity Priority

Use the strongest available identity basis in this order:

1. Source-native stable ID
2. Stable event detail URL
3. Fallback composite identity:
   - normalized title
   - normalized start timestamp
   - normalized venue/location

### Important Constraint

The canonical key must not depend on:
- volatile query parameters
- description text
- ticket URL querystrings
- scrape timestamps
- transient badges or labels
- ranking fields

These may change without changing event identity.

---

## Required Fields

A canonical event in v1 should contain the following minimum fields:

- `tenant_id`
- `source_key`
- `canonical_key`
- `title`
- `starts_at`
- `timezone`
- `status`
- `visibility`
- `provenance`
- `created_at`
- `updated_at`

If minimum identity-supporting fields are missing, the event may still exist as canonical only if identity generation remains deterministic and explainable.

If not, it must be rejected before canonicalization.

---

## Canonical Schema v1

## Identity and Scope

### `tenant_id`
Logical tenant scope.

Type:
- string / uuid

Rules:
- required
- immutable after creation

### `source_key`
Stable source identity inside tenant.

Type:
- string

Rules:
- required
- must match the source that produced the event
- immutable after creation

### `canonical_key`
Deterministic event key within source scope.

Type:
- string

Rules:
- required
- unique within `(tenant_id, source_key)`
- derived only from normalized stable identity inputs
- immutable unless identity logic version explicitly changes

---

## Core Event Fields

### `title`
Normalized event title.

Type:
- string

Rules:
- required unless event is rejected before canonical stage
- trimmed
- whitespace normalized
- source boilerplate removed where safe
- should reflect user-visible event name, not internal listing text

### `subtitle`
Optional secondary label.

Type:
- string | null

Rules:
- optional
- must not duplicate title unnecessarily

### `description`
Normalized descriptive text.

Type:
- string | null

Rules:
- optional
- may be long-form
- may contain lossy cleanup from HTML
- must not be used for identity

### `starts_at`
Normalized event start datetime.

Type:
- ISO timestamp

Rules:
- required for publishable event behavior
- timezone-aware or paired with timezone
- if only date is known, normalization policy must be explicit

### `ends_at`
Normalized end datetime.

Type:
- ISO timestamp | null

Rules:
- optional
- may be null if source does not provide end time
- must not be fabricated unless policy explicitly allows inferred end times

### `timezone`
Event timezone.

Type:
- string

Rules:
- required
- default should be tenant/city timezone only when source does not specify and policy allows it

### `all_day`
All-day flag.

Type:
- boolean

Rules:
- default false
- true only when source meaning supports all-day interpretation

---

## Location Fields

### `venue_name`
Normalized venue label.

Type:
- string | null

### `location_label`
Human-readable location string.

Type:
- string | null

### `address_locality`
City/locality.

Type:
- string | null

### `address_postal_code`
Postal code.

Type:
- string | null

### `address_street`
Street address.

Type:
- string | null

### `area`
Operational area label used by downstream logic.

Type:
- string | null

Rules:
- optional
- may be derived from known mappings
- useful for snapshot filtering
- must remain explainable

### `coordinates`
Optional geolocation.

Type:
- object | null

Shape:
- `lat`
- `lng`

Rules:
- optional
- must only be populated from trusted source or stable mapping

---

## Commercial / Link Fields

### `detail_url`
Primary event page URL.

Type:
- string | null

Rules:
- preferred identity input when stable
- normalized before identity use
- query params removed where appropriate

### `ticket_url`
Primary ticket URL.

Type:
- string | null

Rules:
- optional
- normalized separately from detail URL
- must not affect identity
- may be used in snapshot eligibility

### `image_url`
Primary event image.

Type:
- string | null

Rules:
- optional
- not identity-bearing
- may be absent even for valid events

---

## Classification Fields

### `category`
Primary canonical category.

Type:
- string | null

### `tags`
Freeform normalized tags.

Type:
- string[] | empty

### `audience`
Optional audience label.

Type:
- string | null

### `language`
Optional event language.

Type:
- string | null

Rules:
- all classification fields are optional in v1
- source-derived classification may be imperfect
- classification must not control identity

---

## Lifecycle Fields

### `status`
Canonical lifecycle state.

Type:
- enum

Allowed values:
- `active`
- `cancelled`
- `postponed`
- `draft`
- `unknown`

Rules:
- required
- default should be `active` only when source evidence supports it
- otherwise `unknown`

### `visibility`
Operational visibility decision.

Type:
- enum

Allowed values:
- `allowed`
- `blocked`
- `out_of_scope`
- `review`

Rules:
- required
- visibility is not the same as status
- event may be active but out_of_scope
- event may be active but blocked due to policy

### `is_publishable`
Derived convenience flag.

Type:
- boolean

Rules:
- derived from status + visibility + required publishing conditions
- should not replace raw fields in diagnostics

---

## Provenance and Audit Fields

### `provenance`
Structured origin metadata.

Type:
- object

Suggested fields:
- `source_key`
- `run_id`
- `adapter_key`
- `source_url`
- `detail_url_raw`
- `mapping_version`
- `canonicalization_version`

Rules:
- required
- must support traceability back to ingest run and source behavior

### `field_sources`
Optional per-field origin metadata.

Type:
- object | null

Purpose:
- explain where a field came from
- source html
- mapped field
- enrichment
- static mapping

### `raw_fingerprint`
Fingerprint of raw mapped source content.

Type:
- string | null

Rules:
- optional
- useful for change detection
- must not be primary identity

### `change_hash`
Stable change detection hash.

Type:
- string | null

Rules:
- based on meaningful publish-relevant fields
- must exclude volatile values
- used to track real event changes
- not identity-bearing

### `created_at`
Canonical record creation time.

### `updated_at`
Canonical record update time.

### `first_seen_at`
Optional first observed time.

### `last_seen_at`
Optional latest observed time.

---

## Relationship to Ingest Layer

The ingest layer may produce:
- raw extracted candidates
- mapped events
- source-specific fields
- parser-specific quality variations

Canonicalization must:
- normalize field names
- normalize text and URLs
- normalize time representation
- assign deterministic identity
- attach provenance
- reject non-events when identity or semantic validity is insufficient

Ingest is allowed to be messy.
Canonical is not.

---

## Relationship to Snapshot Layer

Snapshot builder must consume canonical events, not raw ingest outputs.

Snapshot logic may:
- filter by visibility
- filter by date window
- apply eligibility rules
- apply diversity logic
- perform cross-source grouping or dedupe if defined separately

Snapshot layer must not redefine canonical identity.
It may create snapshot-level grouping identities, but canonical storage remains source-scoped in v1.

---

## Merge Rules v1

## Within-Source Merge

Canonical merge/update is allowed only when:
- tenant matches
- source_key matches
- canonical_key matches

This means v1 supports:
- record updates across runs for the same source event
- deterministic re-ingest refresh
- source-local continuity

### Update Semantics

When the same canonical record is observed again:
- stable fields are refreshed from the latest trustworthy input
- provenance is updated
- last_seen_at is updated
- change_hash is recomputed
- updated_at is updated

### Conflict Rule

If a new ingest result would produce the same canonical_key but materially incompatible identity fields, it must be flagged for review or treated as a collision, not silently merged.

Examples:
- same key but clearly different title family
- same key but incompatible event date basis
- same key but location mismatch beyond allowed tolerance

---

## Cross-Source Merge

Cross-source merge is out of scope for canonical storage in v1.

Reason:
- early merging is risky
- many sources are partial or lossy
- real-world event equivalence is probabilistic

Instead:
- preserve source-scoped canonical truth
- allow later snapshot-stage grouping if needed
- keep reasoning inspectable

This is a deliberate safety rule.

---

## Normalization Rules

## Text Normalization
Apply:
- trim
- collapse whitespace
- HTML entity cleanup where applicable
- remove obvious boilerplate wrappers where safe

Do not:
- aggressively rewrite semantic content
- translate titles automatically
- infer missing descriptive meaning

## URL Normalization
Apply:
- lowercase host
- remove tracking query params
- remove known volatile query params
- normalize trailing slash policy consistently

Do not:
- collapse clearly different paths
- assume two different URLs are the same event unless rules say so

## Time Normalization
Apply:
- resolve explicit timezone when available
- otherwise use tenant timezone only under explicit policy
- preserve uncertainty when source precision is weak

Do not:
- fabricate exact times from vague text unless explicitly allowed

---

## Rejection Rules

An item must not become canonical if any of the following is true:

- it is not actually an event
- identity cannot be built deterministically
- title is missing and no stable source-native identity exists
- start time is unusable and no acceptable fallback policy exists
- extracted item is navigation/search/category content
- detail target is clearly a list page rather than event detail page

Rejected items belong in ingest diagnostics, not canonical storage.

---

## Constraints and Invariants

The following invariants must hold:

1. Canonical identity is deterministic.
2. Canonical storage is source-scoped in v1.
3. Identity must not depend on volatile fields.
4. Visibility is operational policy, not event existence.
5. Status is event lifecycle, not policy outcome.
6. Snapshot builder consumes canonical events, not raw mapped events.
7. Cross-source unification is not canonical responsibility in v1.
8. Every canonical event must have provenance.

---

## Recommended Minimal Table Shape

Suggested conceptual record shape:

- tenant_id
- source_key
- canonical_key
- title
- subtitle
- description
- starts_at
- ends_at
- timezone
- all_day
- venue_name
- location_label
- address_street
- address_postal_code
- address_locality
- area
- coordinates
- detail_url
- ticket_url
- image_url
- category
- tags
- audience
- language
- status
- visibility
- is_publishable
- provenance
- field_sources
- raw_fingerprint
- change_hash
- first_seen_at
- last_seen_at
- created_at
- updated_at

---

## Open Questions for v1 Finalization

The following should be decided explicitly before locking implementation:

1. Is `starts_at` always required for canonical storage, or only for publishable events?
2. What is the exact fallback recipe for canonical_key generation?
3. Which URL query params are globally stripped?
4. Which fields participate in `change_hash`?
5. Should `is_publishable` be stored or computed on read?
6. How should recurring events be represented in v1?
7. What is the minimum acceptable location model for snapshot diversity logic?

---

## Recommended Next Documents

After this model, CityOS should define:

1. Canonical Field Definitions v1
2. Canonical Identity Rules v1
3. Snapshot Builder Contract v1
4. Visibility Policy Contract v1
5. Canonical Change Hash Rules v1

---

## Summary

Canonical Event Model v1 establishes a stable, deterministic, source-scoped event representation for CityOS.

Its core decisions are:
- canonical storage is source-scoped
- identity is deterministic and non-volatile
- provenance is required
- ingest may be messy, canonical may not
- cross-source merge is deferred to later layers

This keeps the system safe, explainable, and compatible with snapshot-driven delivery.
