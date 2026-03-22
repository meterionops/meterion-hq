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
