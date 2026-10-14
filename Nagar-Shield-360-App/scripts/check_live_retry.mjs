import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { resolve, join } from 'node:path'
import { createRequire } from 'node:module'
import { randomUUID } from 'node:crypto'

const webRoot = resolve(process.env.NAGAR_WEB_DIR || '../NagarShield-360')
const require = createRequire(join(webRoot, 'package.json'))
const { createClient } = require('@supabase/supabase-js')
const config = JSON.parse(await readFile('config/supabase.local.json', 'utf8'))
const staff = JSON.parse(await readFile('config/demo-accounts.local.json', 'utf8'))
const api = createClient(config.SUPABASE_URL, config.SUPABASE_PUBLISHABLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
})
const executive = staff.find(item => item.role === 'executive')
const auth = await api.auth.signInWithPassword({ email: executive.email, password: executive.password })
if (auth.error) throw auth.error
const incidentId = '200ef8f7-2e9d-4839-a5be-3af84c442d14'
async function escalation() {
  const { data, error } = await api.from('incidents').select('escalated').eq('id', incidentId).single()
  if (error) throw error
  return data.escalated
}
async function action(id) {
  const { data, error } = await api.rpc('perform_mobile_action', {
    p_request_id: id,
    p_action: 'toggle_escalation',
    p_target: incidentId,
    p_payload: { note: 'Synthetic retry verification' },
  })
  if (error) throw error
  return data
}
const before = await escalation()
const id = randomUUID()
try {
  const first = await action(id)
  const second = await action(id)
  assert.deepEqual(second, first)
  assert.equal(await escalation(), !before, 'Duplicate retry changed the incident twice')
  process.stdout.write('Live staff action retry is idempotent.\n')
} finally {
  if (await escalation() !== before) await action(randomUUID())
}
