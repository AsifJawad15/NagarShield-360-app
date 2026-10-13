import Link from 'next/link'
import { performWorkflowAction } from '@/app/actions/workflow'
import { DemoNote, EmptyState, Notice, PageHeading, StatusPill } from '@/src/components/Ui'
import { dateBn } from '@/src/lib/demo'
import { requireOfficial } from '@/src/lib/supabase/server'
import type { DemoTask } from '@/src/lib/types'

export default async function TasksPage({ searchParams }: { searchParams: Promise<{ notice?: string }> }) {
  const { supabase, profile } = await requireOfficial()
  const { data } = await supabase.from('tasks').select('*,departments(name_bn),profiles!tasks_assignee_id_fkey(display_name),incidents(code,title_bn,area_bn)').order('updated_at',{ascending:false})
  const tasks = (data || []) as (DemoTask & { incidents?: {code:string;title_bn:string;area_bn:string} | null })[]
  const { notice } = await searchParams
  return <><PageHeading kicker="দায়িত্ব বণ্টন" title={profile.role === 'field_employee' ? 'আমার কাজ' : 'কাজের বোর্ড'} description="গ্রহণ থেকে প্রমাণ জমা ও ফল যাচাই পর্যন্ত প্রতিটি কাজের অবস্থা দেখুন।"/><Notice value={notice}/><DemoNote/>
    <section className="panel section-gap"><div className="panel-head"><div><span className="mini-kicker">শেয়ার করা কাজ</span><h2>{tasks.length}টি দায়িত্ব</h2></div></div>{tasks.length ? <div className="task-grid">{tasks.map(task => <article className="task-card" key={task.id}><div className="task-card-top"><span className="row-meta">{task.incidents?.code} · {dateBn(task.created_at)}</span><StatusPill value={task.status}/></div><h3>{task.incidents?.title_bn}</h3><p>{task.incidents?.area_bn} · {task.departments?.name_bn}</p><div className="task-card-note">{task.note || 'স্থান পরিদর্শন ও ফল নথিবদ্ধ করুন।'}</div><Link className="inline-link" href={`/incidents/${task.incident_id}`}>ঘটনা ও পদক্ষেপ দেখুন →</Link>{profile.role === 'field_employee' && task.assignee_id === profile.id && ['assigned','acknowledged'].includes(task.status) && <form action={performWorkflowAction} className="task-card-action"><input type="hidden" name="target" value={task.id}/><input type="hidden" name="return_to" value="/tasks"/><input type="hidden" name="action" value={task.status === 'assigned' ? 'acknowledge_task' : 'start_task'}/><button className="button-dark" type="submit">{task.status === 'assigned' ? 'দায়িত্ব গ্রহণ' : 'কাজ শুরু'}</button></form>}</article>)}</div> : <EmptyState text="এখনও কোনো দায়িত্ব দেওয়া হয়নি। অনুমোদিত কর্মকর্তা ঘটনা থেকে দায়িত্ব দিতে পারবেন।"/>}</section>
  </>
}
