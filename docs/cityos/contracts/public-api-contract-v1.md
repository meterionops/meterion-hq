# Public API Contract v1

## Purpose

Public API Contract v1 defines the stable external delivery interface of CityOS.

It exists to ensure that:
- frontend consumers receive a predictable and versioned data shape
- public delivery does not depend on internal database schemas
- snapshot-based outputs are exposed consistently
- freshness and degradation are visible to consumers
- CityOS can evolve internally without breaking downstream clients

This contract is the boundary between:
- CityOS internal runtime
- frontend and external consumers

---

## Core Principle

The Public API does not expose internal truth directly.

It exposes a **stable delivery view** over internal truth.

This means:
- canonical storage is internal
- snapshot builder is internal
- public API is an external contract
- consumers must rely only on the public contract, not on internal implementation details

---

## Architectural Position

Public API sits after snapshot builder.

Flow:

- ingest layer
- canonical layer
- visibility policy
- snapshot builder
- public API
- frontend consumer

Public API MUST NOT:
- read raw ingest artifacts directly for public homepage-like outputs
- expose parser-specific fields
- expose unstable internal diagnostics by default
- require frontend to reconstruct business logic already defined in snapshot or policy layers

---

## Contract Goals

Public API v1 must be:

- Stable  
  Consumers should not break due to internal table changes.

- Explicit  
  Output shape must be versioned and documented.

- Deterministic  
  Same published snapshot should yield same API output.

- Safe  
  Degraded states must be valid and interpretable.

- Freshness-aware  
  Consumers must be able to reason about how current the data is.

- Bounded  
  Payload shapes and limits must be intentional.

---

## Public API Scope

Public API v1 covers:

- homepage-style snapshot delivery
- module/bucket outputs
- public event summary delivery
- freshness metadata
- error/degradation signaling

Public API v1 does NOT define:
- admin APIs
- private operator APIs
- source debugging endpoints
- ingest diagnostics endpoints
- editorial write APIs
- internal mutation workflows

Those belong to separate internal/admin contracts.

---

## Versioning Rule

Every public API response MUST be versioned explicitly.

Minimum required version fields:

- `schema_version`
- `api_version`

Recommended examples:

- `schema_version = "public-api.v1"`
- `api_version = "v1"`

Versioning must be explicit in payload and/or route design.

Internal implementation version alone is not sufficient.

---

## Response Classes

Public API v1 may expose more than one delivery shape, but each must be explicit.

Conceptual response classes:

1. Snapshot response
2. Module-scoped response
3. Public event list response
4. Health/freshness metadata response (optional)
5. Not-found / empty / degraded response

If multiple endpoints exist, each endpoint must have a clearly documented contract.

---

## Core Rule: Snapshot as Primary Delivery Surface

Homepage-like public outputs SHOULD be served from snapshot-derived data.

This is a key architectural rule.

Reason:
- keeps frontend simple
- keeps logic centralized
- preserves deterministic behavior
- avoids duplicating selection/filter logic in frontend

Frontend must not recompute:
- visibility filtering
- bucket logic
- diversity logic
- ranking/sorting logic already performed by snapshot builder

---

## Minimum Snapshot Response Shape

A public snapshot response MUST contain:

- tenant scope
- API/schema version
- generated timestamp
- module outputs
- freshness/status metadata

Recommended conceptual shape:

```json
{
  "api_version": "v1",
  "schema_version": "public-api.v1",
  "tenant_id": "helsinki",
  "generated_at": "2026-03-25T10:00:00Z",
  "status": "ok",
  "freshness": {
    "is_stale": false,
    "max_age_seconds": 900
  },
  "modules": {
    "today": [],
    "weekend": [],
    "next7days": []
  }
}

Exact naming may vary, but the contract must remain stable and documented.

Module Output Contract

Each module key in the public API must resolve to a structurally valid module payload.

Minimum requirement:

module exists with stable key
module payload is present even if empty, unless omission is explicitly documented
items are ordered as delivered by snapshot builder
frontend must not guess ordering rules

Recommended module shape:

{
  "key": "today",
  "title": "Today",
  "items": []
}

Alternative map-based output is acceptable if documented consistently.

Event Summary Contract

Public API MUST expose event summaries, not full internal canonical records.

Recommended public event summary fields:

source_key
canonical_key
title
subtitle (optional)
starts_at
ends_at (optional)
timezone
venue_name (optional)
location_label (optional)
area (optional)
detail_url (optional)
ticket_url (optional)
image_url (optional)
category (optional)
tags (optional)

Optional delivery-safe derived fields:

is_ongoing
day_label
time_label

Public API MUST NOT expose by default:

raw provenance blobs
internal collision flags
internal scoring/debug fields
raw source HTML or parser artifacts
hidden moderation or internal review metadata
Required Field Semantics
source_key

Stable source identity used for traceability.

canonical_key

Stable source-scoped event identity.
This may be public if useful for routing, dedupe, or stable frontend keys.

title

Primary display title.

starts_at

Primary time anchor for display and ordering.

timezone

Timezone associated with the event time interpretation.

detail_url

User-facing event page if available.

These semantics must remain stable across v1.

Freshness Contract

Every public response MUST include freshness-relevant metadata.

Minimum freshness fields:

generated_at
status

Recommended freshness block:

is_stale
max_age_seconds
stale_reason (optional)
last_successful_snapshot_at (optional)
Purpose

This allows frontend and operators to answer:

how old is the data
is this safe to display normally
is the system serving last-known-good data
should the UI show a warning or fallback state
Status Contract

Every response MUST include a response-level status.

Recommended allowed values:

ok
degraded
stale
empty
error
Meaning
ok

Response is healthy and current enough for normal use.

degraded

Response is structurally valid, but some modules or freshness expectations are impaired.

stale

Response is valid, but exceeds freshness target.

empty

Response is valid but contains no results.

error

Response contract exists, but request could not be fulfilled safely.

Important:
A response with status = error should still aim to be structurally interpretable when possible.

Empty State Contract

An empty state is not an error by default.

Examples:

no events today
no weekend events in scope
tenant legitimately has zero eligible events

In such cases:

return valid structure
use empty arrays
set status to empty or ok depending on contract semantics
optionally include explanatory metadata

Frontend must be able to distinguish:

empty because nothing exists
empty because system is degraded
empty because endpoint failed
Degraded State Contract

Public API may serve degraded output when:

snapshot generation partially failed
one or more modules are unavailable
last-known-good snapshot is being served
freshness threshold exceeded
Requirements

Degraded responses must:

remain structurally valid
signal degradation explicitly
avoid mixing undocumented partial shapes
avoid silent omission of important modules unless contract allows it

Recommended metadata:

status = degraded
warnings = [...]
generated_at
last_successful_snapshot_at if applicable
Error Contract

When the system cannot serve a valid public payload safely:

return explicit error status
return stable error body shape
do not leak internal sensitive details
do not expose stack traces
do not expose DB/schema internals

Recommended error shape:

{
  "api_version": "v1",
  "schema_version": "public-api.v1",
  "status": "error",
  "error": {
    "code": "SNAPSHOT_UNAVAILABLE",
    "message": "Public snapshot is currently unavailable."
  }
}

Error codes must be stable and documented if relied on by consumers.

Route Contract

Routes may vary by deployment, but route semantics must be explicit.

Conceptual examples:

/public/snapshot
/public/modules/:key
/public/events
/public/health

If tenant-scoped routing is used, that must also be explicit.

Examples:

/public/:tenant/snapshot
/public/:tenant/events

The route structure itself is implementation-specific.
The contract requirement is that route meaning must be stable and version-aware.

Tenant Scope Contract

Every public response must be tenant-scoped, either:

explicitly in route
explicitly in payload
or both

This avoids ambiguity in multi-city / multi-tenant operation.

Recommended field:

tenant_id

Consumers must never need to infer tenant from unrelated fields.

Public Event List Contract

If a full public event list exists in addition to homepage snapshot modules, its contract must be documented separately but remain aligned with v1 semantics.

Core rules for public event list:

only visible/eligible events
deterministic sorting
explicit filtering semantics
explicit pagination/window semantics if applicable

The public event list MUST NOT silently diverge from core policy definitions.

If it differs from snapshot output, the reason must be architectural and documented.

Pagination Contract

If an endpoint can return unbounded results, pagination must be explicit.

Pagination contract must define:

sort basis
cursor or offset model
page size limits
stability expectations

If no pagination exists:

endpoint result size must still be bounded intentionally
Field Stability Rule

Once a public field is introduced in v1, its meaning must not silently change.

Allowed changes:

additive fields
optional metadata expansion
new endpoints

Disallowed without version bump:

renaming fields
changing field meaning
changing sort semantics silently
changing status meanings silently
replacing arrays with objects or vice versa without versioning
Determinism Requirement

For the same underlying published snapshot, public API output MUST be identical.

This means:

stable module ordering
stable item ordering
stable field naming
stable omission/null behavior
stable empty-state handling

Public API MUST NOT rely on frontend to normalize inconsistent shapes.

Security / Exposure Rule

Public API v1 should expose only delivery-safe data.

Public API MUST NOT expose by default:

internal operator notes
private provenance internals
admin-only flags
collision diagnostics
review state internals
raw ingest artifacts
source credentials or internal endpoints

Exposure must be intentional and documented.

Debug Exposure Rule

If debug metadata is exposed publicly in any context, it must be:

safe
bounded
explicitly enabled
non-sensitive

Production public consumers should not depend on debug metadata.

Last-Known-Good Fallback Contract

If CityOS serves a previous successful snapshot because the latest build failed, this must be representable.

Recommended metadata:

status = degraded or stale
generated_at = timestamp of served snapshot
last_attempted_build_at (optional)
serving_fallback = true
fallback_reason (optional)

This is critical for trust.

Invariants

The following must always hold:

Public API is versioned explicitly.
Public API does not expose internal database schema directly.
Homepage-style delivery is snapshot-derived.
Public responses are tenant-scoped.
Empty and degraded states are structurally valid.
Freshness is visible to consumers.
Public field semantics are stable within v1.
Public API does not leak sensitive internal diagnostics by default.
Same snapshot input produces same public output.
Recommended Minimal Snapshot Endpoint Shape
{
  "api_version": "v1",
  "schema_version": "public-api.v1",
  "tenant_id": "helsinki",
  "status": "ok",
  "generated_at": "2026-03-25T10:00:00Z",
  "freshness": {
    "is_stale": false,
    "max_age_seconds": 900
  },
  "modules": {
    "today": {
      "key": "today",
      "items": []
    },
    "weekend": {
      "key": "weekend",
      "items": []
    },
    "next7days": {
      "key": "next7days",
      "items": []
    }
  }
}

This is a conceptual reference shape, not a mandated final wire format.
The key requirement is stability, versioning, and explicit semantics.

Out of Scope for v1

Public API Contract v1 does not define:

admin mutation endpoints
write APIs
internal source operations
auth/session management
search relevance ranking
user personalization
recommendation systems
analytics tracking contracts

These may be specified separately later.

Open Questions for Finalization

The following should be decided explicitly:

What is the exact public wire format for modules?
Are module titles part of the API or frontend-owned?
Is canonical_key public in all endpoints?
Is full event list a separate contract or part of public-api.v1 core?
What are the exact stale thresholds per tenant/environment?
Which degraded-state warnings are safe to expose publicly?
Which routes are permanently public and stable?
Summary

Public API Contract v1 defines the stable external interface of CityOS.

Its core decisions are:

public delivery is snapshot-derived
the API is versioned and tenant-scoped
freshness and degradation are visible
public fields are stable and delivery-safe
internal schemas and diagnostics remain internal by default

This ensures CityOS can act as:

a reliable frontend backend
a stable delivery platform
an evolvable system with clear boundaries
