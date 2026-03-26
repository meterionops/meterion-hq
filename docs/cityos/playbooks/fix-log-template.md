---
title: Source Fix Log Template
doc_type: playbook
project_key: cityos
domain_key: operations
status: active
---

# Source Fix Log Template

Fill this for every source fix — even if the case is still in progress.

This is mandatory for system learning.

---

## Source

- Source:
- URL:
- Family:

---

## Diagnosis

- Root cause (initial hypothesis):
- UI recommendation:
- Actual problem:

---

## Category

Mark all that apply:

- [ ] Wrong URL
- [ ] Missing URL
- [ ] Parser broken
- [ ] DOM changed
- [ ] No real events
- [ ] Pipeline not executed
- [ ] Pipeline failing
- [ ] Visibility filtering too aggressive
- [ ] Other: ________

---

## Fix type

Mark the primary fix type:

- [ ] config-only
- [ ] governance-only
- [ ] parser tweak
- [ ] source-local adapter
- [ ] data-source switch (API vs HTML)
- [ ] visibility/config fix
- [ ] shared parser enhancement
- [ ] shared runner fix
- [ ] UI-only
- [ ] other: ________

---

## Fix result

- Working now:  
  - [ ] Yes  
  - [ ] Partially  
  - [ ] No  

---

## Validation

Describe validation across all three layers:

- Runtime result (run_source):
- Fixture result (run_source_fixture):
- Evaluator / test result:

---

## Notes

- Additional observations:
- Follow-up needed:
