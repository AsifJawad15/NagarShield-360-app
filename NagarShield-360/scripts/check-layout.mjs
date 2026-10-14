import { chromium } from 'playwright-core'
import { join } from 'node:path'
import { tmpdir } from 'node:os'

const browser = await chromium.launch({ executablePath: process.env.CHROME_PATH || 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe', headless: true })
try {
  const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 })
  await page.goto('http://localhost:3000', { waitUntil: 'networkidle' })
  const details = await page.evaluate(() => ({ viewport: innerWidth, document: document.documentElement.scrollWidth, menu: getComputedStyle(document.querySelector('.menu-toggle')).display, title: document.querySelector('h1').getBoundingClientRect().toJSON() }))
  const path = join(tmpdir(), 'nagarshield-mobile-viewport.png')
  const signInPath = join(tmpdir(), 'nagarshield-mobile-signin.png')
  await page.screenshot({ path })
  await page.locator('#signin').screenshot({ path: signInPath })
  process.stdout.write(`${JSON.stringify(details)}\n${path}\n${signInPath}\n`)
  if (details.document > details.viewport || details.menu === 'none') process.exitCode = 1
} finally { await browser.close() }
