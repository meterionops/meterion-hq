# YritystenTiedot — Project Control Pointer

Status: ACTIVE
Current stage: BUILD
Current phase: PHASE 0 — FOUNDATION CLOSEOUT
Phase 0 status: FUNCTIONALLY COMPLETE
Next phase: PHASE 1 — COMPANY EVENT FOUNDATION
Phase 1 status: IMPLEMENTATION-READY / REPOSITORY-BLOCKED

Master Plan: v1.1 LOCKED
Implementation repository: NOT YET CREATED
Production database: Supabase project porkfghjezygajprlwtn
Frontend: FROZEN until Data Readiness Gate

## Source-of-truth model

- Google Drive = strategy, locked roadmap, decisions, parking lot, change requests
- GitHub = implementation and machine-readable contracts
- Supabase = production reality
- ChatGPT = operator across these systems, not a fourth source of truth

## Locked direction

YritystenTiedot is being rebuilt as Finland-first Company Intelligence Infrastructure.

Key constraints:
- Finland-only product for now; Europe-ready architecture
- agent-first, not agent-only
- no paid-data dependency for v1
- full financials are not a v1 launch requirement
- full Person Graph is not a v1 launch requirement
- new frontend will be built from scratch only after the data layer passes the Data Readiness Gate

## Current production checkpoint

As of 2026-09-22:
- companies: 693,706
- source_observations: 693,720
- company_versions: 693,695
- company_events: 0
- company_notices: 0
- PRH company_delta_sync: dormant / disabled
- provenance frozen manifest: 693,706 / 693,706 terminal
- provenance verification: gate_ok = true
- provenance duplicate observations: 0
- provenance duplicate versions: 0
- provenance duplicate business IDs: 0
- provenance orphan observations: 0
- provenance outside-manifest observations: 0
- company_addresses with end_date: 0
- legacy provenance/enrichment crons: disabled

## Phase 0 closeout status

COMPLETED
1. Provenance baseline final QA completed. Built-in verification returns gate_ok = true.
2. Completed provenance worker cron disabled.
3. Stale company_enrichment runner intentionally paused; its cron disabled.
4. Address-history limitation documented.

OPEN
5. Create a dedicated private implementation repository for YritystenTiedot before Phase 1 coding.

## Approved data-correctness change

CR-2026-09-22-01 — Register Event Semantics Correction

Stored raw PRH/YTJ payloads prove registeredEntries[] is source-native status-entry history, not a generic membership interval list.

Therefore Phase 1 atomic register events are:
- REGISTER_STATUS_STARTED
- REGISTER_STATUS_ENDED

Higher-level derived events reserved for later:
- REGISTER_JOINED
- REGISTER_LEFT

Do not map every registeredEntries.registrationDate directly to JOINED or every endDate directly to LEFT.

## Phase 1 architecture readiness

Project Control contains:
- 05 — Phase 1 Event Foundation — Data Architecture Contract v1.1
- 06 — Phase 1 Migration Draft v1.1 — STAGING ONLY
- 07 — Phase 1 Canary & QA Plan
- 08 — Phase 1 Backfill Runbook

The Phase 1 contract is locked around:
- deterministic UNIQUE event_key
- semantic_key independent of end/effective date
- effective_precision
- first-class company_event_evidence
- resumable event backfill state
- source-backed atomic event types only
- no guessed historical ADDRESS_CHANGED
- no guessed NAME_CHANGED
- no direct REGISTER_JOINED / REGISTER_LEFT inference

## Safe atomic event baseline

Reference counts from production audit 2026-09-22:
- NAME_REGISTERED: 1,003,766
- NAME_ENDED: 471,440
- REGISTER_STATUS_STARTED: 3,541,366
- REGISTER_STATUS_ENDED: 1,888,057
- total safe atomic candidates: 6,904,629

Known quality exclusions / ambiguities:
- inverted name intervals: 24
- inverted register end rows: 5,695
- register status identities with multiple valid end dates: 700

These counts are a reference snapshot and must be recomputed before execution.

## Phase 1 canary

Fixed hard-case cohort:
17 business IDs

Expected trusted events:
- NAME_REGISTERED: 26
- NAME_ENDED: 22
- REGISTER_STATUS_STARTED: 73
- REGISTER_STATUS_ENDED: 50
- TOTAL: 171

Canary must also verify:
- inverted end boundaries produce no trusted END event
- multiple valid end-date ambiguity produces no trusted END event
- one valid + inverted evidence uses only the valid end boundary
- duplicate event_key = 0
- every event has evidence
- identical rerun inserts 0 events and 0 duplicate evidence

## Rollout gates

17-company canary
-> 1,000 companies
-> 10,000
-> 100,000
-> full frozen cohort

Each gate requires:
- semantic-count reconciliation
- evidence completeness
- zero duplicate event keys
- zero-delta idempotence rerun
- no production regression

## Phase 1 scope

- Event Schema v1.1
- deterministic deduplication
- event evidence/provenance
- name-history event derivation
- source-native register-status event derivation
- resumable batch backfill
- idempotence tests
- QA

Do not build here:
- frontend
- Person Graph
- full financials
- Europe expansion
- AI chatbot
- Business Finland
- Hilma
- continuous PRH delta sync

## Gate

Phase 1 must not be applied to production from Drive staging documents.

Before implementation:
1. create dedicated private YritystenTiedot implementation repository
2. commit migration/backfill code there
3. re-run production preflight and recompute source counts
4. run the fixed 17-company canary
5. only after PASS advance through rollout gates

Do not place YritystenTiedot implementation code in meterion-hq.
