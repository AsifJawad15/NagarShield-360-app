import Link from 'next/link'

export default function IncidentNotFound() {
  return <div className="official-error"><h2>ঘটনাটি পাওয়া যায়নি</h2><p>এটি আপনার অ্যাকাউন্টের জন্য দৃশ্যমান না-ও হতে পারে।</p><Link href="/incidents">ঘটনার তালিকায় ফিরুন</Link></div>
}
