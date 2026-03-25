---
title: CityOS Contract Registry v1
doc_type: spec
project_key: cityos
domain_key: Event Identity
status: active
---

# CityOS Event Identity & Merge Engine Spec v1
Contract-level specification for event identity resolution, canonical event creation, and cross-source merge during snapshot projection.

1 · Purpose
CityOS aggregates events from multiple independent sources. The same real-world event may appear with different titles, slightly different times, variant venue names, or different URLs across sources.

The Event Identity & Merge Engine is responsible for two distinct operations:

Canonical Identity — constructing a source-scoped canonical event from raw ingest data (single-source, per-row).
Snapshot Merge — grouping canonical events from different sources that represent the same real-world event and selecting a winner for the public snapshot (cross-source, projection-time).
These are architecturally separate operations. This spec defines the contracts for both.

2 · Architecture Position
Event identity and merge operate within the CityOS 6-stage execution pipeline:

1. Sources — external event providers

2. Raw Ingest — extraction → RawEventContract

3. Canonical Identity — field assembly → CanonicalEventContract

4. Merge Group — cross-source grouping → EventMergeContract

5. Snapshot Projection — winner emission → SnapshotContract

6. Site Visibility — public presentation

Terminology alignment: "Merge" is reserved exclusively for cross-source snapshot-layer unification (stage 4). Canonical-layer operations (stage 3) use "Canonical Identity," "Field Assembly," and "Source Deduplication." This prevents confusion between single-source record construction and cross-source event unification.

3 · Event Identity Model
Event identity in CityOS is source-scoped. Each canonical event row represents one source's observation of an event — not a unified "master event."

Canonical Key

Pattern: {tenant_slug}:{source_key}:{dateKey}:{slugName}. This key is the upsert target and defines source-scoped uniqueness.

Source Scoping

One canonical row = one source observation. Two sources reporting the same concert produce two canonical rows with different canonical keys.

Recurring Events

Events sharing a URL must append #YYYYMMDD to source_event_id to prevent source-level uniqueness collisions.

Cross-Source Unification

Unification happens only during snapshot projection (stage 4–5). Canonical rows are never modified by the merge process.

4 · RawEventContract
A raw event is an unprocessed observation extracted from a single source. It contains the original data before normalization, identity resolution, or quality scoring. Raw events are ephemeral inputs to the canonical identity pipeline.

Fields
raw_event_id
string
— Unique raw event identifier
source_id
string
— Event source that produced this raw event
source_event_id
string
— Source-native identifier; recurring events append #YYYYMMDD
tenant_id
string
— Tenant scope
application_id
string
— Application scope
title
string
— Original event title from source
description
string?
— Original description
start_time
string?
— Start time as extracted (may need parsing)
end_time
string?
— End time as extracted
url
string?
— Source URL for the event
image_url
string?
— Event image URL
venue_text
string?
— Raw venue name/text from source
address_text
string?
— Raw address from source
ticket_url
string?
— Ticket purchase URL
category_text
string?
— Category/tag text from source
price_text
string?
— Price information from source
ingest_origin
enum
— jsonld | api | html — extraction method
date_source_used
string
— Which date field was used (Date Confidence Model)
date_confidence
number
— 0.00–1.00 per Date Confidence Model v1
date_confidence_reason
string
— Explanation of date confidence score
raw_json
json?
— Complete original payload for audit
extracted_at
timestamp
— When extraction occurred
ingest_origin values
jsonld
api
html
5 · EventIdentityCandidateContract
An identity candidate is a normalized intermediate representation of a raw event, prepared for canonical identity resolution. It carries normalized fields and identity signals used to match against existing canonical events or create new ones. This is the Field Assembly stage output.

Fields
candidate_id
string
— Unique candidate identifier
raw_event_id
string
— Source raw event
source_id
string
— Event source
tenant_id
string
application_id
string
normalized_title
string
— Cleaned, lowercased title
title_slug
string
— URL-safe slug from title
parsed_start_time
timestamp?
— Parsed and validated start time
parsed_end_time
timestamp?
— Parsed and validated end time
date_key
string
— YYYYMMDD date key for canonical key construction
venue_id
string?
— Resolved venue from Venue Graph, if matched
venue_text_normalized
string?
— Normalized venue text for matching
canonical_key_proposed
string
— {tenant_slug}:{source_key}:{dateKey}:{slugName}
identity_signals
json
— Computed identity signals (see §8)
data_quality
enum
— verified | inferred | html_fallback
created_at
timestamp
data_quality values
verified
inferred
html_fallback
6 · CanonicalEventContract
The canonical event is the publishable truth layer. One row represents one source-specific observation — it is strictly source-scoped. Cross-source unification (Merge) occurs only during snapshot projection and does not modify canonical rows. The canonical_key pattern is {tenant_slug}:{source_key}:{dateKey}:{slugName}.

Fields
canonical_event_id
string
— Unique canonical event identifier (id column)
canonical_key
string
— {tenant_slug}:{source_key}:{dateKey}:{slugName} — upsert target
tenant_id
string
— Tenant scope
application_id
string
— Application scope
title
string
— Canonical event title
description
string?
— Canonical description
starts_at
timestamp
— Canonical start time
ends_at
timestamp?
— Canonical end time
timezone
string
— Event timezone (default: Europe/Helsinki)
venue_id
string?
— Venue Graph reference
venue_name
string?
— Venue display name
city
string?
— City name (inherited from venue when possible)
address
string?
— Event address
lat
number?
— Latitude
lon
number?
— Longitude
url
string?
— Canonical event URL
ticket_url
string?
— Ticket purchase URL
category
string?
— Event category
tags
json?
— Event tags array
source_type
string?
— Source type identifier
source_event_id
string?
— Source-native event ID
source_refs
json?
— Source reference metadata
field_sources
json
— Tracks which source provided each field
status
enum
— active | cancelled | postponed | draft
visibility
enum
— public | hidden | review
visibility_reason_code
string?
— Why visibility was set
change_hash
string?
— Content hash for change detection
time_bucket
string
— Time bucket for snapshot partitioning
multi_day
boolean
— Whether event spans multiple days
created_at
timestamp
updated_at
timestamp
status values
active
cancelled
postponed
draft
7 · EventMergeContract
Records a cross-source merge decision during snapshot projection. Merge is exclusively a snapshot-layer operation — it groups canonical events from different sources that represent the same real-world event, selects a winner, and produces a unified snapshot entry. Canonical rows are never modified by merge.

Fields
merge_id
string
— Unique merge group identifier
merge_hash
string
— Deterministic hash: tenant + truncated title + date
tenant_id
string
application_id
string
member_canonical_keys
string[]
— Canonical keys in this merge group
member_count
number
— Number of members
winner_canonical_key
string
— Selected winner for snapshot
winner_reason
string
— Deterministic selection reason
merge_confidence
enum
— HIGH_CONFIDENCE | LIKELY | AMBIGUOUS
title_similarity
number?
— Bigram similarity score
venue_consistent
boolean?
— Whether venue matched across members
source_pair_label
string?
— e.g. venue↔ticketing for diagnostics
snapshot_id
string
— Snapshot this merge was computed for
created_at
timestamp
merge_confidence values
HIGH_CONFIDENCE
LIKELY
AMBIGUOUS
FALSE_POSITIVE
8 · Identity Signals
Identity signals are computed during Field Assembly (stage 3) and used for both canonical key construction and downstream merge grouping. The signal contract defines what is computed — not how.

title_normalized
Lowercased, trimmed, diacritics-removed title

title_slug
URL-safe slug derived from normalized title

date_key
YYYYMMDD from parsed start time

venue_id_resolved
Venue Graph match result (venue_id or null)

venue_text_normalized
Lowercased, trimmed venue text for fallback matching

domain_match
Whether source domain matches a known venue domain

ticket_url_domain
Extracted domain from ticket URL for source typing

date_confidence
Date Confidence Model v1 score (0.00–1.00)

ingest_origin
Extraction method: jsonld, api, or html

Signal computation algorithms (fuzzy matching, bigram similarity, normalization rules) are implementation details and are not part of this contract.

9 · Merge Rules
Merge operates during snapshot projection (stage 4). The merge contract defines the rules interface — deterministic and auditable.

Merge Grouping
Events are grouped by merge_hash = tenant + truncated title + date.

Only HIGH_CONFIDENCE groups are merged. LIKELY and AMBIGUOUS are flagged for review.

Grouping considers title similarity (bigram) and venue consistency.

Winner Selection (deterministic ranking)
Source Priority Tier — Venue Source > Ticketing > City > Aggregator
Venue Completeness — presence and length of venue text
Ticket URL Presence — events with ticket links ranked higher
Description Richness — length of content as tiebreaker
canonical_key — lexicographical comparison as final tiebreak
Every merge decision records winner_reason for operator auditability.

10 · Event Lifecycle
An event progresses through the following lifecycle:

Raw Ingest — Source adapter extracts raw event data. A RawEventContract entry is produced with extraction metadata and Date Confidence Model fields.
Field Assembly — Raw fields are normalized, parsed, and assembled into an EventIdentityCandidateContract. Venue matching against the Venue Graph occurs here.
Canonical Identity — The candidate is upserted as a CanonicalEventContract row using the computed canonical_key. Database upsert targets application_id, tenant_id, and canonical_key.
Merge Group — During snapshot projection, canonical events are grouped by merge_hash. HIGH_CONFIDENCE groups produce a single winner.
Snapshot Projection — Winners (and ungrouped events) are emitted into the SnapshotContract. Losers are suppressed but remain queryable.
Site Visibility — Visibility policy applies final filtering (hidden events, visibility_reason_code). The public site renders the result.
11 · Event Updates
Events are updated through re-ingest, not through direct mutation:

When a source is re-ingested, new raw events are extracted.
Field Assembly produces updated identity candidates.
Canonical upsert (on canonical_key) updates the existing row if change_hash differs.
If change_hash matches, no update is written (idempotent).
The field_sources JSON tracks which source provided each field, enabling provenance audit.
Updated canonical events participate in the next snapshot projection cycle.
12 · Duplicate Prevention
CityOS prevents duplicates at two distinct layers, following the Terminology Alignment contract:

Source Deduplication (canonical layer)

Same-source conflicts are resolved by canonical_key uniqueness. Recurring events sharing a URL append #YYYYMMDD to source_event_id. Upsert on canonical_key ensures one row per source observation per date.

Cross-Source Merge (snapshot layer)

Different sources reporting the same real-world event are grouped by merge_hash during snapshot projection. Only HIGH_CONFIDENCE groups are merged. Canonical rows are never modified.

13 · Event Trust Levels
Trust levels indicate how reliable the event data is. Trust is assigned during Field Assembly based on extraction quality and source reliability.

VERIFIED
Structured data from authoritative source (JSON-LD, official API). Date confidence ≥ 0.95.
STRONG
Parsed event content with high date confidence (0.75–0.94). Clear title, time, and venue.
INFERRED
HTML-extracted with partial confidence (0.55–0.74). Some fields may be inferred.
WEAK
Ambiguous extraction. Date confidence 0.25–0.54. May require manual review.
UNTRUSTED
Known fallback data (e.g., WP post date used as event date). Date confidence ≤ 0.24. Hard-capped.
Trust level assignment logic is implementation-specific. This contract defines the vocabulary and semantic meaning of each level.

14 · Event Quality Score
Event quality score is a composite metric indicating how complete and reliable an event record is. It is computed after Field Assembly and stored on the canonical event for downstream use.

Quality dimensions (contract-level)

Field completeness — presence of title, start_time, venue, description, URL
Date confidence — Date Confidence Model v1 score
Venue resolution — whether venue_id was resolved from Venue Graph
Data quality tier — verified > inferred > html_fallback
Description richness — non-trivial description content
The exact scoring formula is an implementation detail. The contract guarantees that quality_score is a normalized 0–100 value available on canonical events for merge winner selection and observability.

15 · Event Graph
The Event Graph is the aggregate view of canonical events, their merge relationships, and venue anchoring:

Raw Events → Field Assembly → Canonical Events

↕ venue_id

Venue Graph

↓

Canonical Events → merge_hash → Merge Groups

↓

Merge Winners → Snapshot Events

The Event Graph is a read projection — it does not have its own storage contract. It is computed from canonical events, merge groups, and venue references during snapshot building and observability queries.

16 · Pertti Integration
Pertti (the CityOS AI agent) may participate in event identity operations:

Pertti may suggest venue matches for unresolved events, recorded via VenueSourceLinkContract.
Pertti may flag ambiguous merge groups for operator review.
Pertti may propose visibility changes (hidden → review) with governance audit trail.
Pertti does not directly modify canonical events — all changes flow through the standard re-ingest or governance action pipeline.
Pertti's merge confidence assessments are diagnostic only — they do not override the deterministic ranking model.
17 · Snapshot Integration
The snapshot layer consumes canonical events and merge decisions to produce the public delivery package:

Snapshot projection reads all active canonical events for a tenant/application.
Merge groups are computed using merge_hash. Only HIGH_CONFIDENCE groups produce a single winner.
The winner's canonical data populates the snapshot event. Losers are suppressed.
Ungrouped canonical events appear directly in the snapshot.
Visibility policy is applied post-merge: hidden events, admin overrides, and visibility_reason_code filtering.
The snapshot includes ingest_origin and data_quality per Build Contract V1.5.
Merge decisions are auditable via the Merge Group Inspector in the control plane.
18 · Design Rules
•
Raw events are not truth — they are source observations that require normalization and validation.
•
Canonical events are the publishable truth layer — one row per source observation, source-scoped.
•
Merge is exclusively a snapshot-layer operation — canonical rows are never modified by merge.
•
Merge decisions must be explainable — every winner selection records a deterministic reason.
•
Venue match is the strongest identity signal — venue_id from the Venue Graph anchors events to cities.
•
Date confidence is a first-class field — every event carries Date Confidence Model v1 metadata.
•
Terminology alignment is enforced — 'Merge' means cross-source unification only.
•
The frontend is a rendering layer — it does not perform deduplication, grouping, or ranking.
•
Event identity is stable within a source — canonical_key is deterministic and idempotent.
•
Cross-source unification is projection-time only — it produces snapshot output, not canonical mutations.
19 · Document Placement
This document is placed under Engine → Event Identity Spec in the CityOS control plane.

It complements:

Core Contracts Pack v1 — foundational entity contracts (CanonicalEventContract, SnapshotContract)
Venue Graph Spec v1 — venue identity, aliases, and source linkage
Discovery Contracts Pack v1 — candidate lifecycle and signals
Platform Contract — engine/project/site boundaries
Engine Spec v1.4.14 — Date Confidence Model, execution pipeline
