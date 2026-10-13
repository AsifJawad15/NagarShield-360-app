import { NextResponse } from 'next/server'
import { requireOfficial } from '@/src/lib/supabase/server'
import { hazards, priorities, statuses } from '@/src/lib/demo'
import type { Incident } from '@/src/lib/types'

const csv = (value: unknown) => `"${String(value ?? '').replaceAll('"','""')}"`
export async function GET() {
  const { supabase, profile } = await requireOfficial()
  if (profile.role === 'field_employee') return new NextResponse('Forbidden', { status: 403 })
  const { data, error } = await supabase.from('incidents').select('*').order('created_at',{ascending:false})
  if (error) return new NextResponse('Report unavailable', { status: 500 })
  const rows = (data || []) as Incident[]
  const header = ['আইডি','শিরোনাম','সমস্যা','অবস্থা','অগ্রাধিকার','স্কোর','এলাকা','তৈরির সময়']
  const body = rows.map(item=>[item.code,item.title_bn,hazards[item.hazard],statuses[item.status],priorities[item.priority],item.score,item.area_bn,item.created_at].map(csv).join(','))
  return new NextResponse('\uFEFF'+[header.map(csv).join(','),...body].join('\r\n'), { headers: {'Content-Type':'text/csv; charset=utf-8','Content-Disposition':'attachment; filename="nagar-shield-demo-report.csv"','Cache-Control':'private, no-store'} })
}
