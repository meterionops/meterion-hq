# Meterion Control Room — Owner Reconciliation Proposal v1

Status: PROPOSAL / OWNER APPROVAL REQUIRED
Date: 2026-09-12

## Purpose

Turn the broad seed registry into a practical first Control Room portfolio without asking the Owner to classify every repository or idea manually.

This document contains **recommendations**, not canonical assignments, except where an explicit source already marks lifecycle state.

## Capacity rule

Meterion 10/10 portfolio policy:

- CORE: max 3
- EXPERIMENT: max 2
- AUTOPILOT
- MAINTENANCE
- VAULT

Control Room itself is **system infrastructure** and should not consume a 10/10 portfolio slot.

## Explicit lifecycle facts already available

- Cala Europe — explicitly added by Owner to the active weekly portfolio review.
- Rail Atlas — explicitly added by Owner to the active weekly portfolio review.
- Folio — explicitly added by Owner to the active weekly portfolio review.
- Pertti — current canonical `meterion-hq/projects/pertti.md` explicitly says `Status: Active`.
- CityOS — current canonical `meterion-hq/projects/cityos.md` explicitly says `Status: Active development`, last updated 2026-03-25. Treat this as active-but-stale until refreshed, not as proof of recent execution.

All other lifecycle values below remain recommendations unless separately confirmed.

---

## Recommended first Control Room classification

| Project | Keep? | Lifecycle recommendation | Portfolio recommendation | Confidence / note |
|---|---|---:|---|---|
| Meterion Control Room | yes | active | SYSTEM / outside 10/10 | Internal coordination infrastructure, not portfolio capacity |
| AI Company OS | yes | active | CORE | Strategic operating-system product; strong CORE candidate |
| Maistio | yes | active | CORE | Highest-value Local Discovery Graph launch candidate |
| Cala Europe | yes | active | CORE | Owner explicitly added to active review; substantial current build |
| Sprinkler RFQ Platform | yes | active | **CONFLICT** | Behaves like CORE-level commercial work, but 3 CORE slots would already be full |
| Rail Atlas | yes | active | EXPERIMENT | Owner explicitly added to active review; strong but still validation/build stage |
| Folio | yes | active | EXPERIMENT | Owner explicitly added to active review; fills second experiment slot |
| Calendar Platform | yes | active | AUTOPILOT | Live multi-country utility platform with recurring update pattern |
| Yritystiedot | yes | active | AUTOPILOT | Large data asset with recurring import/update behavior |
| Nordic Bottle Index | yes | active | AUTOPILOT | Data-matching asset suited to recurring background operation |
| Namorada | yes | unconfirmed | MAINTENANCE | Existing operational/admin product; no reason to occupy scarce build capacity by default |
| Tinku Latin Flavors | yes | unconfirmed | MAINTENANCE | Client website / reservation presence |
| House of Flores | yes | unconfirmed | MAINTENANCE | Client SEO / Timma website |
| Volaire | yes | paused | VAULT | Keep context, but do not compete with Rail Atlas/Folio while experiment slots are full |
| Pelovio | yes | paused | VAULT | Keep concept separate from Volaire; no active slot recommendation |
| Avoinna | yes | paused | VAULT | Strong concept, but no current slot recommendation |
| Digiapu247 | yes | paused | VAULT | Retain project truth; reactivate only through explicit portfolio decision |
| Pertti | yes | active-but-stale | VAULT / RECONCILE | Canonical file says Active, but it overlaps Control Room / supervisory-system territory and needs strategic reconciliation before consuming capacity |
| CityOS | yes | active-but-stale | VAULT / RECONCILE | Canonical file says Active development but last update is old; needs refresh before priority allocation |
| Sprinkler Water Tank — site delivery | yes | completed candidate | MAINTENANCE → archive | Site work appears near/at closure; keep operational record but not product portfolio capacity |

## Folio identity

Add Folio to Project Registry v1:

- Name: Folio
- Kind: `product`
- Goal: Finnish-company intelligence / competitor monitoring and decision-support product using existing Meterion company data where appropriate.
- Portfolio recommendation: `EXPERIMENT`
- Lifecycle fact: `active` because the Owner explicitly added Folio to the active weekly portfolio review.
- Primary workspace: ChatGPT + product prototype / data sources.
- Constraint: Do not duplicate Yritystiedot as a second company master-data source; reuse company data rather than re-own it.

---

# The only real Owner decisions needed now

## Decision 1 — CORE conflict

Recommended CORE set:

1. AI Company OS
2. Maistio
3. Cala Europe

But Sprinkler RFQ Platform is also behaving like CORE-level work.

Recommended default:

- keep the three above as CORE;
- keep Sprinkler RFQ active but `UNCONFIRMED` until the Owner chooses whether it replaces one CORE project or is intentionally handled outside the max-3 CORE set temporarily.

Control Room should surface this as a **one-in-one-out conflict**, not silently assign a fourth CORE slot.

## Decision 2 — Pertti / Control Room overlap

Pertti's canonical project file describes it as a supervisory OS, portfolio-level operator, memory system and cross-project coordinator.

Meterion Control Room now targets a much lighter job: project state, Founder attention and resume-anywhere coordination.

Recommended default:

- preserve Pertti code/history;
- do not merge Pertti into Control Room automatically;
- classify Pertti as `VAULT / RECONCILE` until we decide whether any of its contracts are reused later;
- Control Room remains deliberately simpler.

## Decision 3 — CityOS freshness

CityOS canonical state explicitly says Active development, but the project snapshot is dated 2026-03-25.

Recommended default:

- preserve lifecycle evidence as `active-but-stale`;
- do not give it active portfolio capacity until current intent is refreshed;
- show `state stale` rather than guessing `paused` or `active now`.

## Decision 4 — completed sprinkler site job

Recommended default:

- mark the site-delivery/compliance project `completed` after final closeout is confirmed;
- retain it in Control Room history;
- do not mix it with Sprinkler RFQ Platform.

---

# Proposed visible portfolio if defaults are accepted

## CORE

- AI Company OS
- Maistio
- Cala Europe

## EXPERIMENT

- Rail Atlas
- Folio

## AUTOPILOT

- Calendar Platform
- Yritystiedot
- Nordic Bottle Index

## MAINTENANCE

- Namorada
- Tinku Latin Flavors
- House of Flores
- Sprinkler Water Tank site record after closeout

## VAULT / RECONCILE

- Volaire
- Pelovio
- Avoinna
- Digiapu247
- Pertti
- CityOS

## UNRESOLVED ACTIVE CONFLICT

- Sprinkler RFQ Platform — needs one-in-one-out decision if treated as CORE

---

# UX implication

The Today page should not show all of the above.

Default Today visibility:

1. Owner-needed blockers / decisions
2. CORE projects with material state changes
3. active EXPERIMENT projects with material state changes
4. AUTOPILOT only on anomaly, milestone or required action
5. MAINTENANCE only when attention is required
6. VAULT never appears unless explicitly searched or a reactivation signal is reviewed

This keeps Control Room quiet by default.

## Recommended next implementation step after Owner confirmation

Freeze the accepted registry and add a very small persistence layer for:

- project identity
- current project state
- material events
- source-system connections

Do not build UI or Supabase schema until the CORE conflict and Pertti overlap are resolved.
