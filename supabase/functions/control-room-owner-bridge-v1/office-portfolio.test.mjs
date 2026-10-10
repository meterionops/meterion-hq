import test from 'node:test';
import assert from 'node:assert/strict';
import {buildOfficePortfolio, readOfficePortfolio, publicResult} from './office-portfolio.mjs';
const p={id:'a',project_key:'a',name:'A',phase:'BUILD',state_version:3,verified_at:'2026-09-01',classification_verified:false,secret:'hidden'};
test('canonical fields preserved; fetch date does not overwrite verification; metadata allowlist',()=>{
 const result=buildOfficePortfolio([p],[{project_id:'a',connection_type:'production',url:'https://a.test',updated_at:'2026-10-01',metadata:{secret:'hidden',published:true}}],'2026-10-07');
 assert.equal(result.entries[0].state_version,3);assert.equal(result.entries[0].verified_at,p.verified_at);assert.equal(result.observed_at,'2026-10-07');assert.doesNotMatch(JSON.stringify(result),/hidden|secret/);
});
test('explicit child identity, domains and DNS evidence preserved',()=>{
 const child={id:'child',parent_project_id:'a',name:'FI',domains:[{url:'https://fi.test',dns_provider:'DNS',dns_checked_at:'2026-10-04',nameservers:['ns.test'],token:'hidden'}],secret:'hidden'};
 const result=buildOfficePortfolio([p],[{project_id:'a',metadata:{office_product:child}}]);assert.equal(result.entries[0].products[0].id,'child');assert.deepEqual(result.entries[0].products[0].domains[0].nameservers,['ns.test']);assert.doesNotMatch(JSON.stringify(result),/hidden/);
});
test('wrong binding, duplicate projects and duplicate products fail closed',()=>{
 assert.throws(()=>buildOfficePortfolio([p,p],[]));
 assert.throws(()=>buildOfficePortfolio([p],[{project_id:'a',metadata:{office_product:{id:'x',parent_project_id:'b'}}}]));
 assert.throws(()=>buildOfficePortfolio([p],[1,2].map(()=>({project_id:'a',metadata:{office_product:{id:'x',parent_project_id:'a'}}}))));
});
test('conflicting publication is unknown; foreign connections and unsafe domains omitted',()=>{
 const c=[true,false].map(published=>({project_id:'a',metadata:{published}}));c.push({project_id:'foreign',connection_type:'production',url:'https://foreign.test'});c.push({project_id:'a',connection_type:'production',url:'https://user:pass@unsafe.test'});
 const e=buildOfficePortfolio([p],c).entries[0];assert.equal(e.publication_status,'unknown');assert.deepEqual(e.domains,[]);
});
function admin({ownerRows=[{id:'a'}],projects=[p,{...p,id:'foreign'}],connections=[],work=[],failure}={}){
 const calls=[];return {calls,rpc:async()=>{calls.push('tracking');return {data:projects,error:failure==='tracking'?{}:null}},from(table){calls.push(table);const q={select(){return q},eq(k,v){calls.push([k,v]);return q},in(k,v){calls.push([k,v]);return q},order(){return q},async limit(){return {count:(table==='control_room_projects'?ownerRows:table==='control_room_project_work_units_v1'?work:connections).length,data:table==='control_room_projects'?ownerRows:table==='control_room_project_work_units_v1'?work:connections,error:failure===table?{}:null}}};return q}};
}
test('organization scope precedes tracking and excludes foreign rows',async()=>{
 const a=admin();const dto=await readOfficePortfolio(a,'org');assert.equal(dto.entries.length,1);assert.equal(dto.entries[0].id,'a');assert.deepEqual(a.calls.slice(0,3),['control_room_projects',['organization_id','org'],'tracking']);
});
test('empty authorized registry is distinct from source error',async()=>{
 assert.deepEqual((await readOfficePortfolio(admin({ownerRows:[]}),'org')).entries,[]);
 for(const failure of ['control_room_projects','tracking','control_room_project_connections'])await assert.rejects(readOfficePortfolio(admin({failure}),'org'));
 await assert.rejects(readOfficePortfolio(admin(),null));
});
test('missing scoped tracking record fails rather than silently dropping project',async()=>{
 await assert.rejects(readOfficePortfolio(admin({projects:[]}),'org'));
});


test('work records are scoped and execution secrets omitted',async()=>{
 const dto=await readOfficePortfolio(admin({work:[{id:'w',project_id:'a',objective:'Goal',status:'active',execution_token:'hidden'},{id:'other',project_id:'foreign',objective:'foreign goal'}]}),'org');
 assert.equal(dto.entries[0].work_units.length,1); assert.equal(dto.entries[0].work_status,'available'); assert.doesNotMatch(JSON.stringify(dto),/hidden|foreign goal/);
});
test('work source failure preserves portfolio and reports unavailable',async()=>{
 const dto=await readOfficePortfolio(admin({failure:'control_room_project_work_units_v1'}),'org');
 assert.equal(dto.entries[0].work_status,'unavailable'); assert.deepEqual(dto.entries[0].work_units,[]);
});

test('worker result strips nested secret fields and limits evidence',()=>{
 const r=publicResult({summary:'Real check',execution_token:'hidden',countries:[{country_code:'FI',search_console:{secret:'hidden'},token:'hidden'},null],alerts:['OK',{secret:'hidden'}],source_tables:['site_instances']});
 assert.doesNotMatch(JSON.stringify(r),/hidden|secret|token/);assert.equal(r.countries[0].country_code,'FI');assert.deepEqual(r.alerts,['OK']);
});
test('simple work result needs evidence and never queries graph runtime',async()=>{
 const result={summary:'Checked',verified_at:'2026-10-10T07:00:00Z',observed_at:'2026-10-10T06:00:00Z',checks:['coverage'],source_project:'calendar',source_tables:['metrics']};
 const a=admin({work:[{id:'w',project_id:'a',status:'completed',metadata:{office_result:result}},{id:'active',project_id:'a',status:'active',metadata:{office_result:result}},{id:'missing',project_id:'a',status:'completed',metadata:{office_result:{summary:'unsupported'}}}]});
 const ws=(await readOfficePortfolio(a,'org')).entries[0].work_units;
 assert.equal(ws[0].result.summary,'Checked');assert.equal(ws[1].result,null);assert.equal(ws[2].result,null);assert.ok(!a.calls.some(c=>typeof c==='string'&&c.includes('graph')));
});
