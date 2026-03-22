# Pertti — Architecture Overview

## Purpose

This document describes the **technical architecture of Pertti** at a structural level.

It complements:
- `north-star.md` → intent and direction
- this document → system structure and boundaries

---

## High-Level Architecture

Pertti is a **layered supervisory system** built around strict separation of:

- reasoning
- policy
- planning
- coordination
- execution (externalized)

Pertti itself does **not execute actions**.

---

## Core Flow

The supervisory pipeline follows a deterministic flow:

```text
Validation
→ World Model
→ Recommendation
→ Decision Policy
→ Execution Routing
→ Outcome Ledger
→ Learning / Feedback
→ Planner
→ Project Adapter Resolver
→ Role Task Model
→ Task Dispatch Boundary
→ Supervisory Run Session

Each step:

consumes structured input

produces structured output

does not mutate external systems

Layered Architecture
Layer 1 — Kernel

Responsibility: system identity, governance, and context validation

Components:

identity

governance rules

project registry

execution context

context validation

Properties:

deterministic

foundational

no domain logic

Layer 2 — Supervisory Reasoning

Responsibility: structured evaluation of system state and possible actions

Components:

World Model

Recommendation layer

Decision Policy Engine

Key behaviors:

evaluates state

generates candidate actions

evaluates consequences

applies governance constraints

Constraints:

no execution

no side effects

Layer 3 — Operational Coordination

Responsibility: transform decisions into coordinated operational intent

Components:

Execution Routing

Project Adapter Resolver

Role Task Model

Task Dispatch Boundary

Key behaviors:

maps decisions → routes

maps routes → adapters

assigns tasks to roles

determines dispatch readiness

Constraints:

no execution

no scheduling

no queueing

Layer 4 — Memory and Audit

Responsibility: track system behavior and outcomes

Components:

Outcome Ledger

Learning / Feedback

Supervisory Run Session

Key behaviors:

record decisions and outcomes

link artifacts across layers

represent feedback and impact

package runs/sessions

Constraints:

no storage implementation

no implicit learning

Layer 5 — Planning and Simulation

Responsibility: structure future actions

Components:

Planner

(future) Simulation layers

Key behaviors:

convert decisions → plans

define goals and steps

represent dependencies and blockers

enable scenario evaluation

Constraints:

no execution

no orchestration

Layer 6 — Opportunity Intelligence (Future)

Responsibility: identify and evaluate opportunities

Planned components:

gap detection

pattern recognition

source intelligence

opportunity discovery

venture evaluation

Status:

not yet implemented

enabled by existing layers

Layer 7 — Execution Ecosystem

Responsibility: perform actual work

External to Pertti:

OpenClaw

Codex

human operators

APIs and services

Pertti interacts through:

adapter resolution

dispatch boundaries

Key Design Principles
1. Separation of Concerns

Each layer has a strict responsibility:

reasoning ≠ policy

policy ≠ planning

planning ≠ execution

2. Propose-Only Core

Pertti:

proposes

evaluates

plans

routes

It does not:

execute

mutate systems directly

3. Deterministic Contracts

All layers are defined as:

type-safe contracts

pure transformations

no hidden side effects

4. Governance First

All outputs are constrained by:

capability rules

project boundaries

approval requirements

5. Explicit Linking

All cross-layer relationships are:

ID-based

explicit

audit-friendly

No hidden coupling.

6. Auditability

System behavior can always be traced through:

decisions

routes

tasks

dispatch readiness

outcomes

feedback

Data Flow Model

Each layer operates on:

structured input

deterministic transformation

structured output

Example:

WorldModelInput → WorldModelOutput
→ RecommendationEnvelope
→ PolicyDecisionEnvelope
→ ExecutionRoutingEnvelope
→ PlanOutline
→ RoleTaskEnvelope
→ TaskDispatchEnvelope
→ SupervisoryRunEnvelope
Project Isolation

Pertti enforces strict separation between projects:

no shared mutable state

no cross-project leakage

explicit project context required

Adapter Abstraction

All execution systems are abstracted as:

adapter types

adapter references

capability mappings

No execution details exist inside Pertti.

Current Implementation State

Implemented:

full contract layer across all supervisory components

Not implemented:

execution logic

storage layer

simulation engine (beyond contracts)

opportunity intelligence layer

Future Extensions

Planned additions:

opportunity discovery contracts

simulation engine implementation

execution outcome boundary

canonical ID system

governance review records

adapter registry implementation

runtime orchestration layer (outside core contracts)

Summary

Pertti is a layered supervisory system that:

separates reasoning, planning, and execution

enforces governance at every stage

maintains full auditability

scales across multiple projects and domains

It acts as:

a deterministic supervisory core coordinating external execution systems.
