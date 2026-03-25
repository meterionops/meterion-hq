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
