import { DemoNote, PageHeading } from '@/src/components/Ui'
import { roleLabels } from '@/src/lib/demo'
import { requireOfficial } from '@/src/lib/supabase/server'

const capabilities = [
  {role:'executive',scope:'সব ডেমো এলাকা ও বিভাগ',actions:'সমস্যা যাচাই, সব বিভাগে কাজ দেওয়া, ফল অনুমোদন, প্রতিবেদন দেখা ও ডেমো আবার শুরু করা'},
  {role:'department_head',scope:'নিজ বিভাগের ঘটনা ও কাজ',actions:'নিজ বিভাগের সমস্যা যাচাই, কাজ দেওয়া, ফল অনুমোদন ও প্রতিবেদন দেখা'},
  {role:'supervisor',scope:'নিজ দলের কাজ',actions:'নিজ দলের কাজ দেখা, জমা দেওয়া কাজ যাচাই ও প্রয়োজনে ফেরত পাঠানো'},
  {role:'field_employee',scope:'নিজের দায়িত্ব',actions:'দায়িত্ব নেওয়া, কাজ শুরু এবং কাজের বিবরণ ও নমুনা ছবি জমা দেওয়া'},
  {role:'survey_operator',scope:'নিজ বিভাগের ডেমো জরিপ',actions:'জরিপের নমুনা দেখা; এই ওয়েবসাইটে নতুন জরিপ জমা দেওয়া যায় না'},
] as const

export default async function GovernancePage() {
  const { supabase, profile } = await requireOfficial()
  if (profile.role !== 'executive' && profile.role !== 'department_head') return <><PageHeading kicker="অনুমতি" title="শুধু অনুমোদিত কর্মকর্তার জন্য" description="এই পাতা আপনার ভূমিকার জন্য উপলব্ধ নয়।"/></>
  const [{data:departments},{data:profiles}] = await Promise.all([supabase.from('departments').select('id,name_bn,description_bn').order('name_bn'),supabase.from('profiles').select('id,display_name,role,department_id')])
  return <><PageHeading kicker="কার কী অনুমতি" title="বিভাগ ও অনুমতি" description="প্রতিটি ভূমিকায় কে কী দেখতে ও করতে পারেন, তা এখানে দেখুন। এই পাতা থেকে অ্যাকাউন্ট খোলা যায় না।"/><DemoNote>ডেমো অ্যাকাউন্ট প্রশাসক তৈরি করেন। সাধারণ দর্শকদের সাইন আপ করার সুযোগ নেই।</DemoNote><div className="governance-grid section-gap"><section className="panel"><div className="panel-head"><div><span className="mini-kicker">দায়িত্ব বিভাজন</span><h2>৫টি বিভাগ</h2></div></div><div className="governance-list">{(departments||[]).map(d=><div key={d.id}><strong>{d.name_bn}</strong><span>{d.description_bn}</span></div>)}</div></section><section className="panel"><div className="panel-head"><div><span className="mini-kicker">ভূমিকা</span><h2>কর্মকর্তার ভূমিকা</h2></div></div><div className="governance-list">{capabilities.map(c=><div key={c.role}><strong>{roleLabels[c.role]}</strong><span>{c.scope}</span><small>{c.actions}</small></div>)}</div></section></div><section className="panel section-gap"><div className="panel-head"><div><span className="mini-kicker">তৈরি করা অ্যাকাউন্ট</span><h2>{(profiles||[]).length} জন কর্মকর্তা</h2></div></div><div className="governance-list compact">{(profiles||[]).map(p=><div key={p.id}><strong>{p.display_name}</strong><span>{roleLabels[p.role as keyof typeof roleLabels]} · {departments?.find(d=>d.id===p.department_id)?.name_bn || 'সব বিভাগ'}</span></div>)}</div></section></>
}
