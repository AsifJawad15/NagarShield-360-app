import { DemoNote, PageHeading } from '@/src/components/Ui'
import { roleLabels } from '@/src/lib/demo'
import { requireOfficial } from '@/src/lib/supabase/server'

const capabilities = [
  {role:'executive',scope:'সব ডেমো এলাকা ও বিভাগ',actions:'পর্যবেক্ষণ যাচাই, বিভাগীয় দায়িত্ব, ফল যাচাই, প্রতিবেদন ও ডেমো রিসেট'},
  {role:'department_head',scope:'নিজ বিভাগের ঘটনা ও কাজ',actions:'যাচাই, নিজ বিভাগে দায়িত্ব, ফল অনুমোদন ও প্রতিবেদন'},
  {role:'supervisor',scope:'নিজ দলের কাজ',actions:'দলের দায়িত্ব, মাঠকাজ যাচাই ও পুনরায় কাজ পাঠানো'},
  {role:'field_employee',scope:'নিজের দায়িত্ব',actions:'গ্রহণ, কাজ শুরু, পরের দৃশ্য ও বিবরণ জমা'},
] as const

export default async function GovernancePage() {
  const { supabase, profile } = await requireOfficial()
  if (profile.role !== 'executive' && profile.role !== 'department_head') return <><PageHeading kicker="অনুমতি" title="শুধু অনুমোদিত কর্মকর্তার জন্য" description="এই পাতা আপনার ভূমিকার জন্য উপলব্ধ নয়।"/></>
  const [{data:departments},{data:profiles}] = await Promise.all([supabase.from('departments').select('id,name_bn,description_bn').order('name_bn'),supabase.from('profiles').select('id,display_name,role,department_id')])
  return <><PageHeading kicker="পাঠযোগ্য নীতি" title="বিভাগ ও অনুমতি" description="কে কোন তথ্য দেখবেন এবং কোন পদক্ষেপ নিতে পারবেন, তার ডেমো চিত্র। অ্যাকাউন্ট এখানে তৈরি করা যায় না।"/><DemoNote>অ্যাকাউন্ট কেবল প্রশাসক ব্যক্তিগতভাবে তৈরি করেন; জনসাধারণের নিবন্ধন বন্ধ।</DemoNote><div className="governance-grid section-gap"><section className="panel"><div className="panel-head"><div><span className="mini-kicker">দায়িত্ব বিভাজন</span><h2>৫টি বিভাগ</h2></div></div><div className="governance-list">{(departments||[]).map(d=><div key={d.id}><strong>{d.name_bn}</strong><span>{d.description_bn}</span></div>)}</div></section><section className="panel"><div className="panel-head"><div><span className="mini-kicker">ডেমো পরিচয়</span><h2>কর্মকর্তার ভূমিকা</h2></div></div><div className="governance-list">{capabilities.map(c=><div key={c.role}><strong>{roleLabels[c.role]}</strong><span>{c.scope}</span><small>{c.actions}</small></div>)}</div></section></div><section className="panel section-gap"><div className="panel-head"><div><span className="mini-kicker">সক্রিয় ডেমো অ্যাকাউন্ট</span><h2>{(profiles||[]).length} জন কর্মকর্তা</h2></div></div><div className="governance-list compact">{(profiles||[]).map(p=><div key={p.id}><strong>{p.display_name}</strong><span>{roleLabels[p.role as keyof typeof roleLabels]} · {departments?.find(d=>d.id===p.department_id)?.name_bn || 'সব বিভাগ'}</span></div>)}</div></section></>
}
