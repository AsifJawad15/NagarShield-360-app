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
const publicAccounts = JSON.parse(await readFile('config/public-demo-accounts.local.json', 'utf8'))
const makeClient = () => createClient(config.SUPABASE_URL, config.SUPABASE_PUBLISHABLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
})
async function login(account) {
  const api = makeClient()
  const { error } = await api.auth.signInWithPassword({ email: account.email, password: account.password })
  if (error) throw error
  return api
}
async function value(operation, label) {
  const { data, error } = await operation
  if (error) throw new Error(`${label}: ${error.message}`)
  return data
}
const publicApi = await login(publicAccounts[2])
const executiveApi = await login(staff.find(item => item.role === 'executive'))
const observationId = await value(publicApi.rpc('submit_public_report', {
  p_request_id: randomUUID(),
  p_title: 'DEMO TEST dismiss retry',
  p_description: 'Synthetic report used to verify the mobile human review retry path.',
  p_categories: ['WASTE'],
  p_area: 'Synthetic demo area',
  p_lat: 23.8071,
  p_lng: 90.3679,
  p_precision: 'approximate',
}), 'public report')
const requestId = randomUUID()
const params = {
  p_request_id: requestId,
  p_action: 'dismiss_intake',
  p_target: observationId,
  p_payload: { note: 'Synthetic duplicate review test' },
}
const first = await value(executiveApi.rpc('perform_mobile_action', params), 'first review')
const second = await value(executiveApi.rpc('perform_mobile_action', params), 'duplicate review')
assert.equal(first, second)
const statuses = await value(publicApi.rpc('public_report_status'), 'public status')
assert.equal(statuses.find(row => row.id === observationId)?.status, 'dismissed')
process.stdout.write('Live intake review retry is idempotent.\n')
