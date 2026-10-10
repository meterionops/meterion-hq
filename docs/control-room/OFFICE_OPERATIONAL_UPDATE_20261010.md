# Office operational update — 2026-10-10

## Delivered
- Existing Control Room PER-2 work graph used, no new runtime/queue.
- Real Calendar check `office-calendar-maintenance-20261010`, work UUID `55483550-17ef-4aca-9aee-a98790c8420e`: completed; inspect and verify each attempt_count=1; actions_used=2.
- Checkpoint continued after inspect; duplicate create returned idempotent_replay=true; work_count=1. Controlled checkpoint test, not forced crash simulation.
- Actual evidence: existing daily sync succeeded 2026-10-10 05:30 UTC; four countries fetched that morning; latest metric_date 2026-10-06. DE/SE registry PENDING conflicts with received rows. This does not establish growth or a broken sync.
- Office reader v6 projects allowlisted run result, completed checkpoints and maintenance expectation. Existing JWT/current-owner/org gate unchanged.
- Work-first UI: goal, actual work/result, next action, collapsible evidence; copied work reference for ChatGPT/Dot; completed work gets follow-up instructions, not illegal reopening.
- Transient read error retains labelled in-memory historical snapshot only; authorization rejection/logout clears it.
- Maintenance Automation `6ac9d778bc508191817eaf20fee327b6`: enabled, seven daily runs 11–17 October around 10–11 Europe/Helsinki. Expected next window endpoint 2026-10-11 08:00 UTC. No future run has been observed yet. See OFFICE_CALENDAR_MAINTENANCE_V1.md.
- Frontend production source commit `4e24b85b2a42890d08c8d81427207dc007f9730b`, branch feat/office-current-source-v1. Stable URL https://ai-company-os-ceo-dashboard.vercel.app/office/.
- Code is on feature branches, not merged to main; do not overwrite this release with old main in a later deploy. Backend branch feat/office-current-project-reader-v1.

## Verification
62 Node checks passed covering shared auth, revoked access, reader, safe DTO fields, UI route refresh and snapshot clearing.
Authenticated browser checked actual portfolio (three projects), Calendar work result, four-country evidence, maintenance and findings on commit 7abf44b2d59b2b4258a38bac0941fc767105b1d7. Subsequent changes only clarify handoff/finding labels and unknown counts. Stable production login page and deployment alias inspected.
Copy button's completion was not independently confirmed (secure browser retained-data restriction); selectable work text is available. Responsive CSS retained, no mobile browser resize capability used. No claim of mobile screenshot validation.

## Limits
This is the first functioning bounded loop, not autonomous operation of every project.
Maistio/Far by Rail work registries still have no linked execution, and no new upkeep activated there.
Decisions still happen in ChatGPT/Dot; Office does not ingest arbitrary chat decisions automatically.
The scheduler is ChatGPT Automations; source sync remains the original Calendar cron. No new cron or paid model/data calls.
Permission outages stop execution and must remain visible; scheduling is not proof of a worker currently running.


## Superseding simplification — 10 October 2026
User approved keeping Office lightweight. Owner bridge v7 now reads metadata.office_result directly from existing work records, without graph run/node queries. Calendar Automation now writes one bounded work record per day, with result, source evidence, next action and optional resume_note. No graph/claim/transition runtime is required for this check. Existing verified result was copied into its original work record preserving observed_at and verified_at; original graph history remains unchanged. Existing database, project registry and owner authentication remain dependencies; this is not a database migration or complete separation from Control Room storage. Frontend commit 2d81f717e0dbba2aae87faebd17967e89c34b2d0. Existing seven-run schedule and permissions unchanged. Transactional storage test rolled back without residual test work; 35 backend tests passed, including direct-evidence validation and absence of graph queries. The first scheduled execution is still pending.


## GSC visibility update — 10.10.2026
Superseding addition to lightweight Office, no new tables/queue/cron/runtime.
- Production frontend f75d925fe23a1cc42be7284bf5bbb889e0973a60, deployment dpl_Ahyr8aXA2jwqkUx6drSbP4MnBbCj READY; stable /office/ alias assigned.
- Owner bridge v8 ACTIVE; custom signature/current-owner checks unchanged. Reporting allowlist added only.
- Calendar source Supabase tkvpnkxchkhcftttdyos: four country summaries persisted into the existing project's Supabase connection metadata.office_gsc; observed 2026-10-10T07:46:21.9864Z, fetched about 05:30 UTC. Daily period 9 Sep–6 Oct; query/page period 11 Sep–8 Oct. Dates shown separately.
- FI 28-day clicks 110 vs60, impressions22247 vs32749. Only FI has full previous28-day coverage; DE10,FR8,SE13 previous days. UI suppresses incomplete percentage comparisons and never fills absent values with zero.
- Existing daily automation 6ac9d778bc508191817eaf20fee327b6 amended in place: refresh this summary and make at most one deduplicated planned improvement on Saturdays. Seven-run pilot11–17Oct retained; first actual scheduled execution remains pending.
- First planned improvement: office-gsc-fr-numero-de-semaine, work4b2d1338-6df8-4629-9e0c-05829a4ad9b0. Evidence FR /numero-de-semaine 2143 impressions /0 clicks, not proof of cause. No site edits/publication.
- Maistio and rail-atlas GSC reporting blocked. GSC Wizard returns payment_required / trial ended; their Supabase projects have no discovered GSC reporting tables. Calendar adapter is site_instance/country-scoped; extending it to unrelated projects was deliberately not done. Google property ownership/access for these two is NOT disproved. Need a usable authorized read connection before activation. No paid subscription or credentials created.
- Verification:64 existing+reader tests and3 GSC render tests passed; DB readback verifies four Calendar sites and explicit blockers for the other projects. Fresh production browser reaches normal sign-in; no new authenticated end-to-end browser verification claimed.
- Feature branches remain unmerged. An older main deployment could overwrite Office changes.
