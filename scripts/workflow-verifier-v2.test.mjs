import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { evaluate } from './workflow-verifier.mjs';
const c=JSON.parse(readFileSync(new URL('../workflows/project-verification-v2.json',import.meta.url)));
const real=JSON.parse(readFileSync(new URL('../evidence/real-observation-v2.json',import.meta.url)));
const now=Math.max(Date.parse(real.runtime.observedAt),Date.parse(real.repository.observedAt))+1000;
test('real source snapshot verifies only its declared scope',()=>assert.equal(evaluate(c,real,now).status,'VERIFIED'));
for(const [name,mutate] of [
 ['scope overclaim',x=>x.requestedExecutionScope='unattended_service'],
 ['scope absent',x=>delete x.executionScope],
 ['scope evidence absent',x=>delete x.scopeSourceRef],
 ['wrong exact nodes',x=>x.runtime.nodes[0].key='unrelated'],
 ['conflicting source',x=>x.repository.mergeSha='other'],
 ['missing observation',x=>delete x.repository.observedAt]
]) test(name,()=>{const x=structuredClone(real);mutate(x);assert.equal(evaluate(c,x,now).status,'EVIDENCE_REQUIRED');});
test('approval fixture cannot execute through the pilot',()=>{const x=structuredClone(real);x.requestedAction='send_email';assert.equal(evaluate(c,x,now).status,'WAITING_OWNER');});
