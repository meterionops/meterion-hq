import assert from 'node:assert/strict';import fs from 'node:fs';import vm from 'node:vm';import {runTeamCycle,parseProposal,parseAnalysis,bindings} from '../supabase/functions/control-room-owner-bridge-v1/team-cycle.mjs';import {publicTeam,buildOfficePortfolio} from '../supabase/functions/control-room-owner-bridge-v1/office-portfolio.mjs';
const target={key:'sample',name:'Sample',brief:{status:'proposed',objective:'Goal',mvp:['Do one thing'],acceptance:['Check one thing']}};
const proposal={target_key:'sample',objective:'Valmistele rajattu tuote',steps:['Määritä syöte','Tee tulos','Tarkista tulos'],acceptance:['Syöte toimii','Tulos vastaa briefiä'],risks:[]};
assert.throws(()=>parseProposal(JSON.stringify({...proposal,target_key:'other'}),target));assert.throws(()=>parseAnalysis('{"approve":"yes"}'));
function mock({reject=false,providerFail=false,readbackFail=false,changed=false,replay=false}={}){
 let work,graph,nodes={},calls=0,saved=0;
 const binding=bindings['digital-studio'];const plan={schema_version:1,parent_project_id:binding.id,operations:{schema_version:1,authority_recorded_at:'2026-10-13'},brands:[{key:'sample',name:'Sample',build_brief:target.brief}]};
 const admin={from(table){const filters={};const query={select(){return query;},eq(k,v){filters[k]=v;return query;},single(){return resolve();},maybeSingle(){return resolve();}};
 async function resolve(){if(table==='control_room_projects')return {data:{id:binding.id,project_key:'digital-studio',kind:'candidate',organization_id:'2e737407-7aa5-4567-a8bf-0d110cfef2ae'}};
 if(table==='control_room_project_current_v2')return {data:{version:1}};
 if(table==='control_room_project_connections')return {data:{id:binding.connection,project_id:binding.id,metadata:{office_incubator:changed&&calls>1?{...plan,brands:[{...plan.brands[0],build_brief:{...target.brief,objective:'Changed'}}]}:plan}}};
 if(table==='control_room_project_graph_runs_v1')return {data:replay?{run_key:'old'}:graph?{run_key:graph}:null};
 if(table==='control_room_project_work_units_v1')return {data:{metadata:{office_team:{artifact:readbackFail?{}:work}}}};throw Error(table);}
 return query;},async rpc(name,p){
 if(name==='control_room_create_project_work_graph_v1'){graph=p.p_run_key;assert.equal(p.p_nodes.length,6);assert.equal(p.p_edges.length,5);nodes=Object.fromEntries(p.p_nodes.map((n,i)=>[n.node_key,{status:i===0?'ready':'waiting_dependency'}]));return {data:{idempotent_replay:false}};}
 if(name==='control_room_transition_project_graph_node_v1'){const n=nodes[p.p_node_key];assert.equal(n.status,p.p_expected_status);n.status=p.p_new_status;n.result=p.p_result;n.evidence=p.p_evidence;if(n.status==='completed'){const keys=Object.keys(nodes),next=nodes[keys[keys.indexOf(p.p_node_key)+1]];if(next)next.status='ready';}return {data:{}};}
 if(name==='control_room_save_incubator_team_artifact_v1'){assert.equal(nodes.execute.status,'running');work=p.p_artifact;saved++;return {data:{artifact:work}};}throw Error(name);}};
 const fetcher=async(url,opt)=>{calls++;const input=JSON.parse(opt.body);assert.equal(input.input_classification,'non_personal');assert(!opt.body.includes('access_token'));if(providerFail)return {ok:false};return {ok:true,json:async()=>({bounded_runtime_verified:true,runtime_run_id:'runtime-'+calls,provider:'openai',model:'registered',estimated_cost_usd:.01,output_text:JSON.stringify(calls===1?proposal:{approve:!reject,reason:reject?'Liian laaja':'Vastaa briefiä',risks:[]})})};};
 return {admin,fetcher,get:()=>({nodes,calls,saved,work})};
}
for(const option of [{},{reject:true},{providerFail:true},{readbackFail:true},{changed:true},{replay:true}]){
 const m=mock(option);const result=await runTeamCycle(m.admin,'Bearer mock','digital-studio',m.fetcher,new Date('2026-10-13T18:00:00Z'));const state=m.get();
 if(option.replay){assert(result.replayed);assert.equal(state.calls,0);}
 else if(Object.keys(option).length){assert(result.blocked);assert(Object.values(state.nodes).some(n=>n.status==='failed'));if(!option.readbackFail)assert.equal(state.saved,0);}
 else{assert(result.verified);assert.equal(state.calls,2);assert.equal(state.saved,1);assert(Object.values(state.nodes).every(n=>n.status==='completed'));assert.equal(state.work.artifact_status,'proposed');}
}
assert.equal(publicTeam({schema_version:1,run_key:'bad'}),null);
console.log('PASS: bounded six-stage runtime, idempotency, rejection, failures, source preservation and safe projection');
