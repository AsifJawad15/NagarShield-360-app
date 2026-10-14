import Link from 'next/link'
import { redirect } from 'next/navigation'
import { Download } from 'lucide-react'
import { DemoNote, PageHeading } from '@/src/components/Ui'
import { ReportCharts } from '@/src/components/ReportCharts'
import { bn, hazards, priorities, statuses } from '@/src/lib/demo'
import { requireOfficial } from '@/src/lib/supabase/server'
import type { DemoTask, Incident } from '@/src/lib/types'
import { PrivateMedia } from '@/src/components/PrivateMedia'

export default async function ReportsPage() {
  const { supabase, profile } = await requireOfficial()
  if (profile.role === 'survey_operator') redirect('/surveys')
  if (profile.role === 'field_employee') return <><PageHeading kicker="আমার অগ্রগতি" title="কাজের সারসংক্ষেপ" description="আপনার নিজের দায়িত্বের তথ্য কাজের বোর্ডে দেখুন।"/><Link className="button-dark" href="/tasks">আমার কাজ দেখুন</Link></>

  const [{data:incidentsRaw},{data:tasksRaw},{data:departments}] = await Promise.all([
    supabase.from('incidents').select('*'), supabase.from('tasks').select('*'), supabase.from('departments').select('id,name_bn'),
  ])
  const incidents=(incidentsRaw||[]) as Incident[], tasks=(tasksRaw||[]) as DemoTask[]
  const statusData=Object.entries(statuses).filter(([key])=>incidents.some(i=>i.status===key)).map(([key,name])=>({name,value:incidents.filter(i=>i.status===key).length}))
  const hazardData=Object.entries(hazards).filter(([key])=>incidents.some(i=>i.hazard===key)).map(([key,name])=>({name,value:incidents.filter(i=>i.hazard===key).length}))
  const workload=(departments||[]).map(d=>({name:d.name_bn,value:tasks.filter(t=>t.department_id===d.id).length}))
  const resolved=incidents.filter(i=>i.status==='resolved').length
  const compared=incidents.filter(i=>i.before_key && i.after_key)
  const completed=tasks.filter(t=>t.status==='resolved')
  const averageHours=completed.length ? Math.round(completed.reduce((sum,t)=>sum+(new Date(t.updated_at).getTime()-new Date(t.created_at).getTime())/3600000,0)/completed.length) : 0
  const dayKey=(value:string)=>new Intl.DateTimeFormat('sv-SE',{timeZone:'Asia/Dhaka',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date(value))
  const timeline=Array.from({length:7},(_,index)=>{
    const day=new Date(`${dayKey(new Date().toISOString())}T06:00:00Z`); day.setUTCDate(day.getUTCDate()-6+index)
    const key=dayKey(day.toISOString())
    return { name:new Intl.DateTimeFormat('bn-BD',{day:'numeric',month:'short',timeZone:'Asia/Dhaka'}).format(day), detected:incidents.filter(i=>dayKey(i.created_at)===key).length, resolved:incidents.filter(i=>i.status==='resolved' && dayKey(i.updated_at)===key).length }
  })

  return <>
    <PageHeading kicker="পরিমাপ ও পর্যালোচনা" title="ডেমো প্রতিবেদন" description="আপনার অনুমতি অনুযায়ী দেখা ঘটনাগুলোর হিসাব এখানে রয়েছে। এখানে নমুনা ঘটনার পাশাপাশি মোবাইল থেকে জমা দেওয়া পরীক্ষামূলক নথিও থাকতে পারে।" action={<a className="button-dark" href="/api/reports/export"><Download size={16}/> CSV ডাউনলোড</a>}/>
    <DemoNote/>
    <div className="stat-grid">
      <div className="stat-card"><span>মোট ঘটনা</span><strong>{bn(incidents.length)}</strong><small>আপনি দেখতে পারেন এমন ঘটনা</small></div>
      <div className="stat-card"><span>কাজ শেষ</span><strong>{bn(resolved)}</strong><small>কর্মকর্তার যাচাইয়ের পর</small></div>
      <div className="stat-card"><span>কাজ শেষ করতে গড় সময়</span><strong>{completed.length ? `${bn(averageHours)} ঘ.` : '—'}</strong><small>ডেমোতে সংরক্ষিত সময়</small></div>
      <div className="stat-card"><span>আগে ও পরের ছবি</span><strong>{bn(compared.length)}</strong><small>ছবি যুক্ত ঘটনা</small></div>
    </div>
    <div className="section-gap"><ReportCharts statuses={statusData} hazards={hazardData} workload={workload} timeline={timeline}/></div>
    <section className="panel section-gap"><div className="panel-head"><div><span className="mini-kicker">অগ্রাধিকার</span><h2>বর্তমান বিতরণ</h2></div></div><div className="distribution-list">{Object.entries(priorities).map(([key,label])=><div key={key}><span>{label}</span><strong>{bn(incidents.filter(i=>i.priority===key).length)}</strong></div>)}</div></section>
    <section className="panel section-gap"><div className="panel-head"><div><span className="mini-kicker">ছবি মিলিয়ে দেখুন</span><h2>আগে ও পরের ছবি</h2></div></div>{compared.length ? <div className="report-comparisons">{compared.slice(0,3).map(item=><Link href={`/incidents/${item.id}`} key={item.id} className="report-comparison"><strong>{item.code} · {item.title_bn}</strong><div><figure><PrivateMedia mediaKey={item.before_key!} alt="কাজের আগের নমুনা"/><figcaption>আগে</figcaption></figure><figure><PrivateMedia mediaKey={item.after_key!} alt="কাজের পরের নমুনা"/><figcaption>পরে</figcaption></figure></div></Link>)}</div> : <p className="muted">এখনো আগের ও পরের ছবি যোগ হয়নি।</p>}<p className="help-text">নমুনা ঘটনার ছবি কৃত্রিম। মোবাইল থেকে জমা দেওয়া ছবি ও সময় পরীক্ষামূলক; বাস্তবে কাজ হওয়ার প্রমাণ হিসেবে ব্যবহার করবেন না।</p></section>
  </>
}
