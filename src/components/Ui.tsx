import Link from 'next/link'
import { ArrowUpRight, MapPin } from 'lucide-react'
import { bn, dateBn, hazards, priorities, statuses } from '@/src/lib/demo'
import type { Incident, IncidentStatus, Priority } from '@/src/lib/types'

export function PageHeading({ kicker, title, description, action }: { kicker: string; title: string; description: string; action?: React.ReactNode }) {
  return <div className="page-heading"><div><span className="page-kicker">{kicker}</span><h1>{title}</h1><p>{description}</p></div>{action}</div>
}
export function DemoNote({ children }: { children?: React.ReactNode }) { return <div className="demo-note">ডেমো তথ্য · {children || 'সব ঘটনা, অবস্থান ও ফল ধারণামূলক। বাস্তব সিদ্ধান্তের আগে মাঠপর্যায়ে যাচাই প্রয়োজন।'}</div> }
export function StatusPill({ value }: { value: IncidentStatus | string }) { return <span className={`status-pill status-${value}`}>{statuses[value as IncidentStatus] || value}</span> }
export function PriorityPill({ value }: { value: Priority | string }) { return <span className={`priority-pill priority-${value}`}>{priorities[value as Priority] || value}</span> }
export function EmptyState({ text }: { text: string }) { return <div className="empty-state">{text}</div> }
export function Notice({ value }: { value?: string }) {
  if (!value) return null
  const text = value === 'done' ? 'পদক্ষেপটি নথিবদ্ধ হয়েছে।' : value === 'reset' ? 'ডেমো তথ্য আবার শুরু হয়েছে।' : value === 'denied' ? 'এই কাজের অনুমতি নেই।' : value
  return <div role="status" className="notice">{text}</div>
}
export function IncidentList({ incidents }: { incidents: Incident[] }) {
  if (!incidents.length) return <EmptyState text="এই পরিসরে কোনো ডেমো ঘটনা নেই।" />
  return <div className="incident-list">{incidents.map(item => <Link href={`/incidents/${item.id}`} className="incident-row" key={item.id}>
    <div className="incident-row-icon"><MapPin size={18}/></div><div className="incident-row-main"><div className="row-meta">{item.code} · {dateBn(item.created_at)}</div><strong>{item.title_bn}</strong><span>{item.area_bn} · {hazards[item.hazard]}</span></div>
    <div className="incident-row-tags"><PriorityPill value={item.priority}/><StatusPill value={item.status}/></div><strong className="score-cell">{bn(item.score)}<small>/১০০</small></strong><ArrowUpRight size={17} className="row-arrow" />
  </Link>)}</div>
}
