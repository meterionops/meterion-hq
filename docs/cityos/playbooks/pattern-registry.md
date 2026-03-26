---
title: Pattern Registry
doc_type: playbook
project_key: cityos
domain_key: operations
status: active
---

# Pattern Registry

This document defines known failure patterns when ingesting and fixing sources.

Use this to:
- identify root cause quickly
- avoid guesswork
- select the safest fix

---

# Top patterns (quick use)

These are the most common patterns:

1. Analyzer → Runtime disconnect  
2. Probe-only / missing runtime config  
3. API vs HTML mismatch  
4. JS-rendered listing  
5. Calendar / DOM-specific structure  
6. Parser assumption mismatch  
7. UI preview is not ground truth  

---

# Source / Data patterns

## API vs HTML mismatch

**Trigger signals**
- 0 candidates
- SPA/hashbang URL
- Events visible on site but not in list URL

**Root cause**  
HTML page is not the real data source — data comes from API.

**Safe first fix**  
→ switch to API-based ingestion

**Risk**  
low–medium

**Example**  
Annantalo

---

## Probe-only / missing runtime config

**Trigger signals**
- run success
- 0 events
- runtime_list_url = null
- runtime_recipe_family = null

**Root cause**  
Source looks active but has no runtime ingest path.

**Safe first fix**  
→ config-only fix

**Risk**  
low

**Example**  
Bar Loose

---

## Wrong URL / wrong listing page

**Trigger signals**
- homepage has no events
- correct event page exists elsewhere

**Root cause**  
Ingest targets wrong page.

**Safe first fix**  
→ fix URL

**Risk**  
low

**Examples**  
Dance House Helsinki, Musiikkitalo

---

## JS-rendered listing

**Trigger signals**
- events visible in browser
- not visible in raw HTML
- candidates missing

**Root cause**  
Client-side rendering

**Safe first fix**  
→ browser-based adapter (playwright)

**Risk**  
medium

**Example**  
Dance House Helsinki

---

## Candidate contamination

**Trigger signals**
- candidates found
- but clearly wrong links included
- poor coverage

**Root cause**  
link filtering too loose

**Safe first fix**  
→ source-level filtering

**Risk**  
low–medium

**Example**  
Musiikkitalo

---

## Container-first extraction needed

**Trigger signals**
- many irrelevant links
- nav/footer mixed with event links

**Root cause**  
global link extraction instead of scoped container

**Safe first fix**  
→ restrict extraction to container

**Risk**  
low

**Example**  
Helsingin Jäähalli

---

## Single-page multi-event source

**Trigger signals**
- list_url ≈ detail_url
- multiple events in same DOM
- mapped_events = 0

**Root cause**  
no separate detail pages

**Safe first fix**  
→ inline multi-event extraction

**Risk**  
low–medium

**Example**  
Johnscotts

---

## Outbound links are not detail pages

**Trigger signals**
- links go to ticketing platforms
- detail fetch fails

**Root cause**  
external links misinterpreted as detail pages

**Safe first fix**  
→ disable detail-following

**Risk**  
low

**Examples**  
Siltanen, Lippu.fi

---

# Pipeline / Runtime patterns

## Analyzer → Runtime disconnect

**Trigger signals**
- analyzer shows correct mode
- runtime uses different mode

**Root cause**  
analysis not promoted to runtime

**Safe first fix**  
→ fix promote flow

**Risk**  
high

**Example**  
Bar Typo

---

## Activation gap

**Trigger signals**
- code exists
- but runtime path not active

**Root cause**  
config / mapping / deploy mismatch

**Safe first fix**  
→ config fix + verify deploy

**Risk**  
medium

**Example**  
Siltanen

---

## Candidates ≠ actual events

**Trigger signals**
- high candidate count
- low extracted events

**Root cause**  
noise in candidate set

**Safe first fix**  
→ filtering + container scoping

**Risk**  
low–medium

**Example**  
Jäähalli

---

## Self-collapsing candidates

**Trigger signals**
- URLs normalize to same path
- duplicates inflate counts

**Root cause**  
duplicate / non-event links

**Safe first fix**  
→ normalize + filter URLs

**Risk**  
low

**Example**  
Johnscotts

---

## Blocked / bot-protected source

**Trigger signals**
- fetch fails without clear error
- no HTML returned

**Root cause**  
WAF / bot protection

**Safe first fix**  
→ mark as blocked (do not fix)

**Risk**  
low

**Example**  
Lippu.fi

---

# UI / Ops patterns

## UI preview is not ground truth

**Trigger signals**
- UI shows 0 events
- run_source shows data

**Root cause**  
UI uses wrong data source

**Safe first fix**  
→ UI-only fix

**Risk**  
low

---

## Evaluator mismatch

**Trigger signals**
- events correct
- tests show FAIL

**Root cause**  
wrong truth source used

**Safe first fix**  
→ align evaluator with actual data (e.g. inline_events)

**Risk**  
low

**Example**  
Johnscotts

---

# Governance patterns

## Source is not a real ingest source

**Trigger signals**
- page redirects elsewhere
- no real events

**Root cause**  
hub / aggregator page

**Safe first fix**  
→ governance-only (do not ingest)

**Risk**  
low

**Example**  
Kuudes Linja

---

## Proposal vs applied mismatch

**Trigger signals**
- UI shows change
- runtime uses old value

**Root cause**  
change not applied

**Safe first fix**  
→ apply proposal

**Risk**  
low

---

## Source role mismatch

**Trigger signals**
- venue treated as ticketing or vice versa

**Root cause**  
wrong classification

**Safe first fix**  
→ fix source role

**Risk**  
low

**Examples**  
Lippu.fi, Jäähalli
