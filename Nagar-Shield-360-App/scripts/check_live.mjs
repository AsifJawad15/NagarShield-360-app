import { readFile } from 'node:fs/promises'
import { resolve, join } from 'node:path'
import { createRequire } from 'node:module'

const webRoot = resolve(process.env.NAGAR_WEB_DIR || '../NagarShield-360')
const require = createRequire(join(webRoot, 'package.json'))
const { createClient } = require('@supabase/supabase-js')
const config = JSON.parse(await readFile('config/supabase.local.json', 'utf8'))
const accounts = JSON.parse(await readFile('config/demo-accounts.local.json', 'utf8'))
const client = () => createClient(config.SUPABASE_URL, config.SUPABASE_PUBLISHABLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
})
const admin = client()
const executive = accounts.find(account => account.role === 'executive')
if (!executive) throw new Error('No executive demo account')
const { data: officialSession, error: signInError } = await admin.auth.signInWithPassword({
  email: executive.email,
  password: executive.password,
})
if (signInError) throw new Error('Executive sign in: ' + signInError.message)
const { data: missions, error: missionError } = await admin.from('survey_missions').select('id').limit(1)
if (missionError) throw new Error('Mobile schema: ' + missionError.message)
const { data: profile, error: profileError } = await admin.from('profiles').select('role').eq('id', officialSession.user.id).single()
if (profileError || profile?.role !== 'executive') throw new Error('Executive profile unavailable')
process.stdout.write('Live mobile schema and executive sign in passed. Survey mission rows visible: ' + missions.length + '\n')
const publicAccounts = JSON.parse(await readFile('config/public-demo-accounts.local.json', 'utf8'))
for (const account of publicAccounts) {
  const visitor = client()
  const { data: session, error: publicError } = await visitor.auth.signInWithPassword({
    email: account.email, password: account.password,
  })
  if (publicError || !session.user) throw new Error('Public demo sign in failed for slot ' + account.slot)
  const { data: statuses, error: statusError } = await visitor.rpc('public_report_status')
  if (statusError || !Array.isArray(statuses)) throw new Error('Public status unavailable for slot ' + account.slot)
}
process.stdout.write('Three public demo identities and owned status function passed.\n')