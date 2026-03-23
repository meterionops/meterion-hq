# Pertti Change Rules

This document defines how changes to Pertti must be made.

The goal is to ensure:
- stability
- auditability
- traceability
- controlled evolution

---

## 1. Core Principle

Pertti must evolve through explicit, reviewable changes.

No silent mutation.
No hidden behavior.
No implicit architecture changes.

---

## 2. Types of Changes

All changes fall into one of these categories:

### 2.1 Contract Changes
- changes in `src/types/`
- affects system boundaries

### 2.2 Architecture Changes
- new layers
- modified flows
- new subsystems

### 2.3 Workflow Changes
- changes to development rules
- changes to Codex usage
- changes to GitHub structure

### 2.4 Documentation Changes
- updates to `docs/pertti/`
- clarifications of system behavior

### 2.5 State Updates
- checkpoint updates in `state/`
- current snapshot updates in `projects/`

---

## 3. Allowed Change Pattern

All changes should follow this flow:

1. Define change in chat
2. Clarify scope and constraints
3. (If needed) create Codex prompt
4. Generate/update files
5. Review result
6. Accept or refine
7. Save to GitHub
8. Create checkpoint if significant

---

## 4. Contract Change Rules

When modifying `src/types/`:

- Do not break existing contracts silently
- Prefer additive changes over destructive ones
- If breaking change is required:
  - document it
  - justify it
  - checkpoint it

### Rule

Contracts define system boundaries.  
They must be stable and intentional.

---

## 5. Architecture Change Rules

When adding or modifying layers:

- Define clear position in architecture
- Define inputs and outputs explicitly
- Maintain separation of concerns
- Do not mix:
  - reasoning
  - memory
  - strategy
  - execution

### Required

- update docs (`docs/pertti/`)
- checkpoint after acceptance

---

## 6. No Silent Mutation Rule

The following are forbidden:

- changing behavior without documentation
- modifying contracts without visibility
- introducing implicit logic into “pure” layers
- mixing execution logic into advisory layers

All meaningful changes must be visible in:
- GitHub
- commit history
- documentation

---

## 7. Codex Usage Rules

Codex must not introduce uncontrolled changes.

### Required:

- use explicit prompts
- define scope clearly
- define out-of-scope explicitly
- restrict file edits

### Forbidden:

- “fix everything” prompts
- undefined refactors
- cross-layer implicit changes

---

## 8. Review Rule

Every important change must be:

- reviewed in chat
- understood before acceptance
- aligned with architecture

### Questions to ask:

- Does this respect separation of concerns?
- Does this introduce hidden behavior?
- Does this break any contract?
- Is this traceable later?

---

## 9. Checkpoint Rule

Create a checkpoint when:

- finishing a major layer
- completing a contract family
- introducing a new subsystem
- making a structural change

Checkpoint should include:

- updated `state/current-state.md`
- updated docs if needed
- clear commit message

---

## 10. Rollback Safety

Changes must be reversible.

### Therefore:

- avoid large unreviewed commits
- keep changes scoped
- use meaningful commit messages
- prefer incremental evolution

---

## 11. Change Visibility

Every important change must be visible through:

- Git commit history
- updated documentation
- clear file structure

No important decision should exist only in chat.

---

## 12. Bottom Line

Pertti evolves through:

- explicit changes
- visible decisions
- controlled updates

Not through:

- implicit behavior
- silent mutation
- uncontrolled generation

---

## Rule Summary

- No silent changes
- No hidden logic
- No uncontrolled Codex use
- No architecture drift

All changes must be:

> explicit, reviewable, and recoverable
