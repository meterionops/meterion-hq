Pertti Execution Surface v1
1. Purpose

This document defines the execution surface boundary between Pertti and external execution systems.

Execution Surface is the first layer where:

plans become actionable

tasks are mapped to real systems

execution becomes possible (but not automatic)

This layer is non-executing by design:

it does not run actions

it does not schedule work

it does not orchestrate workflows

It only defines:

what should be executed, where, and under what conditions

2. Position in Architecture

Execution Surface sits between:

Upstream:

planner

roleTask

taskDispatch

adapter resolution

Downstream:

OpenClaw

Codex

Human operators

External APIs

3. Core Principles

Binding, not execution

Explicit over implicit

Traceable to plan + task + dispatch

Capability-aware

Adapter-driven

No hidden orchestration

4. Execution Surface Model
4.1 Execution Surface Types

Defined in executionSurfaceBridge.ts:

openclaw

codex

human_operator

api_adapter

internal_tool

unknown

4.2 Surface Binding

Each execution surface binding defines:

target surface

linked plan / task / dispatch

adapter (if applicable)

rationale

binding status

4.3 Binding Status

unbound

partially_bound

bound

blocked

deferred

5. Execution Surface Package

The output of this layer:

ExecutionSurfacePackage

Contains:

all bindings

execution targets

traceability links

summary + notes

6. Data Flow
Plan
 → Plan Steps
 → Role Tasks
 → Dispatch Records
 → Adapter Resolution
 → Execution Surface Bridge
 → Surface Package
 → (External Execution System)
7. Adapter Model

Execution does NOT happen directly.

Instead:

Pertti → Adapter → External System

Adapters:

translate intent → execution format

enforce capability constraints

isolate Pertti from system-specific logic

7.1 Adapter Examples
OpenClaw Adapter

content updates

SEO changes

publishing actions

Codex Adapter

code generation

repo changes

infra updates

API Adapter

third-party integrations

data ingestion

external triggers

Human Adapter

manual review tasks

approvals

interventions

8. Capability Awareness

Each execution surface must align with:

required capabilities (from tasks)

available adapter capabilities

policy constraints

If mismatch:

→ binding becomes blocked

9. Traceability Requirements

Every binding must link to:

plan

plan step(s)

task(s)

dispatch record(s)

Optional:

adapter ID

recommendation

decision

10. Constraints

Execution Surface MUST NOT:

execute actions

retry tasks

schedule work

mutate plans

bypass governance

11. Failure Modes
11.1 Unbound Surface

No valid execution target

11.2 Capability Mismatch

Adapter cannot fulfill requirement

11.3 Policy Block

Execution not allowed

11.4 Incomplete Mapping

Missing plan/task/dispatch linkage

12. Relationship to Governance

Execution Surface is:

downstream of policy decisions

upstream of execution

All execution must be:

policy → approved → bound → executed
13. Integration Targets
OpenClaw

Primary execution layer

Codex

Builder / system modifier

Human Operators

Fallback + approval

External Systems

APIs, tools, services

14. v1 Scope

Included:

surface binding model

adapter abstraction

traceable mapping

Excluded:

execution runtime

retry logic

scheduling

monitoring

15. Future Extensions

execution feedback loop (real-time)

retry / failure handling

execution metrics integration

adaptive routing

dynamic capability discovery

16. Bottom Line

Execution Surface is:

the contract where intent becomes executable

It ensures:

Pertti stays supervisory

execution remains controlled

systems remain decoupled

every action remains traceable

🔥 Mitä tämä mahdollistaa nyt

Tässä kohtaa:

sinulla on täysi upstream stack valmis

sinulla on nyt downstream boundary määritelty

👉 seuraava looginen askel on:

🚀 OpenClaw Adapter Contracts v1

eli:

mitä payload näyttää

mitä capability tarkoittaa konkreettisesti

miten dispatch → OpenClaw action
