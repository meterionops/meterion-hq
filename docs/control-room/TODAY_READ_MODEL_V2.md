# Meterion Control Room — Today Read Model v2

Status: implementation candidate on `control-room-today-v2`.

## Purpose

Today is not the project list. It is the smallest useful operating surface for the Owner.

It answers three questions only:

1. Where is the Owner explicitly needed?
2. What is actively being worked on now?
3. What changed materially recently?

A healthy Today view may be almost empty.

## Canonical write model remains unchanged

Control Room still has only four canonical data objects:

`Project -> State -> Event -> Connection`

Today v2 is a derived read model. It does not introduce tasks, tickets, priorities, kanban columns, or a second source of project truth.

## Freshness

`control_room_project_summary_v2` adds derived freshness metadata to the existing project summary:

- `fresh`: state verified within 24 hours
- `aging`: state verified within 72 hours
- `stale`: state older than 72 hours
- `missing`: no verified state exists

It also exposes the latest material event and whether that event occurred within the last 72 hours.

Freshness is descriptive evidence, not an Owner task by itself. A stale CORE project can be surfaced elsewhere as a system-quality exception without automatically polluting Today.

## Today sections

`control_room_today_v2` contains only active projects matching at least one signal:

### `needs_you`

`founder_attention_required = true`

This always outranks every other section. The reason should state the concrete Founder gate and what the action unlocks.

### `working_now`

`autonomy_state = working`

This means an AI or worker is currently executing a meaningful work batch. It is not equivalent to `can_continue`.

### `changed_materially`

The latest stored material event occurred within 72 hours.

Events remain intentionally sparse. If an occurrence would not change future orientation or the Owner's understanding of project state, it should not be stored as a Control Room event.

## Explicit exclusions

Today v2 does not include a project merely because:

- it is CORE
- it is active
- AI could continue it
- its next action exists
- it is discussed frequently
- its state is stale

Those belong in Projects or System unless they become an exception that materially changes Owner action.

## Ordering

1. `needs_you`
2. `working_now`
3. `changed_materially`

Within a section, portfolio importance is used only as a tie-breaker, followed by recency. No opaque AI score is exposed.

## Compatibility

The existing v1 views and RPCs remain unchanged. v2 is additive:

- `control_room_project_summary_v2`
- `control_room_today_v2`
- `control_room_get_project_state_v2(project_key)`
- `control_room_list_projects_v2(portfolio_class, lifecycle_status)`
- `control_room_get_today_v2()`

The ChatGPT MCP can migrate from v1 to v2 after validation. The current Business full-MCP rollout blocker does not block the read-model work.
