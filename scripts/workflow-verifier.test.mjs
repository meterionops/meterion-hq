import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { evaluate, validateContract, compileReadGraph, digest } from './workflow-verifier.mjs';
const c = JSON.parse(readFileSync(new URL('../workflows/project-verification-v1.json', import.meta.url)));
const now = Date.parse('2026-09-30T19:00:00Z');
const fixture = () => ({ requestedAction: 'verify_read_only', runtime: { project: c.expected.project, runKey: c.expected.targetRun, sourceRef: 'fixture:runtime', observedAt: new Date(now).toISOString(), graph:'completed', workUnit:'completed', envelope:'completed', actions:4, retries:0, spend:0, openExceptions:0, nodes:['a','b','c','d'].map(key=>({key,status:'completed'})) }, repository:{repository:c.expected.repository,sourceRef:'fixture:pr',observedAt:new Date(now).toISOString(),merged:true,base:'main',mergeSha:c.expected.mergeSha} });
test('complete synthetic fixture verifies',()=>assert.equal(evaluate(c,fixture(),now).status,'VERIFIED'));
for(const [name,mutate] of [
 ['missing runtime',x=>delete x.runtime],
 ['wrong project',x=>x.runtime.project='other'],
 ['wrong run',x=>x.runtime.runKey='other'],
 ['unmerged PR',x=>x.repository.merged=false],
 ['conflicting commit',x=>x.repository.mergeSha='wrong'],
 ['missing accounting',x=>delete x.runtime.spend],
 ['incomplete node',x=>x.runtime.nodes[0].status='running'],
 ['duplicate node',x=>x.runtime.nodes[0].key='b'],
 ['open exception',x=>x.runtime.openExceptions=1],
 ['stale observation',x=>x.runtime.observedAt='2020-01-01T00:00:00Z'],
 ['future observation',x=>x.runtime.observedAt='2030-01-01T00:00:00Z'],
 ['missing provenance',x=>delete x.repository.sourceRef]
]) test(name,()=>{const x=fixture();mutate(x);assert.equal(evaluate(c,x,now).status,'EVIDENCE_REQUIRED');});
test('approval request never executes, even if caller asserts approval',()=>{const x=fixture();x.requestedAction='external_outreach';x.approved=true;const r=evaluate(c,x,now);assert.equal(r.status,'WAITING_OWNER');assert.equal(r.externalActionPerformed,false);});
test('malformed contract fails closed',()=>{const d=structuredClone(c);delete d.approvals;assert.equal(evaluate(d,fixture(),now).status,'INVALID_CONTRACT');});
test('graph binds exact procedure and contains only current permitted reads',()=>{const g=compileReadGraph(c);assert.equal(g.scope_contract.workflow.contract_hash,digest(c));assert.equal(g.nodes.length,2);assert.ok(g.nodes.every(n=>n.authority_class==='read_only'));});
test('hash stable across key ordering, changed by procedure edits',()=>{assert.equal(digest({a:1,b:2}),digest({b:2,a:1}));const d=structuredClone(c);d.procedure.version++;assert.notEqual(digest(c),digest(d));});
test('all declared fields are present',()=>assert.deepEqual(validateContract(c),[]));
export { fixture, c, now };
