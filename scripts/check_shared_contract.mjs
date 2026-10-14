import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { resolve, join } from 'node:path'
import { createRequire } from 'node:module'

const webRoot = resolve(process.env.NAGAR_WEB_DIR || '../NagarShield-360')
const require = createRequire(join(webRoot, 'package.json'))
const { createClient } = require('@supabase/supabase-js')
const config = JSON.parse(await readFile('config/supabase.local.json', 'utf8'))
const staff = JSON.parse(await readFile('config/demo-accounts.local.json', 'utf8'))
const citizens = JSON.parse(await readFile('config/public-demo-accounts.local.json', 'utf8'))
const client = () => createClient(config.SUPABASE_URL, config.SUPABASE_PUBLISHABLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
})
const official = client()
const executive = staff.find(item => item.role === 'executive')
assert(executive, 'Missing executive test account')
const login = await official.auth.signInWithPassword({ email: executive.email, password: executive.password })
if (login.error) throw login.error
const failures = []
for (const [table, columns] of [
  ['survey_missions','id,operator_id,department_id,kind,site_label'],
  ['observations','id,source,scenario_id,report_code,media_key'],
  ['media_assets','id,storage_key,stage'],
]) {
  const { data, error } = await official.from(table).select(columns).limit(1)
  if (error) failures.push(`${table} shared schema: ${error.message}`)
  else process.stdout.write(`${table}: shared columns available (${data.length} sampled)\n`)
}
const owned = []
for (const citizen of citizens.slice(0,2)) {
  const api = client()
  const result = await api.auth.signInWithPassword({ email: citizen.email, password: citizen.password })
  if (result.error) throw result.error
  const { data, error } = await api.rpc('public_report_status')
  if (error) throw error
  owned.push(new Set(data.map(row => row.id)))
  const { data: profiles, error: profileError } = await api.from('profiles').select('id')
  if (profileError) throw profileError
  assert.equal(profiles.length,0,'Citizen account can see an official profile')
}
assert(owned.length === 2, 'Two public demo identities are required')
assert([...owned[0]].every(id => !owned[1].has(id)), 'A/B report ownership overlaps')
process.stdout.write('Citizen A/B status ownership and official profile isolation passed.\n')
if (failures.length) {
  failures.forEach(message => process.stderr.write(`${message}\n`))
  process.exitCode = 1
}
