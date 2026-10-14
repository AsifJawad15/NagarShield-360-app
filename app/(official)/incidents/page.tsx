import Link from 'next/link'
import { redirect } from 'next/navigation'
import { performWorkflowAction } from '@/app/actions/workflow'
import { DemoNote, IncidentList, Notice, PageHeading, PriorityPill } from '@/src/components/Ui'
import { PrivateMedia } from '@/src/components/PrivateMedia'
import { bn, dateBn, statuses } from '@/src/lib/demo'
import { requireOfficial } from '@/src/lib/supabase/server'
import type { Incident } from '@/src/lib/types'

type Intake = {
  id: string
  title_bn: string
  description_bn: string | null
  area_bn: string
  priority: string
  source: 'scenario' | 'public' | 'drone' | 'gapscan'
  report_code: string | null
  media_key: string | null
  created_at: string
}
const sourceLabels = {
  scenario: 'নমুনা দৃশ্য',
  public: 'মোবাইল নাগরিক প্রতিবেদন',
  drone: 'ড্রোন জরিপ',
  gapscan: 'সংকীর্ণ স্থান জরিপ',
}
function ReviewAction({ item, approve }: { item: Intake; approve: boolean }) {
  const action = approve ? 'verify_observation' : 'dismiss_observation'
  return <form action={performWorkflowAction}>
    <input type="hidden" name="action" value={action}/>
    <input type="hidden" name="target" value={item.id}/>
    <input type="hidden" name="return_to" value="/incidents"/>
    {approve && <label className="review-note">যাচাইয়ের মন্তব্য <textarea name="note" maxLength={1000} placeholder="কেন গ্রহণ করছেন, সংক্ষেপে লিখুন" /></label>}
    <button className={approve ? 'button-dark' : 'button-text'} type="submit">
      {approve ? 'যাচাই করে ঘটনা খুলুন' : 'বাতিল'}
    </button>
  </form>
}

export default async function IncidentsPage({
  searchParams,
}: { searchParams: Promise<{ notice?: string; status?: string; q?: string }> }) {
  const { supabase, profile } = await requireOfficial()
  if (profile.role === 'survey_operator') redirect('/surveys')
  const canReview = profile.role === 'executive' || profile.role === 'department_head'
  const [{ data: incidents, error: incidentsError }, { data: observations, error: observationsError }] = await Promise.all([
    supabase.from('incidents').select('*').order('updated_at', { ascending: false }),
    canReview
      ? supabase.from('observations')
          .select('id,title_bn,description_bn,area_bn,priority,source,report_code,media_key,created_at')
          .eq('status', 'needs_review').order('created_at', { ascending: false })
      : Promise.resolve({ data: [] as Intake[], error: null }),
  ])
  const { notice, status, q } = await searchParams
  const query = (q || '').trim().toLocaleLowerCase()
  const matches = (code: string | null, title: string) => !query ||
    `${code || ''} ${title}`.toLocaleLowerCase().includes(query)
  const list = ((incidents || []) as Incident[]).filter(item =>
    (!status || item.status === status) && matches(item.code, item.title_bn))
  const queue = ((observations || []) as Intake[]).filter(item => matches(item.report_code, item.title_bn))
  return <>
    <PageHeading kicker="পর্যবেক্ষণ ও দায়িত্ব" title="ঘটনা কেন্দ্র"
      description="মোবাইল নাগরিক প্রতিবেদন, জরিপ ও নমুনা পর্যবেক্ষণ যাচাই করুন। নিশ্চিত হলে ঘটনা হিসেবে নথিভুক্ত করুন।"
      action={canReview ? <Link className="button-dark" href="/analysis">নমুনা ছবি দেখুন</Link> : undefined}/>
    <Notice value={notice}/>
    <DemoNote/>
    <form method="get" className="incident-search">
      <label htmlFor="incident-q">রিপোর্ট কোড বা শিরোনাম খুঁজুন</label>
      <input id="incident-q" name="q" defaultValue={q || ''} placeholder="NS-P-..." />
      <button className="button-outline" type="submit">খুঁজুন</button>
    </form>
    {(incidentsError || observationsError) && <div role="alert" className="notice notice-error">তথ্য দেখানো যাচ্ছে না। ডেটাবেসের নতুন পরিবর্তনগুলো চালু আছে কি না দেখে আবার চেষ্টা করুন।</div>}
    {canReview && <section className="panel section-gap">
      <div className="panel-head"><div><span className="mini-kicker">কর্মকর্তার যাচাই</span>
        <h2>যাচাইয়ের অপেক্ষায় · {bn(queue.length)}</h2></div></div>
      {queue.length ? <div className="review-list">{queue.map(item =>
        <div className="review-row" key={item.id}>
          <div>
            <span className="row-meta">
              {sourceLabels[item.source] || item.source} · {dateBn(item.created_at)} · {item.area_bn}
            </span>
            <strong>{item.report_code ? item.report_code + ' · ' : ''}{item.title_bn}</strong>
            {item.description_bn && <p>{item.description_bn}</p>}
          </div>
          {item.media_key && <div className="review-media">
            <PrivateMedia mediaKey={item.media_key} alt={item.title_bn} controls/>
          </div>}
          <PriorityPill value={item.priority as Incident['priority']}/>
          <ReviewAction item={item} approve/>
          <ReviewAction item={item} approve={false}/>
        </div>,
      )}</div> : <div className="empty-state">এই মুহূর্তে যাচাইয়ের জন্য কিছু নেই।</div>}
    </section>}
    <section className="panel section-gap">
      <div className="panel-head"><div><span className="mini-kicker">ঘটনার তালিকা</span>
        <h2>ঘটনা · {bn(list.length)}</h2></div>
        <form method="get">
          {q && <input type="hidden" name="q" value={q}/>}
          <label className="visually-hidden" htmlFor="status-filter">অবস্থা অনুযায়ী দেখুন</label>
          <select name="status" id="status-filter" defaultValue={status || ''}>
            <option value="">সব অবস্থা</option>
            {(['verified','assigned','acknowledged','in_progress','verification_pending','resolved'] as const)
              .map(value => <option key={value} value={value}>{statuses[value]}</option>)}
          </select>
          <button className="button-outline" type="submit">দেখুন</button>
        </form>
      </div>
      <IncidentList incidents={list}/>
    </section>
  </>
}
