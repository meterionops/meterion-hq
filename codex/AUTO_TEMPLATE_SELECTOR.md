# Auto-Template Selector v1

Use this selector before writing a Codex prompt in the Pertti codebase.

Purpose:
- choose the correct prompt template fast
- reduce prompt-shape mistakes
- improve Codex output consistency
- keep work aligned with architectural intent

--------------------------------
TEMPLATE OPTIONS
--------------------------------

1. TYPE
2. PURE FUNCTION
3. BOUNDARY
4. MASTER

--------------------------------
QUICK DECISION RULE
--------------------------------

Ask:

What is the main thing being created?

- types / interfaces / contracts only -> TYPE
- deterministic logic / mapper / builder / evaluator -> PURE FUNCTION
- translation layer / adapter / handoff / routing boundary -> BOUNDARY
- other tightly scoped implementation -> MASTER

--------------------------------
DECISION TREE
--------------------------------

STEP 1

Is the task mainly about defining shapes, contracts, or type structures?

Examples:
- src/types/...
- input/output contracts
- envelope types
- governance types
- recommendation types
- handoff contracts
- adapter contract definitions

If YES -> use TYPE
If NO -> go to Step 2

--------------------------------
STEP 2

Is the task mainly about implementing deterministic logic with explicit inputs and outputs?

Examples:
- buildX(...)
- mapXToY(...)
- composeX(...)
- evaluateX(...)
- create read model
- build dashboard view
- pure world-model helper
- deterministic planner helper

If YES -> use PURE FUNCTION
If NO -> go to Step 3

--------------------------------
STEP 3

Is the task mainly about bridging, translating, packaging, routing, or preserving boundaries between layers?

Examples:
- adapter layer
- execution handoff builder
- proposal packaging layer
- review envelope builder
- routing boundary
- adapter resolver
- transformation boundary
- execution surface translator

If YES -> use BOUNDARY
If NO -> go to Step 4

--------------------------------
STEP 4

Is it still a tightly scoped engineering task, but not clearly one of the above?

Examples:
- small targeted refactor
- limited export surface update
- constrained module cleanup
- single-file implementation with mixed but controlled concerns

If YES -> use MASTER
If NO -> split the task before prompting Codex

--------------------------------
GOLDEN RULE
--------------------------------

Choose based on the dominant responsibility.

Do not choose based on:
- what sounds sophisticated
- how large the task feels
- what template you used last time

Choose based on:
- what the file/module is primarily responsible for

--------------------------------
MAPPING TABLE
--------------------------------

Type-only contract file
-> TYPE

New src/types/... file
-> TYPE

Union / interface / envelope definitions
-> TYPE

Pure builder
-> PURE FUNCTION

Pure mapper
-> PURE FUNCTION

Deterministic evaluator
-> PURE FUNCTION

Dashboard read-model builder
-> PURE FUNCTION

Execution handoff builder
-> BOUNDARY

Adapter resolver
-> BOUNDARY

Surface translator
-> BOUNDARY

Proposal packaging boundary
-> BOUNDARY

Governance review bridge
-> BOUNDARY

Small scoped implementation that does not fit cleanly elsewhere
-> MASTER

--------------------------------
WHEN TO SPLIT THE TASK
--------------------------------

Split the task before prompting Codex if it includes multiple dominant responsibilities.

Examples of tasks that should be split:

Bad:
- define types
- implement builder
- add execution flow

Better:
1. define type contracts
2. implement pure builder
3. implement boundary module

Another bad example:
- create adapter types
- add runtime orchestration
- wire scheduling

Better:
1. adapter contracts
2. boundary mapping
3. runtime orchestration later

--------------------------------
ANTI-PATTERNS
--------------------------------

Do NOT use TYPE when:
- real logic is required
- transformation behavior is central

Do NOT use PURE FUNCTION when:
- the main job is translating across architectural boundaries
- traceability and packaging are core concerns

Do NOT use BOUNDARY when:
- no real boundary exists
- the task is just local deterministic logic

Do NOT use MASTER as the default for everything.
Use MASTER only when the task is tightly scoped but does not cleanly fit the other three.

--------------------------------
FAST SELECTOR
--------------------------------

Use this mini-check:

A. Is it types only?
-> TYPE

B. Is it pure deterministic logic?
-> PURE FUNCTION

C. Is it a bridge/adapter/handoff/routing layer?
-> BOUNDARY

D. None of the above, but still tightly scoped?
-> MASTER

--------------------------------
EXAMPLES
--------------------------------

Example:
"Create src/types/recommendationEnvelope.ts"
-> TYPE

Example:
"Implement buildDashboardSupervisoryView from dashboard input"
-> PURE FUNCTION

Example:
"Implement buildExecutionHandoff from adapter outputs"
-> BOUNDARY

Example:
"Update index.ts exports for a new contract module"
-> MASTER

--------------------------------
FINAL RULE
--------------------------------

If the task seems to require more than one template,
the task probably needs to be split first.
