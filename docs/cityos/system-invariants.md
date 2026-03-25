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
## Documentation Invariant

docs/cityos is the single source of truth for all CityOS contracts and specifications.

CityOS Admin UI renders and uses these documents but does not define independent contract truth.

If a conflict exists:
→ docs/cityos is correct
→ UI must be updated or deprecated
