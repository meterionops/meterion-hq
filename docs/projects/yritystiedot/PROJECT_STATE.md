# YritystenTiedot — Project Control Pointer

Status: ACTIVE
Current stage: BUILD
Current phase: PHASE 0 — FOUNDATION CLOSEOUT
Phase 0 status: FUNCTIONALLY COMPLETE
Next phase: PHASE 1 — COMPANY EVENT FOUNDATION
Phase 1 status: IMPLEMENTATION-READY / REPOSITORY-BLOCKED

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

## Phase 0 closeout status

COMPLETED
1. Provenance baseline final QA completed. Built-in verification returns gate_ok = true. The old run-level processed counter is treated as non-authoritative telemetry because the frozen manifest is complete and all integrity gates pass.
2. Completed provenance worker cron disabled.
3. Stale company_enrichment runner intentionally paused; its cron disabled.
4. Address-history limitation documented: company_addresses currently has no end_date history, so ADDRESS_CHANGED cannot be historical-backfilled from that field.

OPEN
5. Create a dedicated private implementation repository for YritystenTiedot before major Phase 1 coding.

## Phase 1 architecture readiness

Project Control now contains:
- 05 — Phase 1 Event Foundation — Data Architecture Contract
- 06 — Phase 1 Migration Draft — STAGING ONLY

The live-data-derived Phase 1 contract is locked around:
- deterministic UNIQUE event_key
- semantic_key
- effective_precision
- first-class company_event_evidence
- resumable event backfill state
- source-backed atomic event types only
- no guessed historical ADDRESS_CHANGED
- no guessed NAME_CHANGED

Potential atomic history event candidates:
- NAME_REGISTERED: 1,003,766
- NAME_ENDED: 471,464
- REGISTER_JOINED: 3,544,019
- REGISTER_LEFT: 1,895,163
- maximum total: 6,914,412

Primary-name history audit:
- transition rows: 120,662
- exact prior-end/new-start same day: 41,895
- gap: 73,756
- overlap: 3,678
- prior row still open: 1,333

Therefore the initial history backfill stores NAME_REGISTERED / NAME_ENDED lifecycle facts and does not infer NAME_CHANGED from adjacency.

## Phase 1 scope

- Event Schema v1
- deterministic deduplication
- event evidence/provenance
- name-history event derivation
- register-history event derivation
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
3. re-run production preflight
4. only then apply the additive Event Foundation migration

Do not place YritystenTiedot implementation code in meterion-hq.
