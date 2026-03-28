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
Interpretation:

calm layout
more whitespace
softer CTA hierarchy

---

# 🧱 4.  
## `docs/cityos/city-site-system/renderer-boundaries-v1.md`

```md
---
title: Renderer Boundaries v1
doc_type: spec
project_key: cityos
domain_key: city-site-system
status: active
---

# Renderer Boundaries v1

## Purpose

Define what is fixed vs flexible in rendering.

---

## Fixed (Non-negotiable)

- page types
- route structure
- template slot definitions
- data sources
- system hierarchy

---

## Flexible

- visual tone
- layout density
- component styling
- section emphasis
- ordering of optional slots

---

## Pertti Boundaries

Pertti MAY:

- adjust tone
- tune layout density
- prioritize content

Pertti MUST NOT:

- create new page types
- break template structure
- alter routing
- invent unsupported UI blocks

---

## Spec Update Requirement

If change affects:

- structure
- routing
- slots

→ must update template spec first
