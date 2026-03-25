---
title: Specs Index
doc_type: guide
project_key: cityos
domain_key: specs
status: active
---

# Specs Index

## Purpose

This index lists the technical specifications under the `specs` domain.

Use this section for documents that define stable system behavior, rules, and implementation contracts.

---

## What belongs here

Specs should define:

- system behavior
- processing rules
- selection rules
- invariants at component level
- deterministic contracts for implementation

---

## Current documents

### 1. Snapshot Builder Spec
Path: `docs/cityos/specs/snapshot-builder.md`

Defines:
- snapshot builder responsibilities
- filtering
- deduplication boundary
- module logic
- deterministic output rules

---

## Reading order

Recommended order:

1. `snapshot-builder.md`

---

## What does NOT belong here

Do not place these here:

- operational repair instructions → use `playbooks`
- onboarding / writing guidance → use `onboarding`
- high-level architecture overviews → root docs / architecture domain
