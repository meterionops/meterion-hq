# Pertti

## Status
Active.

Pertti has progressed from Kernel v1 and Supervisory Kernel Foundation into a broader supervisory architecture contract stack.

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

## Newly Completed Architecture Contracts

### World Model Contracts
Completed:
- `src/types/worldModel.ts`

Purpose:
- defines structured state/action/constraint/consequence contracts
- keeps World Model between validation and decision policy
- no execution
- no policy implementation

### Recommendation Boundary Contracts
Completed:
- `src/types/recommendation.ts`

Purpose:
- defines recommendation candidates, rationale, and human review packaging
- preserves separation between world model reasoning and downstream policy

### World Model Engine Interface
Completed:
- `src/types/worldModelEngine.ts`

Purpose:
- defines pure engine invocation boundary
- no implementation logic
- no simulation engine implementation yet

### Decision Policy Engine Contracts
Completed:
- `src/types/decisionPolicy.ts`

Purpose:
- defines policy-facing decision contracts
- explicit human approval requirement
- no execution logic
- status terminology kept separate from execution semantics

### Execution Routing Contracts
Completed:
- `src/types/executionRouting.ts`

Purpose:
- transforms policy decisions into abstract routing contracts
- preserves approval visibility
- keeps routing distinct from execution

### Outcome Ledger Contracts
Completed:
- `src/types/outcomeLedger.ts`

Purpose:
- defines audit-oriented, link-based ledger records
- captures decisions, routes, impact, and audit notes
- no storage logic

### Learning / Feedback Contracts
Completed:
- `src/types/learningFeedback.ts`

Purpose:
- defines structured feedback records and learning targets
- keeps learning boundary audit-friendly and non-adaptive
- no learning engine logic
- no self-modification

## Current Locked Supervisory Spine
Validation
→ World Model
→ Recommendation Boundary
→ Decision Policy Engine
→ Execution Routing
→ Outcome Ledger
→ Learning / Feedback

## What Pertti Is Becoming
Pertti is being built as:
- a governance-driven supervisory AI operating system
- a portfolio-level operator
- a memory-capable and reasoning-capable system
- a simulation-capable and review-oriented architecture

Pertti is not:
- a chatbot
- a wild autonomous agent
- an execution engine

## Recommended Next Step
Next recommended architecture layer:
- Planner Contracts

Rationale:
The current supervisory contract spine is now strong enough that planning can be defined on top of:
- reasoning
- recommendation
- policy
- routing
- ledger
- feedback

## Operating Guidance
Continue using:
- ChatGPT = architect
- Codex desktop/local = builder
- GitHub = source of truth

Continue with:
- small pack
- review
- next pack

Avoid jumping directly into execution-heavy implementation before planner boundaries are locked.
