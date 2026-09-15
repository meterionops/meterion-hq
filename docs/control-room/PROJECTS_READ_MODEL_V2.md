# Meterion Control Room — Projects Read Model v2

Status: implementation candidate on `control-room-projects-v2`.

## Purpose

Projects is the portfolio truth surface, not a task manager.

It answers:

- which project identities are registered?
- which projects are explicitly confirmed as active portfolio work?
- which identities still lack Owner-confirmed classification or lifecycle?
- which active project states are fresh, aging, stale or missing?
- where does each project primarily live?

The canonical write model remains unchanged:

`Project -> State -> Event -> Connection`

Projects v2 is derived read state only.

## Owner authority

Project identity, goal, portfolio class, lifecycle and canonical constraints remain Owner-controlled.

Repository presence, recent chat activity or an AI-generated next step must never silently activate or classify a project.

The current Owner-confirmed CORE set is valid at five projects:

- AI Company OS
- Maistio
- Cala Europe
- Sprinkler RFQ Platform
- Rail Atlas / Junamatkailusivusto

Meterion Control Room is SYSTEM infrastructure and does not consume a portfolio slot.

## Primary sections

`control_room_projects_surface_v2.projects_section` derives one mutually exclusive display section per registered project.

### `active_portfolio`

Lifecycle is explicitly `active` and portfolio class is confirmed.

This is the normal portfolio surface and should be grouped by portfolio class: CORE, EXPERIMENT, AUTOPILOT, MAINTENANCE, VAULT.

### `active_unclassified`

Lifecycle is confirmed active, but portfolio class is still `UNCONFIRMED`.

This state is intentionally supported. It means the project is known to be active without inventing its portfolio classification.

### `unconfirmed_identity`

The identity is registered, but lifecycle is `unconfirmed`.

These projects belong in a quiet “Needs confirmation” area, not the active portfolio.

### `inactive`

Lifecycle is explicitly paused, completed or archived.

These remain recoverable historical portfolio records but stay out of the active portfolio.

### `system`

Internal Control Room infrastructure. It is visible for operational context but separate from the portfolio.

## State quality

Projects v2 reuses Today v2 freshness:

- `fresh` — verified within 24 hours
- `aging` — verified within 72 hours
- `stale` — older than 72 hours
- `missing` — no state exists

An active project with `stale` or `missing` state gets `state_quality_exception = true`.

This is a system-quality signal, not automatically a Founder task. It should normally be visible in Projects/System, not Today.

## Verification flags

Each row exposes `verification_flags[]` so the UI can explain uncertainty without guessing:

- `classification_unconfirmed`
- `lifecycle_unconfirmed`
- `state_missing`
- `state_stale`

A project may carry more than one flag.

## Connections

Projects v2 exposes only a compact source index:

- connection count
- primary connection type
- primary connection label
- primary external reference
- primary URL when available

The underlying source system remains canonical for its own detailed data. Control Room does not copy repository, Supabase, Lovable or production contents into the project row.

## Historical exclusions

Pertti and CityOS remain historical-only under the Owner decision already stored in Project Registry v1 and Control Room constraints.

They are not reintroduced as active registered projects by Projects v2. Historical repositories are evidence, not proof of current project validity.

## Overview

`control_room_projects_overview_v2` provides compact counts for the Projects header and System diagnostics:

- total registered identities
- confirmed active portfolio count
- active-but-unclassified count
- unconfirmed identity count
- inactive count
- system count
- active state-quality exceptions
- missing state count
- Owner-attention count
- source connection count

These counts describe portfolio truth quality; they are not productivity KPIs.

## RPCs

Projects v2 adds:

- `control_room_get_projects_surface_v2(projects_section, portfolio_class, state_freshness)`
- `control_room_get_projects_overview_v2()`

Existing v1/v2 project and Today RPCs remain unchanged for compatibility.

## UI rule

The Projects screen should be visually quiet:

1. confirmed active portfolio first
2. active but unclassified next
3. unconfirmed identities in a collapsed/secondary area
4. inactive records only on demand
5. SYSTEM separated from portfolio

No Kanban columns, story points, sprint status, task trees or fabricated AI priority scores.