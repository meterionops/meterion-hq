# Canonical Identity Rules v1

## Purpose

Canonical Identity Rules v1 defines how `canonical_key` is generated for events in CityOS.

This is the single source of truth for:
- event identity stability
- duplicate prevention within a source
- safe re-ingest updates
- collision detection

These rules must be deterministic, explicit, and non-ambiguous.

---

## Core Principle

Canonical identity must answer:

👉 “Is this the same event as before?”

The answer must be:
- deterministic
- explainable
- stable across re-ingest runs

---

## Identity Scope

Canonical identity is scoped by:

- `tenant_id`
- `source_key`
- `canonical_key`

Constraint:

`canonical_key` MUST be unique within `(tenant_id, source_key)`

There is NO cross-source identity in v1.

---

## Identity Strategy

Identity is built using a **priority ladder**.

Always use the strongest available identity source.

### Priority Order

1. Source-native event ID
2. Stable event detail URL
3. Fallback composite identity

---

## Rule 1: Source-native ID (Highest Priority)

### When to use

Use when the source provides:
- explicit event ID
- stable identifier embedded in data or URL

Examples:
- `/event/12345`
- `data-event-id="abc123"`

### Canonical Key Format


srcid:<normalized_id>


### Normalization Rules

- lowercase
- trim whitespace
- remove obvious prefixes if inconsistent
- must be stable across runs

### Constraints

- must not change across runs for same event
- must not include timestamps or volatile tokens

---

## Rule 2: Detail URL Identity

### When to use

Use when:
- no reliable source-native ID
- event has a stable detail page URL

### Canonical Key Format


url:<normalized_url>


---

## URL Normalization Rules (STRICT)

Apply in this exact order:

### 1. Lowercase host


HTTPS://Site.fi/Event
 → https://site.fi/Event


### 2. Remove protocol differences

Treat:
- http
- https

as equivalent → normalize to https

### 3. Remove trailing slash


/event/123/ → /event/123


### 4. Strip query parameters

REMOVE ALL by default:


?utm_source=...
?ref=...
?date=...


Exception:
ONLY allow explicitly whitelisted params (v1 default = none)

### 5. Remove fragments


#section → removed


### 6. Collapse duplicate slashes


/events//123 → /events/123


---

## URL Identity Constraints

URL must be:
- a detail page (NOT listing page)
- stable across time
- not paginated or filtered view

### Reject URL identity if:

- contains `/page/`
- contains `/search`
- contains `/category`
- contains `/tag`
- contains dynamic filters

---

## Rule 3: Fallback Composite Identity

Used when:
- no source ID
- no reliable URL

### Canonical Key Format


cmp:<hash(title + starts_at + venue)>


---

## Composite Inputs

### Required components:

- normalized title
- normalized start time
- normalized venue OR location label

---

## Normalization Rules

### Title normalization

- lowercase
- trim
- collapse whitespace
- remove obvious boilerplate:
  - “Buy tickets”
  - “Official event”
  - “Click here”
- do NOT translate
- do NOT truncate meaningfully

---

### Time normalization

- must be ISO timestamp
- must include timezone or be paired with it

If only date is known:
- normalize to `YYYY-MM-DDT00:00:00` with explicit policy

---

### Venue normalization

- lowercase
- trim
- remove duplicate whitespace
- fallback to location_label if venue missing

---

## Hash Function

Use stable hash:

Recommended:
- sha1 or sha256 (truncated)

Example:


cmp:sha1("concert|2026-04-01T19:00:00+02:00|tavastia")


---

## Composite Identity Constraints

Composite identity is weakest and must be used carefully.

### Risks:
- duplicate events with same title/time/venue
- recurring events
- multi-day events

### Mitigation:
- collisions must be detectable
- must not silently overwrite

---

## Collision Handling

A collision occurs when:

- same `(tenant_id, source_key, canonical_key)`
- but materially different event content

---

## Collision Detection Signals

Trigger collision if:

- title distance exceeds threshold
- time difference exceeds tolerance
- venue mismatch is significant

---

## Collision Policy

DO NOT silently merge.

Instead:

- flag as `collision`
- set `visibility = review`
- store both versions if needed (implementation-dependent)
- log in diagnostics

---

## Forbidden Identity Inputs

These fields MUST NEVER be used in identity:

- description
- ticket_url
- image_url
- scrape timestamp
- ranking or scoring fields
- tags
- categories
- dynamic labels (e.g. “Tonight”)
- query parameters

---

## Identity Stability Rule

For the same real-world event:

👉 canonical_key MUST remain identical across runs

If it changes:
- it is considered a new event
- previous continuity is broken

---

## Identity Versioning

If identity logic changes in the future:

- introduce `identity_version`
- do NOT silently change canonical_key behavior
- migrations must be explicit

---

## Edge Cases

### Recurring Events

v1 behavior:

Each occurrence = separate canonical event

Identity must include:
- start timestamp

---

### Multi-day Events

Options:

- use start date as identity anchor
- OR treat each day as separate event (implementation decision)

Must be consistent.

---

### Missing Time

If:
- no time
- only date

Then:

- normalize to start-of-day
- include timezone
- accept reduced precision

---

### Missing Venue

Fallback to:

- location_label
- OR “unknown”

BUT:
- must still produce deterministic identity

---

## Identity Decision Flow


IF source_native_id exists
→ use Rule 1

ELSE IF stable_detail_url exists
→ use Rule 2

ELSE
→ use Rule 3 (composite)


---

## Invariants

The following MUST always hold:

1. Identity is deterministic
2. Identity does not depend on volatile fields
3. Identity is stable across runs
4. Identity is scoped to source
5. Composite identity is last resort only
6. Collisions are never silently merged
7. URL normalization is consistent system-wide

---

## Diagnostics Requirements

System must be able to answer:

- which rule was used (srcid / url / cmp)
- raw inputs used for identity
- normalized inputs
- hash inputs (for composite)
- why fallback was triggered
- whether collision was detected

This is required for debugging and trust.

---

## Summary

Canonical Identity Rules v1 defines a strict, deterministic identity system based on:

- source-native IDs when available
- normalized URLs as second-best identity
- composite fallback only when necessary

Key decisions:

- identity is source-scoped
- identity must be stable and explainable
- collisions must be explicit
- volatile fields are forbidden in identity

This ensures the system remains:
- stable
- debuggable
- safe to evolve
