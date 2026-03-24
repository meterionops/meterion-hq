---
title: CityOS Architecture Overview
doc_type: architecture
project_key: cityos
domain_key: architecture
status: active
tags:
  - architecture
  - overview
summary: High-level overview of CityOS system architecture.
priority: 90
is_featured: true
---

# CityOS Architecture Overview

CityOS consists of the following layers:

- Ingest pipeline
- Canonical model
- Snapshot builder
- Public API
- Control plane (Lovable UI)

The system is designed to be deterministic, observable, and safe to operate.
