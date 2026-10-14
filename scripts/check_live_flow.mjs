import { readFile } from 'node:fs/promises'
import { resolve, join } from 'node:path'
import { createRequire } from 'node:module'
import { randomUUID } from 'node:crypto'
import assert from 'node:assert/strict'

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
  const { data, error } = await api.auth.signInWithPassword({
    email: account.email, password: account.password,
  })
  if (error || !data.user) throw error || new Error('Sign in failed')
  return { api, uid: data.user.id }
}
async function value(operation, label) {
  const { data, error } = await operation
  if (error) throw new Error(label + ': ' + error.message)
  return data
}
const first = await login(publicAccounts[0])
const second = await login(publicAccounts[1])
const executive = await login(staff.find(item => item.role === 'executive'))
const supervisor = await login(staff.find(item => item.role === 'supervisor' && item.department_id === 'drainage'))
const worker = await login(staff.find(item => item.role === 'field_employee' && item.department_id === 'drainage'))
const otherWorker = await login(staff.find(item => item.role === 'field_employee' && item.department_id === 'waste'))
const { count: resolvedBefore, error: beforeMetricError } = await executive.api
  .from('incidents').select('id', { count: 'exact', head: true }).eq('status','resolved')
if (beforeMetricError) throw beforeMetricError
const requestId = randomUUID()
const title = 'DEMO TEST public drain ' + requestId.slice(0, 8)
const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9ZlN8AAAAASUVORK5CYII=', 'base64')
const beforeKey = 'public/' + first.uid + '/' + requestId + '.png'
await value(first.api.storage.from('evidence').upload(beforeKey, png, { contentType: 'image/png' }), 'before upload')
const reportParams = {
  p_request_id: requestId,
  p_title: title,
  p_description: 'Synthetic hackathon workflow test with one pixel before evidence.',
  p_categories: ['DRAIN_OBSTRUCTION'],
  p_area: 'Synthetic demo area',
  p_lat: 23.8071,
  p_lng: 90.3679,
  p_precision: 'approximate',
  p_media_key: beforeKey,
  p_mime_type: 'image/png',
}
const observationId = await value(first.api.rpc('submit_public_report', reportParams), 'submit report')
assert.equal(await value(first.api.rpc('submit_public_report', reportParams), 'idempotent report retry'), observationId)
const foreignStatuses = await value(second.api.rpc('public_report_status'), 'foreign statuses')
assert(!foreignStatuses.some(item => item.id === observationId), 'Second public account read first account report')
const foreignRows = await value(second.api.from('observations').select('id').eq('id', observationId), 'foreign observation select')
assert.equal(foreignRows.length, 0, 'Second public account read first account observation')
const foreignRetry = await second.api.rpc('submit_public_report', reportParams)
assert(foreignRetry.error, 'Second public account reused request ID')
const publicReview = await first.api.rpc('review_intake_observation', { p_id: observationId, p_approve: true })
assert(publicReview.error, 'Public account could verify report')
const incidentId = await value(executive.api.rpc('review_intake_observation', {
  p_id: observationId, p_approve: true, p_note: 'Synthetic live acceptance test',
}), 'human review')
const taskId = await value(executive.api.rpc('perform_demo_action', {
  p_action: 'assign_task',
  p_target: incidentId,
  p_payload: {
    department_id: 'drainage',
    team_id: 'drainage-a',
    assignee_id: worker.uid,
    note: 'Synthetic field test task.',
  },
}), 'assign task')
const otherTasks = await value(otherWorker.api.from('tasks').select('id').eq('id', taskId), 'other team task select')
assert.equal(otherTasks.length, 0, 'Other team accessed task')
await value(worker.api.rpc('perform_demo_action', {
  p_action: 'acknowledge_task', p_target: taskId, p_payload: {},
}), 'accept task')
await value(worker.api.rpc('perform_demo_action', {
  p_action: 'start_task', p_target: taskId, p_payload: {},
}), 'start task')
const afterKey = 'task/' + worker.uid + '/' + randomUUID() + '.png'
await value(worker.api.storage.from('evidence').upload(afterKey, png, { contentType: 'image/png' }), 'after upload')
await value(worker.api.rpc('submit_task_evidence', {
  p_task_id: taskId,
  p_note: 'Synthetic after evidence attached for live workflow test.',
  p_media_key: afterKey,
  p_mime_type: 'image/png',
}), 'submit task evidence')
await value(supervisor.api.rpc('perform_demo_action', {
  p_action: 'approve_task', p_target: taskId, p_payload: { note: 'Synthetic approval test' },
}), 'approve task')
const ownedStatuses = await value(first.api.rpc('public_report_status'), 'owned statuses')
assert.equal(ownedStatuses.find(item => item.id === observationId)?.status, 'resolved')
const { count: resolvedAfter, error: metricError } = await executive.api.from('incidents')
  .select('id', { count: 'exact', head: true }).eq('status', 'resolved')
if (metricError) throw metricError
assert(resolvedAfter >= (resolvedBefore ?? 0) + 1, 'Executive resolved metric did not increase')
const events = await value(executive.api.from('events').select('kind').eq('incident_id', incidentId), 'audit events')
assert(events.length >= 5, 'Audit timeline incomplete')
process.stdout.write('Live public ownership, idempotency, human review, assignment, evidence, approval, status, and metrics passed.\n')
process.stdout.write('Synthetic test incident: ' + incidentId + '\n')
