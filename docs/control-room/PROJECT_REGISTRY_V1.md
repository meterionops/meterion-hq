# Meterion Control Room — Project Registry v1

Status: OWNER-CONFIRMED CORE SET / REMAINING SECONDARY CLASSIFICATIONS MAY STILL BE REFINED
Date: 2026-09-12

## Purpose

This registry defines the top-level Meterion work domains that may appear in Meterion Control Room.

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
3. AI Company OS is represented in Control Room as one connected project/system surface; its internally created AI Companies remain inside AI Company OS.
4. A GitHub repository does not automatically equal a Control Room project.
5. Recent activity does not automatically mean `active`.
6. Portfolio class and lifecycle are Owner-controlled.
7. Control Room must never infer certainty from chat volume, repo activity or telemetry alone.
8. Pertti and CityOS are historical architecture/projects, not current Control Room portfolio projects unless explicitly reactivated later.

## Owner portfolio decision — 2026-09-12

The current CORE set is explicitly confirmed as five projects:

1. AI Company OS
2. Maistio
3. Cala Europe
4. Sprinkler RFQ Platform
5. Rail Atlas / Junamatkailusivusto

This Owner decision supersedes the earlier `CORE max 3` assumption for Control Room classification. Control Room must not raise a conflict merely because CORE contains these five confirmed projects.

Meterion Control Room itself is system infrastructure and does not consume a portfolio slot.

---

# A. Current top-level Control Room projects

## meterion-control-room

- Name: Meterion Control Room
- Kind: `internal_system`
- Goal: Keep a lightweight, reliable cross-project operating picture of Meterion and minimize Founder coordination overhead.
- Portfolio class: `SYSTEM`
- Lifecycle: `active`
- State authority: `control_room`
- Primary workspace: `meterionops/meterion-hq`
- Constraint: Must remain a thin coordination layer; no Kanban, sprint system, CRM, general workflow builder or duplicate project database.
- Constraint: Does not replace ChatGPT, Work, GitHub, Supabase, Lovable or project source systems.

## ai-company-os

- Name: AI Company OS
- Kind: `internal_system`
- Goal: Operating system for AI-native companies created and operated through the governed AI Company OS lifecycle.
- Portfolio class: `CORE`
- Lifecycle: `active`
- State authority: `external_system`
- Primary workspace: `meterionops/ai-company-os`
- Constraint: External Meterion projects are not registered as AI Companies merely to make them visible in Control Room.
- Constraint: Company Factory / Company Creation remains the canonical AI Company creation path.
- Control Room role: Show summarized OS health, Founder attention and selected material changes; deep operation remains in AI Company OS.

## maistio

- Name: Maistio
- Kind: `product`
- Goal: Helsinki-first restaurant discovery product built on the Local Discovery Graph.
- Portfolio class: `CORE`
- Lifecycle: `active`
- State authority: `control_room`
- Primary workspace: `chatgpt + supabase + lovable`
- Constraint: Restaurants are the first vertical.
- Constraint: Bars, nightlife and events are later verticals and must not expand Maistio launch scope before restaurant launch.

## cala-europe

- Name: Cala Europe
- Kind: `product`
- Goal: Europe-first beach discovery and practical beach intelligence product.
- Portfolio class: `CORE`
- Lifecycle: `active`
- State authority: `control_room`
- Primary workspace: `chatgpt + supabase + lovable`
- Constraint: Core product must not depend on paid APIs for images, maps, weather, beach data or content.

## sprinkler-rfq-platform

- Name: Sprinkler RFQ Platform
- Kind: `product`
- Goal: Discover and qualify European sprinkler / fire-protection opportunities and relevant buyers / suppliers for commercial RFQ activity.
- Portfolio class: `CORE`
- Lifecycle: `active`
- State authority: `control_room`
- Primary workspace: `chatgpt + github + data pipelines`
- Known GitHub: `meterionops/fire-sprinkler-hub`
- Constraint: Historical country activity must not permanently lock suppliers or buyers to specific countries.
- Constraint: Respect permanent company exclusion rules maintained by the project.

## rail-atlas

- Name: Rail Atlas / Junamatkailusivusto
- Kind: `product`
- Goal: Global train-travel discovery product centered on memorable train experiences and journeys.
- Portfolio class: `CORE`
- Lifecycle: `active`
- State authority: `control_room`
- Primary workspace: `chatgpt + supabase + lovable`

## folio

- Name: Folio
- Kind: `product`
- Goal: Finnish-company intelligence / competitor monitoring and decision-support product using existing Meterion company data where appropriate.
- Portfolio class: `EXPERIMENT`
- Lifecycle: `active`
- State authority: `control_room`
- Primary workspace: `chatgpt + prototype + data sources`
- Constraint: Reuse Yritystiedot company data where appropriate instead of creating a competing company master-data source.

## calendar-platform

- Name: Calendar Platform
- Kind: `platform`
- Goal: Country-localized calendar / week-number / holiday utility network, beginning from Kalenterissa.fi and expanding through country-standard clones.
- Portfolio class: `AUTOPILOT`
- Lifecycle: `active`
- State authority: `control_room`
- Primary workspace: `chatgpt + github + production sites`
- Known GitHub family:
  - `meterionops/paivasta-selva`
  - `meterionops/kalenderklart`
  - `meterionops/calendify-your-world`
  - `meterionops/kalenderpunkt`
- Constraint: Country sites are deployments/projects inside the Calendar Platform family, not separate top-level Control Room products by default.

## yritystiedot

- Name: Yritystiedot
- Kind: `data_asset`
- Goal: Maintain broad Finnish company data coverage and make it reusable by Meterion products.
- Portfolio class: `AUTOPILOT`
- Lifecycle: `active`
- State authority: `control_room`
- Primary workspace: `data pipeline / external`

## nordic-bottle-index

- Name: Nordic Bottle Index
- Kind: `product`
- Goal: Cross-Nordic alcohol product matching / indexing across national retail catalogs.
- Portfolio class: `AUTOPILOT`
- Lifecycle: `active`
- State authority: `control_room`
- Primary workspace: `github + data pipelines`
- Known GitHub family:
  - `meterionops/nordic-bottle-index`
  - `meterionops/nordic-bottle-index-source`
  - `meterionops/nordic-bottle-index-v2`
  - `meterionops/nordic-bottle-compass`

## namorada

- Name: Namorada
- Kind: `product`
- Goal: Charter administration workflow for customers, cruises, communications and invoicing.
- Portfolio class: `MAINTENANCE`
- Lifecycle: `unconfirmed`
- State authority: `control_room`
- Primary workspace: `external / chatgpt`

## tinku-latin-flavors

- Name: Tinku Latin Flavors
- Kind: `client_operation`
- Goal: Restaurant website and reservation / marketing presence.
- Portfolio class: `MAINTENANCE`
- Lifecycle: `unconfirmed`
- State authority: `control_room`
- Primary workspace: `external`

## house-of-flores

- Name: House of Flores
- Kind: `client_operation`
- Goal: SEO website and Timma-linked bilingual online presence.
- Portfolio class: `MAINTENANCE`
- Lifecycle: `unconfirmed`
- State authority: `control_room`
- Primary workspace: `external`

## volaire

- Name: Volaire
- Kind: `product`
- Goal: Airport-specific discovery / SEO / affiliate platform.
- Portfolio class: `VAULT`
- Lifecycle: `paused`
- State authority: `control_room`
- Primary workspace: `chatgpt + github`
- Known GitHub: `meterionops/volairport`
- Constraint: Volaire is distinct from Pelovio.

## pelovio

- Name: Pelovio
- Kind: `product`
- Goal: Country-manual / travel-guide platform explaining how countries work for visitors.
- Portfolio class: `VAULT`
- Lifecycle: `paused`
- State authority: `control_room`
- Primary workspace: `chatgpt + github`
- Possible legacy/related GitHub: `meterionops/chinamanual` — mapping must be explicitly verified before treated as canonical.
- Constraint: Pelovio is distinct from Volaire.

## avoinna

- Name: Avoinna
- Kind: `product`
- Goal: Modern Finland-wide opening-hours discovery service.
- Portfolio class: `VAULT`
- Lifecycle: `paused`
- State authority: `control_room`
- Primary workspace: `chatgpt / external`

## digiapu247

- Name: Digiapu247
- Kind: `product`
- Goal: AI phone-agent / digital-help service.
- Portfolio class: `VAULT`
- Lifecycle: `paused`
- State authority: `control_room`
- Primary workspace: `github + external voice infrastructure`
- Known GitHub: `meterionops/digiapu247`

## sprinkler-water-tank-site

- Name: Sprinkler Water Tank — site delivery / compliance
- Kind: `client_operation`
- Goal: Deliver and close the sprinkler tank installation / compliance work package safely and correctly.
- Portfolio class: `MAINTENANCE`
- Lifecycle: `completed_candidate`
- State authority: `control_room`
- Primary workspace: `chatgpt + email / site documentation`
- Constraint: Do not mix this operational client job with the Sprinkler RFQ Platform product.

---

# B. Historical projects not in current Control Room portfolio

## pertti

- Name: Pertti
- Current Control Room validity: `historical_only`
- Current lifecycle: `retired_candidate`
- Source history: `meterionops/pertti` + `meterionops/meterion-hq`
- Rule: Preserve existing code, architecture and state files for historical/reference value. Do not surface Pertti in Today or the active portfolio unless the Owner explicitly reactivates it.

## cityos

- Name: CityOS
- Current Control Room validity: `historical_only`
- Current lifecycle: `retired_candidate`
- Source history: `meterionops/meterion-hq`
- Rule: Preserve existing architecture/state files for historical/reference value. Do not surface CityOS in Today or the active portfolio unless the Owner explicitly reactivates it.

Historical files may still describe these as active at the time they were written. Control Room must treat the newer Owner decision on 2026-09-12 as the current authority.

---

# C. GitHub repository candidates — not automatically projects

Repositories such as `jorm-operator-hub`, `antojo-refoundation`, `Lomakone`, `Lomakone-preview`, `aea-crv-rrv-validator`, `nextjs-boilerplate` and temporary probe repos do not become Control Room projects merely because they exist.

Rules:

- boilerplates and temporary probes are not projects by default;
- renamed products map to one canonical project identity rather than creating duplicates;
- multiple repos may belong to one project;
- one repo may support multiple projects only when the mapping is explicit.

---

# D. Registry exclusions / not-yet-projects

Do not create separate top-level projects for:

- Maistio bars vertical
- Maistio nightlife vertical
- Maistio events vertical
- individual Calendar Platform country sites
- individual AI Company OS AI Companies
- individual data-enrichment waves
- one-off Work runs
- one-off GitHub branches / pull requests

They may become top-level projects later only through an explicit Owner decision.

---

# E. Control Room visibility rule

Today should default to:

1. Owner-needed blockers / decisions
2. CORE projects with material state changes
3. active EXPERIMENT projects with material state changes
4. AUTOPILOT only on anomaly, milestone or required action
5. MAINTENANCE only when attention is required
6. VAULT never unless explicitly opened or a reactivation proposal is reviewed
7. historical-only projects never in normal portfolio views

This keeps Control Room quiet by default.

## Next step

Build the minimal persistence/read-model layer for:

- project identity
- current project state
- material events
- source-system connections

Do not introduce task-management abstractions.