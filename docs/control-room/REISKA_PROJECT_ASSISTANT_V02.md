# Reiska Project Assistant v0.2

Status: deployed internal pilot
Date: 2026-09-19

## Purpose

Reiska is the owner-facing project assistant on top of Meterion Control Room.

It does not replace Control Room project state, Google Drive, GitHub, Supabase or project source systems.
It reduces founder coordination overhead by turning current project state into a small number of useful recommendations.

## User experience

Primary views:
- Tänään: at most three relevant recommendations / owner decisions.
- Projektit: all active projects and their current control state.
- Keskustele: source-derived quick answers about focus, owner attention, preparation and material changes.
- Asetukset: quiet diagnostics.

Pilot projects:
- rail-atlas
- maistio

All active projects remain visible. Pilot only affects recommendation weighting.

## Mobile contract

- Bottom navigation on <= 760 px.
- Safe-area aware bottom padding.
- Minimum 44-48 px action targets.
- No required horizontal scrolling for the primary flow.
- Work and research packets can be copied; Web Share is offered when supported.
- Technical/source details remain collapsed behind project detail.

## Recommendation contract

Recommendations come from current Control Room state:
- next_best_action
- current_build / current_focus
- next_gate / gate_status
- founder_attention_required
- state freshness

Reiska must not invent work simply to appear active.
"Ei nyt" is a device-local 24 h snooze in v0.2; it does not alter project truth.

## Execution handoff

"Valmistele työ" creates a bounded text work packet.
Copying or sharing it does not execute work.
ChatGPT or another authorized executor performs the work.
Verified material results return through the existing Control Room closed-loop write path.

## Research boundary

Research is limited to active projects.
Before research, the task must state which current project decision or work phase the information may change.
Research may produce:
- a small experiment recommendation,
- no-action conclusion,
- or a request for missing evidence.

Research must not:
- create a new project,
- change portfolio priority,
- reactivate paused work,
- or expand authority.

In v0.2 the UI prepares a research packet. It does not start autonomous web research.

## Safety / authority

No new email, payment, external commitment, production-write or credential authority is introduced.
Control Room remains the coordination source.
Detailed truth remains in source systems.
