---
title: Source Fix Playbook v2
doc_type: playbook
project_key: cityos
domain_key: operations
status: active
---

# Source Fix Playbook v2

## Fix Process

This defines the standard step-by-step workflow for fixing a source safely.

---

### 1. Identify when to use this playbook

Use when a source:

- shows 0 events
- ingest fails
- parsing looks incorrect
- coverage is low
- UI shows conflicting data
- fix approach is unclear

---

### 2. Investigation first (no changes yet)

Always start by understanding the real state:

- run source
- inspect mapped output
- check mapped_sample classification
- compare analyzer vs runtime behavior

Goal: identify the **actual problem layer**:
- source issue
- parser issue
- pipeline issue
- UI issue

---

### 3. Identify the correct pattern

Use Pattern Registry to classify the issue:

Examples:

- parser mismatch
- wrong URL
- candidate contamination
- API vs HTML mismatch
- JS-rendered listing
- outbound link hub

Do NOT guess — match to an existing pattern.

---

### 4. Apply the smallest safe fix

Principles:

- prefer source-local config changes
- avoid shared parser changes
- avoid runner changes
- change only one thing at a time

Typical fixes:

- correct URL
- adjust link filtering
- switch data source (API vs HTML)
- refine extraction target

---

### 5. Re-run and validate

After applying fix:

- run source again
- verify mapped events
- check event correctness (not just count)
- confirm no regression

---

### 6. Validate against correction rules

Before closing:

- ensure fix actually solved the problem
- confirm no side effects
- check coverage improvement
- verify pipeline consistency

Follow: `correction-rules.md`

---

### 7. Document the learning

Always:

- add entry to Fix Log
- link to pattern used
- add example if useful
- update playbook if new insight discovered

---

## Outcome

A fix is considered complete only when:

- root cause is understood
- fix is minimal and safe
- result is validated
- learning is documented
