# Visibility Policy Contract v1

## Purpose

Visibility Policy Contract v1 defines how CityOS determines whether a canonical event is eligible for downstream consumption.

It answers:

👉 “Should this event be visible in the system output?”

Visibility is a controlled, explainable decision layer between:
- canonical truth
- snapshot builder selection

---

## Core Principle

Visibility is NOT event truth.

It is:
- an operational decision
- policy-driven
- reversible
- explainable

An event may exist in canonical storage but still be hidden from all outputs.

---

## Separation of Concerns

### Canonical Layer
- defines what the event is

### Visibility Policy
- defines whether the event is allowed to appear

### Snapshot Builder
- selects from visible events

---

## Visibility Field

Each canonical event MUST have:

`visibility: enum`

Allowed values:

- `allowed`
- `blocked`
- `out_of_scope`
- `review`

---

## Visibility States

### `allowed`

Event is eligible for snapshot builder.

Meaning:
- passes all policy checks
- safe to include in outputs

---

### `blocked`

Event is explicitly disallowed.

Meaning:
- known bad
- not an event
- spam / noise
- parser error output
- wrong content type

Blocked events must NEVER appear in snapshot output.

---

### `out_of_scope`

Event is valid but not relevant to current system scope.

Examples:
- wrong city
- wrong domain (e.g. jobs, courses if not supported)
- internal/private events
- not matching product focus

Out_of_scope events:
- remain in canonical storage
- are excluded from snapshot output

---

### `review`

Event requires human or automated review.

Examples:
- identity ambiguity
- collision detected
- missing key fields
- suspicious mapping
- borderline classification

Review events:
- must NOT appear in snapshot output
- must be visible in admin/debug tools

---

## Visibility Decision Model

Visibility is determined by evaluating a set of policy rules.

Each rule may:
- pass
- fail
- flag for review

The final visibility state is derived deterministically.

---

## Evaluation Order

Visibility must be computed in this order:

1. Structural validity checks
2. Identity integrity checks
3. Content-type classification
4. Scope validation
5. Quality thresholds
6. Collision detection
7. Manual overrides (if present)

Order matters and must remain stable.

---

## Rule Categories

### 1. Structural Validity

Checks whether event structure is minimally valid.

Fail → `blocked`

Examples:
- missing title AND no fallback identity
- missing or invalid starts_at
- completely empty content
- non-event content (navigation, category page)

---

### 2. Identity Integrity

Checks whether identity is safe and stable.

Fail → `review`

Examples:
- canonical_key collision with incompatible data
- unstable identity inputs
- identity rule fallback used with weak inputs

---

### 3. Content-Type Classification

Checks if the item is actually an event.

Fail → `blocked`

Examples:
- list page mistaken as event
- category page
- search results
- promotional banner
- “load more” artifacts

---

### 4. Scope Validation

Checks if event belongs to tenant domain.

Fail → `out_of_scope`

Examples:
- wrong city
- wrong geographic area
- unsupported event category
- external/global content not relevant

---

### 5. Quality Thresholds

Checks whether event meets minimum quality requirements.

Fail → `review` OR `blocked` depending on severity

Examples:
- missing title but has weak fallback
- missing venue AND location unclear
- incomplete time data
- extremely low confidence mapping

---

### 6. Collision Detection

Checks if identity conflict exists.

Fail → `review`

Examples:
- same canonical_key, different title cluster
- same key, incompatible time
- same key, different venue beyond tolerance

---

### 7. Manual Overrides

Manual system may override visibility.

Override priority:
- manual decision > automatic policy

Examples:
- force allow
- force block
- force review

Overrides must be logged and traceable.

---

## Visibility Decision Matrix

| Condition                         | Result        |
|----------------------------------|--------------|
| structural invalid               | blocked      |
| not an event                     | blocked      |
| identity conflict                | review       |
| ambiguous mapping                | review       |
| wrong scope                      | out_of_scope |
| low quality (recoverable)        | review       |
| low quality (irrecoverable)      | blocked      |
| passes all checks                | allowed      |

---

## Determinism Requirement

Visibility MUST be deterministic.

For same:
- canonical input
- policy rules
- configuration

Result MUST be identical.

No randomness or hidden heuristics allowed.

---

## Explainability Requirement

System MUST be able to explain:

- why visibility = allowed
- why visibility = blocked
- why visibility = out_of_scope
- why visibility = review

Minimum explanation structure:

- rule triggered
- field(s) involved
- decision result

---

## Provenance Integration

Visibility decision must be traceable via:

- canonical provenance
- visibility evaluation metadata

Optional structure:


visibility_reason: {
rule: "scope_mismatch",
detail: "event outside Helsinki",
stage: "scope_validation"
}


---

## Snapshot Builder Contract Dependency

Snapshot Builder MUST:

- include only `visibility = allowed`
- exclude all other states by default

Snapshot Builder MUST NOT reinterpret visibility.

This is a strict boundary.

---

## Manual Override Contract

If manual overrides exist:

### Requirements

- override must be explicit
- override must be stored separately from canonical fields
- override must include:
  - who
  - when
  - reason

### Override Types

- force_allowed
- force_blocked
- force_review

---

## Transition Rules

Visibility may change over time.

Examples:
- review → allowed (after validation)
- allowed → blocked (after detection of issue)
- out_of_scope → allowed (scope change)

### Rule

Transitions must:
- be logged
- be explainable
- not silently erase previous state without trace

---

## Invariants

The following must always hold:

1. Every canonical event has a visibility state
2. Visibility is separate from status
3. Snapshot Builder uses visibility as filter
4. Blocked events never reach snapshot
5. Review events never reach snapshot
6. Out_of_scope events never reach snapshot
7. Visibility is deterministic
8. Visibility is explainable
9. Manual overrides are traceable

---

## Diagnostics Requirements

System must support:

- count of events per visibility state
- reason distribution (why events are blocked/reviewed)
- ability to inspect individual event visibility reasoning

---

## Minimal Visibility Output Shape

Canonical event must include:


visibility: "allowed" | "blocked" | "out_of_scope" | "review"


Optional debug:


visibility_reason: {
rule: string,
stage: string,
detail: string
}


---

## Out of Scope for v1

Visibility Policy v1 does NOT define:

- ranking logic
- recommendation logic
- personalization
- UI display rules
- editorial overrides (beyond explicit manual override flag)

---

## Open Questions

To finalize v1:

1. What exact quality thresholds trigger review vs blocked?
2. What scope rules define “in-city” precisely?
3. Should confidence scoring be part of visibility?
4. How are manual overrides stored (table vs inline)?
5. Should visibility_reason be stored or computed on demand?
6. What is the minimal acceptable event for “allowed”?

---

## Summary

Visibility Policy Contract v1 defines a deterministic and explainable system for deciding whether canonical events are eligible for output.

Key decisions:

- visibility is separate from event truth
- visibility is policy-driven
- only allowed events reach snapshot
- blocked/review/out_of_scope are strictly excluded
- every decision must be explainable

This ensures:
- safe output
- predictable behavior
- debuggable system
- operational control
