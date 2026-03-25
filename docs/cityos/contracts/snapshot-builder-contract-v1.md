# Snapshot Builder Contract v1

## Purpose

Snapshot Builder Contract v1 defines how CityOS transforms canonical events into a stable, publishable snapshot for downstream consumers.

This contract exists to ensure that:
- frontend consumers do not depend on raw ingest or canonical storage details
- snapshot output is deterministic
- visibility and publishability are applied consistently
- bucket/module composition is explainable
- the public API serves a stable and bounded payload

Snapshot Builder is the boundary between:
- internal event truth
- external delivery shape

---

## Role in System Architecture

Snapshot Builder sits after canonical storage and before delivery/public API.

Flow:

- ingest layer
- canonical layer
- snapshot builder
- public API
- frontend consumer

Snapshot Builder MUST consume canonical events only.

It MUST NOT consume:
- raw candidates
- mapped events directly
- source HTML
- parser-specific output

This is a hard system rule.

---

## Core Responsibilities

Snapshot Builder v1 is responsible for:

- selecting eligible canonical events
- applying visibility and publishability rules
- applying time-window logic
- producing deterministic event lists and buckets
- optionally applying diversity constraints
- generating a stable snapshot payload for public consumption

Snapshot Builder v1 is NOT responsible for:

- source ingestion
- canonical identity generation
- parser diagnostics
- UI rendering decisions
- editorial freeform content authoring
- recommendation/personalization logic

---

## Contract Boundary

### Input

Snapshot Builder input is a set of canonical events within a tenant scope.

Minimum required input fields per event:

- `tenant_id`
- `source_key`
- `canonical_key`
- `title`
- `starts_at`
- `timezone`
- `status`
- `visibility`
- `detail_url`
- `ticket_url` (optional)
- `image_url` (optional)
- `area` (optional)
- `venue_name` (optional)
- `location_label` (optional)
- `category` (optional)
- `tags` (optional)
- `change_hash` (optional)
- `updated_at`

### Output

Snapshot Builder output is a tenant-scoped snapshot object containing:
- snapshot metadata
- bucket/module outputs
- event summaries prepared for public delivery
- diagnostics metadata as allowed by environment or debug mode

---

## Core Principle

Snapshot Builder does not create event truth.

It creates a **delivery view** over canonical truth.

This means:
- canonical remains the source of truth
- snapshot is a deterministic projection
- snapshot may filter, group, or limit events
- snapshot must not invent event identity

---

## Determinism Rules

For the same:
- tenant
- snapshot builder configuration
- canonical input set
- build time reference rules

the output snapshot MUST be identical.

Determinism requires:
- stable filtering
- stable sorting
- stable tie-breaking
- explicit limits
- explicit diversity logic
- explicit fallback behavior

Snapshot Builder MUST NOT rely on:
- random ordering
- non-deterministic database ordering
- hidden heuristics
- implicit frontend-side filtering

---

## Eligibility Rules

An event is eligible for snapshot consideration only if all required conditions are met.

### Minimum eligibility

Event must satisfy:

- `status = active` OR explicit policy allows otherwise
- `visibility = allowed`
- `starts_at` is present and usable
- event falls within applicable window or module rule
- required delivery fields are present for the target module when applicable

### Ineligible examples

An event is ineligible if:

- `visibility = blocked`
- `visibility = out_of_scope`
- `visibility = review`
- `status = cancelled` unless explicitly included in a special module
- missing or invalid `starts_at`
- outside the module window
- fails module-specific requirements

---

## Visibility and Status Contract

Snapshot Builder MUST treat `status` and `visibility` separately.

### `status`
Represents event lifecycle truth:
- active
- cancelled
- postponed
- draft
- unknown

### `visibility`
Represents operational policy:
- allowed
- blocked
- out_of_scope
- review

### Rule

Snapshot inclusion requires passing both lifecycle and policy conditions.

Examples:
- active + allowed → eligible
- active + out_of_scope → not eligible
- cancelled + allowed → not eligible in normal modules
- active + review → not eligible

---

## Time Window Contract

Snapshot Builder v1 is time-window driven.

Each bucket/module must define its own explicit window rule.

Examples:
- today
- weekend
- next 7 days
- next 21 days
- ongoing now
- newest upcoming

### Window rules must be explicit

Every module must define:
- lower bound
- upper bound
- timezone basis
- inclusion semantics

### Inclusion semantics must specify

Whether the window uses:
- `starts_at >= lower_bound`
- `starts_at < upper_bound`
- inclusive or exclusive edges
- ongoing-event handling if relevant

### Timezone rule

All window calculations MUST use tenant/city timezone unless module explicitly defines another timezone basis.

---

## Module / Bucket Contract

Snapshot Builder output may contain multiple modules or buckets.

Each module must be defined declaratively by configuration or stable builder type.

Each module definition must include at minimum:
- `module_key`
- `builder_type`
- explicit selection rule
- explicit sort rule
- explicit limit
- optional diversity rule

### Supported conceptual builder types in v1

Examples:
- `time_bucket`
- `keyword_query`
- `newest`
- `static`
- `unsupported`

A module without a recognized builder type must not silently degrade into undefined behavior.

It must either:
- return empty with diagnostics
- or fail in controlled admin/debug context

---

## Sort Contract

Each module must define explicit sort behavior.

### Default sort for time-based modules

1. earliest `starts_at`
2. stable secondary sort by `title`
3. stable tertiary sort by `(source_key, canonical_key)`

This guarantees deterministic output even when times are equal.

### Important constraint

Database natural order MUST NOT be relied on.

---

## Limit Contract

Each module must define an explicit item limit.

Examples:
- homepage today = 6
- sports picks = 3
- next 7 days = 12

If more eligible items exist than limit allows:
- apply sort first
- then diversity rule if configured
- then final truncation deterministically

No implicit unlimited modules in public snapshots unless explicitly intended.

---

## Diversity Contract

Diversity is optional per module, but if used it must be explicit and deterministic.

### Purpose

Diversity prevents a module from being dominated by:
- one source
- one venue
- one organizer proxy
- one narrow event cluster

### Allowed diversity dimensions in v1

Examples:
- `source_key`
- `venue_name`
- `area`
- organizer proxy if explicitly defined

### Diversity rules must specify

- dimension
- max items per dimension value
- fallback behavior if diversity exhausts candidates

### Example

For a module with limit 6:
- max 2 per source
- sorted candidate list processed in order
- items exceeding source cap skipped
- continue until limit reached or candidates exhausted

### Diversity rule constraint

Diversity MUST NOT break determinism.
It is a deterministic post-filter over an already sorted candidate list.

---

## Cross-Source Handling

Snapshot Builder MAY perform grouping or dedupe across sources if such logic is explicitly defined.

However, in v1:

- canonical storage remains source-scoped
- snapshot-level grouping must not overwrite canonical identity
- snapshot grouping logic must be explainable and bounded

If no explicit grouping contract exists, Snapshot Builder MUST treat source-scoped canonical events as distinct items.

This is the safe default.

---

## Event Summary Shape

Snapshot Builder output should not expose full canonical records by default.

Instead, it should emit delivery-oriented event summaries.

### Recommended event summary fields

- `source_key`
- `canonical_key`
- `title`
- `subtitle` (optional)
- `starts_at`
- `ends_at` (optional)
- `timezone`
- `venue_name` (optional)
- `location_label` (optional)
- `area` (optional)
- `detail_url` (optional)
- `ticket_url` (optional)
- `image_url` (optional)
- `category` (optional)
- `tags` (optional)

### Optional derived delivery fields

If explicitly supported:
- `is_ongoing`
- `day_label`
- `time_label`

Derived fields must remain presentation-safe and deterministic.

---

## Snapshot Metadata Contract

Every snapshot must include metadata sufficient for debugging and freshness validation.

### Required metadata

- `tenant_id`
- `snapshot_version`
- `schema_version`
- `generated_at`
- `builder_version`
- `source_count` (optional but recommended)
- `event_count_total`
- `module_keys`

### Recommended metadata

- `input_window_summary`
- `build_duration_ms`
- `warnings`
- `debug_enabled`

Metadata should help operators answer:
- when was this built
- from what contract version
- how many events were considered
- which modules were produced

---

## Empty State Contract

A module may legitimately produce zero results.

When this happens:
- output must still be structurally valid
- empty list is preferable to omitted field unless omission is part of contract
- optional diagnostics may explain why

Possible reasons:
- no eligible events
- no events in time window
- diversity/filter rules exhausted candidates
- unsupported builder type

Empty state must not be ambiguous.

---

## Error Handling Contract

Snapshot Builder v1 must fail safely.

### Safe failure rules

- do not publish malformed snapshot structure
- do not silently mix incompatible schemas
- do not return partial random data without metadata
- do not hide module-level failures in admin/debug contexts

### Production-safe behavior

In public delivery:
- prefer last known good snapshot if available
- otherwise return a valid empty or degraded snapshot with clear metadata if system design allows

### Admin/debug behavior

Admin/debug contexts may expose:
- module failures
- unsupported builder warnings
- counts before/after filtering
- diversity drop reasons

---

## Diagnostics Contract

Snapshot Builder must be inspectable.

At minimum, system should be able to explain:
- number of canonical inputs considered
- count after visibility filter
- count after time window filter
- count after module-specific constraints
- count after diversity
- final emitted count

This may exist in:
- logs
- debug snapshot metadata
- admin diagnostics UI

The exact surfacing may vary, but the information must exist.

---

## Freshness Contract

Snapshot Builder output is expected to represent a current publishable view, not a historical archive.

Freshness rules should be explicit at system level.

Recommended metadata:
- `generated_at`
- `source_snapshot_age` or equivalent if available
- warning when stale beyond threshold

Frontend consumers should be able to reason about freshness without inspecting internal tables.

---

## Public API Contract Relationship

Public API is a delivery surface over snapshot output.

The public API:
- may expose snapshot as-is
- may expose selected modules
- may expose full event lists derived from canonical or snapshot-adjacent logic depending on system design

But homepage-style public outputs should rely on snapshot contract, not ad hoc recomputation in frontend.

This is a key architectural rule.

---

## Invariants

The following must always hold:

1. Snapshot Builder consumes canonical events only.
2. Snapshot output is deterministic for identical inputs.
3. Visibility and status are applied explicitly.
4. Every module has explicit selection, sort, and limit rules.
5. Diversity, if used, is deterministic and explicit.
6. Snapshot does not redefine canonical identity.
7. Public delivery must not depend on raw ingest shapes.
8. Empty modules remain structurally valid.
9. Snapshot metadata must include generation context.

---

## Recommended Minimal Snapshot Shape

```json
{
  "tenant_id": "helsinki",
  "schema_version": "snapshot.v1",
  "builder_version": "snapshot-builder.v1",
  "generated_at": "2026-03-25T10:00:00Z",
  "meta": {
    "event_count_total": 42,
    "module_keys": ["today", "weekend", "next7days"]
  },
  "events": {
    "today": [],
    "weekend": [],
    "next7days": []
  }
}
