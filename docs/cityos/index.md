---
title: CityOS
doc_type: guide
project_key: cityos
domain_key: system
status: active
---

# CityOS

CityOS is a deterministic event intelligence system for ingesting, normalizing, and publishing city-level event data.

It is composed of:

- Ingest pipeline (sources → candidates → canonical)
- Canonical data model (event identity and structure)
- Snapshot builder (curated, API-ready output)
- Public API layer (frontend consumption)

---

## 🧭 Navigation

### 🧱 Architecture
- [Architecture Overview](./architecture-overview.md)

### 📐 Models
- [Models Index](./models/index.md)

### 📜 Contracts
- [Contracts Index](./contracts/index.md)

### 📊 Specifications
- [Specs Index](./specs/index.md)

### 🛠 Operations
- [Playbooks Index](./playbooks/index.md)

### 🚀 Onboarding
- [Onboarding Index](./onboarding/index.md)

---

## 🧠 System Layers

### 1. Ingest Layer
- Source adapters
- Candidate extraction
- Analyzer pipeline

### 2. Canonical Layer
- Canonical event identity
- Field normalization
- Cross-source merge (snapshot stage)

### 3. Snapshot Layer
- Deterministic selection
- Deduplication
- Diversity constraints

### 4. Delivery Layer
- Public API
- Frontend consumption (City sites)

---

## ⚙️ Core Principles

- Deterministic output (no randomness in snapshot)
- Source-local fixes (never break the runner)
- Canonical-first architecture
- Observability at every stage
- One source of truth per layer

---

## 📌 Key Documents

- Snapshot Builder → [specs/snapshot-builder.md](./specs/snapshot-builder.md)
- Canonical Model → [models.md](./models.md)
- Fix Source → [playbooks/fix-source.md](./playbooks/fix-source.md)
- Authoring Guide → [onboarding/docs-authoring-guide.md](./onboarding/docs-authoring-guide.md)
