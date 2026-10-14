import { readFile, writeFile } from 'node:fs/promises'

const common = JSON.parse(await readFile('config/supabase.local.json', 'utf8'))
const accounts = JSON.parse(await readFile('config/public-demo-accounts.local.json', 'utf8'))
for (const account of accounts) {
  const name = 'config/public-demo-' + account.slot.toLowerCase() + '.local.json'
  await writeFile(name, JSON.stringify({
    ...common,
    PUBLIC_DEMO_SLOT: account.slot,
    PUBLIC_DEMO_EMAIL: account.email,
    PUBLIC_DEMO_PASSWORD: account.password,
  }, null, 2) + '\n', { mode: 0o600 })
}
await writeFile('config/showcase.local.json', JSON.stringify({
  ...common,
  PUBLIC_DEMO_ACCOUNTS: JSON.stringify(accounts),
}, null, 2) + '\n', { mode: 0o600 })
process.stdout.write('One ignored Flutter dart-define file prepared for the showcase APK.\n')
