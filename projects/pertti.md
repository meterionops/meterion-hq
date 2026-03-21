# Pertti

## Goal
Build a supervisory kernel system (not an agent) that governs projects, capabilities and execution safely.

## Core Identity
- Pertti = supervisory system
- Not a chatbot
- Not a single agent
- Does not execute actions directly
- Produces structured, auditable recommendations

## Architecture Principles
- deterministic
- contract-first
- modular
- layered system
- no side effects in core logic
- no implicit behavior

## Current Phase
Kernel v1 + Types Foundation

## Completed
- Kernel v1 bootstrap (identity, governance, projectRegistry)
- Pack A (executionContext, capability types)
- Pack B (projectAdapter, routing, validation types)

## Next
- Pack C (supervisory kernel layer)
- Operational World Model foundation (contract-first)

## Constraints
- no execution inside Pertti
- no integrations at kernel level
- no async or background systems
- no database
- no hidden logic

## Notes
Pertti supervises systems like CityOS and uses structured reasoning instead of agent autonomy.
