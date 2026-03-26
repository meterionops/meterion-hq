---
title: Correction Rules
doc_type: playbook
project_key: cityos
domain_key: operations
status: active
---

# Correction Rules v2

This document defines when a source fix is considered complete.

A fix is not complete when the source “works”.  
A fix is complete only when the system has learned from it.

---

# Mandatory after every source fix

After every fix, you MUST do the following:

- Fill Source Fix Log
- Compare the case against Pattern Registry

---

## Pattern handling

- If the case matches an existing pattern:
  - add a new example source to that pattern

- If the case reveals:
  - a new root cause  
  - or a new fix strategy  
  → create a new pattern

- If the case changes:
  - debugging order  
  - guardrails  
  - broken vs partial thinking  
  → update the Playbook

---

## Shared change rule

If the fix required:

- shared parser change
- adapter change
- runner change

You MUST document:

- why source-local fix was not sufficient
- how backward compatibility was ensured
- how the change was validated

---

## Non-source issue rule

If the issue was NOT a source issue but instead:

- governance
- UI
- pipeline

You MUST explicitly record this.

Do not misclassify system issues as source problems.

---

## 3-layer validation rule (MANDATORY)

A fix is NOT complete until all three layers are aligned:

1. Runtime result  
   (`run_source → mapped_events, inserted`)

2. Fixture result  
   (`run_source_fixture → events_extracted, mode_used`)

3. Evaluator / test result  
   (`starts_at_present, starts_at_coverage, tests PASS`)

---

## Closure rule

A fix is NOT considered fully closed until at least one of these is updated:

- Fix Log
- Pattern Registry
- Playbook
- Quick Guide

---

# One-line rule

Every fix must teach the system something —  
and that learning must be recorded immediately.
