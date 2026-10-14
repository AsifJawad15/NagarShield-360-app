import { readFile } from 'node:fs/promises'
import { createClient } from '@supabase/supabase-js'

const url = process.env.NEXT_PUBLIC_SUPABASE_URL
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY
if (!url || !serviceKey) throw new Error('Set Supabase URL and service role key in .env.local')
const accounts = JSON.parse(await readFile(process.env.DEMO_ACCOUNTS_FILE || 'demo-accounts.local.json', 'utf8'))
if (!Array.isArray(accounts) || !accounts.length) throw new Error('Account file must contain a nonempty JSON array')
const roles = new Set(['executive','department_head','supervisor','field_employee','survey_operator'])
const departments = new Set(['drainage','waste','health','footpath','inspection'])
for (const account of accounts) {
  if (!account.email || !account.password || account.password.length < 5 || account.password.includes('REPLACE_') || !account.display_name || !roles.has(account.role) || (account.role !== 'executive' && !departments.has(account.department_id))) throw new Error('Invalid demo account definition or placeholder password')
  if (['supervisor','field_employee'].includes(account.role) && account.team_id !== `${account.department_id}-a`) throw new Error(`Team mismatch for ${account.email}`)
}
const admin = createClient(url, serviceKey, { auth: { autoRefreshToken: false, persistSession: false } })
const { data: listed, error: listError } = await admin.auth.admin.listUsers({ page: 1, perPage: 1000 })
if (listError) throw listError
for (const account of accounts) {
  const existing = listed.users.find(user => user.email?.toLowerCase() === account.email.toLowerCase())
  let id = existing?.id
  if (!id) {
    const { data, error } = await admin.auth.admin.createUser({ email: account.email, password: account.password, email_confirm: true })
    if (error || !data.user) throw error || new Error('Could not create account')
    id = data.user.id
  }
  const { error } = await admin.from('profiles').upsert({ id, display_name: account.display_name, role: account.role, department_id: account.role === 'executive' ? null : account.department_id, team_id: account.team_id || null })
  if (error) throw error
  process.stdout.write(`Provisioned ${account.role}: ${account.email}\n`)
}

const scenes = {
  drain: { sky:'#b7d2c5',road:'#adb9a8',accent:'#497968',objects:'<path d="M220 330h360l-34 112H260Z" fill="#344a43"/><path d="M247 346h290" stroke="#8ca494" stroke-width="12" stroke-dasharray="22 15"/><path d="M345 322q32-32 68 5l45 52-91 14Z" fill="#7c7751"/><circle cx="466" cy="371" r="20" fill="#b79c57"/>' },
  water: { sky:'#b9d6d0',road:'#aebcb1',accent:'#78b8ad',objects:'<ellipse cx="405" cy="388" rx="250" ry="80" fill="#77a8aa"/><path d="M200 382q180-35 410 9M300 430q120-30 270-9" stroke="#badad3" stroke-width="9" fill="none"/>' },
  waste: { sky:'#c8d9c8',road:'#b7bcad',accent:'#b69861',objects:'<path d="M240 410q65-145 130-40 40-140 125-40 90 10 110 85Z" fill="#6b7556"/><path d="M264 390 314 320l47 76M410 379l34-78 60 102" fill="#aa9563"/><circle cx="526" cy="384" r="26" fill="#d2b873"/>' },
  footpath: { sky:'#c6d9d1',road:'#c9c5ad',accent:'#be8c5d',objects:'<path d="M155 459 386 294 627 353l-210 114Z" fill="#e3d9ba"/><path d="M420 266h160v176H420Z" fill="#8c765e"/><path d="M410 263h181v24H410Z" fill="#6b5b4e"/><path d="M257 430 475 299" stroke="#d0aa75" stroke-width="18"/>' },
  mixed: { sky:'#b5d0c3',road:'#aeb8a8',accent:'#79a8a0',objects:'<path d="M165 391h250l-25 71H190Z" fill="#354b41"/><ellipse cx="485" cy="412" rx="185" ry="55" fill="#77a6a1"/><path d="M398 374q26-86 75-17l68 55-158 10Z" fill="#88805e"/><circle cx="550" cy="370" r="28" fill="#bfa36a"/>' },
  clean: { sky:'#b9d9cb',road:'#c2c8b3',accent:'#7eb99b',objects:'<path d="M70 365q170-55 350 13t340-5" stroke="#b6c9a7" stroke-width="12" fill="none"/><g fill="#5c9d77"><circle cx="150" cy="285" r="55"/><circle cx="600" cy="267" r="66"/></g><path d="M130 300v110M600 300v110" stroke="#6c8060" stroke-width="16"/>' },
}
function svg(scene) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="800" height="500" viewBox="0 0 800 500"><defs><linearGradient id="s" x2="0" y2="1"><stop stop-color="${scene.sky}"/><stop offset="1" stop-color="#e5eee1"/></linearGradient></defs><rect width="800" height="500" fill="url(#s)"/><path d="M0 210 190 180v130L0 350ZM540 170l260-35v225l-260-55Z" fill="#d7dfd1"/><path d="M0 342 800 278v222H0Z" fill="${scene.road}"/><path d="M0 383 800 319" stroke="#edf0df" stroke-width="7" stroke-dasharray="50 42"/><path d="M0 461 800 392" stroke="#e8e3ca" stroke-width="13"/>${scene.objects}<rect x="24" y="22" width="154" height="34" rx="8" fill="#173f35" opacity=".88"/><text x="39" y="44" fill="#fff" font-family="Arial,sans-serif" font-size="15" font-weight="bold">Nagar Shield 360</text><rect x="650" y="22" width="126" height="31" rx="8" fill="#f6fbf0" opacity=".9"/><text x="664" y="43" fill="#255744" font-family="Noto Sans Bengali,sans-serif" font-size="13">ডেমো দৃশ্য</text></svg>`
}
for (const [key, scene] of Object.entries(scenes)) {
  const path = `scenarios/${key}.svg`
  const { error } = await admin.storage.from('demo-media').upload(path, Buffer.from(svg(scene)), { contentType: 'image/svg+xml', upsert: true })
  if (error) throw error
  process.stdout.write(`Uploaded private demo media: ${path}\n`)
}
for (const key of ['water','mixed']) {
  const path = `scenarios/${key}.webm`
  const video = await readFile(new URL(`../demo-media/${key}.webm`, import.meta.url))
  const { error } = await admin.storage.from('demo-media').upload(path, video, { contentType: 'video/webm', upsert: true })
  if (error) throw error
  process.stdout.write(`Uploaded private demo clip: ${path}\n`)
}
const { error: resetError } = await admin.rpc('reset_demo')
if (resetError) throw resetError
process.stdout.write('Shared fictional dataset reset and ready. Passwords were not printed.\n')
