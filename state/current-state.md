## 🔹 Pertti — Supervisory Contracts v1 + Identity Normalization (Checkpoint)

### Status
Pertti supervisory OS contract foundation is now structurally complete (v1) with canonical identity layer integrated.

### Completed

#### 1. Supervisory Contract Stack (v1)

Full end-to-end contract pipeline defined:

- World Model (state → actions → consequences)
- Recommendation Boundary
- Decision Policy Engine
- Execution Routing
- Outcome Ledger
- Learning / Feedback
- Planner
- Project Adapter Resolver
- Role Task Model
- Task Dispatch Boundary
- Supervisory Run Session
- Governance Review / Approval
- Execution Outcome Boundary

System properties:
- fully type-driven
- deterministic
- non-executing (supervisory only)
- audit-first
- proposal → decision → routing → tasking → dispatch → outcome → feedback loop complete

---

#### 2. Canonical Identity Layer (ID-A)

Created:

- src/types/canonicalIds.ts

Defines canonical aliases:
- RecommendationId
- PolicyDecisionId
- RouteId
- TaskId
- DispatchRecordId
- LedgerEntryId
- RunId
- ReviewId
- ExecutionResultId
- PlanId
- PlanStepId
- AdapterId
- ProjectId

Constraint:
- string-based aliases only (no branding yet)

---

#### 3. Identity Normalization Pass — Core (ID-B1)

Normalized:
- recommendation.ts
- decisionPolicy.ts
- executionRouting.ts
- planner.ts (partial, safe scope)
- roleTask.ts
- projectAdapterResolver.ts

Key result:
- core coordination layer now uses canonical IDs
- no architectural changes introduced

---

#### 4. Identity Normalization Pass — Audit / Outcome (ID-B2)

Normalized:
- outcomeLedger.ts
- learningFeedback.ts
- taskDispatch.ts
- supervisoryRunSession.ts
- governanceReview.ts
- executionOutcome.ts

Key result:
- audit, review, and outcome layers now use canonical IDs
- linkage across system is now consistent

---

### Current System Capability

Pertti now supports:

- structured reasoning (World Model)
- controlled decision-making (Policy layer)
- execution abstraction (Routing + Dispatch)
- full audit trail (Ledger + Review)
- feedback loop (Outcome → Feedback)
- planning and coordination (Planner + RoleTask)
- cross-project supervision (Run Session)

System is ready to:

- coordinate multiple projects
- track decisions and outcomes
- support large-scale portfolio supervision
- operate as a deterministic supervisory AI OS

---

### Known Limitations (Intentional)

Not yet implemented:

- envelope-level identity standard
- execution path identity (executionId normalization)
- goal-level identity (GoalId)
- identity branding / opaque types
- runtime engines (all layers are contract-only)
- discovery / opportunity layer

---

### Next Options

1. Envelope Identity Standardization Pack
2. Opportunity Discovery Contracts
3. First runtime adapter layer (very controlled)

Recommended next step:
→ Decide between infra refinement vs capability expansion
## 2026-03-22 — Memory Contracts Foundation Complete

### Summary

Pertti architecture has been extended with a full Memory Contracts layer, completing the foundational separation between:

- supervisory operating system (reasoning, decisions, routing, planning)
- memory operating system (storage, retrieval, promotion, and knowledge representation)

This establishes Pertti as a dual-layer system:
- Supervisory OS → thinks, evaluates, proposes
- Memory OS → stores, structures, and serves knowledge

---

### Memory Contracts Pack (v1)

New file:

- src/types/memory.ts

This introduces a complete type-level boundary for memory operations.

#### Core capabilities defined

Memory system now supports:

- layered memory model
  - working
  - episodic
  - semantic
  - procedural
  - simulation

- explicit scope model
  - global
  - domain
  - project
  - tenant
  - run
  - session
  - simulation

- authority model
  - speculative → system_of_record

- lifecycle model
  - candidate → reviewed → trusted → archived/superseded/rejected

- temporal model
  - validFrom / validTo
  - supersession support
  - temporalStatus

- provenance model
  - sourceType
  - producerType
  - derivationMethod
  - evidenceRefs

- confidence model (separate from authority)

---

### Memory Boundaries Introduced

#### Write Boundary

MemoryWriteRequest / MemoryWriteResult

- explicit target layer
- explicit target scope
- full memory envelope required
- no implicit memory mutation

#### Retrieval Boundary

MemoryRetrievalQuery / MemoryRetrievalResult

- scope-first retrieval (allowedScopes required)
- optional filtering by:
  - layer
  - class
  - authority
  - lifecycle
  - temporal constraints
- explicit handling of hypothetical memory
- conflict visibility supported

#### Promotion Boundary

MemoryPromotionRequest / MemoryPromotionResult

- explicit lifecycle transitions
- optional reviewer involvement
- no silent promotion

---

### Architectural Impact

Pertti now has a clearly defined Memory OS:

- memory is no longer implicit or tied to chat/state
- memory is governed, scoped, and auditable
- simulation memory is explicitly isolated
- promotion replaces silent learning

This aligns memory with the same design principles as the supervisory kernel:

- deterministic
- explicit
- auditable
- proposal-driven (via promotion)

---

### Relationship to Supervisory System

Memory integrates with supervisory artifacts but remains separate.

Memory may reference:

- recommendations
- policy decisions
- execution routes
- tasks and dispatches
- supervisory runs
- governance reviews
- execution outcomes
- outcome ledger entries
- learning / feedback records

Rule:
Memory is not reasoning and does not replace the supervisory pipeline.

---

### Status

- Memory Contracts Pack: COMPLETE
- Supervisory Contract Stack: COMPLETE (v1)
- Canonical ID foundation: PARTIALLY APPLIED

---

### Next Steps

1. GitHub checkpoint (this update)
2. Continue with:
   - Opportunity Discovery Contracts (recommended next)
   OR
   - Memory Retrieval refinement (optional)

Memory storage, retrieval engines, and infrastructure are intentionally NOT implemented yet.

## 2026-03-22 — Opportunity Discovery + Simulation Contracts Complete

### Summary

Pertti architecture has been extended with:

- Opportunity Discovery Contracts
- Simulation / Scenario Contracts

This completes the full upstream intelligence pipeline:

memory → reasoning → discovery → simulation

Pertti can now:

- identify new opportunities
- structure them as explicit candidates
- simulate alternative futures
- compare branches without making decisions
- keep all hypothetical reasoning isolated from operational truth

---

### Opportunity Discovery Contracts (v1)

New file:

- src/types/opportunityDiscovery.ts

#### Capabilities

Pertti can now represent opportunities with:

- explicit source:
  - memory_pattern
  - world_model
  - simulation
  - external_signal
  - operator_input

- scoped targeting:
  - global / domain / project / city / country

- structured hypothesis:
  - assumptions
  - risks
  - uncertainties
  - expected value

- linked evidence:
  - signals
  - entities
  - memory references

- lightweight scoring (non-authoritative)

#### Architectural Role

Opportunity Discovery sits:

- above memory + world model
- before simulation and planning

It introduces structured exploration without decision authority.

---

### Simulation / Scenario Contracts (v1)

New file:

- src/types/simulationScenario.ts

#### Capabilities

Pertti can now:

- represent simulation scenarios as structured objects
- create multiple scenario branches
- attach:
  - assumptions
  - constraints
  - signals
  - expected outcomes

- compare branches (advisory only)
- explicitly mark all outputs as hypothetical

#### Critical Safety Property

All scenarios include:

- isHypothetical: true

Rule:
Simulation results must never be treated as production truth without explicit promotion.

---

### Intelligence Pipeline (v1)

Pertti now supports the following upstream flow:

1. Memory + Observations
2. World Model reasoning
3. Opportunity Discovery
4. Simulation / Scenario modeling

This pipeline is:

- non-executing
- non-authoritative
- explainable
- traceable
- governance-safe

---

### Architectural Impact

Pertti now operates as:

- Supervisory OS (decisions, planning, routing)
- Memory OS (knowledge, retrieval, promotion)
- Discovery OS (opportunity identification)
- Simulation OS (hypothetical modeling)

This establishes a full pre-execution intelligence layer.

---

### Status

- Supervisory Contracts: COMPLETE (v1)
- Memory Contracts: COMPLETE (v1)
- Opportunity Discovery: COMPLETE (v1)
- Simulation / Scenario: COMPLETE (v1)
- Canonical IDs: PARTIALLY APPLIED

---

### Next Steps

1. GitHub checkpoint (this update)
2. Next layer:
   - Venture Proposal Contracts (recommended)

Future (not yet):

- simulation execution logic
- memory retrieval refinement
- learning loop activation

## 2026-03-22 — Venture Proposal Layer + Exploration Stack Complete

STATE UPDATE — Venture Proposal Layer + Exploration Stack Complete
Summary

Pertti has now reached a major architectural milestone:

Full exploration → proposal pipeline is defined as pure, governed, type-only contract layers.

This introduces a complete upstream intelligence stack capable of:

discovering opportunities

simulating scenarios

formalizing venture proposals

feeding structured inputs into recommendation and policy systems

All layers remain:

deterministic

non-executing

governance-aligned

traceable and auditable

🧠 New Layer Added
Venture Proposal Contracts (ventureProposal.ts)

A new formalization boundary between exploration and decision-making.

Capabilities:

converts opportunities + simulations into structured proposals

represents buildable venture candidates

captures:

rationale (problem, assumptions, risks, uncertainties)

expected outcomes

dependencies

alternative options

links proposals to:

opportunity candidates

simulation scenarios

memory evidence

Key property:

Venture proposals are non-executing, uncertainty-aware, and review-oriented artifacts

🔗 Exploration Stack (Now Complete)

Pertti now includes a fully defined upstream intelligence pipeline:

Memory
→ Opportunity Discovery
→ Simulation / Scenario
→ Venture Proposal
→ Recommendation
→ Decision Policy
→ Planning / Routing / Dispatch
→ Execution (external systems only)
🧱 Architectural Properties

The exploration stack enforces:

1. Separation of Concerns

discovery ≠ simulation ≠ proposal ≠ decision

no layer leaks execution or policy responsibilities

2. Traceability

Every proposal can be traced back to:

memory evidence

opportunity signals

simulation branches

3. Uncertainty Awareness

assumptions, risks, and uncertainties are first-class

no implicit certainty is introduced

4. Governance Compatibility

proposals are safe inputs for:

recommendation system

decision policy layer

no autonomous execution paths

📁 Files Added (This Phase)

src/types/opportunityDiscovery.ts

src/types/simulationScenario.ts

src/types/ventureProposal.ts

🧩 System Maturity Update

Pertti is now capable (architecturally) of:

supervising multiple projects

exploring new venture opportunities

simulating strategic paths

formalizing new business concepts as structured proposals

This enables future capabilities such as:

automated venture pipeline generation

portfolio-level opportunity comparison

country-level expansion simulation

systematic discovery of new products/services

⚠️ Still Missing (Next Steps)

The following layers are not yet defined:

Proposal → Recommendation bridge

Strategic / portfolio-level prioritization

Simulation evaluation refinement

Memory retrieval optimization layer

Execution integration (OpenClaw / external adapters)

## 2026-03-22 — Venture Intelligence Chain Complete

### Summary

Pertti has now completed a full venture intelligence contract chain on top of the previously defined supervisory and memory architecture.

New layers added in this phase:

- Opportunity Discovery Contracts
- Simulation / Scenario Contracts
- Venture Proposal Contracts
- Proposal → Recommendation Bridge Contracts

This means Pertti can now model the full upstream path from observed patterns to formal recommendation candidates.

---

### Completed Venture Intelligence Layers

#### 1. Opportunity Discovery
File:
- `src/types/opportunityDiscovery.ts`

Purpose:
- represent new opportunities as structured candidates
- link opportunities to memory, reasoning, and signals
- preserve scope, evidence, and uncertainty

#### 2. Simulation / Scenario
File:
- `src/types/simulationScenario.ts`

Purpose:
- represent hypothetical branches and scenarios
- attach assumptions, constraints, signals, and modeled outcomes
- keep all scenario outputs explicitly hypothetical

#### 3. Venture Proposal
File:
- `src/types/ventureProposal.ts`

Purpose:
- formalize opportunities and simulations into reviewable venture proposals
- capture rationale, dependencies, options, expected outcomes, and uncertainties
- remain non-executing and policy-neutral

#### 4. Proposal → Recommendation Bridge
File:
- `src/types/proposalToRecommendation.ts`

Purpose:
- convert proposals into recommendation candidates
- preserve traceability and explicit conversion records
- support selective conversion, rejection, or deferral

---

### New End-to-End Intelligence Path

Pertti now supports the following structural path:

Memory
→ Opportunity Discovery
→ Simulation / Scenario
→ Venture Proposal
→ Proposal → Recommendation Bridge
→ Recommendation
→ Decision Policy
→ Planning / Routing / Dispatch
→ External Execution
→ Outcome / Feedback

---

### Architectural Impact

Pertti is no longer only a supervisory operations architecture.

It now includes a formal venture intelligence stack capable of:

- detecting opportunities
- modeling alternative futures
- shaping candidate ventures
- converting them into policy-ready recommendations

This enables later development toward:

- systematic venture generation
- market-entry simulation
- cross-project opportunity comparison
- portfolio-level strategic intelligence

---

### Safety / Governance Properties Preserved

These new layers remain:

- deterministic at the contract layer
- non-executing
- non-authoritative by default
- uncertainty-aware
- traceable to evidence
- compatible with governance review and policy gating

---

### Current Status

Completed:
- Supervisory OS contracts (v1)
- Memory OS contracts (v1)
- Venture intelligence chain (v1)
- Canonical identity foundation (partially normalized)

Still not implemented:
- runtime logic
- storage / retrieval engines
- execution integrations
- strategic thesis layer
- portfolio prioritization layer

---

### Recommended Next Step

Next recommended architecture layer:
- Portfolio Thesis / Strategic Themes Contracts

Rationale:
Now that Pertti can generate opportunity and proposal candidates, it needs a strategic layer that can group, frame, and evaluate them against broader portfolio direction.

## 2026-03-22 — Portfolio Thesis Layer Complete

### Summary

Pertti architecture has been extended with a strategic portfolio framing layer on top of the previously completed venture intelligence stack.

New layer added in this phase:

- Portfolio Thesis / Strategic Themes Contracts

This gives Pertti the ability to organize opportunities and venture proposals under broader strategic direction instead of treating them as disconnected candidates.

---

### New Layer Added

#### Portfolio Thesis / Strategic Themes
File:
- `src/types/portfolioThesis.ts`

Purpose:
- represent portfolio-level theses
- represent strategic themes
- link opportunities and venture proposals to broader strategy
- provide a framing layer before prioritization and policy selection

Capabilities introduced:
- thesis status
- strategic theme categories
- portfolio scope
- strategic rationale
- thesis/theme grouping
- explicit thesis → opportunity / proposal links

---

### Strategic Venture Intelligence Stack

Pertti now supports the following full upstream intelligence path:

Memory
→ Opportunity Discovery
→ Simulation / Scenario
→ Venture Proposal
→ Proposal → Recommendation Bridge
→ Portfolio Thesis / Strategic Themes
→ Recommendation
→ Decision Policy
→ Planning / Routing / Dispatch
→ External Execution
→ Outcome / Feedback

---

### Architectural Impact

Pertti now includes a complete strategic intelligence chain capable of:

- detecting opportunities
- simulating alternative futures
- formalizing venture candidates
- converting proposals into recommendations
- grouping opportunities and proposals under strategic portfolio theses

This strengthens Pertti’s role as:

- supervisory AI operating system
- memory operating system
- venture intelligence system
- portfolio strategy system

---

### Safety / Governance Properties Preserved

The new strategic layer remains:

- non-executing
- non-authoritative by default
- explainable
- scope-aware
- evidence-compatible
- review-friendly

No policy decisions or prioritization logic are introduced in this layer.

---

### Current Status

Completed:
- Supervisory OS contracts (v1)
- Memory OS contracts (v1)
- Venture Intelligence chain (v1)
- Portfolio Thesis / Strategic Themes layer (v1)
- Canonical identity foundation (partially normalized)

Still not implemented:
- prioritization layer
- portfolio allocation / capacity layer
- runtime engines
- storage/retrieval engines
- execution integrations

---

### Recommended Next Step

Next recommended architecture layer:
- Opportunity / Proposal Prioritization Contracts

Rationale:
Now that Pertti can generate and strategically frame venture candidates, it needs an explicit prioritization layer to determine what should move forward first.

## 2026-03-22 — Strategic Venture Pipeline Complete

### Summary

Pertti architecture has been extended with a full strategic venture pipeline on top of the previously completed supervisory and memory systems.

New layers added in this phase:

- Opportunity Discovery Contracts
- Simulation / Scenario Contracts
- Venture Proposal Contracts
- Proposal → Recommendation Bridge Contracts
- Portfolio Thesis / Strategic Themes Contracts
- Opportunity / Proposal Prioritization Contracts

This means Pertti can now move structurally from observed patterns and memory into strategic venture candidates, simulated alternatives, formal proposals, recommendation conversion, thesis alignment, and explicit prioritization.

---

### Completed Strategic Venture Layers

#### 1. Opportunity Discovery
File:
- `src/types/opportunityDiscovery.ts`

Purpose:
- discover structured opportunities
- connect opportunities to signals, memory, and reasoning outputs
- preserve uncertainty and scope

#### 2. Simulation / Scenario
File:
- `src/types/simulationScenario.ts`

Purpose:
- represent hypothetical branches
- attach assumptions, constraints, signals, and expected outcomes
- keep all scenario artifacts explicitly hypothetical

#### 3. Venture Proposal
File:
- `src/types/ventureProposal.ts`

Purpose:
- formalize opportunities and simulations into buildable but non-executing proposals
- capture rationale, expected outcomes, dependencies, and options

#### 4. Proposal → Recommendation Bridge
File:
- `src/types/proposalToRecommendation.ts`

Purpose:
- convert venture proposals into recommendation candidates
- preserve conversion traceability
- support rejection and deferral without hidden logic

#### 5. Portfolio Thesis / Strategic Themes
File:
- `src/types/portfolioThesis.ts`

Purpose:
- frame opportunities and proposals within broader portfolio strategy
- define strategic themes and thesis-level grouping
- support portfolio coherence before prioritization

#### 6. Prioritization
File:
- `src/types/prioritization.ts`

Purpose:
- express advisory prioritization signals for opportunities and proposals
- capture strategic alignment, feasibility, and prioritization rationale
- remain non-authoritative and separate from policy decisions

---

### Full Strategic Intelligence Path

Pertti now supports the following end-to-end strategic path:

Memory
→ Opportunity Discovery
→ Simulation / Scenario
→ Venture Proposal
→ Proposal → Recommendation Bridge
→ Portfolio Thesis / Strategic Themes
→ Prioritization
→ Recommendation
→ Decision Policy
→ Planning / Routing / Dispatch
→ External Execution
→ Outcome / Feedback

---

### Architectural Impact

Pertti now includes:

- Supervisory OS contracts
- Memory OS contracts
- Venture intelligence contracts
- Strategic framing contracts
- Prioritization contracts

This means Pertti is architecturally capable of:

- discovering new opportunities
- modeling alternative futures
- formalizing venture candidates
- aligning them with strategy
- prioritizing them before policy and execution

---

### Safety / Governance Properties Preserved

All new layers remain:

- deterministic at the contract layer
- non-executing
- non-policy-authoritative
- traceable to evidence or rationale
- uncertainty-aware
- compatible with governance review and human override

---

### Current Status

Completed:
- Supervisory OS contracts (v1)
- Memory OS contracts (v1)
- Strategic venture pipeline (v1)
- Portfolio thesis / theme layer (v1)
- Prioritization layer (v1)
- Canonical identity foundation (partially normalized)

Still not implemented:
- allocation / capacity planning layer
- runtime engines
- storage / retrieval engines
- execution integrations
- strategic review / thesis revision loop

---

### Recommended Next Step

Next recommended architecture layer:
- Portfolio Allocation / Capacity Planning Contracts

Rationale:
Now that Pertti can frame and prioritize opportunities and proposals, it needs an explicit layer for allocating constrained attention, resources, and execution capacity across the portfolio.

## 2026-03-22 — Portfolio Allocation Layer Complete

### Summary

Pertti architecture has been extended with an explicit portfolio allocation and capacity planning layer on top of the previously completed strategic venture pipeline.

New layer added in this phase:

- Portfolio Allocation / Capacity Planning Contracts

This gives Pertti the ability to move from:

- opportunity discovery
- venture proposal
- strategic framing
- prioritization

into an explicit advisory model of:

- where constrained portfolio attention should go
- how capacity constraints are represented
- what tradeoffs exist between candidate initiatives

---

### New Layer Added

#### Portfolio Allocation / Capacity Planning
File:
- `src/types/portfolioAllocation.ts`

Purpose:
- represent advisory allocation structures
- represent capacity constraints and capacity windows
- connect opportunities, proposals, and strategic themes to constrained portfolio capacity
- preserve tradeoff visibility before policy or execution decisions

Capabilities introduced:
- capacity units
- capacity windows
- capacity constraints
- allocation targets
- allocation reasons
- allocation comparisons
- advisory allocation records

---

### Strategic Venture Pipeline (Current)

Pertti now supports the following strategic path:

Memory
→ Opportunity Discovery
→ Simulation / Scenario
→ Venture Proposal
→ Proposal → Recommendation Bridge
→ Portfolio Thesis / Strategic Themes
→ Prioritization
→ Portfolio Allocation / Capacity Planning
→ Recommendation
→ Decision Policy
→ Planning / Routing / Dispatch
→ External Execution
→ Outcome / Feedback

---

### Architectural Impact

Pertti now includes the full contract-level structure required to:

- discover new opportunities
- model possible futures
- shape venture candidates
- connect them to portfolio strategy
- prioritize them
- express how constrained capacity should be allocated across them

This makes Pertti architecturally capable of acting not only as a supervisory system, but as a portfolio intelligence and allocation system.

---

### Safety / Governance Properties Preserved

The allocation layer remains:

- non-executing
- non-scheduling
- non-policy-authoritative
- advisory and explainable
- explicit about constraints and tradeoffs

No hidden optimization or execution semantics are introduced.

---

### Current Status

Completed:
- Supervisory OS contracts (v1)
- Memory OS contracts (v1)
- Strategic venture pipeline (v1)
- Portfolio thesis / themes layer (v1)
- Prioritization layer (v1)
- Portfolio allocation / capacity planning layer (v1)
- Canonical identity foundation (partially normalized)

Still not implemented:
- strategic review / thesis revision loop
- runtime engines
- storage / retrieval engines
- execution integrations
- allocation execution / resource management

---

### Recommended Next Step

Next recommended architecture layer:
- Strategic Review / Thesis Revision Contracts

Rationale:
Now that Pertti can frame, prioritize, and allocate work across the portfolio, it needs a governed way to revise strategic theses and themes based on memory, outcomes, and feedback over time.

## 2026-03-22 — Strategic Review Loop Complete

### Summary

Pertti architecture has been extended with a strategic review and thesis revision layer on top of the previously completed strategic venture pipeline.

New layer added in this phase:

- Strategic Review / Thesis Revision Contracts

This completes a full strategic loop for portfolio-level venture intelligence.

Pertti can now:

- generate opportunities
- simulate alternative futures
- formalize venture proposals
- connect them to strategic themes
- prioritize them
- model capacity allocation
- review and revise strategic theses based on evidence, outcomes, and feedback

---

### New Layer Added

#### Strategic Review / Thesis Revision
File:
- `src/types/strategicReview.ts`

Purpose:
- represent explicit strategic review cycles
- represent revision proposals for theses and themes
- connect revision work to:
  - memory evidence
  - outcome artifacts
  - learning / feedback artifacts
  - governance review artifacts

Capabilities introduced:
- review cycle states
- revision types
- revision impact levels
- evidence links
- review records
- review recommendations

---

### Strategic Portfolio Loop (Current)

Pertti now supports the following strategic cycle:

Memory
→ Opportunity Discovery
→ Simulation / Scenario
→ Venture Proposal
→ Proposal → Recommendation Bridge
→ Portfolio Thesis / Strategic Themes
→ Prioritization
→ Portfolio Allocation / Capacity Planning
→ Recommendation / Policy / Planning
→ Outcome / Feedback / Governance Review
→ Strategic Review / Thesis Revision
→ back to Portfolio Thesis / Strategic Themes

---

### Architectural Impact

Pertti now includes a complete strategy formation and revision loop.

This means Pertti can now, at contract level:

- frame strategic direction
- align venture candidates to themes
- prioritize them
- allocate constrained capacity
- review whether strategy itself should change

This turns Pertti from a static portfolio reasoning model into a dynamic strategic operating model.

---

### Safety / Governance Properties Preserved

The strategic review layer remains:

- non-executing
- non-policy-authoritative
- evidence-linked
- explicit about revision proposals
- free of silent thesis mutation

All strategy changes remain:
- explainable
- reviewable
- auditable

---

### Current Status

Completed:
- Supervisory OS contracts (v1)
- Memory OS contracts (v1)
- Strategic venture pipeline (v1)
- Portfolio thesis / theme layer (v1)
- Prioritization layer (v1)
- Portfolio allocation / capacity layer (v1)
- Strategic review / thesis revision loop (v1)
- Canonical identity foundation (partially normalized)

Still not implemented:
- portfolio initiative / program layer
- runtime engines
- storage / retrieval engines
- execution integrations
- strategic review execution workflow

---

### Recommended Next Step

Next recommended architecture layer:
- Portfolio Initiative / Program Contracts

Rationale:
Now that Pertti can create, prioritize, allocate, and revise strategic work, it needs a higher-order structure for grouping multiple proposals and initiatives into longer-running portfolio programs.

## 2026-03-22 — Portfolio Initiative Layer Complete

### Summary

Pertti architecture has been extended with a portfolio initiative / program layer on top of the completed strategic venture pipeline and strategic review loop.

New layer added in this phase:

- Portfolio Initiative / Program Contracts

This introduces a stable structure for grouping opportunities, proposals, and allocations into longer-running portfolio efforts.

---

### New Layer Added

#### Portfolio Initiative / Program
File:
- `src/types/portfolioInitiative.ts`

Purpose:
- group opportunities and proposals into structured initiatives
- connect initiatives to:
  - strategic themes and theses
  - portfolio allocation decisions
  - longer-running portfolio goals
- provide a stable abstraction for multi-step, multi-proposal efforts

Capabilities introduced:
- initiative status and lifecycle
- initiative types (program categories)
- initiative scope
- initiative goals
- initiative rationale
- explicit link sets (thesis, themes, opportunities, proposals, allocation)
- initiative timelines
- initiative-level review notes

---

### Strategic Portfolio Model (Current)

Pertti now supports a full multi-layer portfolio intelligence structure:

Memory
→ Opportunity Discovery
→ Simulation / Scenario
→ Venture Proposal
→ Proposal → Recommendation Bridge
→ Portfolio Thesis / Strategic Themes
→ Prioritization
→ Portfolio Allocation / Capacity Planning
→ Strategic Review / Thesis Revision
→ Portfolio Initiative / Program
→ Recommendation / Policy / Planning
→ Execution / Outcome / Feedback

---

### Architectural Impact

Pertti now includes a full portfolio structuring layer:

- initiatives provide grouping across:
  - multiple opportunities
  - multiple proposals
  - multiple allocation decisions
- initiatives connect strategy to longer-running work
- portfolio structure is no longer flat (list of proposals), but hierarchical

This enables Pertti to reason about:

- coordinated programs
- multi-step venture tracks
- cross-proposal execution paths
- longer-term portfolio evolution

---

### Safety / Governance Properties Preserved

The initiative layer remains:

- non-executing
- non-scheduling
- non-policy-authoritative
- purely structural and explanatory

No execution or hidden orchestration behavior is introduced.

---

### Current Status

Completed:
- Supervisory OS contracts (v1)
- Memory OS contracts (v1)
- Strategic venture pipeline (v1)
- Portfolio thesis / themes layer (v1)
- Prioritization layer (v1)
- Portfolio allocation / capacity planning layer (v1)
- Strategic review / thesis revision loop (v1)
- Portfolio initiative / program layer (v1)
- Canonical identity foundation (partially normalized)

Still not implemented:
- initiative → recommendation / planning bridge
- runtime engines
- storage / retrieval engines
- execution integrations
- portfolio-level approval / gating mechanisms

---

### Recommended Next Step

Next recommended architecture layer:
- Initiative → Recommendation / Planning Bridge

Rationale:
Now that Pertti can structure work into initiatives, it needs a controlled and traceable way to translate those initiatives into concrete recommendations and planning inputs.

## 2026-03-22 — Initiative Bridge Complete

### Summary

Pertti architecture has been extended with an explicit bridge from portfolio initiatives into downstream recommendation and planning artifacts.

New layer added in this phase:

- Initiative → Recommendation / Planning Bridge Contracts

This completes the structural connection between:

- higher-order portfolio initiatives/programs
- recommendation-level advisory outputs
- planner-facing operational structures

---

### New Layer Added

#### Initiative → Recommendation / Planning Bridge
File:
- `src/types/initiativeBridge.ts`

Purpose:
- translate portfolio initiatives into recommendation-facing artifacts
- translate portfolio initiatives into planning-facing artifacts
- preserve decomposition traceability
- support partial conversion without hidden logic

Capabilities introduced:
- initiative conversion statuses
- initiative conversion reasons
- initiative → recommendation links
- initiative → plan links
- explicit decomposition records
- bridge input/output boundary

---

### Portfolio-to-Operations Path (Current)

Pertti now supports the following structural flow:

Memory
→ Opportunity Discovery
→ Simulation / Scenario
→ Venture Proposal
→ Proposal → Recommendation Bridge
→ Portfolio Thesis / Strategic Themes
→ Prioritization
→ Portfolio Allocation / Capacity Planning
→ Strategic Review / Thesis Revision
→ Portfolio Initiative / Program
→ Initiative → Recommendation / Planning Bridge
→ Recommendation / Planner / Decision Policy
→ Routing / Dispatch / Execution Surfaces
→ Outcome / Feedback

---

### Architectural Impact

Pertti now includes an explicit bridge from portfolio-level structures into downstream operational advisory structures.

This means Pertti can now:

- shape portfolio initiatives
- keep them strategically coherent
- decompose them into recommendation and planning outputs
- preserve traceability between high-level strategy and lower-level operational work

This removes the previous architectural gap between:
- initiative/program-level portfolio structures
- recommendation/planning-level operational structures

---

### Safety / Governance Properties Preserved

The bridge layer remains:

- non-executing
- non-scheduling
- non-policy-authoritative
- explicit about decomposition
- free of hidden conversion behavior

No silent initiative decomposition or execution behavior is introduced.

---

### Current Status

Completed:
- Supervisory OS contracts (v1)
- Memory OS contracts (v1)
- Strategic venture pipeline (v1)
- Portfolio thesis / themes layer (v1)
- Prioritization layer (v1)
- Portfolio allocation / capacity planning layer (v1)
- Strategic review / thesis revision loop (v1)
- Portfolio initiative / program layer (v1)
- Initiative → Recommendation / Planning bridge (v1)
- Canonical identity foundation (partially normalized)

Still not implemented:
- portfolio-level gate / investment committee layer
- runtime engines
- storage / retrieval engines
- execution integrations
- formal planning → execution surface bridge
- memory trust/retrieval refinements

---

### Recommended Next Step

Next recommended architecture layer:
- Portfolio Gate / Investment Committee Contracts

Rationale:
Now that Pertti can generate, prioritize, allocate, group, and decompose initiatives, it needs a governed portfolio-level gate for formal approval, rejection, deferral, or investment-style decisions across higher-order work.

## 2026-03-22 — Portfolio Governance Layer Complete

### Summary

Pertti architecture has been extended with a portfolio governance layer that formalizes portfolio-level gating and persistent decision recording.

New layers added in this phase:

- Portfolio Gate / Investment Committee Contracts
- Portfolio Decision Record / Investment Ledger Contracts

This completes the governance side of the strategic venture pipeline.

---

### New Layers Added

#### 1. Portfolio Gate / Investment Committee
File:
- `src/types/portfolioGate.ts`

Purpose:
- represent portfolio-level gate decisions
- support proposal-level and initiative-level gating
- model:
  - explicit gate targets
  - committee references
  - gate rationale
  - constraints
  - conditions
- preserve explainability and human/governance visibility

Capabilities introduced:
- gate status
- gate decision
- gate target reference
- committee reference
- rationale / constraints / conditions
- review notes

#### 2. Portfolio Decision Record / Investment Ledger
File:
- `src/types/portfolioDecisionLedger.ts`

Purpose:
- persist portfolio-level decisions as explicit, audit-safe ledger records
- preserve temporal decision history
- connect decisions to:
  - gates
  - proposals
  - initiatives
  - allocation references

Capabilities introduced:
- decision record status
- decision record type
- decision snapshot
- decision temporal metadata
- ledger envelope and ledger boundary

---

### Strategic Governance Path (Current)

Pertti now supports the following strategic governance flow:

Portfolio Thesis / Themes
→ Prioritization
→ Allocation / Capacity
→ Portfolio Initiative / Program
→ Portfolio Gate / Investment Committee
→ Portfolio Decision Record / Investment Ledger
→ Outcome / Feedback / Memory

---

### Architectural Impact

Pertti now includes a full portfolio governance structure at the contract level.

This means Pertti can now:

- gate higher-order strategic work explicitly
- represent portfolio-level approval/reject/defer/escalate decisions
- store these decisions in a durable, append-oriented ledger model
- support traceable portfolio governance over time

This removes the previous gap between:
- strategic initiative shaping
- and persistent portfolio decision history

---

### Safety / Governance Properties Preserved

These governance layers remain:

- non-executing
- non-workflow-implementing
- non-budget-engine
- audit-first
- explicit about decision rationale and conditions
- free of silent overwrite semantics

No hidden portfolio approval logic or execution behavior is introduced.

---

### Current Status

Completed:
- Supervisory OS contracts (v1)
- Memory OS contracts (v1)
- Strategic venture pipeline (v1)
- Portfolio thesis / themes layer (v1)
- Prioritization layer (v1)
- Portfolio allocation / capacity planning layer (v1)
- Strategic review / thesis revision loop (v1)
- Portfolio initiative / program layer (v1)
- Initiative → Recommendation / Planning bridge (v1)
- Portfolio gate / investment committee layer (v1)
- Portfolio decision record / investment ledger layer (v1)
- Canonical identity foundation (partially normalized)

Still not implemented:
- planning → execution surface bridge
- runtime engines
- storage / retrieval engines
- execution integrations
- memory trust/retrieval refinements

---

### Recommended Next Step

Next recommended architecture layer:
- Planning → Execution Surface Bridge

Rationale:
Now that Pertti can generate, govern, and persist portfolio decisions, it needs a controlled bridge from planning artifacts into concrete execution surfaces such as OpenClaw, Codex, human operators, and other adapters.

## 2026-03-22 — Memory Trust Workflow Complete

### Summary

Pertti architecture has been extended with a full trust-oriented memory workflow layer on top of the previously completed base memory and retrieval contracts.

New layer added in this phase:

- Memory Promotion / Trust Workflow Contracts

This means Pertti now has an explicit contract-level model for how memory moves from candidate state toward reviewed or trusted state without silent mutation.

---

### New Layer Added

#### Memory Promotion / Trust Workflow
File:
- `src/types/memoryPromotion.ts`

Purpose:
- represent memory promotion workflow states explicitly
- represent trust/promotion review records
- represent promotion decisions and target states
- connect promotion to:
  - evidence
  - governance reviews
  - outcomes
  - feedback
  - retrieval traces

Capabilities introduced:
- promotion workflow status
- promotion decision
- promotion target state
- promotion evidence links
- promotion conditions
- promotion rationale
- explicit promotion transition records

---

### Memory OS (Current)

Pertti now supports the following memory path:

Memory
→ Memory Retrieval Refinement
→ Memory Promotion / Trust Workflow
→ reviewed / trusted memory use in reasoning, planning, audit, simulation, and strategy

This means memory is now structured not only as stored knowledge, but as a governed trust system.

---

### Architectural Impact

Pertti now includes a complete contract-level memory trust pipeline:

- base memory envelope
- refined retrieval boundary
- promotion / trust workflow boundary

This enables future development toward:

- explicit trust transitions
- evidence-backed promotion
- governance-linked memory review
- safe handling of supersession and rejection
- stronger auditability for long-lived system knowledge

---

### Safety / Governance Properties Preserved

The promotion layer remains:

- non-executing
- non-storage-implementing
- non-workflow-engine
- explicit about trust transitions
- free of silent mutation semantics

Historical memory remains preserved through explicit transitions rather than overwrite behavior.

---

### Current Status

Completed:
- Supervisory OS contracts (v1)
- Memory OS contracts (base + retrieval + promotion) (v1)
- Strategic venture pipeline (v1)
- Portfolio governance layer (v1)
- Execution surface bridge (v1)
- Canonical identity foundation (partially normalized)

Still not implemented:
- memory ingestion refinement
- execution surface package refinement
- cross-layer traceability / evidence graph layer
- runtime engines
- storage / retrieval engines
- execution integrations

---

### Recommended Next Step

Next recommended architecture layer:
- Cross-Layer Traceability / Evidence Graph Contracts

Rationale:
Now that Pertti contains many structured artifacts across memory, strategy, governance, planning, and execution boundaries, it needs an explicit graph/traceability layer that can represent relationships and evidence paths across the full system.

## 2026-03-23 — Orchestration Boundary + Run Definition Layer Complete

### Summary

Pertti architecture has been extended with a full pre-runtime orchestration boundary layer.

New files added:

- `src/types/perttiOrchestrator.ts`
- `src/types/perttiStageCatalog.ts`
- `src/types/perttiStageValidation.ts`
- `src/types/perttiStageConfig.ts`
- `src/types/perttiRunDefinition.ts`

These complete the missing orchestration-side contract structure between session framing and any future runtime orchestration.

---

### New Layers Added

#### 1. Orchestrator Contracts
File:
- `src/types/perttiOrchestrator.ts`

Purpose:
- define run modes
- define orchestration stages and categories
- define artifact flow contracts
- define completion states
- define invariant violation model

Key property:
- contracts-only
- no runtime behavior
- no service object
- no execution logic

#### 2. Static Stage Catalog
File:
- `src/types/perttiStageCatalog.ts`

Purpose:
- define the static stage graph
- define stage metadata
- define allowed transitions
- define required and optional modes per stage
- define required and emitted artifacts

Key property:
- static orchestration structure only
- no runtime coordination

#### 3. Stage Validation Layer
File:
- `src/types/perttiStageValidation.ts`

Purpose:
- validate stage catalog integrity
- validate transitions
- validate mode consistency
- validate artifact declaration consistency
- validate invariant alignment

Key property:
- pure validation only
- deterministic
- no stage execution

#### 4. Stage Config / Build-Test Entry
File:
- `src/types/perttiStageConfig.ts`

Purpose:
- provide a tiny typed entry point for validating the default stage catalog
- connect catalog + validation for build/test usage

Key property:
- not a runtime orchestrator
- no service semantics
- no stateful coordination

#### 5. Run Definition / Run Intent Layer
File:
- `src/types/perttiRunDefinition.ts`

Purpose:
- define why a run exists
- define run intent, trigger, scope, requested stages, seed artifacts, and expectations
- model one run before orchestration execution exists

Key property:
- pre-runtime boundary only
- separate from session frame
- separate from stage coordination

---

### Architectural Impact

Pertti now includes:

- supervisory contracts
- memory contracts
- venture intelligence chain
- portfolio strategy + governance layers
- execution surface boundary
- orchestration boundary contracts
- static orchestration catalog
- orchestration validation layer
- run definition / intent layer

This means the missing runtime-side contract boundary is now defined without introducing runtime behavior.

---

### Status

Completed:
- Supervisory OS contracts (v1)
- Memory OS contracts (v1)
- Venture intelligence chain (v1)
- Portfolio strategy + governance layers (v1)
- Execution surface boundary (v1)
- Orchestration boundary contracts (v1)
- Stage catalog + validation layer (v1)
- Run definition / intent layer (v1)

Still not implemented:
- runtime orchestrator
- stage invocation runtime
- run definition validation layer
- simulated end-to-end run
- storage / retrieval engines
- execution integrations

---

### Recommended Next Step

Next recommended architecture layer:
- Run Definition Validation

Rationale:
Now that Pertti can describe a run before orchestration begins, it needs a small pure validation layer to check run-definition integrity before any future simulated runtime is introduced.

## Orchestration Boundary + Run Definition Layer Complete

Pertti now includes a full pre-runtime orchestration boundary layer consisting of:

- `src/types/perttiOrchestrator.ts`
- `src/types/perttiStageCatalog.ts`
- `src/types/perttiStageValidation.ts`
- `src/types/perttiStageConfig.ts`
- `src/types/perttiRunDefinition.ts`

### What this adds

This layer defines:

- orchestration stage graph contracts
- stage categories and run modes
- artifact flow expectations across stages
- static catalog structure
- pure validation for catalog integrity
- build/test-level validation entrypoint
- run intent / run definition modeling before runtime exists

### What this does not add

This layer does not implement:

- runtime orchestration
- stage execution
- policy logic
- governance logic
- routing logic
- service-style orchestration objects

### Architectural significance

This is the missing boundary between:

- session framing
- orchestration contracts
- future runtime behavior

Pertti can now describe:
- what a run is
- what stages exist
- what structure is valid
- what pre-runtime orchestration shape is allowed

without introducing execution semantics.

### Next recommended layer

- Run Definition Validation
