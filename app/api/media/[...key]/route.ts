import { NextResponse, type NextRequest } from 'next/server'
import { requireOfficial } from '@/src/lib/supabase/server'

export async function GET(_request: NextRequest, context: { params: Promise<{ key: string[] }> }) {
  const { supabase } = await requireOfficial()
  const { key } = await context.params
  const path = key.join('/')
  if (!path || key.some(part => part === '..' || part === '.')) return new NextResponse('Bad path', { status: 400 })
  const { data, error } = await supabase.storage.from('demo-media').download(path)
  if (error || !data) return new NextResponse('Not found', { status: 404 })
  return new NextResponse(data, { headers: { 'Content-Type': data.type || 'application/octet-stream', 'Cache-Control': 'private, no-store', 'X-Content-Type-Options': 'nosniff' } })
}
