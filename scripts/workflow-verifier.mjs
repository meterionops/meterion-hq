import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

const nonempty = x => typeof x === 'string' && x.trim().length > 0;
const strings = x => Array.isArray(x) && x.length > 0 && x.every(nonempty);
const canonical = x => Array.isArray(x) ? x.map(canonical) : x && typeof x === 'object'
  ? Object.fromEntries(Object.keys(x).sort().map(k => [k, canonical(x[k])])) : x;
export const digest = x => createHash('sha256').update(JSON.stringify(canonical(x))).digest('hex');

export function validateContract(c) {
  const failures = [];
  if (!c || c.schema !== 'meterion.workflow.v1') return ['contract_schema'];
  for (const key of ['id', 'trigger', 'objective', 'escalationPath']) if (!nonempty(c[key])) failures.push(key);
  for (const key of ['inputs', 'systems', 'decisions', 'actions', 'failureConditions', 'verificationCriteria', 'toolRouting', 'supportingEvidence', 'evaluationCases']) if (!strings(c[key])) failures.push(key);
  if (![1, 2].includes(c.version)) failures.push('version');
  if (!nonempty(c.owner?.role) || c.owner.authority !== 'read_only') failures.push('owner_authority');
  if (c.approvals?.externalAction !== 'owner_required') failures.push('approvals');
  if (!nonempty(c.procedure?.id) || !Number.isInteger(c.procedure?.version) || c.procedure.version < 1 || !strings(c.procedure.rules)) failures.push('procedure');
  if (c.intelligenceRouting?.objectiveFacts !== 'deterministic' || c.intelligenceRouting?.ambiguity !== 'reasoning_then_escalate') failures.push('intelligence_routing');
  for (const key of ['project', 'repository', 'targetRun', 'mergeSha']) if (!nonempty(c.expected?.[key])) failures.push('expected_' + key);
  for (const key of ['actions', 'nodes']) if (!Number.isInteger(c.expected?.[key]) || c.expected[key] < 1) failures.push('expected_' + key);
  if (!Number.isInteger(c.evidenceMaxAgeSeconds) || c.evidenceMaxAgeSeconds < 1 || c.evidenceMaxAgeSeconds > 86400) failures.push('freshness_bound');
  if (c.version === 2 && (c.verifiedExecutionScope !== 'callable_session' || !strings(c.expected?.nodeKeys) || c.expected.nodeKeys.length !== c.expected.nodes || new Set(c.expected.nodeKeys).size !== c.expected.nodes)) failures.push('scope_or_node_contract');
  return failures;
}

/** Pure evaluator. Collector observations are trusted only at the authorized connector boundary.
 * Hashes prove artifact integrity, not provider authenticity. No network or mutation occurs here. */
export function evaluate(c, observation, now = Date.now()) {
  const contractErrors = validateContract(c);
  const base = { workflow: c?.id ?? null, version: c?.version ?? null, procedure: c?.procedure ?? null,
    contractHash: digest(c ?? null), evidenceHash: digest(observation ?? null), evaluatedAt: new Date(now).toISOString() };
  const finish = (status, failures) => ({ ...base, status, failures, externalActionPerformed: false });
  if (contractErrors.length) return finish('INVALID_CONTRACT', contractErrors);
  if (!observation || typeof observation !== 'object') return finish('EVIDENCE_REQUIRED', ['observation_missing']);
  if (observation.requestedAction !== 'verify_read_only') return finish('WAITING_OWNER', ['action_outside_contract']);
  const failures = [];
  for (const key of ['runtime', 'repository']) {
    const s = observation[key];
    if (!s || !nonempty(s.sourceRef)) { failures.push(key + '_source_missing'); continue; }
    const ts = Date.parse(s.observedAt);
    if (!Number.isFinite(ts) || ts > now || now - ts > c.evidenceMaxAgeSeconds * 1000) failures.push(key + '_stale_or_invalid');
  }
  const r = observation.runtime, g = observation.repository, e = c.expected;
  if (!r || r.project !== e.project || r.runKey !== e.targetRun) failures.push('runtime_identity');
  if (!r || !['graph', 'workUnit', 'envelope'].every(k => r[k] === 'completed')) failures.push('runtime_incomplete');
  if (!Array.isArray(r?.nodes) || r.nodes.length !== e.nodes || new Set(r.nodes.map(n => n.key)).size !== e.nodes || !r.nodes.every(n => n.status === 'completed')) failures.push('node_outcomes');
  if (r?.actions !== e.actions || r?.retries !== 0 || r?.spend !== 0 || r?.openExceptions !== 0) failures.push('accounting_or_exceptions');
  if (!g || g.repository !== e.repository || g.merged !== true || g.base !== 'main' || g.mergeSha !== e.mergeSha) failures.push('repository_conflict');
  if (c.version === 2) {
    if (observation.requestedExecutionScope !== c.verifiedExecutionScope || observation.executionScope !== c.verifiedExecutionScope || !nonempty(observation.scopeSourceRef)) failures.push('execution_scope_unverified');
    if (!Array.isArray(r?.nodes) || !e.nodeKeys.every(k => r.nodes.some(n => n.key === k))) failures.push('node_identity');
  }
  return finish(failures.length ? 'EVIDENCE_REQUIRED' : 'VERIFIED', failures);
}

export function compileReadGraph(c) {
  const errors = validateContract(c);
  if (errors.length) throw new Error('invalid_contract:' + errors.join(','));
  return {
    scope_contract: { per6: { max_parallel_nodes: 1 }, workflow: { id: c.id, version: c.version, contract_hash: digest(c), procedure_id: c.procedure.id, procedure_version: c.procedure.version } },
    nodes: [
      { node_key: 'repository-context', node_type: 'tool', action_kind: 'github.repository.read', required_capability: 'github.repository.read', execution_mode: 'server_executable', authority_class: 'read_only', failure_policy: 'retry', max_attempts: 2, timeout_seconds: 600, input_contract: { dispatch_input: { repository_full_name: c.expected.repository } } },
      { node_key: 'canonical-state', node_type: 'tool', action_kind: 'control_room.project_state.read', required_capability: 'control_room.project_state.read', execution_mode: 'server_executable', authority_class: 'read_only', failure_policy: 'retry', max_attempts: 2, timeout_seconds: 600, input_contract: {} }
    ],
    edges: [{ from: 'repository-context', to: 'canonical-state' }],
    limits: { max_actions: 3, max_retries: 1, max_spend_microusd: 0 }
  };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [contractPath, evidencePath] = process.argv.slice(2);
  const result = evaluate(JSON.parse(readFileSync(contractPath, 'utf8')), JSON.parse(readFileSync(evidencePath, 'utf8')));
  console.log(JSON.stringify(result, null, 2));
  process.exitCode = result.status === 'VERIFIED' ? 0 : 2;
}
