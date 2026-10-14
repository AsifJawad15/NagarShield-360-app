import { readFile } from 'node:fs/promises'
import { resolve, join } from 'node:path'
import { createRequire } from 'node:module'

const webRoot = resolve(process.env.NAGAR_WEB_DIR || '../NagarShield-360')
const require = createRequire(join(webRoot, 'package.json'))
const { createClient } = require('@supabase/supabase-js')
const config = JSON.parse(await readFile('config/supabase.local.json', 'utf8'))
const groups = [
  ['staff', JSON.parse(await readFile('config/demo-accounts.local.json', 'utf8'))],
  ['public', JSON.parse(await readFile('config/public-demo-accounts.local.json', 'utf8'))],
  ['survey', [JSON.parse(await readFile('config/survey-operator.local.json', 'utf8'))]],
]
for (const [group, accounts] of groups) {
  for (const account of accounts) {
    const api = createClient(config.SUPABASE_URL, config.SUPABASE_PUBLISHABLE_KEY, {
      auth: { persistSession: false, autoRefreshToken: false },
    })
    const { data, error } = await api.auth.signInWithPassword({
      email: account.email, password: account.password,
    })
    if (error || !data.user) throw new Error(`Login failed: ${group} ${account.email}`)
    if (group !== 'public') {
      const profile = await api.from('profiles').select('role').eq('id', data.user.id).single()
      if (profile.error) throw new Error(`Role lookup failed: ${group} ${account.email}`)
      if (profile.data.role !== (account.role ?? 'survey_operator')) {
        throw new Error(`Role mismatch: ${group} ${account.email}`)
      }
    }
    process.stdout.write(`${group}: ${account.email} OK\n`)
  }
}
