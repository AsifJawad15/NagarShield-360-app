import { readFile } from 'node:fs/promises'
import { resolve, join } from 'node:path'
import { createRequire } from 'node:module'

const webRoot = resolve(process.env.NAGAR_WEB_DIR || '../NagarShield-360')
const require = createRequire(join(webRoot, 'package.json'))
const { createClient } = require('@supabase/supabase-js')
const config = JSON.parse(await readFile('config/supabase.local.json', 'utf8'))
const staff = JSON.parse(await readFile('config/demo-accounts.local.json', 'utf8'))
const executive = staff.find(account => account.role === 'executive')
const api = createClient(config.SUPABASE_URL, config.SUPABASE_PUBLISHABLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
})
const auth = await api.auth.signInWithPassword({ email: executive.email, password: executive.password })
if (auth.error) throw auth.error
for (const [name, select] of [
  ['scenarios', 'id,title_bn,kind'],
  ['observations', 'id,title_bn,status,source'],
  ['incidents', 'id,code,title_bn,status,department_id'],
  ['tasks', 'id,incident_id,status,department_id,assignee_id'],
]) {
  const { data, error } = await api.from(name).select(select)
  if (error) throw error
  const counts = {}
  for (const row of data) {
    const key = row.status ?? row.source ?? row.kind ?? 'all'
    counts[key] = (counts[key] ?? 0) + 1
  }
  process.stdout.write(`${name}: ${data.length} ${JSON.stringify(counts)}\n`)
}
