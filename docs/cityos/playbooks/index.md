---
title: Playbooks Index
doc_type: guide
project_key: cityos
domain_key: operations
status: active
---

# Playbooks Index

## Purpose

This index lists operational playbooks used for investigation, diagnosis, and safe repair workflows.

Playbooks are step-by-step guides for operators — not theory, but execution.

This repository is the source of truth for playbook logic used in CityOS.

---

## What belongs here

Playbooks should define:

- investigation flow
- diagnosis steps
- safe repair process
- operator checklists
- validation steps after changes

Focus on **practical actions and decisions**, not explanations.

---

## Current documents

- [Source Fix Playbook v2](./source-fix-playbook-v2.md)
- [Pattern Registry](./pattern-registry.md)
- [Guardrails & Checklist](./guardrails-checklist.md)
- [Correction Rules](./correction-rules.md)
- [Examples](./examples.md)

---

## Recommended reading order

1. Start with: `source-fix-playbook-v2.md`
2. Use: `pattern-registry.md` to identify the issue
3. Follow: `guardrails-checklist.md` before applying fixes
4. Validate using: `correction-rules.md`
5. Reference: `examples.md` for real cases

---

## What does NOT belong here

Do not place these here:

- architectural descriptions
- component specs
- authoring conventions
- broad product strategy
