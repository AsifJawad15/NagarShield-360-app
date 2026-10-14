import { DemoNote, PageHeading } from '@/src/components/Ui'
import { MapPanel } from '@/src/components/MapPanel'
import { requireOfficial } from '@/src/lib/supabase/server'
import type { Incident } from '@/src/lib/types'
import { redirect } from 'next/navigation'

export default async function MapPage() {
  const { supabase, profile } = await requireOfficial()
  if (profile.role === 'field_employee') redirect('/dashboard')
  if (profile.role === 'survey_operator') redirect('/surveys')
  const [{data:incidents},{data:infrastructure}] = await Promise.all([
    supabase.from('incidents').select('*').order('score',{ascending:false}),
    supabase.from('infrastructure').select('id,type,label_bn,geometry'),
  ])
  return <><PageHeading kicker="অবস্থানভিত্তিক পর্যালোচনা" title="কমান্ড মানচিত্র" description="ঘটনার অবস্থান ও আশপাশের ড্রেন-ফুটপাত একসঙ্গে দেখুন। মানচিত্রের স্থানগুলো ডেমোর জন্য সাজানো।"/><DemoNote>সহজ মানচিত্র ইন্টারনেট ছাড়াও দেখা যায়। রাস্তার মানচিত্রে ইন্টারনেট লাগবে।</DemoNote><div className="section-gap"><MapPanel incidents={(incidents||[]) as Incident[]} infrastructure={infrastructure||[]}/></div></>
}
