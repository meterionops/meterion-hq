# Pertti

## Status
Active.

Pertti has progressed from Kernel v1 and Supervisory Kernel Foundation into a broader supervisory operating model contract stack.

## Completed Baseline

### Kernel v1
Completed:
- `src/types/common.ts`
- `src/kernel/identity.ts`
- `src/kernel/governance.ts`
- `src/kernel/projectRegistry.ts`
- `src/index.ts`

### Supervisory Kernel Foundation
Completed:

Pack A
- `src/types/executionContext.ts`
- `src/types/capability.ts`

Pack B
- `src/types/projectAdapter.ts`
- `src/types/routing.ts`
- `src/types/validation.ts`

Pack C
- `src/kernel/supervisoryKernel.ts`

Pack D
- `src/kernel/contextValidation.ts`

Pack E
- `src/index.ts` export update

## Completed Supervisory Architecture Contracts

### World Model Contracts
- `src/types/worldModel.ts`

Purpose:
- structured state/action/constraint/consequence contracts
- positioned between validation and decision policy
- no execution
- no policy implementation

### Recommendation Boundary Contracts
- `src/types/recommendation.ts`

Purpose:
- recommendation candidates
- rationale
- human review packaging
- clean boundary after world model reasoning

### World Model Engine Interface
- `src/types/worldModelEngine.ts`

Purpose:
- pure engine invocation boundary
- no implementation logic
- no simulation implementation

### Decision Policy Engine Contracts
- `src/types/decisionPolicy.ts`

Purpose:
- policy-facing decision contracts
- explicit human approval requirement
- no execution logic

### Execution Routing Contracts
- `src/types/executionRouting.ts`

Purpose:
- abstract routing contracts
- preserves approval visibility
- distinct from execution

### Outcome Ledger Contracts
- `src/types/outcomeLedger.ts`

Purpose:
- audit-oriented, link-based ledger records
- captures decision/routing/impact context
- no storage logic

### Learning / Feedback Contracts
- `src/types/learningFeedback.ts`

Purpose:
- structured feedback records
- learning targets
- non-adaptive contract boundary

### Planner Contracts
- `src/types/planner.ts`

Purpose:
- structured goals, steps, dependencies, blockers
- downstream of supervisory reasoning/policy/routing
- no execution or scheduling

### Project Adapter Resolver Contracts
- `src/types/projectAdapterResolver.ts`

Purpose:
- project/step/route to adapter mapping
- supports ambiguity and unresolved cases
- no dispatch behavior

### Role Task Model Contracts
- `src/types/roleTask.ts`

Purpose:
- role-bound task representation
- explicit capability requirements
- task linkage to plan/route/adapter/project
- no scheduling or execution

### Task Dispatch Boundary Contracts
- `src/types/taskDispatch.ts`

Purpose:
- dispatch readiness representation
- approval gate boundary
- abstract dispatch targets
- no queue/worker/runtime behavior

## Current Locked Supervisory Operating Model
Validation
→ World Model
→ Recommendation Boundary
→ Decision Policy Engine
→ Execution Routing
→ Outcome Ledger
→ Learning / Feedback
→ Planner
→ Project Adapter Resolver
→ Role Task Model
→ Task Dispatch Boundary

## What Pertti Is Becoming
Pertti is being built as:
- a governance-driven supervisory AI operating system
- a portfolio-level operator
- a memory-capable, reasoning-capable, planning-capable system
- a simulation-capable and review-oriented architecture

Pertti is not:
- a chatbot
- a wild autonomous agent
- an execution engine

## Recommended Next Step
Next recommended architecture layer:
- Supervisory Run Session Contracts

Rationale:
The current contract stack is now broad enough that run/session boundaries should be explicitly defined before implementation-heavy runtime behavior.

## Operating Guidance
Continue using:
- ChatGPT = architect
- Codex desktop/local = builder
- GitHub = source of truth

Continue with:
- small pack
- review
- next pack

Avoid jumping into execution-heavy implementation before supervisory run/session boundaries are locked.

### Update — Supervisory Contracts v1 + Identity Layer

Pertti supervisory contract system (v1) has been completed with:

- full end-to-end contract stack (World Model → Outcome → Feedback)
- canonical identity layer (canonicalIds.ts)
- identity normalization across core and audit layers

Pertti is now structurally capable of:

- portfolio-level supervision
- multi-project coordination
- deterministic decision + audit loop
- outcome-driven feedback cycles

Next phase:
- either identity/envelope refinement
- or move toward opportunity discovery layer

## Memory Architecture — Contracts Layer Complete

Pertti now includes a formal Memory OS contract layer.

This defines how memory works across:

- multiple projects
- multiple cities (CityOS scale)
- long-lived supervisory runs
- simulation environments

### What this enables

Pertti can now:

- store structured knowledge with:
  - scope
  - authority
  - provenance
  - temporal validity

- separate:
  - operational truth
  - inferred knowledge
  - simulation results

- retrieve knowledge safely without:
  - cross-project contamination
  - simulation leakage

- evolve knowledge via:
  - explicit promotion lifecycle
  - review and governance controls

---

### Key Design Outcome

Pertti is no longer just a supervisory reasoning system.

It is now:

- a supervisory operating system
- combined with a memory operating system

This combination enables:

- portfolio-level intelligence
- multi-city supervision (CityOS)
- long-term learning with governance
- safe simulation-driven exploration

---

### Strategic Direction

This unlocks future capabilities:

- large-scale opportunity discovery
- cross-project pattern learning
- simulation-driven business creation
- persistent system intelligence over time

---

### Current Status

- Supervisory contracts: complete
- Memory contracts: complete
- Execution: still external (OpenClaw / Codex)
- System remains:
  - read-only
  - propose-only
  - governance-driven

---

### Next Focus

Move from foundation → capability:

- Opportunity Discovery layer (recommended next)
- Later:
  - memory retrieval refinement
  - simulation engine expansion
  - learning loop activation

## Discovery + Simulation Layer Complete

Pertti now includes structured capability for:

- discovering opportunities
- modeling alternative futures
- comparing hypothetical outcomes

### What this enables

Pertti can now:

- identify new CityOS expansion opportunities (cities, sources, markets)
- detect:
  - content gaps
  - SEO opportunities
  - automation opportunities
  - new product ideas

- simulate:
  - multiple strategies
  - alternative launch paths
  - different operational configurations

- compare scenarios before any decision or execution

---

### Key Design Outcome

Pertti is no longer only a supervisory system.

It is now:

- a supervisory system
- a memory system
- a discovery system
- a simulation system

This combination enables:

- portfolio-level opportunity discovery
- safe exploration of new business ideas
- scalable multi-city expansion logic
- structured reasoning over future possibilities

---

### Safety Guarantees

The system enforces:

- no simulation leakage into production truth
- no automatic decision-making from discovery
- no execution without policy + approval layers
- explicit uncertainty representation

---

### Strategic Direction

This unlocks:

- venture discovery pipeline
- simulation-driven strategy design
- cross-project intelligence reuse
- long-term system learning (via memory + feedback)

---

### Current State

Pertti is now:

- architecturally complete at contract level
- capable of:
  - observing
  - reasoning
  - discovering
  - simulating

Still missing:

- formal venture proposal layer
- execution orchestration integration
- runtime + storage implementation

---

### Next Focus

Move from exploration → formalization:

- Venture Proposal Contracts (next step)

After that:

- simulation refinement
- decision-policy integration with proposals
- execution system bridging (OpenClaw / Codex)
## Venture Intelligence Chain Complete

Pertti now includes a complete upstream venture intelligence contract flow:

- Opportunity Discovery
- Simulation / Scenario
- Venture Proposal
- Proposal → Recommendation Bridge

This means Pertti can now move structurally from:

observed patterns / memory
→ opportunity candidate
→ simulated scenarios
→ formal venture proposal
→ recommendation candidate

### What this enables

Pertti can now support:

- structured venture discovery
- market-entry exploration
- scenario-based opportunity shaping
- proposal formalization before policy review
- future portfolio-level strategic filtering

### Strategic significance

This is the first point where Pertti becomes capable, at architecture level, of acting as a venture formation system rather than only an operational supervisor.

### Next recommended layer

- Portfolio Thesis / Strategic Themes Contracts

## Portfolio Thesis / Strategic Themes Layer Complete

Pertti now includes a strategic framing layer that connects:

- opportunities
- simulations
- venture proposals

to broader portfolio theses and strategic themes.

### What this enables

Pertti can now:

- avoid treating opportunities as isolated ideas
- group multiple initiatives under shared strategic direction
- frame venture candidates in portfolio context
- prepare for explicit prioritization and allocation layers

### Strategic significance

This is the point where Pertti becomes capable, at architecture level, of not only generating ventures but also organizing them into coherent portfolio strategy.

### Next recommended layer

- Opportunity / Proposal Prioritization Contracts

## Strategic Venture Pipeline Complete

Pertti now includes a complete strategic venture pipeline:

- Opportunity Discovery
- Simulation / Scenario
- Venture Proposal
- Proposal → Recommendation Bridge
- Portfolio Thesis / Strategic Themes
- Prioritization

### What this enables

Pertti can now:

- discover opportunities
- simulate alternative futures
- shape ventures into formal proposals
- connect them to strategic themes
- prioritize them before decision policy

### Strategic significance

This is the point where Pertti becomes capable, at architecture level, of structured venture portfolio intelligence rather than only operational supervision.

### Next recommended layer

- Portfolio Allocation / Capacity Planning Contracts

## Portfolio Allocation / Capacity Planning Layer Complete

Pertti now includes an explicit portfolio allocation layer that connects:

- opportunities
- venture proposals
- strategic themes
- prioritization outputs

to constrained portfolio capacity.

### What this enables

Pertti can now:

- express where limited attention and capacity should go
- represent tradeoffs between initiatives
- connect strategic direction to practical allocation choices
- prepare for future portfolio operating decisions

### Strategic significance

This is the point where Pertti becomes capable, at architecture level, of not only deciding what is important but also modeling what can realistically be advanced under limited capacity.

### Next recommended layer

- Strategic Review / Thesis Revision Contracts

## Strategic Review / Thesis Revision Loop Complete

Pertti now includes an explicit strategic review layer that can:

- review portfolio theses
- propose revisions to themes and thesis framing
- connect strategic changes to:
  - memory evidence
  - outcomes
  - feedback
  - governance review artifacts

### What this enables

Pertti can now:

- avoid static strategy drift
- revise portfolio logic explicitly
- connect strategic changes to evidence
- maintain a governed strategy loop over time

### Strategic significance

This is the point where Pertti becomes capable, at architecture level, of not only generating and allocating portfolio work but also revising the strategy that governs that work.

### Next recommended layer

- Portfolio Initiative / Program Contracts

## Portfolio Initiative / Program Layer Complete

Pertti now includes a portfolio initiative layer that groups:

- opportunities
- venture proposals
- allocation decisions
- strategic themes

into structured, longer-running portfolio efforts.

### What this enables

Pertti can now:

- represent coordinated programs instead of isolated proposals
- connect strategy to multi-step execution paths
- model portfolio evolution over time
- organize work across multiple initiatives simultaneously

### Strategic significance

This is the point where Pertti becomes capable, at architecture level, of managing a structured venture portfolio rather than a flat set of ideas or recommendations.

### Next recommended layer

- Initiative → Recommendation / Planning Bridge

## Initiative → Recommendation / Planning Bridge Complete

Pertti now includes an explicit bridge that connects:

- portfolio initiatives / programs
- recommendation artifacts
- planning artifacts

### What this enables

Pertti can now:

- decompose higher-order initiatives into downstream advisory structures
- preserve traceability from portfolio strategy to operational planning
- support partial initiative decomposition without hidden behavior

### Strategic significance

This is the point where Pertti becomes capable, at architecture level, of connecting portfolio program structures directly back into the lower-level supervisory operating pipeline.

### Next recommended layer

- Portfolio Gate / Investment Committee Contracts

## Portfolio Governance Layer Complete

Pertti now includes an explicit portfolio governance layer consisting of:

- Portfolio Gate / Investment Committee
- Portfolio Decision Record / Investment Ledger

### What this enables

Pertti can now:

- formally gate portfolio initiatives and proposals
- record portfolio decisions in an append-oriented ledger model
- preserve strategic decision history over time
- connect governance decisions to proposals, initiatives, and allocations

### Strategic significance

This is the point where Pertti becomes capable, at architecture level, of governed portfolio decision-making rather than only strategic suggestion and framing.

### Next recommended layer

- Planning → Execution Surface Bridge

## Memory Promotion / Trust Workflow Complete

Pertti now includes a formal trust workflow layer for memory.

This adds:

- explicit promotion review records
- explicit trust decisions
- explicit lifecycle transitions
- evidence-linked promotion logic
- governance-aware memory trust boundaries

### What this enables

Pertti can now:

- treat trust as an explicit workflow, not an implicit property
- connect memory promotion to outcomes, feedback, and governance review
- preserve historical knowledge without silent overwrite
- support reviewed/trusted memory in a controlled way

### Strategic significance

This is the point where Pertti’s memory system becomes not only structured and retrievable, but governable as a trust pipeline.

### Next recommended layer

- Cross-Layer Traceability / Evidence Graph Contracts

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

## Run Definition Validation Layer Complete

Pertti now includes a pure validation layer for pre-runtime run definitions:

- `src/types/perttiRunDefinitionValidation.ts`

### What this adds

This layer validates:

- run scope presence
- trigger presence and trigger summary
- requested stage selection consistency
- run-mode and intent compatibility
- expected seed-artifact presence
- unresolved stage-catalog validation state

### What this does not add

This layer does not implement:

- runtime orchestration
- stage execution
- service-style orchestration
- policy logic
- governance logic
- routing logic

### Architectural significance

This completes the pre-runtime validation side of the orchestration boundary.

Pertti can now:

- define runs
- define orchestration structure
- validate catalog integrity
- validate individual run definitions

before any simulated or actual runtime behavior exists.

### Next recommended layer

- Minimal Non-Executing Simulated Run Assembly

## Minimal Non-Executing Simulated Run Assembly Complete

Pertti now includes a first minimal simulated run assembly layer:

- `src/types/perttiSimulatedRun.ts`

### What this adds

This layer assembles:

- run definition
- run definition validation
- stage catalog validation
- requested / required / excluded stages
- seed artifacts
- initial artifact registry
- readiness state
- blocking issues

into a single typed simulated run structure.

### What this does not add

This layer does not implement:

- runtime orchestration
- stage execution
- transition coordination
- planner logic
- policy logic
- governance logic
- routing logic
- service-style orchestration behavior

### Architectural significance

This is the first point where Pertti can assemble a run-shaped structure from validated pre-runtime components.

Pertti can now:

- define a run
- validate the run definition
- validate orchestration structure
- assemble a simulated run package
- expose readiness for future orchestration

without executing anything.

### Next recommended layer

- Simulated Run Fixture / Sample Case Layer

## Simulated Run Fixture Layer Complete

Pertti now includes a deterministic simulated run fixture layer:

- `src/types/perttiSimulatedRunFixtures.ts`

### What this adds

This layer provides reusable example cases for:

- valid run definitions
- invalid run definitions
- simulation-mode runs
- portfolio-review runs
- assembled simulated runs based on those definitions

### What this does not add

This layer does not implement:

- runtime orchestration
- stage execution
- transition coordination
- policy logic
- governance logic
- routing logic
- service-style orchestration behavior

### Architectural significance

This is the first point where Pertti has reusable example run cases on top of the pre-runtime orchestration stack.

Pertti can now:

- define runs
- validate run definitions
- validate orchestration structure
- assemble simulated runs
- generate reusable sample cases for testing and simulation preparation

without executing anything.

### Next recommended layer

- Fixture Verification / Test Assertion Layer

## Simulated Run Assertion Layer Complete

Pertti now includes a deterministic assertion and verification layer:

- `src/types/perttiSimulatedRunAssertions.ts`

### What this adds

This layer enables verification of:

- simulated run readiness
- blocking issue presence
- run-mode correctness
- expected validation issue codes

It also provides grouped verification for:

- valid simulated runs
- invalid simulated runs
- simulation-mode runs
- portfolio-review runs

### What this does not add

This layer does not implement:

- runtime orchestration
- stage execution
- transition coordination
- planner logic
- policy logic
- governance logic
- routing logic
- service-style orchestration

### Architectural significance

This completes the pre-runtime verification stack.

Pertti can now:

- define runs
- validate definitions
- validate orchestration structure
- assemble simulated runs
- generate fixtures
- verify correctness of those fixtures

without executing anything.

### Next recommended layer

- Test Harness / Verification Entry Layer

## Verification Harness Layer Complete

Pertti now includes a deterministic verification harness layer:

- `src/types/perttiVerificationHarness.ts`

### What this adds

This layer provides:

- a single entry point to run all fixture verifications
- aggregated assertion results
- summary metrics:
  - total assertions
  - passed assertions
  - failed assertions
  - overall success

### What this does not add

This layer does not implement:

- runtime orchestration
- stage execution
- transition coordination
- planner logic
- policy logic
- governance logic
- routing logic
- service-style orchestration

### Architectural significance

This completes the full pre-runtime system validation stack.

Pertti can now:

- define runs
- validate definitions
- validate orchestration structure
- assemble simulated runs
- generate fixtures
- verify correctness of fixtures
- run full-system verification via a single entry point

without executing anything.

### Next recommended layer

- Runtime v0 — Minimal Orchestrator Runner
## Runtime v0 Complete

Pertti now includes a first runtime entry point:

- `src/types/perttiRuntimeV0.ts`

### What this adds

This layer enables:

- accepting a run definition
- validating the run definition
- validating orchestration structure
- assembling a simulated run
- exposing readiness for orchestration
- exposing blocking issues

### What this does not add

This layer does not implement:

- stage execution
- orchestration loops
- transition coordination
- planner logic
- policy logic
- governance logic
- routing logic
- adapter execution
- async runtime behavior

### Architectural significance

This is the first runnable entry point for Pertti.

Pertti can now:

- take a run definition as input
- validate it
- assemble a run structure
- determine if it is ready for orchestration

without executing anything.

This marks the transition from static architecture to a controlled runtime boundary.

### Next recommended layer

- Stage Progression / Runtime State View
## Stage Progression / Runtime State View Complete

Pertti now includes a first runtime-state view layer:

- `src/types/perttiStageProgression.ts`

### What this adds

This layer provides stage-level visibility for a simulated run, including:

- ready stages
- blocked stages
- unreachable stages
- pending stages

### What this does not add

This layer does not implement:

- stage execution
- transition coordination
- orchestration loops
- planner logic
- policy logic
- governance logic
- routing logic
- service-style orchestration behavior

### Architectural significance

This is the first point where Pertti can inspect stage-level runtime state without executing anything.

Pertti can now:

- prepare a run
- evaluate readiness
- inspect stage progression state
- determine what is blocked or excluded

without introducing execution semantics.

### Next recommended layer

- Stage Transition Eligibility Layer
## Stage Transition Eligibility Layer Complete

Pertti now includes a deterministic stage eligibility layer:

- `src/types/perttiStageEligibility.ts`

### What this adds

This layer enables:

- determining which stages are eligible to be next
- separating stage readiness from transition eligibility
- validating transition constraints using allowedPreviousStages
- producing explicit eligibility reasoning per stage

### What this does not add

This layer does not implement:

- stage execution
- orchestration loops
- transition sequencing
- planner logic
- policy logic
- governance logic
- routing logic
- service-style orchestration

### Architectural significance

This is the first true decision surface in the runtime pipeline.

Pertti can now:

- see which stages are READY
- determine which stages are actually allowed next
- explain why a stage is not eligible

without executing anything.

### Next recommended layer

- Next Stage Selection View
## Next Stage Selection View Complete

Pertti now includes a deterministic next-stage selection layer:

- `src/types/perttiStageSelection.ts`

### What this adds

This layer enables:

- selecting the next stage from eligible candidates
- returning:
  - a recommended stage
  - all candidate stages
  - explicit reasoning

### What this does not add

This layer does not implement:

- stage execution
- orchestration loops
- prioritization or scoring logic
- planner logic
- policy logic
- governance logic
- routing logic
- service-style orchestration

### Architectural significance

This completes the core decision surface of the orchestrator.

Pertti can now:

- determine which stages are possible
- determine which stages are allowed
- select the next stage deterministically

without executing anything.

### Next recommended layer

- Orchestration Cycle View
## Orchestration Cycle View Complete

Pertti now includes a unified orchestration cycle view:

- `src/types/perttiOrchestrationCycle.ts`

### What this adds

This layer provides:

- a complete snapshot of one orchestration cycle
- composed views of:
  - runtime state
  - stage progression
  - stage eligibility
  - next stage selection

### What this does not add

This layer does not implement:

- stage execution
- orchestration loops
- transition sequencing
- planner logic
- policy logic
- governance logic
- routing logic
- service-style orchestration

### Architectural significance

This is the first complete “dry-run orchestrator”.

Pertti can now:

- simulate a full orchestration cycle
- inspect decision-making end-to-end
- debug orchestration behavior safely

without executing anything.

### Next recommended layer

- Orchestration Decision Trace Layer
## Orchestration Decision Trace Layer Complete

Pertti now includes a deterministic decision trace layer:

- `src/types/perttiDecisionTrace.ts`

### What this adds

This layer enables:

- explaining the orchestration cycle
- tracing:
  - stage progression
  - stage eligibility
  - stage selection
- generating a concise summary of system decision state

### What this does not add

This layer does not implement:

- stage execution
- orchestration loops
- decision-making logic
- planner logic
- policy logic
- governance logic
- routing logic
- service-style orchestration

### Architectural significance

This introduces explainability into the orchestrator pipeline.

Pertti can now:

- simulate decisions
- understand decision outcomes
- explain system state step-by-step

without executing anything.

### Next recommended layer

- Orchestration Snapshot / Export Layer
