import { readFile, writeFile, copyFile, mkdir } from 'node:fs/promises'
import { resolve, join } from 'node:path'
import vm from 'node:vm'

const webRoot = resolve(process.env.NAGAR_WEB_DIR || '../NagarShield-360')
const source = await readFile(join(webRoot, 'scripts/provision.mjs'), 'utf8')
const start = source.indexOf('const scenes = {')
const end = source.indexOf('for (const [key, scene]', start)
if (start < 0 || end < 0) throw new Error('Preset source boundary missing')
const { scenes, svg } = vm.runInNewContext(
  '(() => {' + source.slice(start, end) + '; return {scenes,svg}; })()',
  {},
)
const output = resolve('assets/presets')
await mkdir(output, { recursive: true })
for (const [id, scene] of Object.entries(scenes)) {
  await writeFile(join(output, id + '.svg'), svg(scene))
}
for (const id of ['water', 'mixed']) {
  await copyFile(join(webRoot, 'demo-media', id + '.webm'), join(output, id + '.webm'))
}
process.stdout.write('Copied six SVG presets and two video clips into app assets.\n')