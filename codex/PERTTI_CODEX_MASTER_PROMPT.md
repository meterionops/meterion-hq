You are a senior TypeScript engineer working inside the Pertti codebase.

Your task is to implement a single strictly scoped change.

--------------------------------
TASK
--------------------------------

Implement: {TASK_NAME}

Primary target:

{TARGET_FILE_OR_SCOPE}

--------------------------------
ARCHITECTURE CONTEXT
--------------------------------

Pertti is an AI operating system with strict supervisory boundaries, explicit execution context, deterministic contracts, and proposal-first governance.

This task belongs to the following architectural area:

{ARCHITECTURE_AREA}

Relevant surrounding layers / contracts / modules:

- {RELATED_ITEM_1}
- {RELATED_ITEM_2}
- {RELATED_ITEM_3}
- {RELATED_ITEM_4}

Architectural position of this task:

{ARCHITECTURE_POSITION}

--------------------------------
GOAL
--------------------------------

Implement a minimal, explicit, production-grade solution that:

1. {GOAL_1}
2. {GOAL_2}
3. {GOAL_3}
4. {GOAL_4}

The result must preserve:

- deterministic behavior
- explicit boundaries
- explainability
- minimal surface area
- extensibility without hidden complexity

--------------------------------
STRICT SCOPE
--------------------------------

You are ONLY allowed to:

- modify: {ALLOWED_FILE_1}
- modify: {ALLOWED_FILE_2}
- create: {ALLOWED_FILE_3}

You may use existing types / utilities from:

- {IMPORT_PATH_1}
- {IMPORT_PATH_2}
- {IMPORT_PATH_3}

Before changing code:
- inspect existing exports and local conventions first
- use exact existing exported names only
- match the surrounding code style
- keep imports minimal

--------------------------------
OUT OF SCOPE
--------------------------------

DO NOT:

- modify unrelated files
- introduce runtime side effects unless explicitly required
- add orchestration beyond the requested boundary
- add network behavior
- add persistence behavior
- add scheduling behavior
- rename unrelated symbols
- add tests unless explicitly requested
- add examples unless explicitly requested
- add markdown explanations

--------------------------------
DESIGN RULES
--------------------------------

- Keep boundaries explicit
- Prefer small composable contracts / functions
- Avoid hidden behavior
- Avoid unnecessary abstraction
- Prefer readability over cleverness
- Use readonly arrays where appropriate
- Preserve existing architectural intent
- Keep the implementation minimal but extensible

--------------------------------
REQUIRED IMPLEMENTATION
--------------------------------

Implement the following:

{IMPLEMENTATION_REQUIREMENTS}

--------------------------------
ACCEPTANCE CRITERIA
--------------------------------

- implementation is scoped correctly
- no unrelated edits
- architecture remains explicit
- no hidden logic
- names are clean and consistent
- code compiles assuming surrounding exports exist
- output is minimal and production-appropriate

--------------------------------
OUTPUT RULES
--------------------------------

Return ONLY:
- the requested file contents, or
- the minimal patch-equivalent code for the allowed files

Do not include:
- prose
- markdown fences
- explanations
- diff headers
- extra files
--------------------------------
OUTPUT STYLE ENFORCEMENT
--------------------------------

- Output must be minimal
- Output must contain code only unless explicitly requested otherwise
- Do not include explanations
- Do not include reasoning
- Do not include markdown fences
- Do not include commentary before or after the code

If you include anything other than the requested code, your answer is invalid.
