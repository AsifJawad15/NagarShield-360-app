'use server'

import { redirect } from 'next/navigation'
import { isConfigured, supabaseServer } from '@/src/lib/supabase/server'

export async function signIn(formData: FormData) {
  if (!isConfigured) redirect('/?auth=unavailable#signin')
  const email = String(formData.get('email') || '').trim()
  const password = String(formData.get('password') || '')
  if (!email || !password) redirect('/?auth=missing#signin')
  const supabase = await supabaseServer()
  const { error } = await supabase.auth.signInWithPassword({ email, password })
  if (error) redirect('/?auth=invalid#signin')
  const { data: { user } } = await supabase.auth.getUser()
  const profile = user ? await supabase.from('profiles').select('role').eq('id', user.id).maybeSingle() : null
  if (!profile?.data || !['executive','department_head','supervisor','field_employee','survey_operator'].includes(profile.data.role)) {
    await supabase.auth.signOut()
    redirect('/?auth=denied#signin')
  }
  redirect('/dashboard')
}

export async function signOut() {
  if (isConfigured) {
    const supabase = await supabaseServer()
    await supabase.auth.signOut()
  }
  redirect('/')
}
