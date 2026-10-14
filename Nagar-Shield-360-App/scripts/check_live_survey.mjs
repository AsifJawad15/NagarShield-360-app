import { readFile } from 'node:fs/promises'
import { resolve, join } from 'node:path'
import { createRequire } from 'node:module'
import { randomUUID } from 'node:crypto'
import assert from 'node:assert/strict'

const webRoot = resolve(process.env.NAGAR_WEB_DIR || '../NagarShield-360')
const require = createRequire(join(webRoot, 'package.json'))
const { createClient } = require('@supabase/supabase-js')
const config = JSON.parse(await readFile('config/supabase.local.json', 'utf8'))
const surveyAccount = JSON.parse(await readFile('config/survey-operator.local.json', 'utf8'))
const staff = JSON.parse(await readFile('config/demo-accounts.local.json', 'utf8'))
function client() { return createClient(config.SUPABASE_URL, config.SUPABASE_PUBLISHABLE_KEY,
  { auth: { persistSession: false, autoRefreshToken: false } }) }
async function login(account) {
  const api = client()
  const { data, error } = await api.auth.signInWithPassword({ email: account.email, password: account.password })
  if (error || !data.user) throw error || new Error('Sign in failed')
  return { api, uid: data.user.id }
}
async function value(operation, label) {
  const { data, error } = await operation
  if (error) throw new Error(label + ': ' + error.message)
  return data
}
const operator = await login(surveyAccount)
const executive = await login(staff.find(item => item.role === 'executive'))
const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9ZlN8AAAAASUVORK5CYII=', 'base64')
const site = 'DEMO TEST narrow gap ' + randomUUID().slice(0,8)
let firstObservation
for (let index = 0; index < 2; index++) {
  const missionId = await value(operator.api.rpc('create_survey_mission', {
    p_kind: 'gapscan',
    p_area: 'Synthetic demo area',
    p_site: site,
    p_capture_source: 'phone',
    p_captured_at: new Date(Date.now() - index * 3600000).toISOString(),
    p_permission_ref: null,
    p_notes: 'Synthetic repeated observation',
  }), 'create GapScan mission')
  const requestId = randomUUID()
  const key = 'survey/' + operator.uid + '/' + requestId + '.png'
  await value(operator.api.storage.from('evidence').upload(key, png, { contentType: 'image/png' }), 'survey upload')
  const observationId = await value(operator.api.rpc('submit_survey_observation', {
    p_request_id: requestId,
    p_mission_id: missionId,
    p_title: 'DEMO TEST GapScan pass ' + (index + 1),
    p_description: 'Synthetic repeated narrow gap observation',
    p_category: 'DRAIN_OBSTRUCTION',
    p_lat: 23.8071,
    p_lng: 90.3679,
    p_media_key: key,
    p_mime_type: 'image/png',
  }), 'submit survey observation')
  const asset = await value(operator.api.from('media_assets').select('id').eq('observation_id', observationId).single(), 'survey media asset')
  await value(operator.api.rpc('save_media_annotation', {
    p_media_id: asset.id,
    p_label: 'Manual demo box',
    p_shape: 'box',
    p_points: [0.1, 0.2, 0.5, 0.4],
    p_from_ms: null,
    p_to_ms: null,
  }), 'save normalized box')
  if (index === 0) {
    const invalid = await operator.api.rpc('save_media_annotation', {
      p_media_id: asset.id, p_label: 'Outside image',
      p_shape: 'box', p_points: [1.2, 0.2, 0.5, 0.4],
    })
    assert(invalid.error, 'Out of bounds annotation was accepted')
    const noReview = await operator.api.rpc('review_intake_observation', {
      p_id: observationId, p_approve: true,
    })
    assert(noReview.error, 'Survey operator verified own observation')
    firstObservation = observationId
  }
}
const missions = await value(operator.api.from('survey_missions').select('id').eq('site_label', site), 'repeated site')
assert.equal(missions.length, 2)
const incidentId = await value(executive.api.rpc('review_intake_observation', {
  p_id: firstObservation, p_approve: true, p_note: 'Synthetic GapScan human review',
}), 'executive survey verification')
const incident = await value(executive.api.from('incidents').select('id,observation_id').eq('id', incidentId).single(), 'verified survey incident')
assert.equal(incident.observation_id, firstObservation)
process.stdout.write('Live GapScan repeat, survey ownership, normalized annotation, invalid box rejection, and human review passed.\n')
process.stdout.write('Synthetic survey incident: ' + incidentId + '\n')