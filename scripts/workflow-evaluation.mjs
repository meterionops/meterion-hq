import {readFileSync,writeFileSync} from 'node:fs';
import {evaluate,digest} from './workflow-verifier.mjs';
const read=p=>JSON.parse(readFileSync(new URL(p,import.meta.url),'utf8'));
const v1=read('../workflows/project-verification-v1.json'),v2=read('../workflows/project-verification-v2.json');
const observation=read('../evidence/real-observation-v2.json');
const now=Date.parse(read('../evidence/verified-report-v2.json').evaluatedAt);
const cases=[
 {name:'recorded_real_observation',synthetic:false,expected:'VERIFIED',input:observation},
 {name:'repository_conflict',synthetic:true,expected:'EVIDENCE_REQUIRED',input:{...observation,repository:{...observation.repository,mergeSha:'conflicting-commit'}}},
 {name:'external_action',synthetic:true,expected:'WAITING_OWNER',input:{...observation,requestedAction:'deploy'}},
 {name:'unattended_overclaim',synthetic:true,expected:'EVIDENCE_REQUIRED',input:{...observation,requestedExecutionScope:'unattended_service'}}
];
const results=cases.map(c=>({name:c.name,synthetic:c.synthetic,expected:c.expected,v1:evaluate(v1,c.input,now).status,v2:evaluate(v2,c.input,now).status}));
const report={kind:'historical_snapshot_replay_not_fresh_verification',evaluatedAt:new Date(now).toISOString(),contractHashes:{v1:digest(v1),v2:digest(v2)},cases:results,metrics:{executableCoverage:{numerator:3,denominator:5,definition:'Of five declared steps, runtime collection, repository collection and deterministic evaluation are mechanized. Contract recovery and report persistence remain session-operated. Detailed source reads use authorized connectors outside the two-node PER graph.',baseline:3},safeCoverage:{definition:'Expected outcomes in fixed four-case evaluation set; not a production safety rate',v1:results.filter(r=>r.v1===r.expected).length,v2:results.filter(r=>r.v2===r.expected).length,denominator:4},operatorAttention:{additionalUserInterventions:0,humanMinutes:null,agentMinutes:null,definition:'No additional user input requested during this pilot; attention time not instrumented'},learningVelocity:{validatedProcedureRevisions:1,productionRate:null,definition:'One source-review finding led to v1 to v2 revision and evaluation; no production learning-rate claim'}}};
writeFileSync(new URL('../evidence/evaluation-metrics.json',import.meta.url),JSON.stringify(report,null,2)+'\n');
if(results.some(r=>r.v2!==r.expected))process.exitCode=1;
console.log(JSON.stringify(report,null,2));
