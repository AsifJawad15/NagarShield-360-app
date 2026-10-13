import { chromium } from 'playwright-core'
import { writeFile } from 'node:fs/promises'

const browser = await chromium.launch({ executablePath: process.env.CHROME_PATH || 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe', headless: true })
try {
  const page = await browser.newPage()
  for (const scene of ['water','mixed']) {
    const bytes = await page.evaluate(async (kind) => {
      const canvas = document.createElement('canvas'); canvas.width=800; canvas.height=500
      const ctx = canvas.getContext('2d')
      const stream = canvas.captureStream(12)
      const recorder = new MediaRecorder(stream, { mimeType: 'video/webm;codecs=vp8' })
      const chunks = []
      recorder.ondataavailable = event => { if (event.data.size) chunks.push(event.data) }
      const stopped = new Promise(resolve => { recorder.onstop = resolve })
      const draw = (frame) => {
        const t=frame/36
        ctx.fillStyle='#c5ded1'; ctx.fillRect(0,0,800,500)
        ctx.fillStyle='#dfe9df'; ctx.fillRect(30,100,205,170);ctx.fillRect(545,90,225,175)
        ctx.fillStyle='#b8c6b7'; ctx.fillRect(0,280,800,220)
        ctx.strokeStyle='#e9eddd'; ctx.lineWidth=10; ctx.setLineDash([50,40]);ctx.beginPath();ctx.moveTo(0,375);ctx.lineTo(800,305);ctx.stroke();ctx.setLineDash([])
        ctx.fillStyle='#568474';ctx.fillRect(0,445,800,55)
        ctx.fillStyle='#74a8a7';ctx.beginPath();ctx.ellipse(425+Math.sin(t*6)*8,400,230,58,0,0,Math.PI*2);ctx.fill()
        for (let i=0;i<4;i++) { ctx.strokeStyle='#c7e2d5';ctx.lineWidth=3;ctx.beginPath();ctx.ellipse(320+i*55,400+Math.sin(t*7+i)*8,30,6,0,0,Math.PI*2);ctx.stroke() }
        if (kind==='mixed') {ctx.fillStyle='#3d544a';ctx.fillRect(145,335,205,100);ctx.fillStyle='#a69965';ctx.beginPath();ctx.arc(590,375,42,0,Math.PI*2);ctx.fill();ctx.fillStyle='#80765a';ctx.beginPath();ctx.moveTo(495,410);ctx.lineTo(545,325);ctx.lineTo(635,420);ctx.fill()}
        ctx.fillStyle='#173f35';ctx.fillRect(25,22,180,37);ctx.fillStyle='#fff';ctx.font='bold 16px Arial';ctx.fillText('Nagar Shield 360',37,47)
        ctx.fillStyle='#f8fbef';ctx.fillRect(625,22,150,37);ctx.fillStyle='#285b45';ctx.font='bold 14px "Nirmala UI", sans-serif';ctx.fillText('ডেমো ভিডিও',641,47)
      }
      draw(0); recorder.start()
      for (let frame=1;frame<=36;frame++) { await new Promise(resolve=>setTimeout(resolve,84)); draw(frame) }
      recorder.stop(); await stopped
      const buffer=await new Blob(chunks,{type:'video/webm'}).arrayBuffer()
      return Array.from(new Uint8Array(buffer))
    }, scene)
    const path = new URL(`../demo-media/${scene}.webm`, import.meta.url)
    await writeFile(path, Buffer.from(bytes))
    const duration = await page.evaluate(async data => {
      const video = document.createElement('video')
      video.src = URL.createObjectURL(new Blob([new Uint8Array(data)], { type: 'video/webm' }))
      await new Promise((resolve, reject) => { video.onloadedmetadata = resolve; video.onerror = reject })
      const seconds = video.duration
      URL.revokeObjectURL(video.src)
      return seconds
    }, bytes)
    if (!Number.isFinite(duration) || duration < 2) throw new Error(`Invalid video: ${scene}`)
    process.stdout.write(`Generated ${scene}.webm (${bytes.length} bytes, ${duration.toFixed(1)} s)\n`)
  }
} finally { await browser.close() }
