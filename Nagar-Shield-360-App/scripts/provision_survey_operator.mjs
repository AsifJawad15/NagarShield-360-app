import { readFile, writeFile } from 'node:fs/promises'
import { randomBytes } from 'node:crypto'
import { resolve, join } from 'node:path'
import { createRequire } from 'node:module'

const webRoot = resolve(process.env.NAGAR_WEB_DIR || '../NagarShield-360')
const require = createRequire(join(webRoot, 'package.json'))
const { createClient } = require('@supabase/supabase-js')
const config = JSON.parse(await readFile('config/supabase.local.json', 'utf8'))
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY
if (!serviceKey) throw new Error('Service role key required in server environment')
const admin = createClient(config.SUPABASE_URL, serviceKey, {
  auth: { persistSession: false, autoRefreshToken: false },
})
const email = 'survey-operator@nagarshield.example'
const path = 'config/survey-operator.local.json'
let saved
try { saved = JSON.parse(await readFile(path, 'utf8')) } catch {}
const { data: listed, error: listError } = await admin.auth.admin.listUsers({ perPage: 1000 })
if (listError) throw listError
const existing = listed.users.find(user => user.email?.toLowerCase() === email)
if (existing && !saved) throw new Error('Survey account exists without local password')
const password = saved?.password || randomBytes(24).toString('base64url')
let id = existing?.id
if (!id) {
  const { data, error } = await admin.auth.admin.createUser({
    email, password, email_confirm: true,
    user_metadata: { nagar_survey_demo: true },
  })
  if (error || !data.user) throw error || new Error('Survey account creation failed')
  id = data.user.id
}
const { error: profileError } = await admin.from('profiles').upsert({
  id, display_name: 'Survey Operator Demo', role: 'survey_operator',
  department_id: 'inspection', team_id: null,
})
if (profileError) throw profileError
await writeFile(path, JSON.stringify({ id, email, password }, null, 2) + '\n', { mode: 0o600 })
process.stdout.write('Survey operator demo account and inspection profile are ready.\n')