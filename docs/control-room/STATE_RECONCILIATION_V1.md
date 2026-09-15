# Meterion Control Room — State Reconciliation v1

Status: implementation candidate on `control-room-state-reconciliation-v1`.

## Purpose

Keep operational project state trustworthy without making the Founder manually re-brief every project and without allowing AI to silently rewrite project identity or strategy.

State Reconciliation refreshes only the mutable operational State object.

It must never change:

- project identity
- goal
- success definition
- portfolio class
- lifecycle status
- canonical constraints

Those remain Owner-controlled.

## Source rule

A state may be refreshed only from evidence that is strong enough for the claim being written.

Preferred evidence order:

1. canonical structured source system (for example project Supabase)
2. canonical repository / accepted project state documentation
3. verified production/deployment result
4. explicit Owner decision
5. chat context only as supporting evidence, not as silent canonical truth

Repository existence alone is never evidence that a project is active.

## Refresh cadence

Default target freshness:

- CORE: 24 hours
- SYSTEM: 24 hours
- EXPERIMENT: 48 hours
- AUTOPILOT: 72 hours
- MAINTENANCE: 168 hours
- VAULT: no routine refresh
- active UNCONFIRMED project: 48 hours for operational state only

These cadences are operational defaults, not portfolio rules. They may be tuned later based on source cost and volatility.

## Derived queue

`control_room_state_reconciliation_v1` derives:

- target refresh hours
- whether refresh is due
- preferred refresh mode
- whether a direct source refresh is safe
- reconciliation priority
- explicit reason

The queue contains no tasks or tickets. It is a read model for agents/workers and System diagnostics.

## Refresh modes

### `direct_source`

A canonical Supabase/GitHub/AI Company OS source connection exists and state authority is not manual.

The agent may inspect that source and prepare an operational state update.

### `source_index`

A source reference exists but there is no first-class direct connector type. The agent may use the source index to locate evidence, but must not infer facts from the reference alone.

### `manual_evidence`

No sufficiently direct source exists or state authority is manual. Do not fabricate a refresh. Preserve the old state until explicit evidence exists.

## Safe autonomous refresh contract

For a safe direct-source refresh:

1. read the current Control Room state and `state_version`
2. query the canonical source
3. separate observed facts from interpretation
4. update only operational fields supported by the evidence
5. set `confidence` according to evidence quality
6. record `source_type`, `source_ref` and verification time
7. use optimistic concurrency with `expected_version`
8. if the state version changed, re-read and reconcile before retrying
9. append a Project Event only if the source change materially changes future orientation or Owner understanding

Routine freshness updates should not flood Today with events.

## Confidence rule

`high` — direct structured evidence supports the important claims.

`medium` — source is canonical but the operational narrative requires limited interpretation.

`low` — evidence is partial; do not use a low-confidence refresh to hide uncertainty or clear a real blocker.

## Founder Attention

Stale state alone is not Founder Attention.

Owner action is appropriate only when reconciliation reaches a real stop gate such as:

- strategic decision
- credential
- legal/commercial choice
- external communication authority
- contract
- customer data
- production mutation beyond policy
- spend
- live money

Unconfirmed portfolio classification may remain visible in Projects without interrupting the Founder unless classification is required for a current decision.

## Current proof run — 2026-09-15

Before formalizing this read model, the reconciliation pattern was exercised against current sources for all six active non-System project records:

- AI Company OS — GitHub canonical main
- Cala Europe — project Supabase
- Maistio — project Supabase
- Rail Atlas / Junamatkailusivusto — project Supabase
- Sprinkler RFQ Platform — project Supabase
- Folio — project Supabase

The refresh produced new versioned operational State rows while preserving all Owner-controlled Project fields.

After the proof run, active state-quality exceptions in Projects v2 dropped from 6 to 0.

## Non-goals

State Reconciliation is not:

- a scheduler by itself
- a task queue
- an automatic strategy editor
- a portfolio classifier
- a replacement for source-system monitoring
- permission to mutate production systems

It is the bounded bridge between source truth and Control Room operational state.