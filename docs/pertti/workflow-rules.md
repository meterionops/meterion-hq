Pertti Workflow Rules v1
1. Purpose

This document defines the working model for developing Pertti.

The goal is to keep Pertti development:

stable

recoverable

auditable

GitHub-centered

compatible with ChatGPT + Codex collaboration

Pertti is a long-running system.
Because of that, workflow discipline is part of the architecture.

2. GitHub is the Source of Truth
Core rule

Chat is not the source of truth.
GitHub is the source of truth.

Use chat for:

thinking

drafting

reviewing

prompt writing

exploring alternatives

fast iteration

Use GitHub for:

accepted architecture

accepted workflow rules

current project state

milestone checkpoints

reusable documentation

implementation progress

code and contracts

Implication

If something matters to the future of the project, it must be written to GitHub.

3. Chat vs GitHub Rule
Chat is temporary

Chat may contain:

exploration

experiments

partial drafts

rejected ideas

iterative discussion

Chat must not be treated as durable project memory.

GitHub is durable

GitHub must contain:

final accepted specs

current architecture state

current project state

contract files

system maps

workflow rules

invariants

milestone summaries

4. Save Rules
Save to GitHub immediately when:

a major architecture layer is accepted

a new contract family is completed

a workflow rule is defined

a milestone or checkpoint is reached

a reusable design document is produced

a project-level decision is made

a system invariant is clarified

It is acceptable to keep only in chat temporarily when:

the work is still exploratory

the output is clearly provisional

the change is too small to matter on its own

a micro-iteration is still in progress

Final rule

Once accepted, important work must move from chat to GitHub.

5. Checkpoint Rule

Checkpointing is mandatory for major progress.

Create a GitHub checkpoint when:

finishing a major architectural layer

completing a related group of contracts

crossing from one subsystem to another

finishing a meaningful execution boundary

completing a governance or memory milestone

finishing a strategic portfolio layer

Checkpoint contents typically include:

state/current-state.md

projects/pertti.md

relevant docs in docs/pertti/

relevant code/contracts in src/types/

Principle

Do not carry large accepted progress only in chat.

6. Folder Role Rule

Each GitHub area has a different job.

src/types/

Source of truth for system contract boundaries.

Contains:

contract types

envelopes

interfaces

cross-layer boundaries

docs/pertti/

Source of truth for durable architecture and workflow documentation.

Contains:

architecture maps

workflow rules

invariants

memory architecture

execution surface docs

other reusable design docs

state/

Chronological checkpoint log.

Contains:

milestone state updates

accepted progress snapshots

current-state history

projects/

Project-level current snapshot.

Contains:

what Pertti currently is

what phase it is in

current strategic direction

7. Codex Rule

Codex should not be used loosely.

Core rule

Codex must receive explicit, tightly scoped tasks.

Use Codex for:

contract generation

bounded file creation

small focused implementation steps

repetitive structured coding work

Do not use Codex for:

vague architecture exploration

undefined broad redesigns

unstated multi-layer refactors

replacing project judgment

Prompt rule

Use Codex Prompt Pack v1 whenever possible.

A good Codex prompt should specify:

context

goal

scope

out-of-scope

design principles

exact type/file targets

architectural constraints

deliverable format

8. New Conversation Rule

New conversations must begin from GitHub truth, not from assumed chat continuity.

Required startup pattern

When opening a new conversation:

anchor to GitHub repos

reference current saved state

state the system area being continued

define the next bounded task

Recommended format
We are working on Pertti.

Use GitHub as source of truth:
- meterionops/pertti
- meterionops/meterion-hq / codex

Follow Codex Prompt Pack v1 and workflow system.

Task:
...
Principle

A new conversation must be able to continue the project safely even if chat memory is incomplete.

9. Layer Crossing Rule

Before moving from one major layer to the next:

review the completed layer

checkpoint the accepted state

update project/docs if needed

only then continue

Examples

memory layer → checkpoint → strategy layer

strategy layer → checkpoint → execution boundary

execution boundary → checkpoint → runtime-facing layer

Reason

This prevents architectural drift and loss of recoverability.

10. Documentation Rule

Not every useful output belongs in code.

Put in docs/pertti/ when:

it explains architecture

it explains workflow

it explains system boundaries

it is meant to be reread later

it helps onboarding or recovery

Put in src/types/ when:

it defines contracts

it defines envelopes

it defines interfaces

it defines typed system boundaries

Put in state/ when:

it records milestone progress

it describes what changed now

11. Recovery Rule

The project must be recoverable without relying on hidden memory.

Recovery should be possible from GitHub alone through:

current architecture docs

workflow rules

current-state checkpoints

project snapshots

contract files

Principle

If recovery would fail without chat history, the workflow is incomplete.

12. Practical Working Loop

Recommended operating loop:

think in chat

define bounded task

write Codex prompt if code generation is needed

review result

accept or correct

save accepted truth to GitHub

checkpoint at major milestones

start next bounded task

13. Bottom Line

Pertti development follows this rule:

Chat is for thinking.
GitHub is for truth.

And this rule:

Accepted architecture must be recoverable from GitHub.

And this rule:

Major progress must be checkpointed before moving on.
