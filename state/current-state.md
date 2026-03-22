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
