# Codex Workflow Loop v1

This defines the standard workflow for using Codex in the Pertti codebase.

Purpose:
- make Codex usage systematic
- reduce trial-and-error
- improve output quality over iterations
- enforce prompt discipline

--------------------------------
CORE LOOP
--------------------------------

1. DEFINE
2. SELECT TEMPLATE
3. BUILD PROMPT
4. SCORE PROMPT
5. RUN CODEX
6. EVALUATE OUTPUT
7. FIX OR ACCEPT

Repeat until acceptable.

--------------------------------
STEP 1 — DEFINE
--------------------------------

Define the task clearly.

Answer:
- What exactly needs to be built?
- Which file or module?
- What is the responsibility?

Good:
"Implement ExecutionHandoff type contracts in src/types/executionHandoff.ts"

Bad:
"Improve handoff system"

--------------------------------
STEP 2 — SELECT TEMPLATE
--------------------------------

Use AUTO_TEMPLATE_SELECTOR.md

Choose:

- TYPE
- PURE FUNCTION
- BOUNDARY
- MASTER

If unclear:
→ split the task

--------------------------------
STEP 3 — BUILD PROMPT
--------------------------------

Use Codex Prompt Pack v1.

Include:

- TASK
- GOAL
- STRICT SCOPE
- OUT OF SCOPE
- OUTPUT RULES

Recommended:
- ARCHITECTURE CONTEXT
- ACCEPTANCE CRITERIA

--------------------------------
STEP 4 — SCORE PROMPT
--------------------------------

Use PROMPT_SCORING_SYSTEM.md

Quick rule:
- < 35 → improve prompt
- 35–42 → usable
- 43+ → production-ready

Fast check:
- is scope explicit?
- is output defined?
- is task concrete?

--------------------------------
STEP 5 — RUN CODEX
--------------------------------

Send prompt to Codex.

Do NOT modify mid-run.

--------------------------------
STEP 6 — EVALUATE OUTPUT
--------------------------------

Check:

1. Scope
- Did it modify only allowed files?

2. Architecture
- Did it respect boundaries?

3. Completeness
- Did it implement everything requested?

4. Simplicity
- Is it minimal and clear?

5. Correctness
- Does it match the prompt?

--------------------------------
STEP 7 — FIX OR ACCEPT
--------------------------------

IF GOOD:
→ accept and move on

IF BAD:
→ DO NOT rewrite from scratch immediately

Instead:
1. Identify failure type (see CODEX_FAILURE_RECOVERY.md)
2. Add targeted constraints
3. Re-run

--------------------------------
FAST ITERATION MODE
--------------------------------

Loop:

prompt → run → fix → run → fix → done

Goal:
- converge quickly
- avoid large rewrites

--------------------------------
WHEN TO STOP
--------------------------------

Stop when:

- scope is correct
- architecture is respected
- implementation is minimal
- output matches intent

Not when:
- it feels "perfect"

--------------------------------
COMMON FAILURE LOOPS
--------------------------------

Looping problem:
- prompt too vague
→ fix: increase specificity

Looping problem:
- Codex overbuilds
→ fix: tighten scope

Looping problem:
- wrong abstraction
→ fix: enforce abstraction level

--------------------------------
GOLDEN RULE
--------------------------------

Do not fight Codex output.

Guide it.

Better prompt → better output.

--------------------------------
OPTIMIZED LOOP (SHORT VERSION)
--------------------------------

1. Define task
2. Pick template
3. Build prompt
4. Score (quick)
5. Run
6. Evaluate
7. Fix or accept

--------------------------------
TEAM USAGE
--------------------------------

All Codex work should follow this loop.

Benefits:
- predictable output
- consistent code quality
- reduced debugging time
- shared mental model

--------------------------------
FINAL PRINCIPLE
--------------------------------

Codex is not a coder.

It is a prompt-driven compiler.

Your prompt is the program.
