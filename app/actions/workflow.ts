'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'
import { requireOfficial } from '@/src/lib/supabase/server'

const allowedReturns = ['/dashboard', '/map', '/incidents', '/analysis', '/tasks', '/reports', '/governance', '/surveys']
function safeReturn(value: FormDataEntryValue | null) {
  const path = String(value || '/dashboard')
  return allowedReturns.some(base => path === base || path.startsWith(`${base}/`)) && !path.includes('//') ? path : '/dashboard'
}

export async function performWorkflowAction(formData: FormData) {
  const { supabase } = await requireOfficial()
  const action = String(formData.get('action') || '')
  const target = String(formData.get('target') || '')
  const payload = {
    note: String(formData.get('note') || '').slice(0, 1000),
    department_id: String(formData.get('department_id') || ''),
    assignee_id: String(formData.get('assignee_id') || ''),
    team_id: String(formData.get('team_id') || ''),
    media_key: String(formData.get('media_key') || ''),
    scenario_id: String(formData.get('scenario_id') || ''),
  }
  const back = safeReturn(formData.get('return_to'))
  const workflowAction = action === 'verify_intake' ? 'verify_observation'
    : action === 'dismiss_intake' ? 'dismiss_observation' : action
  let error
  if (['verify_observation', 'dismiss_observation'].includes(workflowAction) && target) {
    const observation = await supabase.from('observations').select('source').eq('id', target).maybeSingle()
    if (observation.error || !observation.data) {
      redirect(`${back}?notice=${encodeURIComponent('পর্যবেক্ষণটি পাওয়া যায়নি বা দেখার অনুমতি নেই।')}`)
    }
    if (observation.data.source !== 'scenario') {
      const result = await supabase.rpc('review_intake_observation', {
        p_id: target,
        p_approve: workflowAction === 'verify_observation',
        p_note: payload.note,
      })
      error = result.error
    }
  }
  if (error === undefined) {
    const result = await supabase.rpc('perform_demo_action', {
      p_action: workflowAction, p_target: target || null, p_payload: payload,
    })
    error = result.error
  }
  if (error) redirect(`${back}?notice=${encodeURIComponent(error.message.slice(0, 120))}`)
  revalidatePath('/', 'layout')
  redirect(`${back}?notice=done`)
}

export async function resetDemo() {
  const { supabase, profile } = await requireOfficial()
  if (profile.role !== 'executive') redirect('/dashboard?notice=denied')
  const { error } = await supabase.rpc('reset_demo')
  if (error) redirect(`/dashboard?notice=${encodeURIComponent(error.message.slice(0, 120))}`)
  revalidatePath('/', 'layout')
  redirect('/dashboard?notice=reset')
}
