# Codex Task Registry v1

A lightweight registry for tracking Codex work in the Pertti workflow.

## Purpose

Use this registry to connect:

- task -> prompt
- prompt -> output
- output -> commit / PR
- commit / PR -> review outcome

This is intentionally lightweight.

It is **not** a task platform, workflow engine, or dashboard.

## Design Principles

- keep the system simple
- prefer GitHub as source of truth
- make prompt lineage visible
- support auditability without overhead
- make review easier

## Minimum Record

Each Codex task should capture the following fields:

```yaml
task_id: CT-YYYYMMDD-001
date: YYYY-MM-DD
title: Short descriptive title
goal: One-sentence statement of what should be built
template_used: TYPE | PURE_FUNCTION | BOUNDARY | MASTER
starter_used: PROJECT | CODEX | ARCHITECTURE | none
prompt_location: path, issue link, PR comment link, or pasted reference
target_files:
  - path/to/file.ts
status: drafted | prompted | generated | reviewed | merged | rejected
review_status: pending | approved | changes_requested | rejected
codex_output_summary: Short summary of what Codex produced
related_commit: commit sha or none
related_pr: PR link/number or none
notes:
  - optional note
```

## Required Fields

These fields should exist for every task:

- `task_id`
- `date`
- `title`
- `goal`
- `template_used`
- `prompt_location`
- `target_files`
- `status`
- `review_status`

## Recommended Fields

Use these whenever available:

- `starter_used`
- `codex_output_summary`
- `related_commit`
- `related_pr`
- `notes`

## Status Model

### Task Status

- `drafted` = task idea exists, prompt not finalized
- `prompted` = Codex-ready prompt exists
- `generated` = Codex has produced output
- `reviewed` = output has been reviewed
- `merged` = accepted and merged
- `rejected` = intentionally discarded

### Review Status

- `pending`
- `approved`
- `changes_requested`
- `rejected`

## File Layout Options

Choose one of these lightweight approaches.

### Option A — Single Registry File

Use one file:

```text
/codex/tasks/registry.md
```

Best when task volume is low.

### Option B — One File Per Task

Use:

```text
/codex/tasks/CT-YYYYMMDD-001.md
/codex/tasks/CT-YYYYMMDD-002.md
```

Best when task volume grows and you want easier traceability.

## Recommended v1 Choice

Start with **Option B**.

Reason:
- cleaner history
- simpler reviews
- easier linking to commits and PRs
- no merge conflicts from one shared registry file

## Task File Template

Use this template for each task file:

```md
# CT-YYYYMMDD-001 — Task Title

## Metadata

- Date: YYYY-MM-DD
- Template Used: TYPE | PURE_FUNCTION | BOUNDARY | MASTER
- Starter Used: PROJECT | CODEX | ARCHITECTURE | none
- Status: drafted | prompted | generated | reviewed | merged | rejected
- Review Status: pending | approved | changes_requested | rejected

## Goal

One-sentence goal.

## Prompt Location

- path / link / issue / PR comment reference

## Target Files

- path/to/file.ts
- path/to/other.ts

## Codex Output Summary

Short summary of what Codex produced.

## Traceability

- Related Commit: sha or none
- Related PR: link / number or none

## Notes

- optional note
```

## Naming Convention

Use:

```text
CT-YYYYMMDD-001
```

Examples:
- `CT-20260323-001`
- `CT-20260323-002`

If multiple tasks are created the same day, increment the final number.

## Recommended Workflow

1. Create task record
2. Build prompt using Codex Prompt Pack v1
3. Run Codex
4. Update task status to `generated`
5. Review output
6. Link commit or PR
7. Mark as `merged` or `rejected`

## Example Task

```md
# CT-20260323-001 — Execution Handoff Contracts

## Metadata

- Date: 2026-03-23
- Template Used: TYPE
- Starter Used: CODEX
- Status: merged
- Review Status: approved

## Goal

Define type-only Execution Handoff contracts for adapter-family packaging.

## Prompt Location

- meterion-hq/codex/examples/build-execution-handoff.md

## Target Files

- src/types/executionHandoff.ts

## Codex Output Summary

Created a type-only contract file with handoff bundle, input, output, and engine interface.

## Traceability

- Related Commit: abc1234
- Related PR: #12

## Notes

- Kept handoff non-executing.
- Preserved adapter-family separation.
```

## Review Rule

A Codex task is not complete until:

- output has been reviewed
- commit or PR is linked when applicable
- final status is recorded

## Final Principle

Keep the registry lightweight.

If the registry becomes painful to maintain, it is too heavy for v1.
