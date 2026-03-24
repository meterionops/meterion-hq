---
title: CityOS System Invariants
doc_type: guide
project_key: cityos
domain_key: system
status: active
---

# CityOS System Invariants

The following rules must always hold:

- Ingest pipeline must not be modified lightly
- Canonical model is source-scoped
- Snapshot builder must remain deterministic
- No silent state changes allowed
- Fixes should be source-local whenever possible
