import { redirect } from 'next/navigation'
import { DemoNote, PageHeading } from '@/src/components/Ui'
import { ScenarioAnalysis } from '@/src/components/ScenarioAnalysis'
import { requireOfficial } from '@/src/lib/supabase/server'
import type { Scenario } from '@/src/lib/types'

export default async function AnalysisPage() {
  const { supabase, profile } = await requireOfficial()
  if (!['executive','department_head'].includes(profile.role)) redirect('/dashboard')
  const { data } = await supabase.from('scenarios').select('id,title_bn,summary_bn,kind,hazard,area_bn,media_key,detections,factors').order('id')
  return <><PageHeading kicker="প্রোটোটাইপ প্রদর্শন" title="মিডিয়া বিশ্লেষণ" description="নমুনা দৃশ্য বেছে সিমুলেটেড শনাক্তকরণ, স্কোর ও মানব যাচাইয়ের ধাপ দেখুন।"/><DemoNote>এখানে সত্যিকারের AI বিশ্লেষণ নেই। ফল পূর্বনির্ধারিত নমুনা থেকে তৈরি হয়।</DemoNote><div className="section-gap"><ScenarioAnalysis items={(data || []) as Scenario[]}/></div></>
}
