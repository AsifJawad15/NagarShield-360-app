import Link from 'next/link'
import { performWorkflowAction } from '@/app/actions/workflow'
import { DemoNote, IncidentList, Notice, PageHeading, PriorityPill } from '@/src/components/Ui'
import { bn, dateBn, priorities } from '@/src/lib/demo'
import { requireOfficial } from '@/src/lib/supabase/server'
import type { Incident } from '@/src/lib/types'

export default async function IncidentsPage({ searchParams }: { searchParams: Promise<{ notice?: string; status?: string }> }) {
  const { supabase, profile } = await requireOfficial()
  const [{ data: incidents }, { data: observations }] = await Promise.all([
    supabase.from('incidents').select('*').order('updated_at', { ascending: false }),
    !['executive','department_head'].includes(profile.role) ? Promise.resolve({ data: [] }) : supabase.from('observations').select('id,title_bn,area_bn,priority,score,created_at,status').eq('status','needs_review').order('created_at',{ascending:false}),
  ])
  const { notice, status } = await searchParams
  const list = ((incidents || []) as Incident[]).filter(item => !status || item.status === status)
  return <><PageHeading kicker="পর্যবেক্ষণ ও দায়িত্ব" title="ঘটনা কেন্দ্র" description="প্রতিটি ঘটনার বর্তমান অবস্থা, অগ্রাধিকার ও যাচাইয়ের পথ দেখুন।" action={['executive','department_head'].includes(profile.role) ? <Link className="button-dark" href="/analysis">নতুন বিশ্লেষণ</Link> : undefined}/><Notice value={notice}/><DemoNote/>
    {['executive','department_head'].includes(profile.role) && <section className="panel section-gap"><div className="panel-head"><div><span className="mini-kicker">মানুষের সিদ্ধান্ত</span><h2>যাচাইয়ের অপেক্ষায় · {bn((observations || []).length)}</h2></div></div>{(observations || []).length ? <div className="review-list">{observations?.map(o => <div className="review-row" key={o.id}><div><span className="row-meta">{dateBn(o.created_at)} · {o.area_bn}</span><strong>{o.title_bn}</strong></div><PriorityPill value={o.priority}/><form action={performWorkflowAction}><input type="hidden" name="action" value="verify_observation"/><input type="hidden" name="target" value={o.id}/><input type="hidden" name="return_to" value="/incidents"/><button className="button-dark" type="submit">ঘটনা তৈরি ও যাচাই</button></form><form action={performWorkflowAction}><input type="hidden" name="action" value="dismiss_observation"/><input type="hidden" name="target" value={o.id}/><input type="hidden" name="return_to" value="/incidents"/><button className="button-text" type="submit">বাতিল</button></form></div>)}</div> : <div className="empty-state">নতুন পর্যবেক্ষণ নেই। বিশ্লেষণ পাতা থেকে ডেমো দৃশ্য বেছে নিন।</div>}</section>}
    <section className="panel section-gap"><div className="panel-head"><div><span className="mini-kicker">ডেমো রেকর্ড</span><h2>সব ঘটনা · {bn(list.length)}</h2></div><form method="get"><label className="visually-hidden" htmlFor="status-filter">অবস্থা অনুযায়ী দেখুন</label><select name="status" id="status-filter" defaultValue={status || ''}><option value="">সব অবস্থা</option>{(['verified','assigned','acknowledged','in_progress','verification_pending','resolved'] as const).map(value => <option key={value} value={value}>{value === 'verified' ? 'যাচাইকৃত' : value === 'assigned' ? 'দায়িত্ব দেওয়া' : value === 'acknowledged' ? 'গ্রহণ করা' : value === 'in_progress' ? 'কাজ চলছে' : value === 'verification_pending' ? 'ফল যাচাই' : 'সমাধান'}</option>)}</select><button className="button-outline" type="submit">দেখুন</button></form></div><IncidentList incidents={list}/></section>
  </>
}
