# Meterion Control Room — Project Registry v1

Status: DRAFT / OWNER REVIEW REQUIRED FOR PORTFOLIO CLASS AND LIFECYCLE
Date: 2026-09-12

## Purpose

This registry defines which Meterion work domains may appear in Meterion Control Room.

It is deliberately **not** a task tracker and **not** the AI Company OS company registry.

Control Room answers:

- what are we building or operating?
- why does it exist?
- where does it live?
- what is the current state?
- what should happen next?
- is Founder attention required?

Actual work remains in ChatGPT / Work, GitHub, Supabase, Lovable, production services and other source systems.

## Hard boundaries

1. AI Company OS remains a separate product and domain.
2. Meterion projects created outside AI Company OS are **not imported as AI Companies**.
3. AI Company OS is represented in Control Room as one connected system / project surface; its internally created AI Companies remain inside AI Company OS.
4. A GitHub repository does not automatically equal a Control Room project.
5. Recent activity does not automatically mean `active`.
6. Portfolio class (`CORE`, `EXPERIMENT`, `AUTOPILOT`, `MAINTENANCE`, `VAULT`) is Owner-controlled.
7. Lifecycle status is Owner-controlled unless an explicit previously accepted rule defines it.
8. Unconfirmed values remain `UNCONFIRMED`; Control Room must never infer certainty from chat volume, repo activity or telemetry alone.

## Registry object

Minimum identity record:

```yaml
project_key: string
name: string
kind: product | platform | internal_system | client_operation | data_asset | candidate
goal: string | null
portfolio_class: CORE | EXPERIMENT | AUTOPILOT | MAINTENANCE | VAULT | UNCONFIRMED
lifecycle_status: active | paused | completed | archived | unconfirmed
state_authority: control_room | external_system | manual
primary_workspace: chatgpt | github | external | mixed
canonical_constraints: []
connections: []
```

Operational state (`phase`, `current_focus`, `last_material_result`, `next_best_action`, blockers, autonomy, Founder attention and freshness) belongs to the separate Project State contract, not this registry.

---

# A. Meterion projects — seed registry

The entries below establish **identity and scope only**. Portfolio class and lifecycle remain unconfirmed unless explicitly confirmed by the Owner later.

## meterion-control-room

- Name: Meterion Control Room
- Kind: `internal_system`
- Goal: Keep a lightweight, reliable cross-project operating picture of Meterion and minimize Founder coordination overhead.
- Portfolio class: `UNCONFIRMED`
- Lifecycle: `active` (current build conversation)
- State authority: `control_room`
- Primary workspace: `meterionops/meterion-hq`
- Constraint: Must remain a thin coordination layer; no Kanban, sprint system, CRM, general workflow builder or duplicate project database.
- Constraint: Does not replace ChatGPT, Work, GitHub, Supabase, Lovable or project source systems.

## ai-company-os

- Name: AI Company OS
- Kind: `internal_system`
- Goal: Operating system for AI-native companies created and operated through the governed AI Company OS lifecycle.
- Portfolio class: `UNCONFIRMED`
- Lifecycle: `unconfirmed`
- State authority: `external_system`
- Primary workspace: `meterionops/ai-company-os`
- Constraint: External Meterion projects are not registered as AI Companies merely to make them visible in Control Room.
- Constraint: Company Factory / Company Creation remains the canonical AI Company creation path.
- Control Room role: Show only summarized OS health, Founder attention and selected material changes; deep operation remains in AI Company OS.

## maistio

- Name: Maistio
- Kind: `product`
- Goal: Helsinki-first restaurant discovery product built on the Local Discovery Graph.
- Portfolio class: `UNCONFIRMED`
- Lifecycle: `unconfirmed`
- State authority: `control_room`
- Primary workspace: `chatgpt + supabase + lovable`
- Constraint: Restaurants are the first vertical.
- Constraint: Bars, nightlife and events are later verticals and must not expand Maistio launch scope before restaurant launch.

## cala-europe

- Name: Cala Europe
- Kind: `product`
- Goal: Europe-first beach discovery and practical beach intelligence product.
- Portfolio class: `UNCONFIRMED`
- Lifecycle: `unconfirmed`
- State authority: `control_room`
- Primary workspace: `chatgpt + supabase + lovable`
- Constraint: Core product must not depend on paid APIs for images, maps, weather, beach data or content.

## sprinkler-rfq-platform

- Name: Sprinkler Tank / Fire Sprinkler RFQ Platform
- Kind: `product`
- Goal: Discover and qualify European sprinkler / fire-protection opportunities and relevant buyers / suppliers for commercial RFQ activity.
- Portfolio class: `UNCONFIRMED`
- Lifecycle: `unconfirmed`
- State authority: `control_room`
- Primary workspace: `chatgpt + github + data pipelines`
- Known GitHub: `meterionops/fire-sprinkler-hub`
- Constraint: Historical country activity must not permanently lock suppliers or buyers to specific countries.
- Constraint: Respect permanent company exclusion rules maintained by the project.

## rail-atlas

- Name: Rail Atlas
- Kind: `product`
- Goal: Global train-travel discovery product centered on memorable train experiences and journeys.
- Portfolio class: `UNCONFIRMED`
- Lifecycle: `unconfirmed`
- State authority: `control_room`
- Primary workspace: `chatgpt + supabase + lovable`

## calendar-platform

- Name: Calendar Platform
- Kind: `platform`
- Goal: Country-localized calendar / week-number / holiday utility network, beginning from Kalenterissa.fi and expanding through country-standard clones.
- Portfolio class: `UNCONFIRMED`
- Lifecycle: `unconfirmed`
- State authority: `control_room`
- Primary workspace: `chatgpt + github + production sites`
- Known GitHub family:
  - `meterionops/paivasta-selva`
  - `meterionops/kalenderklart`
  - `meterionops/calendify-your-world`
  - `meterionops/kalenderpunkt`
- Constraint: Country sites are projects / deployments inside the Calendar Platform family, not separate top-level Control Room products by default.

## volaire

- Name: Volaire
- Kind: `product`
- Goal: Airport-specific discovery / SEO / affiliate platform.
- Portfolio class: `UNCONFIRMED`
- Lifecycle: `unconfirmed`
- State authority: `control_room`
- Primary workspace: `chatgpt + github`
- Known GitHub: `meterionops/volairport`
- Constraint: Volaire is distinct from Pelovio.

## pelovio

- Name: Pelovio
- Kind: `product`
- Goal: Country-manual / travel-guide platform explaining how countries work for visitors.
- Portfolio class: `UNCONFIRMED`
- Lifecycle: `unconfirmed`
- State authority: `control_room`
- Primary workspace: `chatgpt + github`
- Possible legacy/related GitHub: `meterionops/chinamanual` — mapping must be explicitly verified before treated as canonical.
- Constraint: Pelovio is distinct from Volaire.

## avoinna

- Name: Avoinna
- Kind: `product`
- Goal: Modern Finland-wide opening-hours discovery service.
- Portfolio class: `UNCONFIRMED`
- Lifecycle: `unconfirmed`
- State authority: `control_room`
- Primary workspace: `chatgpt / external`

## yritystiedot

- Name: Yritystiedot
- Kind: `data_asset`
- Goal: Maintain broad Finnish company data coverage and make it reusable by Meterion products.
- Portfolio class: `UNCONFIRMED`
- Lifecycle: `unconfirmed`
- State authority: `control_room`
- Primary workspace: `data pipeline / external`

## nordic-bottle-index

- Name: Nordic Bottle Index
- Kind: `product`
- Goal: Cross-Nordic alcohol product matching / indexing across national retail catalogs.
- Portfolio class: `UNCONFIRMED`
- Lifecycle: `unconfirmed`
- State authority: `control_room`
- Primary workspace: `github + data pipelines`
- Known GitHub family:
  - `meterionops/nordic-bottle-index`
  - `meterionops/nordic-bottle-index-source`
  - `meterionops/nordic-bottle-index-v2`
  - `meterionops/nordic-bottle-compass`

## digiapu247

- Name: Digiapu247
- Kind: `product`
- Goal: AI phone-agent / digital-help service.
- Portfolio class: `UNCONFIRMED`
- Lifecycle: `unconfirmed`
- State authority: `control_room`
- Primary workspace: `github + external voice infrastructure`
- Known GitHub: `meterionops/digiapu247`

## namorada

- Name: Namorada
- Kind: `product`
- Goal: Charter administration workflow for customers, cruises, communications and invoicing.
- Portfolio class: `UNCONFIRMED`
- Lifecycle: `unconfirmed`
- State authority: `control_room`
- Primary workspace: `external / chatgpt`

## tinku-latin-flavors

- Name: Tinku Latin Flavors
- Kind: `client_operation`
- Goal: Restaurant website and reservation / marketing presence.
- Portfolio class: `UNCONFIRMED`
- Lifecycle: `unconfirmed`
- State authority: `control_room`
- Primary workspace: `external`

## house-of-flores

- Name: House of Flores
- Kind: `client_operation`
- Goal: SEO website and Timma-linked bilingual online presence.
- Portfolio class: `UNCONFIRMED`
- Lifecycle: `unconfirmed`
- State authority: `control_room`
- Primary workspace: `external`

## sprinkler-water-tank-site

- Name: Sprinkler Water Tank — site delivery / compliance
- Kind: `client_operation`
- Goal: Deliver and close the sprinkler tank installation / compliance work package safely and correctly.
- Portfolio class: `UNCONFIRMED`
- Lifecycle: `unconfirmed` (likely closure/archive candidate; Owner confirmation required)
- State authority: `control_room`
- Primary workspace: `chatgpt + email / site documentation`
- Constraint: Do not mix this operational client job with the Sprinkler RFQ Platform product.

---

# B. Existing Meterion HQ projects

The current `meterion-hq` repository already contains explicit project snapshots for:

- Pertti
- CityOS

These are **not automatically assigned an active lifecycle or a 10/10 portfolio class** by Control Room v1. Existing files remain valid historical/project truth until reconciled with the new registry.

## pertti

- Name: Pertti
- Kind: `internal_system`
- Goal: Supervisory / memory OS and cross-project coordination architecture.
- Portfolio class: `UNCONFIRMED`
- Lifecycle: `unconfirmed`
- State authority: `github`
- Primary workspace: `meterionops/pertti` + `meterionops/meterion-hq`
- Migration rule: Preserve existing project/state history; do not rewrite it into Control Room state until explicit reconciliation.

## cityos

- Name: CityOS
- Kind: `internal_system`
- Goal: Existing project definition in Meterion HQ; exact current role should be read from its project snapshot during reconciliation.
- Portfolio class: `UNCONFIRMED`
- Lifecycle: `unconfirmed`
- State authority: `github`
- Primary workspace: `meterionops/meterion-hq`
- Migration rule: Preserve existing project/state history; do not infer current activity.

---

# C. GitHub repository candidates — not automatically projects

Accessible `meterionops` repositories reveal additional names that require mapping before Control Room registration. They must not appear in Today / Projects as canonical projects merely because a repository exists.

Current candidates include:

- `meterionops/pertti`
- `meterionops/jorm-operator-hub`
- `meterionops/antojo-refoundation`
- `meterionops/Lomakone`
- `meterionops/Lomakone-preview`
- `meterionops/aea-crv-rrv-validator`
- `meterionops/nextjs-boilerplate`
- `meterionops/tmp-binary-probe-delete-me`

Rules:

- boilerplates, temporary probes and implementation repos do not become projects by default;
- renamed products should map to one canonical project identity rather than creating duplicates;
- multiple repos may belong to one project;
- one repo may support multiple internal projects, but that mapping must be explicit.

---

# D. Registry exclusions / not-yet-projects

Do not create separate top-level projects for these merely because they exist as ideas, modules or future verticals:

- Maistio bars vertical
- Maistio nightlife vertical
- Maistio events vertical
- individual Calendar Platform country sites
- individual AI Company OS AI Companies
- individual data-enrichment waves
- one-off Work runs
- one-off GitHub branches / pull requests

They may become projects later only through an explicit Owner decision.

---

# E. Owner reconciliation fields

Before this registry becomes canonical, each entry needs only three Owner-controlled confirmations:

```text
1. KEEP IN CONTROL ROOM?   yes / no
2. LIFECYCLE               active / paused / completed / archived
3. PORTFOLIO CLASS         CORE / EXPERIMENT / AUTOPILOT / MAINTENANCE / VAULT
```

Control Room must not require the Owner to fill in long descriptions, task lists or metadata.

Where possible, goal / links / state are reconstructed from existing project truth and then shown for lightweight review.

---

# F. Step 3 acceptance criteria

Project Registry v1 is complete when:

- top-level project identities are deduplicated;
- AI Company OS boundary is preserved;
- existing Meterion HQ project history is preserved;
- repo names are mapped to projects instead of treated as projects automatically;
- all lifecycle and portfolio classifications are explicitly Owner-confirmed or remain `UNCONFIRMED`;
- Control Room can list projects without needing task-level data;
- project registry can be recovered independently of ChatGPT conversation history.

## Next step

**Step 3.1 — Owner Reconciliation Surface**

Generate one compact review screen / payload containing only:

`Project | Keep? | Lifecycle | Portfolio class`

After Owner confirmation, freeze Project Registry v1 and continue to the persistence decision / implementation layer.
