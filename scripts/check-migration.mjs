import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { PGlite } from '@electric-sql/pglite'

const db = new PGlite()
await db.exec(`
create role anon; create role authenticated; create role service_role;
create schema auth; create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
create function auth.role() returns text language sql stable as $$ select nullif(current_setting('request.jwt.claim.role',true),'') $$;
create schema storage;
create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text,name text);
alter table storage.objects enable row level security;
grant usage on schema public,auth,storage to anon,authenticated,service_role;
grant select on storage.objects to authenticated;
`)
const migration = await readFile(new URL('../supabase/migrations/202610130001_prototype.sql', import.meta.url), 'utf8')
// PGlite has built-in gen_random_uuid() but does not package Supabase's pgcrypto extension.
try { await db.exec(migration.replace('create extension if not exists pgcrypto;', '')) }
catch (error) { process.stderr.write(`Migration failed: ${error.message}\n${error.detail || ''}\n`); process.exit(1) }
const resetHotfix = await readFile(new URL('../supabase/migrations/202610130002_reset_hotfix.sql', import.meta.url), 'utf8')
// PGlite does not include Supabase safe updates, so guard against the original failure explicitly.
assert.match(resetHotfix, /truncate table public\.notifications/)
assert.doesNotMatch(resetHotfix, /delete\s+from\s+public\./i)
await db.exec(resetHotfix)
const count = await db.query('select count(*)::int as count from public.incidents')
assert.equal(count.rows[0].count, 18)
const scores = await db.query(`select id,score,round(least(100,
  (factors->>'drain')::numeric*.30+(factors->>'vector')::numeric*.25+
  (factors->>'waste')::numeric*.15+(factors->>'access')::numeric*.15+
  (factors->>'recurrence')::numeric*.10+(factors->>'evidence')::numeric*.05+
  (factors->>'bonus')::numeric))::int as expected from public.scenarios`)
for (const row of scores.rows) assert.equal(row.score,row.expected,`Score mismatch: ${row.id}`)

const users = [
  ['00000000-0000-4000-8000-000000001001','নির্বাহী','executive',null,null],
  ['00000000-0000-4000-8000-000000001002','প্রধান','department_head','drainage',null],
  ['00000000-0000-4000-8000-000000001003','তত্ত্বাবধায়ক','supervisor','drainage','drainage-a'],
  ['00000000-0000-4000-8000-000000001004','ড্রেনেজ কর্মী','field_employee','drainage','drainage-a'],
  ['00000000-0000-4000-8000-000000001005','বর্জ্য কর্মী','field_employee','waste','waste-a'],
]
for (const [id,name,role,department,team] of users) {
  await db.query('insert into auth.users(id) values($1)',[id])
  await db.query('insert into public.profiles(id,display_name,role,department_id,team_id) values($1,$2,$3,$4,$5)',[id,name,role,department,team])
}
await db.exec("select set_config('request.jwt.claim.role','service_role',false); select public.reset_demo();")
await db.exec("insert into storage.objects(bucket_id,name) values ('demo-media','scenarios/drain.svg'),('demo-media','unlisted/private.svg')")

async function asUser(id, fn) {
  await db.exec('set role authenticated')
  await db.query("select set_config('request.jwt.claim.sub',$1,false)",[id])
  await db.exec("select set_config('request.jwt.claim.role','authenticated',false)")
  try { return await fn() } finally { await db.exec('reset role') }
}
const executiveId=users[0][0], supervisorId=users[2][0], drainageId=users[3][0], wasteId=users[4][0]
await asUser(executiveId, async () => {
  const visible=await db.query('select count(*)::int as count from public.incidents')
  assert.equal(visible.rows[0].count,18)
  const score=await db.query("select score from public.scenarios where id='mixed'")
  assert.equal(score.rows[0].score,90)
})
await asUser(drainageId, async () => {
  const visible=await db.query('select count(*)::int as count from public.incidents')
  assert(visible.rows[0].count>0 && visible.rows[0].count<18)
  const mapFeatures=await db.query('select count(*)::int as count from public.infrastructure')
  assert.equal(mapFeatures.rows[0].count,0)
  const media=await db.query('select name from storage.objects order by name')
  assert.deepEqual(media.rows.map(row=>row.name),['scenarios/drain.svg'])
})
await asUser(wasteId, async () => {
  const hidden=await db.query("select count(*)::int as count from public.incidents where department_id='drainage'")
  assert.equal(hidden.rows[0].count,0)
})
const assigned=await db.query("select id,incident_id from public.tasks where status='assigned' and assignee_id=$1 limit 1",[drainageId])
assert(assigned.rows.length)
const taskId=assigned.rows[0].id
await asUser(drainageId, async () => {
  await assert.rejects(db.query("select public.perform_demo_action('start_task',$1,'{}')",[taskId]))
  await db.query("select public.perform_demo_action('acknowledge_task',$1,'{}')",[taskId])
  await db.query("select public.perform_demo_action('start_task',$1,'{}')",[taskId])
  await db.query("select public.perform_demo_action('submit_task',$1,$2)",[taskId,JSON.stringify({media_key:'scenarios/clean.svg',note:'ডেমো কাজ শেষ হয়েছে'})])
})
await asUser(supervisorId, async () => {
  await db.query("select public.perform_demo_action('approve_task',$1,'{}')",[taskId])
})
const resolved=await db.query('select status from public.incidents where id=$1',[assigned.rows[0].incident_id])
assert.equal(resolved.rows[0].status,'resolved')
await asUser(wasteId, async () => {
  await assert.rejects(db.query("select public.perform_demo_action('reopen_task',$1,'{}')",[taskId]))
})
await asUser(supervisorId, async () => {
  const scenarios=await db.query('select count(*)::int as count from public.scenarios')
  assert.equal(scenarios.rows[0].count,0)
  await assert.rejects(db.query("select public.perform_demo_action('create_observation',null,$1)",[JSON.stringify({scenario_id:'drain'})]))
})
let newIncident
await asUser(executiveId, async () => {
  const observation=await db.query("select public.perform_demo_action('create_observation',null,$1) as id",[JSON.stringify({scenario_id:'mixed'})])
  const verified=await db.query("select public.perform_demo_action('verify_observation',$1,'{}') as id",[observation.rows[0].id])
  newIncident=verified.rows[0].id
  await db.query("select public.perform_demo_action('assign_task',$1,$2)",[newIncident,JSON.stringify({department_id:'drainage',assignee_id:drainageId,team_id:'drainage-a'})])
  await db.query("select public.perform_demo_action('assign_task',$1,$2)",[newIncident,JSON.stringify({department_id:'waste',assignee_id:wasteId,team_id:'waste-a'})])
})
await asUser(supervisorId, async () => {
  const visible=await db.query('select count(*)::int as count from public.incidents where id=$1',[newIncident])
  assert.equal(visible.rows[0].count,1)
})
await asUser(wasteId, async () => {
  const visible=await db.query('select count(*)::int as count from public.incidents where id=$1',[newIncident])
  assert.equal(visible.rows[0].count,1)
  await assert.rejects(db.query("select public.perform_demo_action('toggle_escalation',$1,'{}')",[newIncident]))
  await assert.rejects(db.query('select public.reset_demo()'))
})
const unprofiledId='00000000-0000-4000-8000-000000001006'
await db.query('insert into auth.users(id) values($1)',[unprofiledId])
await asUser(unprofiledId, async () => {
  await assert.rejects(db.query('select public.reset_demo()'))
  const incidents=await db.query('select count(*)::int as count from public.incidents')
  assert.equal(incidents.rows[0].count,0)
})
await asUser(executiveId, async () => {
  await db.query('select public.reset_demo()')
})
const restored=await db.query('select count(*)::int as count from public.incidents')
assert.equal(restored.rows[0].count,18)
await db.exec('set role anon')
await assert.rejects(db.query('select * from public.incidents'))
await db.exec('reset role')
process.stdout.write('Migration, seed, role visibility and task state transitions passed.\n')
await db.close()
