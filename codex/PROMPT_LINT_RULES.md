# Codex Prompt Lint Rules v1

These rules define how Codex prompts should be written inside the Pertti codebase.

Purpose:
- reduce ambiguity
- enforce architectural discipline
- improve output consistency
- prevent scope creep

--------------------------------
CORE PRINCIPLE
--------------------------------

A good Codex prompt is:
- scoped
- explicit
- architecture-aware
- minimal
- deterministic where required

--------------------------------
ANTI-PATTERNS (DO NOT DO)
--------------------------------

1. VAGUE TASKS

❌ Bad:
"Improve this system"
"Refactor this module"
"Make this better"

✅ Good:
"Implement a type contract for X with fields Y and Z"

---

2. MISSING SCOPE

❌ Bad:
"Update the codebase to support handoff"

✅ Good:
"Modify only src/types/executionHandoff.ts"

---

3. MIXING RESPONSIBILITIES

❌ Bad:
"Implement type + logic + execution"

✅ Good:
"Define type-only contracts"

---

4. HIDDEN EXECUTION

❌ Bad:
"Handle execution if needed"

✅ Good:
"No execution logic allowed"

---

5. IMPLICIT BEHAVIOR

❌ Bad:
"Do what's necessary"

✅ Good:
"Map input A → output B explicitly"

---

6. OVERLY LARGE TASKS

❌ Bad:
"Implement full pipeline"

✅ Good:
"Implement only the boundary layer"

---

7. MISSING OUTPUT RULES

❌ Bad:
(no output instructions)

✅ Good:
"Return ONLY the file contents"

---

8. INVENTING STRUCTURE

❌ Bad:
"Create any structure you see fit"

✅ Good:
"Use existing types from ./executionContext"

---

9. NO ARCHITECTURE CONTEXT

❌ Bad:
(no context)

✅ Good:
"This sits between Planner and Execution"

---

10. NON-DETERMINISTIC REQUIREMENTS

❌ Bad:
"Handle edge cases smartly"

✅ Good:
"Do not introduce hidden branching logic"

--------------------------------
REQUIRED ELEMENTS (CHECKLIST)
--------------------------------

Every Codex prompt SHOULD include:

[ ] TASK
[ ] GOAL
[ ] STRICT SCOPE
[ ] OUT OF SCOPE
[ ] OUTPUT RULES

Recommended:

[ ] ARCHITECTURE CONTEXT
[ ] ACCEPTANCE CRITERIA

--------------------------------
TEMPLATE SELECTION RULE
--------------------------------

Before writing a prompt, classify it:

1. Type contract → use TYPE template
2. Pure logic → use PURE FUNCTION template
3. Boundary → use BOUNDARY template
4. Other scoped task → use MASTER template

--------------------------------
SCOPE DISCIPLINE
--------------------------------

Always define:

- allowed files
- forbidden changes
- execution constraints

Golden rule:

👉 If the task could expand, it will expand.

Prevent that explicitly.

--------------------------------
OUTPUT DISCIPLINE
--------------------------------

Default rule:

- no prose
- no markdown fences
- no explanations
- no extra files

--------------------------------
HARDENING (WHEN NEEDED)
--------------------------------

Add this block when repo state may be unclear:

--------------------------------
SAFETY / DISCIPLINE RULES
--------------------------------

- Do not invent missing types blindly
- Prefer verified existing exports
- Keep implementation minimal
- Do not expand scope
- When in doubt, choose the narrower solution

--------------------------------
FINAL RULE
--------------------------------

If a prompt feels "easy to misunderstand",
it is a bad prompt.

Make it more explicit.
