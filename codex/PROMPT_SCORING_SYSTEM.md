# Codex Prompt Scoring System v1

This scoring system is used to evaluate Codex prompts before they are used in the Pertti codebase.

Purpose:
- improve prompt quality
- reduce ambiguity
- prevent scope creep
- increase output consistency
- enforce architectural discipline

--------------------------------
HOW TO SCORE
--------------------------------

Score each category from 0 to 5.

0 = missing / very poor
1 = weak
2 = incomplete
3 = acceptable
4 = strong
5 = excellent

Total score:
- 0–15  = weak prompt
- 16–24 = usable but risky
- 25–34 = good
- 35–42 = very good
- 43–50 = production-grade

--------------------------------
SCORING CATEGORIES
--------------------------------

1. TASK CLARITY
2. GOAL QUALITY
3. SCOPE DISCIPLINE
4. ARCHITECTURE CONTEXT
5. OUT-OF-SCOPE CONTROL
6. IMPLEMENTATION SPECIFICITY
7. OUTPUT DISCIPLINE
8. DETERMINISM / SAFETY
9. ACCEPTANCE CRITERIA
10. TEMPLATE FIT

--------------------------------
1. TASK CLARITY
--------------------------------

Question:
Is the task concrete, explicit, and easy to understand?

0
- task is vague or generic
- example: "improve this"

3
- task is understandable
- outcome is mostly clear

5
- task is precise
- target is obvious
- deliverable is obvious

Strong example:
"Implement a type-only contract for ExecutionHandoffBundle in src/types/executionHandoff.ts"

--------------------------------
2. GOAL QUALITY
--------------------------------

Question:
Does the prompt clearly explain what the result should achieve?

0
- no real goal
- only an action request

3
- goal exists but is partial

5
- goal is explicit
- architectural purpose is clear
- success direction is obvious

Strong example:
"Define a pure type-only contract layer that supports partial handoff and preserves adapter-family traceability"

--------------------------------
3. SCOPE DISCIPLINE
--------------------------------

Question:
Does the prompt tightly constrain where Codex is allowed to work?

0
- no file limits
- open-ended task

3
- some limits exist
- still room for drift

5
- exact file scope is defined
- allowed changes are explicit
- scope is hard to misread

Strong example:
"Create only src/types/executionHandoff.ts. Do not modify existing files."

--------------------------------
4. ARCHITECTURE CONTEXT
--------------------------------

Question:
Does the prompt explain where this work sits in the Pertti architecture?

0
- no architecture context

3
- some context exists
- relation to other layers is partly clear

5
- position in the architecture is explicit
- upstream and downstream context is visible

Strong example:
"This sits between Execution Surface Bridge and future runtime systems."

--------------------------------
5. OUT-OF-SCOPE CONTROL
--------------------------------

Question:
Does the prompt clearly prevent unwanted expansion?

0
- no constraints
- Codex may expand freely

3
- some forbidden areas listed

5
- forbidden changes are explicit
- common expansion paths are blocked

Strong example:
"Do not implement runtime logic, orchestration, retries, scheduling, networking, or extra files."

--------------------------------
6. IMPLEMENTATION SPECIFICITY
--------------------------------

Question:
Does the prompt clearly define what should be implemented?

0
- implementation is mostly guesswork

3
- main structure is visible
- some ambiguity remains

5
- types/functions/fields/interfaces are clearly defined
- Codex does not need to invent much

Strong example:
"Define HandoffStatus, AdapterPackageType, HandoffTrace, ExecutionHandoffBundle, ExecutionHandoffInput, ExecutionHandoffOutput, and ExecutionHandoffEngine"

--------------------------------
7. OUTPUT DISCIPLINE
--------------------------------

Question:
Does the prompt define exactly what Codex should return?

0
- no output rule

3
- output is partly constrained

5
- output format is explicit
- extra explanations are forbidden

Strong example:
"Return ONLY the full contents of src/types/executionHandoff.ts. No prose. No markdown fences. No extra files."

--------------------------------
8. DETERMINISM / SAFETY
--------------------------------

Question:
Does the prompt reduce hallucination risk and encourage narrow safe behavior?

0
- Codex is free to invent missing structure

3
- some safety constraints exist

5
- exact imports / verified exports / narrow behavior are emphasized
- prompt discourages invention and scope expansion

Strong example:
"Inspect existing exported type names first. Use exact existing export names only. When in doubt, choose the narrower solution."

--------------------------------
9. ACCEPTANCE CRITERIA
--------------------------------

Question:
Does the prompt define how success should be judged?

0
- no acceptance criteria

3
- success is implied but not explicit

5
- criteria are explicit and checkable

Strong example:
- clean separation from adapter-specific contracts
- partial handoff is supported
- traceability remains visible
- no execution semantics

--------------------------------
10. TEMPLATE FIT
--------------------------------

Question:
Was the correct prompt template chosen for the task?

0
- wrong template
- task shape and prompt structure do not match

3
- usable template but not ideal

5
- exact right template used
- task matches prompt class cleanly

Examples:
- type contract file -> TYPE template
- deterministic builder -> PURE FUNCTION template
- translation / handoff / routing layer -> BOUNDARY template
- other tightly scoped task -> MASTER template

--------------------------------
SCORING INTERPRETATION
--------------------------------

43–50
Production-grade prompt.
Safe to use for important Codex work.

35–42
Very good prompt.
Minor tightening may improve output, but already strong.

25–34
Good prompt.
Usable, but likely to benefit from better scope, output rules, or architecture context.

16–24
Usable but risky.
Codex may drift, overbuild, or invent structure.

0–15
Weak prompt.
Rewrite before use.

--------------------------------
FAST REVIEW MODE
--------------------------------

Before sending a prompt to Codex, ask:

1. Is the task concrete?
2. Is the file/scope explicit?
3. Is the architecture position clear?
4. Is out-of-scope explicit?
5. Is the output format explicit?

If any answer is "no", the prompt is not ready.

--------------------------------
RECOMMENDED MINIMUM BAR
--------------------------------

Minimum recommended score for normal use:
35+

Minimum recommended score for important architecture work:
40+

Minimum recommended score for core contract / governance / boundary work:
43+

--------------------------------
PROMPT REVIEW TEMPLATE
--------------------------------

Use this format to review a prompt:

Task Clarity: X/5
Goal Quality: X/5
Scope Discipline: X/5
Architecture Context: X/5
Out-of-Scope Control: X/5
Implementation Specificity: X/5
Output Discipline: X/5
Determinism / Safety: X/5
Acceptance Criteria: X/5
Template Fit: X/5

Total: X/50

Verdict:
- weak / risky / good / very good / production-grade

Main weaknesses:
- ...
- ...

Suggested improvements:
- ...
- ...
