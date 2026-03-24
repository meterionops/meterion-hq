---
title: Fix Source Playbook
doc_type: playbook
project_key: cityos
domain_key: operations
status: active
tags:
  - sources
  - fix
  - playbook
summary: Step-by-step process for diagnosing and fixing broken sources.
priority: 100
is_featured: true
---

# Fix Source Playbook

## Goal
Fix a broken source safely without breaking the ingest pipeline.

## Steps

1. Run source and inspect output
2. Check mapped_sample classification
3. Identify pattern:
   - parser mismatch
   - wrong URL
   - candidate contamination
4. Apply smallest possible fix
5. Re-run source
6. Verify mapped events

## Rules

- Never modify runner
- Prefer source-local fixes
- Do not introduce new complexity
