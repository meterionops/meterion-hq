---
title: Docs Authoring Guide
doc_type: guide
project_key: cityos
domain_key: onboarding
status: active
tags:
  - docs
  - standards
  - writing
summary: How to write, structure and maintain CityOS documentation.
priority: 90
is_featured: true
---

# Docs Authoring Guide
---
title: Docs Authoring Guide
doc_type: guide
project_key: cityos
domain_key: onboarding
status: active
tags:
  - docs
  - standards
  - writing
summary: How to write, structure and maintain CityOS documentation.
priority: 90
is_featured: true
---

# Docs Authoring Guide

## Purpose

This guide defines how all CityOS documentation must be written, structured, and maintained.

Goal:
- Consistent documents
- Predictable structure
- Scalable knowledge system (50 → 500+ docs)

---

# 1. File Location (IMPORTANT)

All CityOS documents must live under:


docs/cityos/


Use domain-based folders:

- `playbooks/` → operational guides
- `specs/` → technical specifications
- `architecture/` → system design
- `contracts/` → API & data contracts
- `models/` → domain models
- `strategy/` → roadmap & direction
- `onboarding/` → guides like this

---

# 2. File Naming

Always use:


kebab-case.md


Examples:
- `snapshot-builder.md`
- `event-ingest-pipeline.md`
- `source-health-model.md`

❌ Do not use:
- spaces
- camelCase
- uppercase

---

# 3. Metadata (MANDATORY)

Every document MUST start with frontmatter:

```yaml
---
title:
doc_type:
project_key: cityos
domain_key:
status: active
tags: []
summary:
priority: 50
is_featured: false
---
3.1 Allowed Values
doc_type
overview
guide
playbook
spec
architecture
contract
model
roadmap
decision
domain_key
system
architecture
playbooks
specs
contracts
models
operations
observability
strategy
onboarding
incidents
launch
platform
status
active
draft
deprecated
4. Writing Structure

Use predictable structure:

Title

Clear and specific.

Summary

1–2 sentences explaining what the doc is.

Sections

Use consistent headings:

Purpose
Context
Design / Model / Steps
Examples
Edge cases
Decisions (if relevant)
5. Playbooks vs Specs
Playbook

👉 How to do something

Example:

Fix Source Playbook

Structure:

Goal
Steps
Expected output
Common issues
Spec

👉 How something works

Example:

Snapshot Builder Spec

Structure:

Purpose
Inputs
Outputs
Logic
Constraints
6. Tags

Tags should be:

short
lowercase
reusable

Examples:

ingest
snapshot
source
pipeline
7. Featured Documents

Use:

is_featured: true

ONLY for:

system invariants
architecture overview
key playbooks
onboarding docs
8. What NOT to Do

❌ No SQL scripts as docs
❌ No random notes without metadata
❌ No duplicate documents
❌ No mixed responsibilities (spec + playbook in one doc)

9. Source of Truth
GitHub = source of truth
Supabase = indexed view
UI = browsing layer

Never edit docs via database.

10. Philosophy

CityOS docs are:

operational (used daily)
structured (not random notes)
composable (docs link to each other)
scalable (hundreds of docs)

This is not documentation.

This is a knowledge system.
