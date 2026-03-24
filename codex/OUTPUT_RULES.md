# Codex Output Rules (Pertti)

This file defines the required output style for Codex work in the Pertti codebase.

## Purpose

Keep Codex output:

- minimal
- code-only by default
- strictly scoped
- easy to review
- consistent across tasks

## Default Output Rule

Unless explicitly requested otherwise, Codex output must contain:

- code only

Codex output must NOT contain:

- explanations
- reasoning
- markdown fences
- prose before code
- prose after code
- diff headers
- extra files
- comments that are not part of the existing file style

## Output Style Enforcement

Default rule for Pertti Codex work:

- output code only
- no prose
- no explanations
- no markdown fences
- no extra files unless explicitly requested

See OUTPUT_RULES.md for the required output style.

## Style Rules

Codex output should be:

- minimal
- production-appropriate
- deterministic where required
- aligned to existing file style
- free of unnecessary abstraction

## Invalid Output Examples

The following are invalid unless explicitly requested:

- "Here is the implementation..."
- "I updated the file to..."
- markdown code fences
- extra notes after the code
- architectural commentary inside the response

## Valid Output Examples

Valid output:

- the full contents of the requested file
- the minimal patch-equivalent code for the allowed file
- nothing else

## Enforcement Rule

Add this when output discipline must be strict:

```text
If you include anything other than the requested code, your answer is invalid.utput contains anything other than code, it is invalid.
## Implementation Size Rules

Codex must prefer the smallest readable correct implementation.

### Required

- keep implementations compact
- prefer flat logic over unnecessary indirection
- minimize number of helper functions
- reuse existing patterns instead of introducing new abstractions

### Avoid

- unnecessary helper functions
- layered wrappers without clear benefit
- “clean architecture” abstractions without immediate need
- over-generalization
- abstraction for hypothetical future use

### Decision rule

If two implementations are both correct:

- choose the smaller one
- unless it significantly harms readability

### Golden rule

Smallest readable production-grade implementation wins.
