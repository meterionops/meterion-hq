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
