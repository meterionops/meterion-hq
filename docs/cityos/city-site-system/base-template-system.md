---
title: Base Template System
doc_type: spec
project_key: cityos
domain_key: city-site-system
status: active
---

# Base Template System

## Tarkoitus

Määrittää kaikkien kaupunkisivujen yhteinen rakenne.

## Pakollinen layout

- Header (city selector + nav)
- Hero
- Content sections
- Footer

## Pakolliset sivutyypit

- /:city
- /:city/events
- /:city/events/:slug
- /:city/venues/:slug
- /:city/areas/:area
- /:city/categories/:category
- /:city/weekend

## Invariantit

- Routing ei muutu
- canonical_events on päädata source
- Page templates määrittävät rakenteen

## Ei sallittua

- Rakenteen rikkominen per kaupunki
