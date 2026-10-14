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
const path = 'config/public-demo-accounts.local.json'
let prior = []
try { prior = JSON.parse(await readFile(path, 'utf8')) } catch {}
const { data: listed, error: listError } = await admin.auth.admin.listUsers({ perPage: 1000 })
if (listError) throw listError
const accounts = []
for (const slot of ['A','B','C']) {
  const email = 'public-demo-' + slot.toLowerCase() + '@nagarshield.example'
  const existing = listed.users.find(user => user.email?.toLowerCase() === email)
  const saved = prior.find(item => item.slot === slot && item.email === email)
  if (existing && !saved) throw new Error('Account exists without a local password for slot ' + slot)
  const password = saved?.password || randomBytes(24).toString('base64url')
  let id = existing?.id
  if (!id) {
    const { data, error } = await admin.auth.admin.createUser({
      email, password, email_confirm: true,
      user_metadata: { nagar_public_demo_slot: slot },
    })
    if (error || !data.user) throw error || new Error('Account creation failed')
    id = data.user.id
  }
  accounts.push({ slot, id, email, password })
}
await writeFile(path, JSON.stringify(accounts, null, 2) + '\n', { mode: 0o600 })
process.stdout.write('Three separate public demo accounts are ready. Credentials saved only in ignored local app config.\n')