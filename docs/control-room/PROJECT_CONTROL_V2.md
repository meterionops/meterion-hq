# Meterion Control Room — Project Control v2

Status: IMPLEMENTED DESIGN / 2026-09-19

## Purpose

Project Control v2 adds a bounded execution-control packet to the existing versioned Project State.

It does not turn Control Room into a task manager and it does not replace project masters, source systems, GitHub, Supabase or Google Drive.

The Control Room remains the quiet cross-project orientation layer.

## Canonical boundaries

Detailed project truth remains in source systems.

- Google Drive: charter, locked master, decisions, launch criteria and Project Control File
- GitHub: implementation, tests and releases
- Supabase / production system: operational and data reality
- Jev: high-impact uncertainty gates
- Control Room: bounded current control state and resume-anywhere orientation

## Added Project State fields

- current_build
- definition_of_done
- next_gate
- gate_status: none | open | passed | blocked | investigate
- next_autonomous_run
- stop_gates[]
- locked_decisions[]
- last_jev_decision
- last_jev_confidence

Project Control File itself is represented as a Drive connection with metadata role=project_control.

## Read contracts

- control_room_get_project_state_v3(project_key)
- control_room_get_projects_surface_v3(...)
- control_room_get_resume_packet_v2(project_key)

The existing v1/v2 read models are retained for backwards compatibility.

## Write contract

control_room_append_project_state_v2(project_key, expected_version, state)

Project State remains append-only and optimistic-concurrency protected.

## UI

Project rows may show the next gate as a compact status tag.

Project detail adds a Project Control block with:

1. Current build
2. Definition of done
3. Next gate + gate status
4. Next autonomous run
5. Stop gates
6. Locked-decision count
7. Last Jev decision/confidence
8. Project Control File link

The rest of the existing resume-anywhere state remains visible below it.

## Rule

Control Room stores only the bounded control packet needed for orientation and execution boundaries.

If a field requires long prose, source evidence, a complete roadmap or detailed decision history, keep it in the source system and link it rather than copying it into Control Room.
