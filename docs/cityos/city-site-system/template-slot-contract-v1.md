---
title: Template Slot Contract v1
doc_type: spec
project_key: cityos
domain_key: city-site-system
status: active
---

# Template Slot Contract v1

## Purpose

Define how template slots map to UI sections.

---

## Slot Model

Each slot must define:

- slot_key
- role
- required (true/false)
- fallback behavior
- component family

---

## Common Slots

### Hero

- role: entry point
- required: true
- fallback: minimal text hero
- component: HeroSection

---

### Featured Events

- role: highlight content
- required: optional
- fallback: hide section
- component: EventGrid (featured variant)

---

### Category Shortcuts

- role: navigation
- required: optional
- fallback: hide
- component: CategoryChips

---

### Weekend Picks

- role: curated selection
- required: optional
- fallback: fallback to upcoming events
- component: EventCards

---

### Venue Highlights

- role: discovery
- required: optional
- fallback: hide
- component: VenueList

---

### Filter Bar

- role: filtering controls
- required: true (event list)
- fallback: disabled filters
- component: FilterBar

---

### Event Grid

- role: main content
- required: true
- fallback: empty state
- component: EventCardGrid

---

### Pagination

- role: navigation
- required: optional
- fallback: infinite scroll or hide
- component: PaginationControls

---

### Event Meta

- role: metadata display
- required: true (event page)
- fallback: partial display
- component: EventMetaBlock

---

### Venue Card

- role: context
- required: optional
- fallback: hide
- component: VenueCard

---

### Day Sections

- role: grouping
- required: optional
- fallback: flatten list
- component: SectionedList

---

## Ordering Rules

- Required slots must always appear
- Optional slots may move or collapse
- Hero always first

---

## Naming Rules

slot_key must be stable and predictable  
(no dynamic naming or per-city variants)
