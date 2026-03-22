Pertti Architecture Map v1
1. Purpose

This document defines Pertti as a layered AI Operating System, not a single pipeline.

Pertti consists of multiple strictly separated layers:

memory system

discovery & exploration

simulation

proposal & recommendation

decision & policy

planning & execution routing

portfolio strategy

governance & audit

cross-layer traceability

The system is contract-driven, where each layer:

consumes structured input

produces structured output

does not leak responsibilities across boundaries

2. Core Principles

Propose → Review → Approve → Execute

Strict layer separation

No silent mutation

Memory ≠ reasoning

Simulation ≠ production truth

All outputs must be traceable

Governance is always above execution

3. High-Level Layer Stack

Top-down view:

Memory System

Discovery & Exploration

Simulation Layer

Venture Formalization

Recommendation Layer

Decision & Policy Layer

Planning & Tasking Layer

Execution Routing & Dispatch

Execution Surface Bridge

Outcome / Feedback / Learning

Governance & Review

Portfolio Strategy Layer

Portfolio Decision Layer

Cross-Layer Traceability (Evidence Graph)

4. Layer-by-Layer Breakdown
Memory System

Purpose
Store, version, and serve knowledge with scope, authority, and temporal awareness.

Key Contracts

memory.ts

memoryRetrieval.ts

memoryPromotion.ts

Produces

memory envelopes

retrieval result sets

promotion decisions

Consumes

observations, outcomes, feedback, reviews

Constraints

scope-first retrieval

no silent promotion

simulation isolation

Discovery & Exploration

Purpose
Generate opportunity candidates from signals and patterns.

Key Contracts

opportunityDiscovery.ts

Produces

opportunity candidates

Consumes

memory retrieval

world model output

Constraints

non-authoritative

evidence-linked

uncertainty preserved

Simulation

Purpose
Explore hypothetical futures and scenario branches.

Key Contracts

simulationScenario.ts

Produces

simulation scenarios

scenario branches

comparisons

Consumes

opportunities

memory

world model

Constraints

always hypothetical

no production truth mutation

Venture Formalization

Purpose
Convert exploration into structured, reviewable proposals.

Key Contracts

ventureProposal.ts

proposalToRecommendation.ts

Produces

venture proposals

recommendation mappings

Consumes

opportunities

scenarios

Constraints

non-executing

rationale + uncertainty required

Recommendation System

Purpose
Produce advisory recommendations for action.

Key Contracts

recommendation.ts

Produces

recommendation candidates

Consumes

proposals

world model

Constraints

advisory only

no execution authority

Policy & Decision

Purpose
Evaluate recommendations against constraints and governance.

Key Contracts

decisionPolicy.ts

Produces

policy decisions

approval requirements

Consumes

recommendations

constraint views

Constraints

no execution

governance-first

Routing

Purpose
Determine eligible execution paths.

Key Contracts

executionRouting.ts

Produces

execution routes

Consumes

policy decisions

Constraints

eligibility only

no execution

Planning

Purpose
Structure goals and steps.

Key Contracts

planner.ts

Produces

plan outlines

steps and dependencies

Consumes

routing

policy decisions

Constraints

no scheduling engine

no execution

Role Tasking

Purpose
Convert plans into role-specific tasks.

Key Contracts

roleTask.ts

Adapter Resolution

Purpose
Map tasks to execution capabilities.

Key Contracts

projectAdapterResolver.ts

Dispatch

Purpose
Prepare tasks for execution handoff.

Key Contracts

taskDispatch.ts

Execution Surface Bridge

Purpose
Map internal artifacts to real execution surfaces.

Key Contracts

executionSurfaceBridge.ts

Constraints

no execution logic

only binding

Outcome & Learning

Purpose
Capture results and learning signals.

Key Contracts

executionOutcome.ts

outcomeLedger.ts

learningFeedback.ts

Produces

execution results

outcome ledger entries

feedback signals

Governance

Purpose
Review, approve, and audit decisions.

Key Contracts

governanceReview.ts

supervisoryRunSession.ts

Constraints

human override always possible

full audit trail required

Portfolio / Strategy Layer
Thesis & Themes

portfolioThesis.ts

Prioritization

prioritization.ts

Allocation

portfolioAllocation.ts

Strategic Review

strategicReview.ts

Initiative Layer

portfolioInitiative.ts

initiativeBridge.ts

Portfolio Gate

portfolioGate.ts

Decision Ledger

portfolioDecisionLedger.ts

Traceability Layer
Evidence Graph

Key Contract

evidenceGraph.ts

Purpose

connect all artifacts

enable audit chains

surface conflicts

5. End-to-End Flow

Memory
→ Discovery
→ Simulation
→ Proposal
→ Recommendation
→ Policy
→ Routing
→ Planning
→ Tasks
→ Dispatch
→ Execution Surface
→ Outcome
→ Feedback
→ Governance
→ Portfolio
→ Decisions

Loops:

learning loop (outcome → memory)

governance loop (review → adjustment)

strategy loop (portfolio → reprioritization)

6. Separation of Concerns

Memory does not reason

Simulation does not execute

Policy does not discover

Portfolio does not execute

Execution does not define strategy

Evidence graph does not decide

7. Traceability Model

every artifact is linkable

chains can be constructed across layers

conflicts are explicit

audit is end-to-end

8. System Boundaries

Pertti → supervisory OS

OpenClaw → execution layer

Codex → builder

CityOS → domain system

9. Current State (v1)

contracts exist across all layers

system is:

propose-only

non-executing

governance-first

10. Next Steps

execution surface implementations

memory storage backend

retrieval engine

dashboard / UI

policy enforcement runtime
