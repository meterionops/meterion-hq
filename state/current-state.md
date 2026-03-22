# Current State

## Active Focus
Pertti v2 supervisory architecture build-out has progressed beyond the initial reasoning spine into planning, adapter resolution, role-task modeling, and dispatch boundary definition.

## Current Status
Pertti now has a broad supervisory operating model contract foundation implemented at the type-contract level.

Completed contract layers:
1. `src/types/worldModel.ts`
2. `src/types/recommendation.ts`
3. `src/types/worldModelEngine.ts`
4. `src/types/decisionPolicy.ts`
5. `src/types/executionRouting.ts`
6. `src/types/outcomeLedger.ts`
7. `src/types/learningFeedback.ts`
8. `src/types/planner.ts`
9. `src/types/projectAdapterResolver.ts`
10. `src/types/roleTask.ts`
11. `src/types/taskDispatch.ts`

These layers are currently defined as:
- deterministic
- pure / type-only at contract layer
- propose-only by architectural intent
- non-executing
- governance-compatible
- suitable as the foundation for later implementation layers

## Architectural Sequence Now Locked
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

## Important Architectural Decisions
- World Model remains strictly between validation and decision policy.
- Recommendation remains a boundary layer, not a decision or execution layer.
- Decision Policy Engine evaluates recommendations under constraints but does not execute.
- Execution Routing remains abstract and non-executing.
- Outcome Ledger is audit-oriented and link-oriented, not storage logic.
- Learning / Feedback remains contract-only and non-adaptive.
- Planner is a structured planning layer, not an executor or scheduler.
- Project Adapter Resolver maps projects/steps/routes to adapters without dispatching.
- Role Task Model represents role-bound tasks and capability requirements without scheduling or execution.
- Task Dispatch Boundary represents dispatch readiness, targets, and approval gates without queue or worker behavior.

## Constraints Preserved
- No execution logic introduced in these packs
- No worker/queue/runtime dispatch logic introduced
- No scheduler/orchestration engine behavior introduced
- No storage/database logic introduced
- No adaptive/self-modifying logic introduced
- No external integration calls introduced

## Known Follow-up Considerations
- Some cross-layer link fields still assume canonical IDs that may need to be standardized across upstream record types.
- Some abstract target/reference fields may later be tightened to existing union types where useful.
- These are not blocking for current contract-layer progress.

## Recommended Next Step
Next recommended architecture layer:
- Supervisory Run Session Contracts

Rationale:
The current supervisory contract stack is now broad enough that the next useful boundary is the session/run layer that ties together:
- planning
- routing
- task generation
- dispatch readiness
- auditability

## Build Strategy
Continue with:
- small pack
- review
- then next pack

Do not move into implementation-heavy runtime behavior before run/session boundaries are explicitly locked.
