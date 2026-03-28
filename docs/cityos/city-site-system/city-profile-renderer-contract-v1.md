---
title: City Profile Renderer Contract v1
doc_type: spec
project_key: cityos
domain_key: city-site-system
status: active
---

# City Profile Renderer Contract v1

## Purpose

Define how city profile influences rendering.

---

## Core Rule

City profile affects presentation only.  
Never structure.

---

## Allowed Influence

City profile MAY affect:

- tone (editorial / bold / minimal)
- density (spacing, layout compactness)
- emphasis (which sections feel stronger)
- color palette
- typography feel
- CTA style (subtle vs strong)
- imagery style

---

## Forbidden Influence

City profile MUST NOT:

- remove required page types
- change routing
- replace template structure
- modify data contracts
- introduce new sections

---

## Helsinki Reference

```json
{
  "tone": "editorial",
  "density": "airy",
  "emphasis": ["culture", "events"]
}
