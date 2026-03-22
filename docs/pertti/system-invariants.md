# Pertti — System Invariants

## Purpose

This document defines the **non-negotiable invariants of the Pertti system**.

These rules:
- must always hold
- must not be bypassed
- must not be modified by autonomous system behavior

They exist to ensure:
- safety
- predictability
- auditability
- long-term system integrity

---

## 1. Execution Separation

**Pertti must never directly execute actions.**

Pertti:
- proposes
- evaluates
- plans
- routes

Pertti does NOT:
- execute commands
- call external systems directly
- mutate external state

All execution must happen through:
- external adapters
- controlled dispatch boundaries

---

## 2. Governance Enforcement

**All system behavior must be constrained by governance rules.**

This includes:
- capability restrictions
- project boundaries
- approval requirements

No action may:
- bypass governance
- escalate privileges implicitly
- ignore capability constraints

---

## 3. Proposal-First Architecture

**All actions must originate as proposals.**

Flow must always be:

```text
observe → analyze → propose → (review/approve) → route → dispatch

No direct:

execution

mutation

side effects

are allowed without passing through proposal and governance layers.

4. Human Override Supremacy

Human decisions are always final.

The system must:

respect human approvals

respect human rejections

allow human intervention at any stage

No automated process may override:

explicit human decisions

governance-enforced approval gates

5. Deterministic Contract Layers

All core layers must remain deterministic and contract-driven.

This means:

type-only contracts define system boundaries

transformations are explicit

no hidden behavior

No layer may:

introduce implicit side effects

mutate global state

rely on hidden execution logic

6. No Hidden State

All system state must be explicit and traceable.

Allowed:

structured memory layers

explicit inputs and outputs

ID-based linking between layers

Not allowed:

hidden caches

implicit memory

undocumented state mutation

7. Explicit Linking

All cross-layer relationships must be explicit.

This includes:

recommendation → policy

policy → routing

routing → tasks

tasks → dispatch

dispatch → run/session

outcomes → feedback

All links must:

use identifiers

be traceable

be auditable

8. Auditability

All system behavior must be reconstructable.

It must always be possible to determine:

what was proposed

what was evaluated

what was approved

what was routed

what was dispatched

what happened

what was learned

No step may:

lose traceability

hide decisions

obscure outcomes

9. Project Isolation

Projects must remain strictly isolated.

This means:

no cross-project state leakage

no implicit sharing of context

no unintended cross-project actions

All project interactions must be:

explicit

governed

traceable

10. Adapter Abstraction

All execution systems must remain abstracted.

Pertti must not:

depend on concrete execution implementations

embed API calls

include execution payloads

All execution must go through:

adapter references

capability mappings

dispatch boundaries

11. No Autonomous Self-Modification

Pertti must not modify its own governance or core behavior autonomously.

This includes:

governance rules

capability definitions

system invariants

core architecture

All changes must go through:

proposal

review

explicit approval

12. Layer Responsibility Integrity

Each layer must only perform its defined responsibility.

Examples:

World Model → reasoning only

Decision Policy → evaluation only

Planner → planning only

Routing → mapping only

Dispatch → boundary only

No layer may:

absorb responsibilities from other layers

shortcut the pipeline

bypass required steps

13. No Implicit Execution

No structure may contain executable intent.

Disallowed:

embedded commands

execution payloads

hidden instructions

auto-run flags

Allowed:

descriptions

summaries

references

identifiers

14. Capability-Gated Behavior

All actions must be capability-gated.

Every task, route, or dispatch must:

declare required capabilities

be validated against capability constraints

No action may:

execute without capability validation

assume capabilities implicitly

15. Run/Session Integrity

All activity must be traceable within supervisory runs.

Each run/session must:

have explicit scope

link to artifacts (plan, dispatch, ledger, feedback)

maintain status and summary

No activity should exist:

outside a run context

without traceable linkage

16. System Transparency

System behavior must remain explainable.

At any point, it must be possible to answer:

why this was proposed

why this was approved or rejected

why this was routed

why this was blocked

No black-box decisions in core supervisory layers.

Summary

These invariants ensure that Pertti remains:

safe

predictable

governable

auditable

scalable

They must be preserved regardless of:

feature additions

scaling

integration complexity

future automation layers

Breaking any invariant risks:

loss of control

loss of auditability

unsafe behavior

system degradation

Rule

If a change conflicts with these invariants, the change is invalid unless the invariants are explicitly updated through a governed process.
