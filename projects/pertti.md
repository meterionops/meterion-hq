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
