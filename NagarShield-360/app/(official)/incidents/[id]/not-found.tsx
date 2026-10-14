import Link from 'next/link'

export default function IncidentNotFound() {
  return <div className="official-error"><h2>ঘটনাটি পাওয়া যায়নি</h2><p>ঘটনাটি নেই, অথবা এটি দেখার অনুমতি আপনার নেই।</p><Link href="/incidents">ঘটনার তালিকায় ফিরুন</Link></div>
}
