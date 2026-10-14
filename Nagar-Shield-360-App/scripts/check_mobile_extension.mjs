import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { resolve, join } from 'node:path'
import { pathToFileURL } from 'node:url'

const webRoot = resolve(process.env.NAGAR_WEB_DIR || '../NagarShield-360')
const pgliteUrl = pathToFileURL(join(webRoot, 'node_modules/@electric-sql/pglite/dist/index.js'))
const { PGlite } = await import(pgliteUrl.href)
const db = new PGlite()

await db.exec(`
create role anon; create role authenticated; create role service_role;
create schema auth; create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
create function auth.role() returns text language sql stable as $$
  select nullif(current_setting('request.jwt.claim.role',true),'') $$;
create schema storage;
create table storage.buckets(id text primary key,name text,public boolean,
  file_size_limit bigint,allowed_mime_types text[]);
create table storage.objects(id uuid primary key default gen_random_uuid(),
  bucket_id text,name text);
create function storage.foldername(p_name text) returns text[] language sql immutable as $$
  select (string_to_array(p_name,'/'))[1:array_length(string_to_array(p_name,'/'),1)-1] $$;
create function storage.extension(p_name text) returns text language sql immutable as $$
  select split_part(p_name,'.',array_length(string_to_array(p_name,'.'),1)) $$;
alter table storage.objects enable row level security;
grant usage on schema public,auth,storage to anon,authenticated,service_role;
grant select,insert on storage.objects to authenticated;
`)

const base = await readFile(join(webRoot,'supabase/migrations/202610130001_prototype.sql'),'utf8')
const hotfix = await readFile(join(webRoot,'supabase/migrations/202610130002_reset_hotfix.sql'),'utf8')
const extension = await readFile(new URL('../supabase/mobile_extension.sql', import.meta.url),'utf8')
const retryExtension = await readFile(new URL('../supabase/mobile_extension_2.sql', import.meta.url),'utf8')
await db.exec(base.replace('create extension if not exists pgcrypto;', ''))
await db.exec(hotfix)
try { await db.exec(extension) }
catch (error) {
  process.stderr.write(`Mobile extension failed: ${error.message}\n${error.detail || ''}\n`)
  process.exit(1)
}
try { await db.exec(retryExtension) }
catch (error) {
  process.stderr.write(`Mobile retry extension failed: ${error.message}\n${error.detail || ''}\n`)
  process.exit(1)
}

const executive='00000000-0000-4000-8000-000000001001'
const publicUser='00000000-0000-4000-8000-000000001002'
const otherPublic='00000000-0000-4000-8000-000000001003'
for (const id of [executive,publicUser,otherPublic]) {
  await db.query('insert into auth.users(id) values($1)',[id])
}
await db.query(
  "insert into public.profiles(id,display_name,role) values($1,'Executive','executive')",
  [executive],
)
async function asUser(id, work) {
  await db.exec('set role authenticated')
  await db.query("select set_config('request.jwt.claim.sub',$1,false)",[id])
  await db.exec("select set_config('request.jwt.claim.role','authenticated',false)")
  try { return await work() } finally { await db.exec('reset role') }
}
const request='10000000-0000-4000-8000-000000000042'
let report
await asUser(publicUser, async () => {
  const values=[request,'Blocked drain','Water has remained for three days',
    ['DRAIN_OBSTRUCTION','STANDING_WATER'],'Market Road',23.8073,90.3683,'approximate']
  const created=await db.query(
    'select public.submit_public_report($1,$2,$3,$4,$5,$6,$7,$8) as id',values)
  report=created.rows[0].id
  const again=await db.query(
    'select public.submit_public_report($1,$2,$3,$4,$5,$6,$7,$8) as id',values)
  assert.equal(again.rows[0].id,report)
  const own=await db.query('select * from public.public_report_status()')
  assert.equal(own.rows.length,1)
  assert.equal(own.rows[0].status,'needs_review')
  assert.equal((await db.query('select count(*)::int as count from public.incidents')).rows[0].count,0)
})
await asUser(otherPublic, async () => {
  assert.equal((await db.query('select count(*)::int as count from public.observations')).rows[0].count,0)
  assert.equal((await db.query('select * from public.public_report_status()')).rows.length,0)
  await assert.rejects(db.query(
    'select public.submit_public_report($1,$2,$3,$4,$5,$6,$7,$8)',
    [request,'Other report','Another public report detail',
      ['WASTE'],'Other Road',23.8,90.3,'approximate']))
})
let incidentId
await asUser(executive, async () => {
  const reviewed=await db.query(
    'select public.review_intake_observation($1,true) as id',[report])
  incidentId=reviewed.rows[0].id
  assert(incidentId)
  const actionRequest='20000000-0000-4000-8000-000000000042'
  const actionSql="select public.perform_mobile_action($1,'toggle_escalation',$2,$3) as id"
  await db.query(actionSql,[actionRequest,incidentId,JSON.stringify({note:'retry test'})])
  await db.query(actionSql,[actionRequest,incidentId,JSON.stringify({note:'retry test'})])
  const incident=await db.query('select escalated from public.incidents where id=$1',[incidentId])
  assert.equal(incident.rows[0].escalated,true)
  await assert.rejects(db.query(actionSql,[actionRequest,incidentId,JSON.stringify({note:'different'})]))
})
await asUser(publicUser, async () => {
  const own=await db.query('select * from public.public_report_status()')
  assert.equal(own.rows[0].status,'verified')
  assert.equal((await db.query('select count(*)::int as count from public.incidents')).rows[0].count,0)
})
await asUser(executive, async () => {
  await db.query('select public.reset_demo()')
})
const preserved=await db.query('select count(*)::int as count from public.incidents where observation_id=$1',[report])
assert.equal(preserved.rows[0].count,1)
await db.close()
process.stdout.write('Mobile extension, ownership, review, idempotency, and reset passed.\n')
