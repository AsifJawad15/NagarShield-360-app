import { redirect } from 'next/navigation'
import { DemoNote, Notice, PageHeading } from '@/src/components/Ui'
import { PrivateMedia } from '@/src/components/PrivateMedia'
import { bn, dateBn } from '@/src/lib/demo'
import { requireOfficial } from '@/src/lib/supabase/server'

type Mission = {
  id: string
  kind: 'drone' | 'gapscan'
  area_bn: string
  site_label: string | null
  capture_source: string
  captured_at: string
  flight_permission_ref: string | null
  notes: string | null
}
type Observation = {
  id: string
  mission_id: string | null
  title_bn: string
  area_bn: string
  source: string
  status: string
  media_key: string | null
  created_at: string
}
export default async function SurveysPage({
  searchParams,
}: { searchParams: Promise<{ notice?: string }> }) {
  const { supabase, profile } = await requireOfficial()
  if (!['executive','department_head','survey_operator'].includes(profile.role)) {
    redirect('/dashboard')
  }
  const [{ data: missions, error: missionsError }, { data: observations, error: observationsError }] = await Promise.all([
    supabase.from('survey_missions')
      .select('id,kind,area_bn,site_label,capture_source,captured_at,flight_permission_ref,notes')
      .order('captured_at', { ascending: false }),
    supabase.from('observations')
      .select('id,mission_id,title_bn,area_bn,source,status,media_key,created_at')
      .in('source', ['drone','gapscan']).order('created_at', { ascending: false }),
  ])
  const surveyMissions = (missions || []) as Mission[]
  const surveyObservations = (observations || []) as Observation[]
  const gapSites = new Map<string, number>()
  for (const mission of surveyMissions.filter(item => item.kind === 'gapscan')) {
    const site = mission.site_label || mission.area_bn
    gapSites.set(site, (gapSites.get(site) || 0) + 1)
  }
  const { notice } = await searchParams
  return <>
    <PageHeading kicker="জরিপ নথি" title="ড্রোন ও সংকীর্ণ স্থান"
      description="কোথায়, কখন এবং কীভাবে জরিপের নমুনা নেওয়া হয়েছে, তা এখানে দেখুন। এই পাতা দিয়ে ড্রোন চালানো যায় না।"/>
    <Notice value={notice}/>
    <DemoNote>এখানে তৈরি নমুনা জরিপের পাশাপাশি Flutter থেকে জমা দেওয়া পরীক্ষামূলক জরিপও দেখা যায়। কোনো সমস্যা ঘটনা হিসেবে খোলার আগে কর্মকর্তা যাচাই করবেন।</DemoNote>
    {(missionsError || observationsError) && <div role="alert" className="notice notice-error">জরিপের তথ্য দেখানো যাচ্ছে না। ডেটাবেসের জরিপ সংক্রান্ত পরিবর্তনগুলো চালু আছে কি না দেখুন।</div>}
    <section className="panel section-gap">
      <div className="panel-head"><div><span className="mini-kicker">সংকীর্ণ জায়গার আগের জরিপগুলো</span>
        <h2>সংকীর্ণ স্থান · {bn(gapSites.size)}</h2></div></div>
      {gapSites.size ? <div className="survey-site-list">{Array.from(gapSites.entries()).map(([site, count]) =>
        <div key={site}><strong>{site}</strong><span>{bn(count)}টি জরিপ</span></div>,
      )}</div> : <div className="empty-state">এখনো এই ধরনের জরিপ নেই।</div>}
    </section>
    <section className="panel section-gap">
      <div className="panel-head"><div><span className="mini-kicker">জরিপের বিবরণ</span>
        <h2>মোট জরিপ · {bn(surveyMissions.length)}</h2></div></div>
      {surveyMissions.length ? <div className="survey-mission-list">
        {surveyMissions.map(mission => {
          const items = surveyObservations.filter(item => item.mission_id === mission.id)
          return <article key={mission.id} className="survey-mission">
            <div><span className="row-meta">{mission.kind === 'drone' ? 'ড্রোন' : 'সংকীর্ণ স্থান'} · {dateBn(mission.captured_at)}</span>
              <h3>{mission.site_label || mission.area_bn}</h3>
              <p>{mission.area_bn} · উৎস: {mission.capture_source}</p>
              {mission.flight_permission_ref && <p>অনুমতির তথ্য: {mission.flight_permission_ref}</p>}
              {mission.notes && <p>{mission.notes}</p>}
            </div>
            <div className="survey-observations">{items.map(item =>
              <div key={item.id}>
                {item.media_key && <div className="review-media">
                  <PrivateMedia mediaKey={item.media_key} alt={item.title_bn} controls/>
                </div>}
                <strong>{item.title_bn}</strong>
                <span>{item.status === 'needs_review' ? 'কর্মকর্তার যাচাইয়ের অপেক্ষায়' : item.status === 'verified' ? 'যাচাই করা হয়েছে' : 'বাতিল'}</span>
              </div>,
            )}</div>
          </article>
        })}</div> : <div className="empty-state">এখনো কোনো জরিপ নেই। ডেমো আবার শুরু করলে নমুনা জরিপ দেখা যাবে।</div>}
    </section>
  </>
}
