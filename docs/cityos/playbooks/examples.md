---
title: Examples
doc_type: playbook
project_key: cityos
domain_key: operations
status: active
---

# Examples

This document contains real source-fix cases.

Each example links:
- symptom → root cause → fix → outcome

Use this as reference when diagnosing new sources.

---

# Seeded examples

## Annantalo

- Symptom: no events  
- Cause: HTML/SPA was wrong ingest mechanism  
- Fix: LinkedEvents API  
- Outcome: fixed using `linkedevents_v1`

---

## Bar Loose

- Symptom: no data / 0 events  
- Cause: probe-only + missing runtime config  
  - intermediate issue: wrong `jsonld_only` strategy  
- Fix: WP API runtime path  
- Outcome: fixed using `wp_api`

---

## Dance House Helsinki

- Symptom: no events  
- Cause:
  - wrong domain  
  - JS-rendered listing  
  - parser day-header assumption mismatch  
- Fix:
  - `playwright_listing_v1`
  - inline date/title fallback  
- Outcome: fixed

---

## Korjaamo

- Symptom: events found but assigned to wrong year / filtered out  
- Cause: year inference / legacy date mismatch  
- Fix:
  - date normalization  
  - venue fallback  
  - observability improvements  
- Outcome: fixed

---

## Kuudes Linja

- Symptom: appears active but ingest produces no event data  
- Cause: outbound hub, not a real event source  
- Fix: NOT_PRODUCTION_FIT governance classification  
- Outcome: not forced into ingest

---

## Bar Typo

- Symptom: analyzer shows correct recipe but runner uses wrong mode  
- Cause:
  - analyzer → promote → runtime disconnect  
  - runner precedence bug  
- Fix:
  - promote flow fix  
  - precedence correction  
- Outcome: fixed

---

## Apollo Live Club

- Symptom:
  - incomplete detail extraction  
  - UI shows incorrect state  
  - auto-fill not working  
- Cause:
  - DOM mismatch  
  - UI preview mismatch  
  - React derived state timing issue  
- Fix:
  - parser fallbacks  
  - UI preview fix  
  - useEffect-based autofill  
- Outcome: fixed

---

## Siltanen

- Symptom:
  - 0 events → upsert collision → FIXED 16/16  
- Cause:
  - WordPress simcal grid  
  - outbound links (FB/Tiketti) are not detail pages  
  - generic heuristics incorrect  
  - identity fallback reused same URL  
- Fix:
  - `simcal_grid` recipe_family extractor  
  - `source_event_id` passthrough  
  - deploy verification  
- Outcome: fixed — 16 inserted/mapped

---

## G Livelab

- Symptom: no_event_candidates, incorrect link detection  
- Cause:
  - DOM not inspected first  
  - regex/heuristics used prematurely  
- Fix:
  - inspect HTML  
  - identify `/events/<slug>` structure  
  - rebuild link extraction  
- Outcome: fixed — DOM-first extraction

---

## Helsingin Jäähalli

- Symptom:
  - candidates_found: 111  
  - events_extracted: 4  
- Cause:
  - global `a[href]` scan produced noise  
  - nav/feed/pagination links included  
  - no container scoping  
- Fix:
  - strict URL filtering  
  - container-first extraction  
  - exclude feed/pagination  
- Outcome: fixed — correct container extraction

---

## Lippu.fi

- Symptom:
  - fetch fails  
  - analyzer shows error  
- Cause:
  - bot protection (WAF) blocks edge fetch  
  - not a broken source  
- Fix:
  - classify as BLOCKED  
- Outcome: not ingested directly

---

## Postbar

- Symptom:
  - root fetch OK (200)  
  - mapped_events = 0  
  - detail-fetch → `ra.co` blocked_403  
- Cause:
  - simcal list already contained event data  
  - ticket links incorrectly treated as detail pages  
- Fix:
  - simcal list auto-detection  
  - `extractSimcalListEvents`  
  - add `ra.co` to `EXTERNAL_DETAIL_BLOCK_HOSTS`  
- Outcome: fixed — 17 events inserted

---

## Johnscotts

- Symptom:
  - 0–1 events despite rich content  
  - tests FAIL even when data is correct  
- Cause:
  - single-page multi-event source  
  - candidate pollution (assets + CMS links collapse to same URL)  
  - evaluator read wrong data path (`extracted_event` vs `inline_events`)  
- Fix:
  - inline multi-event fallback  
  - candidate filtering before inline gating  
  - fixture alignment  
  - evaluator fix → use `inline_events`  
- Outcome:
  - 28 events extracted  
  - runtime, fixture, and tests aligned

---

# How to use in practice

When a new broken source appears:

1. Open Source Debug Panel  
2. Verify environment / table / applied state  
3. Identify problem layer  
4. Classify:
   - broken source  
   - partial coverage  
   - wrong source  
   - config mismatch  
   - UI mismatch  
5. Fill Source Fix Log  
6. Perform read-only diagnosis  
7. Choose smallest safe fix  
8. Validate with a single run  
9. Update governance  
10. Update:
    - Pattern Registry  
    - Playbook  
    - Quick Guide
