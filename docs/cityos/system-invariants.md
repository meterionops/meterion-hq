---
title: Docs Authoring Guide
doc_type: guide
project_key: cityos
domain_key: onboarding
status: active
tags:
  - docs
  - standards
  - writing
summary: How to write, structure and maintain CityOS documentation.
priority: 90
is_featured: true
---

# Docs Authoring Guide
---
title: CityOS System Invariants
doc_type: guide
project_key: cityos
domain_key: system
status: active
tags:
  - invariants
  - safety
summary: Rules that must never be broken in CityOS.
priority: 100
is_featured: true
---

# CityOS System Invariants

The following rules must always hold:

- Ingest pipeline must not be modified lightly
- Canonical model is source-scoped
- Snapshot builder must remain deterministic
- No silent state changes allowed
- Fixes should be source-local whenever possible
