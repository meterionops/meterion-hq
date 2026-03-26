---
title: Guardrails & Checklist
doc_type: playbook
project_key: cityos
domain_key: operations
status: active
---

# Guardrails & Checklist

This document defines the safety rules and debugging checklist for source fixes.

Use this before making changes.

---

# Do NOT do these first

Avoid these before understanding the real root cause:

- runner changes
- shared parser changes
- adapter-family refactoring
- fixing multiple sources at once
- changing URL blindly
- using Playwright before checking API / HTML / SSR
- shared regex changes made “just in case”
- parser changes before confirming the source is a real ingest source

---

# Do these first

Always start with these:

- environment check
- Source Debug Panel
- problem-layer identification
- Broken vs Partial vs Wrong Source classification
- Fix Log
- read-only diagnosis
- eliminate source-local options first
- only then consider shared changes

Additional required checks:

- normalize candidate URLs (strip trailing slash, query, hash)
- filter non-event links before candidate counting:
  - assets (.css, .js, images, fonts)
  - CMS paths (wp-json, wp-content)
  - navigation pages (/menu, /book-a-table)

- do NOT trust raw candidate count as ground truth
- if inline fallback is used:
  - compute coverage from `inline_events`, not from candidate count
- always validate these 3 layers separately:
  1. runtime output
  2. fixture output
  3. evaluator / test result

---

# Debug Checklist v2

Use this checklist in order.

---

## 0. Correct environment / correct data?

Check:

- are you reading the correct live data?
- correct source record?
- proposal vs applied?
- correct tenant / environment?

---

## 1. Correct domain / correct listing page?

Check:

- not just homepage
- actual event listing page
- correct content type
- correct public URL

---

## 2. Is this source actually ingestable?

Check whether this is:

- a real event source
- or a hub / aggregator / outbound-only page

Do not fix parser logic for a source that should not be ingested.

---

## 3. Is there an active runtime path?

Check:

- `runtime_list_url`
- `runtime_recipe_family`
- `runtime_status`
- probe-only vs active runtime

---

## 4. Is Analyzer → Runtime aligned?

Check:

- was analyzer result promoted?
- does `mode_used` match analyzed path?
- is runtime using the intended config?

---

## 5. HTML, API, or JS-rendered?

Identify the real source type:

- JSON-LD?
- SSR HTML?
- API / XHR?
- browser-rendered content?

Do not jump to Playwright before verifying this.

---

## 6. Where does the pipeline fail?

Trace the exact failure layer:

- fetch
- discovery
- parse
- canonical
- visibility
- UI

---

## 7. Broken source or partial coverage?

Classify clearly:

- 0 events = broken / wrong path / wrong source / blocked
- some events but too few = partial coverage

Do not treat partial coverage as full failure.

---

## 8. What is the smallest safe fix?

Apply fixes in this order:

1. config-only
2. governance-only
3. source-local fix
4. data-source switch
5. UI-only fix
6. shared change last

---

# Operator principle

Investigate first.  
Change only when the problem layer is known.  
Prefer the smallest safe fix.  
Shared changes are the last option, not the first.
