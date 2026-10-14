import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { resolve, join } from 'node:path'
import { createRequire } from 'node:module'

const webRoot = resolve(process.env.NAGAR_WEB_DIR || '../NagarShield-360')
const require = createRequire(join(webRoot, 'package.json'))
const { createClient } = require('@supabase/supabase-js')
const config = JSON.parse(await readFile('config/supabase.local.json', 'utf8'))
const staff = JSON.parse(await readFile('config/demo-accounts.local.json', 'utf8'))
const api = createClient(config.SUPABASE_URL, config.SUPABASE_PUBLISHABLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
})
const worker = staff.find(item => item.role === 'field_employee' && item.department_id === 'drainage')
const auth = await api.auth.signInWithPassword({ email: worker.email, password: worker.password })
if (auth.error) throw auth.error
const incidentId = '200ef8f7-2e9d-4839-a5be-3af84c442d14'
async function value(operation, label) {
  const { data, error } = await operation
  if (error) throw new Error(`${label}: ${error.message}`)
  return data
}
const incident = await value(api.from('incidents').select('after_key').eq('id', incidentId).single(), 'incident')
const task = await value(api.from('tasks').select('id,status').eq('incident_id', incidentId).eq('assignee_id', auth.data.user.id).single(), 'task')
const before = await value(api.from('events').select('id').eq('incident_id', incidentId).eq('kind', 'submit_task'), 'events before')
assert.equal(task.status, 'resolved')
const result = await value(api.rpc('submit_task_evidence', {
  p_task_id: task.id,
  p_note: 'Synthetic after evidence attached for live workflow test.',
  p_media_key: incident.after_key,
  p_mime_type: 'image/png',
}), 'idempotent evidence retry')
assert.equal(result, task.id)
const after = await value(api.from('events').select('id').eq('incident_id', incidentId).eq('kind', 'submit_task'), 'events after')
assert.equal(after.length, before.length)
process.stdout.write('Live task evidence retry is idempotent.\n')
