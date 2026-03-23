# Codex Prompt Pack v1

This folder contains the standard Prompt Pack for Codex work in the Pertti codebase.

## Purpose

Use these templates to keep Codex output:

- strictly scoped
- architecture-aware
- deterministic where required
- explicit about boundaries
- minimal in surface area
- consistent across the repo

## Prompt Library

- `PERTTI_CODEX_MASTER_PROMPT.md`  
  General-purpose template for tightly scoped Codex work.

- `PERTTI_CODEX_TYPE_CONTRACT_PROMPT.md`  
  Use for new `src/types/...` files, contract layers, envelopes, adapter IO types, governance types, and handoff types.

- `PERTTI_CODEX_PURE_FUNCTION_PROMPT.md`  
  Use for deterministic builders, mappers, evaluators, composition modules, and other pure-function logic.

- `PERTTI_CODEX_BOUNDARY_PROMPT.md`  
  Use for adapter layers, boundary translators, routing boundaries, handoff boundaries, and review / proposal packaging boundaries.

## Default Working Rule

Always choose the prompt class first, then fill in the task.

1. Type contract file
2. Pure function module
3. Boundary / adapter module
4. Master template for anything else tightly scoped

## Hardening Block

Add this block when you want Codex to behave more conservatively around uncertain repo state:

```text
--------------------------------
SAFETY / DISCIPLINE RULES
--------------------------------

- If a referenced type or export does not exist exactly as expected, do not invent a replacement blindly.
- Prefer verified existing exports first.
- If necessary, preserve the architectural intent with the smallest possible local definition inside the allowed file.
- Do not expand scope to compensate for uncertainty.
- When in doubt, choose the narrower implementation.
```

## Output Discipline

Unless intentionally overridden, Codex prompts in this pack should enforce:

- no prose
- no markdown fences
- no explanations
- no diff format
- no extra files

## Suggested Usage Pattern

- Put the architectural context high in the prompt.
- Keep scope and out-of-scope explicit.
- Define exact deliverables.
- Define acceptance criteria.
- Prefer explicit boundaries over inferred behavior.

## Prompt Rules

See PROMPT_LINT_RULES.md for writing guidelines and anti-patterns.

## Prompt Quality

See PROMPT_SCORING_SYSTEM.md for pre-flight prompt evaluation.

## Template Selection

See AUTO_TEMPLATE_SELECTOR.md for choosing the correct prompt template.

## Starters

Use starter prompts to initialize a new chat:

- PROJECT_STARTER_PROMPT.md
- CODEX_STARTER_PROMPT.md
- ARCHITECTURE_STARTER_PROMPT.md
