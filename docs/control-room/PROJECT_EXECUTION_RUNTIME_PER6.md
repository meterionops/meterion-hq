# PER-6 Ready-Node Scheduler and Safe Parallelism

Status: implementation contract locked; not yet verified.

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
