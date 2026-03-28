---
title: Renderer Fallback Rules v1
doc_type: spec
project_key: cityos
domain_key: city-site-system
status: active
---

# Renderer Fallback Rules v1

## Purpose

Define safe behavior when data is missing.

---

## Missing Image

- show placeholder
- keep layout intact

---

## Missing Description

- truncate or hide text block
- keep title visible

---

## Missing CTA

- hide CTA
- do not replace with fake content

---

## Missing Optional Slot

- hide entire section
- do not render empty container

---

## Empty Event Lists

- show empty state
- provide fallback messaging

---

## Low Content Density

- reduce spacing
- merge sections if needed

---

## No Content Scenario

- show minimal layout
- keep navigation intact
- avoid blank screen

---

## Principle

Never invent data  
Never break layout  
Always degrade gracefully
