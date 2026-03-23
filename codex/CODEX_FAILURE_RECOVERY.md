# Codex Failure Recovery System v1

This guide defines how to recover when Codex output is incorrect, over-scoped, or inconsistent.

Purpose:
- fix bad outputs fast
- avoid rewriting prompts from scratch
- enforce architectural discipline
- keep iteration cycles tight

--------------------------------
CORE PRINCIPLE
--------------------------------

Do NOT start over immediately.

First:
→ identify failure type
→ apply targeted correction
→ re-run with tighter constraints

--------------------------------
FAILURE TYPES
--------------------------------

1. OVER-SCOPING
2. HIDDEN EXECUTION
3. WRONG ABSTRACTION LEVEL
4. INVENTED TYPES / IMPORTS
5. TOO MANY FILES
6. MISSING OUTPUT DISCIPLINE
7. ARCHITECTURE VIOLATION

--------------------------------
1. OVER-SCOPING
--------------------------------

Symptoms:
- modifies multiple files
- adds extra layers
- introduces new concepts not requested

Fix:

Add:

"STRICT SCOPE:
- Modify ONLY: {file}
- Do not create additional files
- Do not expand beyond requested responsibility"

Re-run.

--------------------------------
2. HIDDEN EXECUTION
--------------------------------

Symptoms:
- adds runtime logic in type layer
- introduces side effects
- adds orchestration

Fix:

Add:

"CONSTRAINTS:
- No execution logic
- No side effects
- No orchestration
- This layer is non-executing"

Re-run.

--------------------------------
3. WRONG ABSTRACTION LEVEL
--------------------------------

Symptoms:
- too high-level (vague wrappers)
- too low-level (unnecessary details)

Fix:

Add:

"ABSTRACTION RULE:
- Stay at the same abstraction level as surrounding modules
- Do not introduce new layers
- Do not generalize beyond this file"

Re-run.

--------------------------------
4. INVENTED TYPES / IMPORTS
--------------------------------

Symptoms:
- uses types that do not exist
- guesses import names
- breaks compilation

Fix:

Add:

"IMPORT RULES:
- Inspect existing exports first
- Use exact existing type names only
- Do not invent substitute types
- If uncertain, keep definitions local and minimal"

Re-run.

--------------------------------
5. TOO MANY FILES
--------------------------------

Symptoms:
- splits into multiple files
- adds helpers in new modules

Fix:

Add:

"FILE CONSTRAINT:
- Implement everything inside the target file
- Do not create additional files"

Re-run.

--------------------------------
6. MISSING OUTPUT DISCIPLINE
--------------------------------

Symptoms:
- includes explanations
- includes markdown
- includes commentary

Fix:

Add:

"OUTPUT RULES:
- Return ONLY the file contents
- No prose
- No markdown fences
- No explanations"

Re-run.

--------------------------------
7. ARCHITECTURE VIOLATION
--------------------------------

Symptoms:
- mixes types + execution
- leaks boundary logic into core
- breaks layer separation

Fix:

Add:

"ARCHITECTURE CONSTRAINT:
- Respect layer boundaries
- Do not mix responsibilities
- Keep contracts, logic, and execution separate"

Re-run.

--------------------------------
FAST RECOVERY MODE
--------------------------------

If multiple issues exist, add:

"STRICT MODE:
- Do not expand scope
- Do not invent missing structures
- Keep implementation minimal
- Follow instructions exactly"

--------------------------------
WHEN TO REWRITE PROMPT
--------------------------------

Rewrite instead of patching if:

- task is unclear
- multiple responsibilities are mixed
- template choice is wrong
- scope cannot be expressed cleanly

--------------------------------
GOLDEN RULE
--------------------------------

Bad output is usually caused by:
→ unclear scope
→ missing constraints
→ wrong template

Fix the prompt, not the code.
