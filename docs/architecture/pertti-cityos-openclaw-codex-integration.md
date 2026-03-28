Pertti–CityOS–OpenClaw–Codex Integration
1. Overview

This document defines the architecture and responsibility boundaries between four core systems:

CityOS
Pertti
OpenClaw
Codex

These systems together form a scalable operational model for managing, diagnosing, and fixing event sources.

Core Principle
CityOS provides truth, constraints, and execution primitives
Pertti owns diagnosis, prioritization, and next-step decisions
OpenClaw performs bounded operational execution on Pertti’s behalf
Codex performs bounded implementation/build work only when explicitly requested by Pertti

Pertti decides, OpenClaw executes, CityOS constrains, Codex builds.

2. System Roles
CityOS

CityOS is:

The operational system (OS layer)
The source of truth for:
source state
ingestion results
observability
The owner of:
guardrails
governance (proposal / approval)
audit trail
The provider of execution primitives:
run source
replay
probe
verify
apply approved changes

CityOS is NOT:

The supervisory brain
A hidden rule engine that decides what to do next
A system that encodes Pertti’s internal implementation or build logic

CityOS exposes signals and state, not final decisions.

Pertti

Pertti is:

The supervisory brain
The decision-making layer
The owner of:
diagnosis
prioritization
next-step selection

Pertti:

reads CityOS state and evidence
determines the next safe action
selects the executor (OpenClaw, human, or none)
evaluates results and decides what happens next

Pertti may internally use different tools or strategies (including builders), but those are internal implementation details and must not leak into CityOS.

OpenClaw

OpenClaw is:

An execution and investigation agent
Used by Pertti to perform:
probes
replays
HTML vs JS checks
verification runs
bounded operational actions

OpenClaw:

interacts with CityOS execution primitives
collects evidence
returns structured observations

OpenClaw does NOT:

make strategic decisions
own prioritization
override guardrails

It is an execution layer, not a decision layer.

Codex

Codex is:

A bounded builder / implementation agent

Used by Pertti for:

generating patches
implementing scoped changes
producing diffs or code updates

Codex is NOT:

part of CityOS runtime decision-making
an operational execution agent
visible or required inside CityOS

Codex is intentionally decoupled from CityOS.

3. Decision Ownership

Decision ownership is strictly defined:

CityOS → provides signals and constraints
Pertti → owns decisions
OpenClaw → returns evidence and execution results
Codex → returns implementation artifacts
Examples
Case: Source returns zero events
CityOS: shows signals (events=0, fetch_ok=true)
Pertti: decides “investigate rendering”
OpenClaw: executes HTML vs JS check
Pertti: evaluates result
Case: Source-local config fix
Pertti decides change is needed
Pertti defines constraints
Implementation executed via allowed path
CityOS enforces approval and logs change
Case: Insufficient evidence
Pertti returns: no_action or investigate further
No changes are executed
4. Execution Ownership

Execution follows a strict chain:

Pertti decides what to do
Pertti instructs OpenClaw (for operational work)
OpenClaw executes against CityOS primitives
CityOS enforces guardrails and logs all actions
Pertti evaluates results
Important Rules
CityOS does not command OpenClaw autonomously
OpenClaw does not decide what to do next
Codex is invoked only by Pertti, not by CityOS
5. Why CityOS Knows About OpenClaw But Not Codex

This is a key architectural decision.

CityOS knows about OpenClaw because:
OpenClaw performs operational execution visible to CityOS
OpenClaw uses CityOS primitives (run, replay, probe, verify)
OpenClaw affects observable system behavior
Execution lifecycle must be tracked and audited
CityOS does NOT know about Codex because:
Codex is part of Pertti’s internal build/implementation layer
It is not part of operational execution
It may change over time (Codex, other builders, internal tools)
Encoding it into CityOS would create tight coupling

CityOS is aware of supervisory decisions and operational execution through OpenClaw, but remains intentionally decoupled from Pertti’s internal build implementation choices.

6. Control Flow
Standard Loop
CityOS provides:
source state
evidence
constraints
execution primitives
Pertti:
reads the case
determines diagnosis
selects the next safe step
Pertti routes execution:
to OpenClaw (for investigation/verification)
or no execution (if insufficient evidence)
OpenClaw:
executes task
collects evidence
returns structured result
Pertti:
evaluates outcome
decides next step
If implementation is required:
Pertti may use Codex
result is applied via CityOS governance flow
CityOS:
enforces constraints
logs all actions
exposes updated state
Example: HTML vs JS Investigation
CityOS: events=0, fetch_ok=true
Pertti: “rendering not confirmed → investigate”
OpenClaw:
checks raw HTML
checks rendered DOM
Result:
HTML: no events
DOM: events present
Pertti:
confirms JS-rendered source
selects next step (e.g., adapter change)
7. Safety Boundaries

The system relies on strict boundaries:

CityOS must not silently make supervisory decisions
Pertti must not bypass CityOS guardrails
OpenClaw must not become a strategic decision-maker
Codex must not become an operational agent inside CityOS
All risky changes must go through governance (proposal / approval)

These boundaries ensure:

traceability
safety
scalability
8. Future-Proofing

This architecture allows independent evolution:

Pertti can change internal logic or tools
OpenClaw capabilities can expand
Codex or any builder can be replaced
CityOS remains stable as:
truth surface
execution OS
governance layer

Key principle:

Internal Pertti implementation must be swappable without requiring CityOS redesign.

9. Practical Design Rules
CityOS exposes signals, not decisions
Pertti returns one next step per case
OpenClaw returns evidence, not strategy
Codex returns bounded implementation artifacts
CityOS models only what it must know operationally
Dangerous changes always require governance
Evidence must precede changes
“No action” is a valid decision
10. Summary

This architecture separates concerns cleanly:

CityOS = operational system, truth, constraints
Pertti = decision-making brain
OpenClaw = execution and investigation agent
Codex = bounded builder

The system is designed to:

scale across many sources
avoid fragile rule-based automation
remain flexible as internal tooling evolves
maintain strict safety and auditability

Pertti decides, OpenClaw executes, CityOS constrains, Codex builds.

(Optional) Visual Summary
CityOS -> truth, constraints, primitives

Pertti -> diagnosis, prioritization, next-step decision

OpenClaw -> investigation, execution, verification

Codex -> bounded implementation/build

Flow:
Pertti -> OpenClaw -> CityOS
Pertti -> Codex
CityOS -> governance, audit, guardrails
🔑 Main Architecture Decisions Captured
Decision-making is centralized in Pertti
CityOS is strictly an execution OS + truth layer
OpenClaw is the only CityOS-visible execution agent
Codex is intentionally invisible to CityOS
Signals ≠ decisions
One case → one next step
All risky changes go through governance
Architecture is designed for future tool replacement without refactoring CityOS
