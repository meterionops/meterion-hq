---
title: Template UI Renderer Contract v1
doc_type: spec
project_key: cityos
domain_key: city-site-system
status: active
---

# Template → UI Renderer Contract v1

## Purpose

Define how page templates map into actual frontend rendering.

Templates are the structural source of truth.  
Renderers are responsible for presentation.

---

## Core Principle

Templates define WHAT must exist.  
Renderers define HOW it is shown.

---

## Template → Renderer Mapping

| template_key     | route pattern                  | renderer responsibility            |
|-----------------|-------------------------------|----------------------------------|
| city-guide      | /:city                        | Compose homepage sections        |
| event-list      | /:city/events                 | List and filter events           |
| event-page      | /:city/events/:slug           | Render single event detail       |
| venue-page      | /:city/venues/:slug           | Render venue + upcoming events   |
| area-page       | /:city/areas/:area            | Localized event aggregation      |
| category-guide  | /:city/categories/:category   | Category-based listing           |
| weekend-guide   | /:city/weekend                | Time-filtered editorial view     |

---

## Renderer Responsibilities

Renderers must:

- follow template-defined structure
- render all required slots
- respect data contracts (canonical_events, venues)
- apply design system consistently
- apply city profile overrides safely

---

## Renderer Must NOT

- invent new sections outside template
- remove required sections
- change routing behavior
- change data source logic
- override system-level invariants

---

## Renderer Freedom

Renderers MAY:

- reorder optional slots
- adjust visual hierarchy
- adapt spacing and density
- apply city-specific tone

---

## Contract Boundary

If a renderer requires:

- new slot type
- new page type
- new data dependency

→ Template spec must be updated first.
