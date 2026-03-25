---
title: Canonical Event Schema v1
doc_type: spec
project_key: cityos
domain_key: models
status: active
---

# Canonical Event Schema v1

## Purpose

This document defines the canonical event record shape used inside CityOS.

It specifies:
- field names
- field meanings
- field ownership
- required vs optional status
- derivation rules
- invariants

This schema is the stable internal contract for canonical events.

It is used by:
- ingest normalization
- canonical storage
- visibility policy
- snapshot builder
- downstream diagnostics

---

## Relationship to Other Documents

This document should be read together with:

- Canonical Event Model v1
- Canonical Identity Rules v1
- Visibility Policy Contract v1
- Snapshot Builder Contract v1

This document defines the field-level schema.
It does not define:
- parsing logic
- ranking logic
- frontend rendering
- public API payload shape

---

## Core Principle

A canonical event is:

- source-scoped
- deterministic
- venue-anchored where possible
- publishable truth layer
- not a raw ingest artifact
- not a cross-source merged record

---

## Record Shape

A canonical event record contains the following sections:

1. Identity
2. Source Scope
3. Core Content
4. Time
5. Venue and Location
6. Links and Media
7. Classification
8. Lifecycle and Visibility Inputs
9. Provenance and Diagnostics
10. Timestamps

---

# 1. Identity

## canonical_id
Stable internal unique row identifier.

Type:
- uuid or text id

Required:
- yes

Meaning:
- database identity for this canonical record

Notes:
- internal only
- not the semantic event identity

---

## canonical_key
Stable semantic identity for the event inside source scope.

Type:
- text

Required:
- yes

Meaning:
- deterministic event identity key
- produced according to Canonical Identity Rules v1

Invariant:
- unique within `(tenant_id, source_key)`

---

## identity_version
Version of identity construction rules used for this record.

Type:
- text

Required:
- yes

Example:
- `canonical-identity.v1`

Purpose:
- allows future identity evolution without silent behavior drift

---

# 2. Source Scope

## tenant_id
Logical tenant scope.

Type:
- text

Required:
- yes

Meaning:
- city / tenant under which this event exists

Examples:
- `helsinki`
- `tampere`

---

## source_key
Stable source identity.

Type:
- text

Required:
- yes

Meaning:
- identifies the source that produced this canonical event

Invariant:
- canonical events are source-scoped

---

## source_type
High-level source type.

Type:
- text

Required:
- no

Examples:
- `venue_site`
- `ticketing_platform`
- `city_feed`
- `aggregator`

Purpose:
- diagnostics and analysis only
- must not define identity

---

## source_event_id
Source-native event identifier when available.

Type:
- text | null

Required:
- no

Meaning:
- strongest source-level identity input if provided

Rule:
- may be used in canonical_key generation
- may be null

---

# 3. Core Content

## title
Primary event title.

Type:
- text

Required:
- yes

Meaning:
- normalized user-visible title of the event

Normalization:
- trimmed
- whitespace collapsed
- obvious boilerplate removed where safe

Must not:
- be translated automatically
- contain layout/navigation text

---

## subtitle
Optional secondary event label.

Type:
- text | null

Required:
- no

Meaning:
- supporting display label if source has one

---

## description
Normalized event description.

Type:
- text | null

Required:
- no

Meaning:
- long-form descriptive text

Rules:
- may be lossy-cleaned from HTML
- must never participate in semantic identity

---

## language
Primary event language if known.

Type:
- text | null

Required:
- no

Examples:
- `fi`
- `sv`
- `en`

---

# 4. Time

## starts_at
Canonical event start timestamp.

Type:
- timestamptz / ISO timestamp

Required:
- yes for publishable canonical event
- may be nullable only if system explicitly allows non-publishable canonical records

Meaning:
- main time anchor for event identity and scheduling

Invariant:
- must be deterministic
- must include timezone semantics

---

## ends_at
Canonical event end timestamp.

Type:
- timestamptz | null

Required:
- no

Meaning:
- explicit event end if known

Rule:
- must not be fabricated silently

---

## timezone
Timezone used for event time interpretation.

Type:
- text

Required:
- yes

Examples:
- `Europe/Helsinki`

Rule:
- explicit if source gives it
- otherwise tenant-default only via explicit policy

---

## all_day
Whether the event is all-day.

Type:
- boolean

Required:
- yes

Default:
- false

Rule:
- true only when source meaning supports it

---

## date_precision
Precision of source time knowledge.

Type:
- text

Required:
- yes

Allowed values:
- `datetime`
- `date`
- `unknown`

Purpose:
- explains whether event has full datetime or date-only precision

---

# 5. Venue and Location

## venue_id
Resolved venue graph identifier.

Type:
- text | null

Required:
- no, but strongly preferred

Meaning:
- primary venue anchor for city assignment and cross-source matching

Rule:
- if available, this is the preferred location anchor

---

## venue_name
Normalized venue name.

Type:
- text | null

Required:
- no

Meaning:
- human-readable venue label

Rule:
- may come from source or venue graph alignment

---

## location_label
Normalized display location string.

Type:
- text | null

Required:
- no

Meaning:
- human-readable fallback when venue is not strongly resolved

Examples:
- `Tavastia, Helsinki`
- `Kulttuuritalo`

---

## city_key
City assignment for the event.

Type:
- text | null

Required:
- yes for in-scope publishable event

Meaning:
- canonical city scope of the event

Rule:
- should come from venue anchor where possible
- should not rely only on raw source wording if venue graph exists

---

## area_key
Operational area grouping inside city.

Type:
- text | null

Required:
- no

Purpose:
- snapshot diversity and filtering support

Examples:
- `kallio`
- `kamppi`
- `pasila`

---

## address_street
Street address.

Type:
- text | null

Required:
- no

## address_postal_code
Postal code.

Type:
- text | null

Required:
- no

## coordinates_lat
Latitude.

Type:
- numeric | null

Required:
- no

## coordinates_lng
Longitude.

Type:
- numeric | null

Required:
- no

Rule:
- coordinates must come from trusted mapping or reliable source
- must not be guessed implicitly

---

# 6. Links and Media

## detail_url
Primary public event detail URL.

Type:
- text | null

Required:
- strongly preferred

Meaning:
- best user-facing page for the event

Rule:
- may be identity input if stable
- normalized before identity use

---

## ticket_url
Primary ticket purchase URL.

Type:
- text | null

Required:
- no

Rule:
- commercial convenience field only
- never used for semantic identity

---

## image_url
Primary image URL.

Type:
- text | null

Required:
- no

Rule:
- optional presentation-support field
- never identity-bearing

---

# 7. Classification

## category_key
Primary canonical category.

Type:
- text | null

Required:
- no

Examples:
- `music`
- `sports`
- `theatre`
- `family`

Rule:
- classification is helpful but secondary
- must not define identity

---

## tags
Normalized tag list.

Type:
- jsonb array / text[]

Required:
- yes

Default:
- empty list

Rule:
- may include source-derived or mapped tags
- tags are non-identity metadata

---

## audience_key
Audience classification if known.

Type:
- text | null

Examples:
- `adults`
- `children`
- `all`

Required:
- no

---

# 8. Lifecycle and Visibility Inputs

## event_status
Lifecycle state of the event itself.

Type:
- text

Required:
- yes

Allowed values:
- `active`
- `cancelled`
- `postponed`
- `draft`
- `unknown`

Meaning:
- represents event truth, not output policy

---

## visibility
Operational visibility decision.

Type:
- text

Required:
- yes

Allowed values:
- `allowed`
- `blocked`
- `out_of_scope`
- `review`

Meaning:
- determined by visibility policy
- controls eligibility for downstream output

---

## visibility_reason_code
Machine-readable primary reason for visibility result.

Type:
- text | null

Required:
- no

Examples:
- `scope_mismatch`
- `not_an_event`
- `identity_collision`
- `missing_required_fields`

---

## is_publishable
Derived publishability flag.

Type:
- boolean

Required:
- yes

Meaning:
- convenience field indicating whether event meets minimum delivery conditions

Rule:
- derived from lifecycle + visibility + core field completeness
- must not replace raw fields in diagnostics

---

# 9. Provenance and Diagnostics

## provenance_source_run_id
Identifier of ingest run that produced or last updated this event.

Type:
- text | null

Required:
- no but recommended

---

## provenance_adapter_key
Adapter/runtime key used during extraction.

Type:
- text | null

Required:
- no

---

## provenance_mapping_version
Version of mapping rules used.

Type:
- text | null

Required:
- no

---

## provenance_canonicalization_version
Version of canonicalization rules used.

Type:
- text | null

Required:
- yes

Example:
- `canonical-schema.v1`

---

## raw_fingerprint
Fingerprint of mapped source material.

Type:
- text | null

Required:
- no

Purpose:
- change diagnostics only

Rule:
- not semantic identity

---

## change_hash
Stable content change hash.

Type:
- text | null

Required:
- yes

Meaning:
- reflects meaningful canonical content changes

Rule:
- excludes volatile fields
- separate from canonical identity

---

## field_sources
Optional field-level provenance map.

Type:
- jsonb | null

Required:
- no

Meaning:
- explains where each major canonical field came from

Example:
```json
{
  "title": "mapped.title",
  "starts_at": "mapped.starts_at",
  "venue_id": "venue_graph.match",
  "city_key": "venue_graph.city"
}
diagnostics_flags

Optional machine-readable diagnostic flags.

Type:

jsonb array / text[]

Required:

yes

Default:

empty list

Examples:

date_only_precision
weak_venue_match
missing_ticket_url
composite_identity_used

Purpose:

debugging and quality analysis
10. Timestamps
first_seen_at

First time this event was observed in canonical storage.

Type:

timestamptz

Required:

yes
last_seen_at

Most recent time this event was observed from source.

Type:

timestamptz

Required:

yes
created_at

Canonical record creation timestamp.

Type:

timestamptz

Required:

yes
updated_at

Canonical record last update timestamp.

Type:

timestamptz

Required:

yes
Required Field Sets
Minimum canonical storage set

The minimum canonical storage set is:

canonical_id
canonical_key
identity_version
tenant_id
source_key
title
starts_at
timezone
all_day
date_precision
event_status
visibility
is_publishable
provenance_canonicalization_version
change_hash
first_seen_at
last_seen_at
created_at
updated_at
Strongly recommended publishable set

For a strong publishable canonical event, the following should also exist:

detail_url
venue_id or venue_name
city_key
category_key (if classification exists)
visibility_reason_code when not allowed
Field Ownership Rules
Fields primarily owned by ingest normalization

These usually originate from source extraction:

source_event_id
title
subtitle
description
starts_at
ends_at
detail_url
ticket_url
image_url
venue_name
location_label
language
Fields primarily owned by venue / city resolution

These should be resolved or confirmed by graph/mapping logic:

venue_id
city_key
area_key
coordinates_lat
coordinates_lng
Fields primarily owned by canonical policy layer

These are assigned during canonicalization / policy application:

canonical_key
identity_version
event_status
visibility
visibility_reason_code
is_publishable
change_hash
diagnostics_flags
Invariants

The following must always hold:

Canonical events are source-scoped.
canonical_key is deterministic within (tenant_id, source_key).
change_hash is not identity.
visibility is policy, not event truth.
event_status is lifecycle truth, not policy.
venue_id is preferred over raw textual city inference.
detail_url, ticket_url, image_url are never semantic identity by themselves unless explicitly allowed for detail_url in identity rules.
Canonical records must remain explainable through provenance and diagnostics.
Example Canonical Event
{
  "canonical_id": "c14c5f3d-6e91-4d8c-8d0a-2e5b77f1a8f2",
  "canonical_key": "url:https://tavastia.fi/events/example-show",
  "identity_version": "canonical-identity.v1",
  "tenant_id": "helsinki",
  "source_key": "tavastia",
  "source_type": "venue_site",
  "source_event_id": null,

  "title": "Example Show",
  "subtitle": null,
  "description": "Live performance in Helsinki.",
  "language": "fi",

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
  "address_street": null,
  "address_postal_code": null,
  "coordinates_lat": 60.1699,
  "coordinates_lng": 24.9302,

  "detail_url": "https://tavastia.fi/events/example-show",
  "ticket_url": "https://tickets.example.com/show-123",
  "image_url": "https://tavastia.fi/images/example.jpg",

  "category_key": "music",
  "tags": ["live", "concert"],
  "audience_key": "adults",

  "event_status": "active",
  "visibility": "allowed",
  "visibility_reason_code": null,
  "is_publishable": true,

  "provenance_source_run_id": "run_2026_04_10_001",
  "provenance_adapter_key": "html_mode3",
  "provenance_mapping_version": "mapping.v4",
  "provenance_canonicalization_version": "canonical-schema.v1",
  "raw_fingerprint": "fp_abc123",
  "change_hash": "chg_8a1d92",
  "field_sources": {
    "title": "mapped.title",
    "starts_at": "mapped.starts_at",
    "venue_id": "venue_graph.match",
    "city_key": "venue_graph.city"
  },
  "diagnostics_flags": [],

  "first_seen_at": "2026-04-10T07:00:00Z",
  "last_seen_at": "2026-04-10T07:00:00Z",
  "created_at": "2026-04-10T07:00:00Z",
  "updated_at": "2026-04-10T07:00:00Z"
}
Open Questions

The following should be decided before implementation lock:

Is canonical_id UUID-only or can it be text?
Is is_publishable stored or derived on read?
Should field_sources be required for all load-bearing fields?
Is city_key always required or only when venue resolution succeeds?
Should date_precision = unknown be allowed in canonical storage?
Should diagnostics_flags be normalized into a separate table later?
Summary

Canonical Event Schema v1 defines the stable internal field structure of CityOS canonical events.

Its key design choices are:

source-scoped identity
deterministic event keys
venue-anchored city assignment
explicit policy fields
separation between identity and change detection
strong provenance and diagnostics support

This schema is the field-level contract that stabilizes the canonical layer.
