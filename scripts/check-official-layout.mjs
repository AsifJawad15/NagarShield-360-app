import { readFile } from 'node:fs/promises'
import { join } from 'node:path'
import { tmpdir } from 'node:os'
import { chromium } from 'playwright-core'

const baseUrl = process.env.DEMO_BASE_URL || 'http://localhost:3000'
const accounts = JSON.parse(await readFile(process.env.DEMO_ACCOUNTS_FILE || 'demo-accounts.local.json', 'utf8'))
const executive = accounts.find(item => item.role === 'executive')
const field = accounts.find(item => item.role === 'field_employee')
if (!executive || !field) throw new Error('Executive and field employee demo accounts are required')

const browser = await chromium.launch({
  executablePath: process.env.CHROME_PATH || 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  headless: true,
})
try {
  for (const { account, path, width, height, name } of [
    { account: executive, path: '/dashboard', width: 1366, height: 768, name: 'executive-desktop' },
    { account: field, path: '/tasks', width: 390, height: 844, name: 'field-mobile' },
  ]) {
    const context = await browser.newContext({ viewport: { width, height } })
    const page = await context.newPage()
    await page.goto(`${baseUrl}/`, { waitUntil: 'domcontentloaded' })
    await page.locator('input[name="email"]').fill(account.email)
    await page.locator('input[name="password"]').fill(account.password)
    await page.getByRole('button', { name: /সাইন ইন করুন/ }).click()
    try { await page.waitForURL('**/dashboard', { timeout: 20000 }) }
    catch {
      const message = await page.locator('.signin-error').textContent().catch(() => null)
      throw new Error(`${name}: sign-in failed (${message || page.url()}); check the Supabase project and existing account password`)
    }
    await page.goto(`${baseUrl}${path}`, { waitUntil: 'networkidle' })
    const metrics = await page.evaluate(() => ({
      viewport: innerWidth,
      document: document.documentElement.scrollWidth,
      heading: document.querySelector('main h1')?.textContent,
      mobileNavigation: getComputedStyle(document.querySelector('.mobile-official-nav')).display,
    }))
    const screenshot = join(tmpdir(), `nagarshield-${name}.png`)
    await page.screenshot({ path: screenshot, fullPage: true })
    process.stdout.write(`${name}: ${JSON.stringify(metrics)}\n${screenshot}\n`)
    if (metrics.document > metrics.viewport || !metrics.heading) process.exitCode = 1
    if (name === 'field-mobile' && metrics.mobileNavigation === 'none') process.exitCode = 1
    await context.close()
  }
} finally { await browser.close() }
