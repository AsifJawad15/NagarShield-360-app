import { cookies } from 'next/headers'
import { createServerClient } from '@supabase/ssr'
import { redirect } from 'next/navigation'
import type { OfficialProfile } from '../types'

export const isConfigured = Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY)

export async function supabaseServer() {
  if (!isConfigured) throw new Error('Supabase environment is not configured')
  const cookieStore = await cookies()
  return createServerClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, {
    cookies: {
      getAll() { return cookieStore.getAll() },
      setAll(values) {
        try { values.forEach(({ name, value, options }) => cookieStore.set(name, value, options)) }
        catch { /* Server Components cannot set cookies. Actions can. */ }
      },
    },
  })
}

export async function requireOfficial() {
  if (!isConfigured) redirect('/?auth=unavailable')
  const supabase = await supabaseServer()
  const { data: { user }, error: authError } = await supabase.auth.getUser()
  if (authError || !user) redirect('/?auth=required')
  const { data, error } = await supabase.from('profiles').select('id,display_name,role,department_id,team_id,departments(name_bn)').eq('id', user.id).single()
  if (error || !data) redirect('/?auth=denied')
  return { supabase, profile: data as unknown as OfficialProfile, user }
}
