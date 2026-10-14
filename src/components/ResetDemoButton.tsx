'use client'

import { resetDemo } from '@/app/actions/workflow'

export function ResetDemoButton() {
  return <form action={resetDemo} onSubmit={event => {
    if (!window.confirm('ডেমোর সব কাজ ও পরিবর্তন মুছে শুরুর অবস্থায় ফিরবে। নিশ্চিত?')) event.preventDefault()
  }}>
    <button className="button-outline" type="submit">ডেমো আবার শুরু করুন</button>
  </form>
}
