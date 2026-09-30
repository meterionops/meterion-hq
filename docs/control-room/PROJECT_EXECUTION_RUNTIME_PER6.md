# PER-6 Ready-Node Scheduler and Safe Parallelism

Status: VERIFIED against the applied runtime; Fresh Critic READY. Canonical closure follows merge.

## Scope
Extend runtime_version=2 and the existing PER-2/3/4/5 execution path. No second scheduler service, credential store, retry ledger, or provider-write authority.

Opt-in contract: Work Unit scope_contract.per6.max_parallel_nodes is an integer from 1 through 4. The existing Work Unit contract hash covers this field. Scheduler inputs come from each node's immutable input_contract.dispatch_input. Legacy graphs without per6 keep existing behavior.

The service-role-only scheduler tick:
- refreshes dependency readiness through PER-2;
- processes one bounded snapshot of ready server/deterministic read-only nodes;
- resolves through PER-3 and prepares provider work through PER-4;
- counts running/verifying nodes and awaiting-provider reservations against the run limit;
- uses stable run/node/attempt dispatch identities, including after safe retries;
- never claims session/human work and never performs provider network calls;
- leaves provider work to PER-5 and uses existing action/retry/lease/evidence state.

The shared PER-2 claim boundary enforces PER-6 slots for every caller, dependency readiness and read-only/mode restrictions before action consumption. Expired or unresolved execution keeps a slot until PER-2 recovery resolves it. Claim and scheduler decisions serialize on the graph row.

## Acceptance
- two independent provider reads can be leased concurrently when limit=2;
- a third read cannot be leased until capacity is released;
- dependent nodes remain unprepared until prerequisites complete;
- retries preserve PER-2 accounting and obtain a new attempt dispatch identity;
- repeated/concurrent scheduler calls do not duplicate handoffs or action charges;
- unsupported routes, session/human tasks, elevated authority and missing contracts fail closed;
- legacy PER-2 through PER-5 regressions remain valid;
- persistent bounded canary completes with actual provider evidence;
- Fresh Critic READY before merge and canonical closure.

No recurring automation is created or changed by this milestone. The tick is a bounded callable scheduler surface; no new cadence or unattended-service SLA is claimed.

## Verification — 2026-09-30
Fresh Critic verdict: **READY** for this bounded runtime milestone.

| Criterion | Observed evidence |
| --- | --- |
| Capacity and dependencies | PER-6 rollback regression PASS: two live claims; third rejected without action consumption; join remains waiting until all predecessors complete. |
| Idempotency | Concurrent persistent ticks returned scheduled=2 and scheduled=0; exactly two initial handoffs. Repeated/terminal ticks do not charge actions. |
| Fail-closed boundary | Focused rollback regression PASS: absent/null/invalid/string-valued limits rejected; forged ready status cannot bypass dependencies; session/human/elevated claims rejected before spending. |
| Retry | Provider failure, explicit PER-2 retry and next tick produce a distinct attempt dispatch; one retry charged, preparation does not charge another action. |
| Preserve | PER-2, PER-3, PER-4 and PER-5 rollback regressions rerun PASS against the applied migration. |
| Real provider canary | Control Room run `per6-parallel-canary-20260930`: three real connected GitHub repository reads and a dependent builtin state read completed. |
| Accounting | Graph Run, Work Unit and Run Envelope completed; 4 actions, 0 retries, 0 spend, 4 dispatches, 0 exceptions. |
| Actual overlap | read-a: 14:24:50–14:25:35 UTC; read-b: 14:24:42–14:25:42 UTC. read-c starts 14:25:58; join starts 14:26:47 after all three reads. |
| Access | Scheduler anon/authenticated execution denied. Fixed search_path; no new tables, credentials or provider authority. |
| Persistence | Applied migration `20260930141918_project_execution_runtime_per6_scheduler`; rollback fixture residue 0. |

Canary host: current authorized ChatGPT session using PER-5 pickup and actual connected GitHub calls. This proves bounded runtime parallelism, not a new scheduled worker cadence.

Supabase security advisor found no PER-6 function warning. Existing service-role tables retain RLS with no client policy (INFO). Auth has an unrelated leaked-password-protection warning; remediation: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection . No Auth settings changed.

No BLOCKER or MATERIAL findings remain for the locked scope. Review was performed by the implementing session using the Fresh Critic reset and direct database/provider evidence, not by a separate reviewer. Next action: merge and close canonical state; do not invent an additional milestone.
