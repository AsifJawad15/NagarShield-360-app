import { DemoNote, PageHeading } from '@/src/components/Ui'
import { MapPanel } from '@/src/components/MapPanel'
import { requireOfficial } from '@/src/lib/supabase/server'
import type { Incident } from '@/src/lib/types'
import { redirect } from 'next/navigation'

export default async function MapPage() {
  const { supabase, profile } = await requireOfficial()
  if (profile.role === 'field_employee') redirect('/dashboard')
  const [{data:incidents},{data:infrastructure}] = await Promise.all([
    supabase.from('incidents').select('*').order('score',{ascending:false}),
    supabase.from('infrastructure').select('id,type,label_bn,geometry'),
  ])
  return <><PageHeading kicker="অবস্থানভিত্তিক পর্যালোচনা" title="কমান্ড মানচিত্র" description="ঘটনা ও অবকাঠামোর স্তর একসঙ্গে দেখুন। অবস্থানগুলো প্রদর্শনের নমুনা।"/><DemoNote>ডিফল্ট স্কিম্যাটিক মানচিত্র অফলাইনেও কাজ করে; টাইল মানচিত্রে ইন্টারনেট প্রয়োজন।</DemoNote><div className="section-gap"><MapPanel incidents={(incidents||[]) as Incident[]} infrastructure={infrastructure||[]}/></div></>
}
