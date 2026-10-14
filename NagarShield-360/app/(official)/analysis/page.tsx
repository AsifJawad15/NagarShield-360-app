import { redirect } from 'next/navigation'
import { DemoNote, PageHeading } from '@/src/components/Ui'
import { ScenarioAnalysis } from '@/src/components/ScenarioAnalysis'
import { requireOfficial } from '@/src/lib/supabase/server'
import type { Scenario } from '@/src/lib/types'

export default async function AnalysisPage() {
  const { supabase, profile } = await requireOfficial()
  if (!['executive','department_head'].includes(profile.role)) redirect('/dashboard')
  const { data } = await supabase.from('scenarios').select('id,title_bn,summary_bn,kind,hazard,area_bn,media_key,detections,factors').order('id')
  return <><PageHeading kicker="প্রোটোটাইপ প্রদর্শন" title="মিডিয়া বিশ্লেষণ" description="একটি নমুনা ছবি বা ভিডিও বেছে নিন। কোথায় সমস্যা দেখানো হয়েছে এবং কেন অগ্রাধিকার দেওয়া হয়েছে, তা দেখুন।"/><DemoNote>ফল আগে থেকেই তৈরি করা; এখানে কোনো ছবি বা ভিডিও স্বয়ংক্রিয়ভাবে বিশ্লেষণ করা হয় না।</DemoNote><div className="section-gap"><ScenarioAnalysis items={(data || []) as Scenario[]}/></div></>
}
