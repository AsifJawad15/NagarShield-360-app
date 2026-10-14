import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { resolve, join } from 'node:path'
import { createRequire } from 'node:module'

const webRoot = resolve(process.env.NAGAR_WEB_DIR || '../NagarShield-360')
const require = createRequire(join(webRoot, 'package.json'))
const { createClient } = require('@supabase/supabase-js')
const config = JSON.parse(await readFile('config/supabase.local.json', 'utf8'))
const accounts = [
  ...JSON.parse(await readFile('config/demo-accounts.local.json', 'utf8')),
  { ...JSON.parse(await readFile('config/survey-operator.local.json', 'utf8')), role: 'survey_operator' },
]
const queries = [
  ['incidents', 'id,code,title_bn,status,priority,department_id'],
  ['tasks', 'id,incident_id,status,department_id,assignee_id,incidents(code,title_bn,area_bn,status)'],
  ['profiles', 'id,display_name,role,department_id,team_id'],
]
for (const account of accounts) {
  const api = createClient(config.SUPABASE_URL, config.SUPABASE_PUBLISHABLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  })
  const auth = await api.auth.signInWithPassword({
    email: account.email, password: account.password,
  })
  if (auth.error) throw auth.error
  const totals = {}
  for (const [table, fields] of queries) {
    const { data, error } = await api.from(table).select(fields)
    if (error) throw new Error(`${account.role} ${table}: ${error.message}`)
    totals[table] = data.length
    if (table === 'tasks' && account.role === 'field_employee') {
      assert(data.every(task => task.assignee_id === auth.data.user.id))
    }
  }
  if (account.role === 'survey_operator') {
    assert.equal(totals.incidents, 0)
    assert.equal(totals.tasks, 0)
  }
  process.stdout.write(`${account.role}: ${JSON.stringify(totals)}\n`)
}
