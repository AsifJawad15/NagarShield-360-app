'use client'

import { useEffect, useState } from 'react'
import { Check, FileVideo, ImagePlus, ScanSearch } from 'lucide-react'
import { performWorkflowAction } from '@/app/actions/workflow'
import { bn, priorities, scoreFactors } from '@/src/lib/demo'
import type { Scenario } from '@/src/lib/types'
import { PrivateMedia } from './PrivateMedia'

export function ScenarioAnalysis({ items }: { items: Scenario[] }) {
  const [selected, setSelected] = useState(items[0]?.id || '')
  const [preview, setPreview] = useState<string | null>(null)
  const [fileKind, setFileKind] = useState<'image' | 'video'>('image')
  const [fileName, setFileName] = useState('')
  const [fileError, setFileError] = useState('')
  const scenario = items.find(s => s.id === selected) || items[0]
  const score = scenario ? scoreFactors(scenario.factors) : null
  useEffect(() => () => { if (preview) URL.revokeObjectURL(preview) }, [preview])
  if (!scenario || !score) return <div className="empty-state">ডেমো দৃশ্য পাওয়া যায়নি।</div>
  function chooseFile(file?: File) {
    if (preview) URL.revokeObjectURL(preview)
    setPreview(null); setFileName(''); setFileError('')
    if (!file) return
    if (!['image/png','image/jpeg','image/webp','video/mp4','video/webm'].includes(file.type) || file.size > 50 * 1024 * 1024) { setFileError('PNG, JPEG, WebP, MP4 বা WebM ফাইল নির্বাচন করুন (সর্বোচ্চ ৫০ MB)।'); return }
    setPreview(URL.createObjectURL(file)); setFileName(file.name); setFileKind(file.type.startsWith('video/') ? 'video' : 'image')
  }
  return <div className="analysis-layout"><section className="panel"><div className="panel-head"><div><span className="mini-kicker">১ · নমুনা নির্বাচন</span><h2>দৃশ্য ও প্রিভিউ</h2></div><ScanSearch size={20}/></div><div className="scenario-options">{items.map(item => <button className={selected === item.id ? 'scenario-option active' : 'scenario-option'} type="button" key={item.id} onClick={() => setSelected(item.id)}><span>{item.kind === 'video' ? <FileVideo size={17}/> : <ImagePlus size={17}/>}</span><strong>{item.title_bn}</strong>{selected === item.id && <Check size={16}/>}</button>)}</div><div className="analysis-preview"><div className="analysis-image">{preview ? fileKind === 'video' ? <video controls src={preview} aria-label="শুধু স্থানীয় ডেমো প্রিভিউ"/> : <img src={preview} alt="শুধু স্থানীয় ডেমো প্রিভিউ"/> : <PrivateMedia mediaKey={scenario.media_key} alt={`${scenario.title_bn} ধারণামূলক দৃশ্য`} controls/>}{!preview && scenario.detections.map((d,index) => <span className="detection-box" key={index} style={{left:`${d.box[0]}%`,top:`${d.box[1]}%`,width:`${d.box[2]}%`,height:`${d.box[3]}%`}}><small>{d.label_bn}</small></span>)}</div><div className="preview-caption">{scenario.kind === 'video' ? 'ধারণামূলক ডেমো ভিডিও · প্রকৃত বিশ্লেষণ নয়' : 'নমুনা দৃশ্য'}{preview ? ` · ${fileName} (এই ডিভাইসেই প্রিভিউ)` : ''}</div></div><label className="upload-label">নিজের ফাইলের স্থানীয় প্রিভিউ<input type="file" accept="image/png,image/jpeg,image/webp,video/mp4,video/webm" onChange={event => chooseFile(event.target.files?.[0])}/></label>{fileError && <p role="alert" className="field-error">{fileError}</p>}<p className="help-text">নির্বাচিত ফাইল সার্ভারে পাঠানো হয় না। নিচের সিমুলেশন শুধু নির্বাচিত ডেমো দৃশ্যের পূর্বনির্ধারিত ফল দেখায়।</p></section>
    <section className="analysis-side"><div className="panel"><div className="panel-head"><div><span className="mini-kicker">২ · সিমুলেটেড ফল</span><h2>পর্যবেক্ষণের সারাংশ</h2></div><span className="prototype-tag">AI সিমুলেশন</span></div><p>{scenario.summary_bn}</p><div className="analysis-facts"><span>ধারণামূলক অবস্থান</span><strong>{scenario.area_bn}</strong><span>শনাক্তকরণের নমুনা</span><strong>{scenario.detections.length ? scenario.detections.map(d => d.label_bn).join(' · ') : 'কোনো সমস্যা দেখানো হয়নি'}</strong></div><div className="score-summary"><div><span>ব্যাখ্যাযোগ্য অগ্রাধিকার</span><strong>{bn(score.score)}<small>/১০০</small></strong></div><span className={`priority-pill priority-${score.priority}`}>{priorities[score.priority]}</span></div><p className="help-text">এই স্কোর ধারণামূলক। রোগ, বন্যা বা আইনগত অবস্থা নির্ণয় করে না।</p></div>
    <div className="panel"><div className="panel-head"><div><span className="mini-kicker">৩ · কারণ দেখুন</span><h2>স্কোরের অবদান</h2></div></div><div className="factor-list">{score.parts.map(([label,value,weight]) => <div key={label}><div><span>{label}</span><strong>{bn(Math.round(value*weight))}</strong></div><div className="factor-track"><span style={{width:`${value}%`}}/></div></div>)}<div className="factor-bonus">প্রাসঙ্গিকতার বোনাস <strong>+{bn(score.bonus)}</strong></div></div><p className="help-text">সূত্র: ০.৩০ ড্রেন + ০.২৫ পানি + ০.১৫ বর্জ্য + ০.১৫ চলাচল + ০.১০ পুনরাবৃত্তি + ০.০৫ তথ্য + বোনাস।</p></div>
    <form action={performWorkflowAction} className="panel analysis-submit"><span className="mini-kicker">৪ · মানুষের যাচাই</span><h2>পর্যবেক্ষণ নথিবদ্ধ করুন</h2><p>দায়িত্বপ্রাপ্ত কর্মকর্তা ঘটনা তৈরির আগে ফলটি যাচাই করবেন।</p><input type="hidden" name="action" value="create_observation"/><input type="hidden" name="scenario_id" value={scenario.id}/><input type="hidden" name="return_to" value="/incidents"/><button className="button-dark" type="submit">যাচাইয়ের তালিকায় পাঠান</button></form></section></div>
}
