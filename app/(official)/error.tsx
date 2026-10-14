'use client'

export default function ErrorPage({ reset }: { error: Error; reset: () => void }) {
  return <div className="official-error" role="alert"><h2>পাতাটি এখন দেখানো যাচ্ছে না</h2><p>পাতাটি খুলতে সমস্যা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন।</p><button type="button" onClick={reset}>আবার চেষ্টা করুন</button></div>
}
