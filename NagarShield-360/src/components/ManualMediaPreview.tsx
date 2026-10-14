'use client'

import { useEffect, useState } from 'react'
import type { PointerEvent, MouseEvent } from 'react'
import type { Scenario } from '@/src/lib/types'
import { PrivateMedia } from './PrivateMedia'

type Annotation = {
  shape: 'box' | 'polygon'
  points: number[] | number[][]
  label: string
  from_ms: number | null
  to_ms: number | null
}
type Point = [number, number]
const clamp = (value: number) => Math.max(0, Math.min(1, value))
function point(event: MouseEvent<HTMLDivElement> | PointerEvent<HTMLDivElement>): Point {
  const rect = event.currentTarget.getBoundingClientRect()
  return [clamp((event.clientX - rect.left) / rect.width),
    clamp((event.clientY - rect.top) / rect.height)]
}

export function ManualMediaPreview({
  scenario, preview, fileKind, fileName,
}: {
  scenario: Scenario
  preview: string | null
  fileKind: 'image' | 'video'
  fileName: string
}) {
  const [annotations, setAnnotations] = useState<Annotation[]>([])
  const [loadedFile, setLoadedFile] = useState<string | null>(null)
  const [mode, setMode] = useState<'box' | 'polygon'>('box')
  const [label, setLabel] = useState('নিজে চিহ্নিত সমস্যা')
  const [fromMs, setFromMs] = useState(0)
  const [toMs, setToMs] = useState(1000)
  const [annotating, setAnnotating] = useState(false)
  const [start, setStart] = useState<Point | null>(null)
  const [polygon, setPolygon] = useState<Point[]>([])

  useEffect(() => {
    if (!fileName) { setAnnotations([]); setLoadedFile(null); return }
    try {
      const saved = localStorage.getItem('nagar-manual:' + fileName)
      setAnnotations(saved ? JSON.parse(saved) as Annotation[] : [])
    } catch { setAnnotations([]) }
    setLoadedFile(fileName)
    setPolygon([])
  }, [fileName])
  useEffect(() => {
    if (fileName && loadedFile === fileName) {
      localStorage.setItem('nagar-manual:' + fileName, JSON.stringify(annotations))
    }
  }, [annotations, fileName, loadedFile])

  function add(points: number[] | number[][], shape: 'box' | 'polygon') {
    const from = fileKind === 'video' ? Math.max(0, fromMs) : null
    const to = fileKind === 'video' ? Math.max(fromMs + 1, toMs) : null
    setAnnotations(previous => [...previous, {
      shape, points, label: label.trim() || 'নিজে চিহ্নিত সমস্যা',
      from_ms: from, to_ms: to,
    }])
  }
  function startBox(event: PointerEvent<HTMLDivElement>) {
    if (mode !== 'box') return
    event.currentTarget.setPointerCapture(event.pointerId)
    setStart(point(event))
  }
  function finishBox(event: PointerEvent<HTMLDivElement>) {
    if (!start || mode !== 'box') return
    const end = point(event)
    const x = Math.min(start[0], end[0])
    const y = Math.min(start[1], end[1])
    const w = Math.abs(start[0] - end[0])
    const h = Math.abs(start[1] - end[1])
    if (w > .01 && h > .01) add([x, y, w, h], 'box')
    setStart(null)
  }
  function addPoint(event: MouseEvent<HTMLDivElement>) {
    if (mode === 'polygon') setPolygon(previous => [...previous, point(event)])
  }
  const active = Boolean(preview) && (fileKind === 'image' || annotating)
  return <>
    <div className={'analysis-image' + (preview ? ' imported' : '')}>
      {preview
        ? fileKind === 'video'
          ? <video controls={!annotating} src={preview} aria-label="আপনার বেছে নেওয়া ভিডিও"/>
          : <img src={preview} alt="আপনার বেছে নেওয়া ছবি"/>
        : <PrivateMedia mediaKey={scenario.media_key} alt={scenario.title_bn + ' নমুনা দৃশ্য'} controls/>}
      {!preview && scenario.detections.map((d, index) =>
        <span className="detection-box" key={index} style={{
          left: d.box[0] + '%', top: d.box[1] + '%',
          width: d.box[2] + '%', height: d.box[3] + '%',
        }}><small>{d.label_bn} · নমুনা</small></span>,
      )}
      {preview && <svg className="manual-overlay" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true">
        {annotations.map((item, index) => item.shape === 'box'
          ? <rect key={index} x={(item.points as number[])[0] * 100}
              y={(item.points as number[])[1] * 100}
              width={(item.points as number[])[2] * 100}
              height={(item.points as number[])[3] * 100}/>
          : <polygon key={index} points={(item.points as number[][])
              .map(p => (p[0] * 100) + ',' + (p[1] * 100)).join(' ')}/>)}
        {polygon.length > 1 && <polyline points={polygon
          .map(p => (p[0] * 100) + ',' + (p[1] * 100)).join(' ')}/>}
      </svg>}
      {active && <div className="manual-hitbox" onPointerDown={startBox}
        onPointerUp={finishBox} onClick={addPoint} role="presentation"/>}
    </div>
    <div className="preview-caption">{preview
      ? fileName + ' · নিজে আঁকা চিহ্ন'
      : 'ডেমো দৃশ্য · স্বয়ংক্রিয় বিশ্লেষণ করা হয়নি'}</div>
    {preview && <div className="manual-controls">
      {fileKind === 'video' && <label><input type="checkbox" checked={annotating}
        onChange={event => setAnnotating(event.target.checked)}/> ভিডিওতে চিহ্ন দিন</label>}
      <label>আকৃতি <select value={mode} onChange={event => setMode(event.target.value as 'box' | 'polygon')}>
        <option value="box">বক্স</option><option value="polygon">বহুভুজ</option>
      </select></label>
      <label>চিহ্নের নাম <input value={label} onChange={event => setLabel(event.target.value)} maxLength={80}/></label>
      {fileKind === 'video' && <>
        <label>শুরু (মিলিসেকেন্ড) <input type="number" min="0" value={fromMs}
          onChange={event => setFromMs(Number(event.target.value))}/></label>
        <label>শেষ (মিলিসেকেন্ড) <input type="number" min="1" value={toMs}
          onChange={event => setToMs(Number(event.target.value))}/></label>
      </>}
      {mode === 'polygon' && <button type="button" className="button-outline"
        disabled={polygon.length < 3} onClick={() => { add(polygon, 'polygon'); setPolygon([]) }}>
        বহুভুজটি শেষ করুন ({polygon.length})
      </button>}
      <button type="button" className="button-text" onClick={() => setAnnotations([])}>
        সব চিহ্ন মুছুন
      </button>
      <small>{annotations.length}টি চিহ্ন এই ব্রাউজারে রাখা আছে। একই ফাইল আবার বেছে নিলে চিহ্নগুলো দেখা যাবে।</small>
      {annotations.length > 0 && <details><summary>চিহ্নের বিস্তারিত দেখুন</summary>
        <pre className="annotation-json">{JSON.stringify(annotations, null, 2)}</pre>
      </details>}
    </div>}
  </>
}
