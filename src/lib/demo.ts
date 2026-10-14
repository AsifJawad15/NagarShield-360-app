import type { DetectionType, IncidentStatus, Priority, Scenario, ScoreFactors } from './types'

export const hazards: Record<DetectionType, string> = {
  DRAIN_OBSTRUCTION: 'বন্ধ ড্রেন',
  STANDING_WATER: 'জমে থাকা পানি',
  WASTE: 'জমে থাকা বর্জ্য',
  FOOTPATH_OBSTRUCTION: 'ফুটপাতের বাধা',
  ACCESS_OBSTRUCTION: 'প্রবেশপথে বাধা',
  WATER_CONTAINER: 'পানি জমার পাত্র',
}

export const statuses: Record<IncidentStatus, string> = {
  needs_review: 'কর্মকর্তার যাচাই বাকি', verified: 'যাচাই হয়েছে', assigned: 'কাজ দেওয়া হয়েছে',
  acknowledged: 'কর্মী কাজটি নিয়েছেন', in_progress: 'কাজ চলছে', action_submitted: 'কাজ শেষে যাচাই বাকি',
  verification_pending: 'কাজ শেষে যাচাই বাকি', resolved: 'কাজ শেষ, অনুমোদিত', dismissed: 'যাচাইয়ে গ্রহণ করা হয়নি',
}
export const priorities: Record<Priority, string> = { low: 'কম', moderate: 'মাঝারি', high: 'উচ্চ', critical: 'অতি জরুরি' }
export const roleLabels = { executive: 'নির্বাহী কর্মকর্তা', department_head: 'বিভাগীয় প্রধান', supervisor: 'তত্ত্বাবধায়ক', field_employee: 'মাঠকর্মী', survey_operator: 'জরিপ অপারেটর' }
export const eventLabels: Record<string,string> = {
  seeded: 'নমুনা ঘটনা তৈরি', verified_observation: 'সমস্যা যাচাই', assigned: 'দায়িত্ব দেওয়া হয়েছে',
  acknowledge_task: 'দায়িত্ব গ্রহণ', start_task: 'কাজ শুরু', submit_task: 'কাজের বিবরণ জমা',
  approve_task: 'কাজের ফল অনুমোদন', rework_task: 'সংশোধনের জন্য ফেরত',
  reopen_task: 'ঘটনা আবার খোলা', escalation_changed: 'অগ্রাধিকার বদলানো হয়েছে',
}

export const scenarios: Scenario[] = [
  { id: 'drain', title_bn: 'ড্রেনের মুখে বাধা', summary_bn: 'বাজার সড়কের ড্রেনের মুখে বর্জ্য জমে আছে।', kind: 'image', hazard: 'DRAIN_OBSTRUCTION', area_bn: 'মিরপুর বাজার সড়ক', media_key: 'scenarios/drain.svg', detections: [{ type: 'DRAIN_OBSTRUCTION', label_bn: 'ড্রেনের মুখ', confidence: 0.88, box: [16, 47, 57, 29] }, { type: 'WASTE', label_bn: 'বর্জ্য', confidence: 0.81, box: [47, 54, 31, 22] }], factors: { drain: 85, vector: 55, waste: 75, access: 50, recurrence: 65, evidence: 80, bonus: 5 } },
  { id: 'water', title_bn: 'জমে থাকা পানি', summary_bn: 'রাস্তার নিচু অংশে পানি জমে আছে।', kind: 'video', hazard: 'STANDING_WATER', area_bn: 'মিরপুর ১০, দক্ষিণ পথ', media_key: 'scenarios/water.webm', detections: [{ type: 'STANDING_WATER', label_bn: 'জমে থাকা পানি', confidence: 0.84, box: [19, 60, 64, 23] }], factors: { drain: 65, vector: 85, waste: 20, access: 55, recurrence: 75, evidence: 70, bonus: 8 } },
  { id: 'waste', title_bn: 'জমে থাকা বর্জ্য', summary_bn: 'বাজারের পাশের গলিতে বর্জ্য জমে আছে।', kind: 'image', hazard: 'WASTE', area_bn: 'বাজার গলি', media_key: 'scenarios/waste.svg', detections: [{ type: 'WASTE', label_bn: 'বর্জ্য', confidence: 0.91, box: [26, 50, 54, 33] }], factors: { drain: 30, vector: 50, waste: 90, access: 35, recurrence: 60, evidence: 85, bonus: 0 } },
  { id: 'footpath', title_bn: 'ফুটপাতের বাধা', summary_bn: 'ফুটপাত দিয়ে হাঁটার পথে বাধা আছে।', kind: 'image', hazard: 'FOOTPATH_OBSTRUCTION', area_bn: 'পাইলট এলাকার পূর্ব পথ', media_key: 'scenarios/footpath.svg', detections: [{ type: 'FOOTPATH_OBSTRUCTION', label_bn: 'চলাচলের বাধা', confidence: 0.86, box: [41, 32, 34, 53] }], factors: { drain: 15, vector: 10, waste: 40, access: 92, recurrence: 65, evidence: 80, bonus: 0 } },
  { id: 'mixed', title_bn: 'বাজার এলাকায় একাধিক সমস্যা', summary_bn: 'একই জায়গায় ড্রেন বন্ধ, পানি জমা ও বর্জ্য—তিনটি সমস্যার নমুনা।', kind: 'video', hazard: 'DRAIN_OBSTRUCTION', area_bn: 'মিরপুর বাজার সড়ক', media_key: 'scenarios/mixed.webm', detections: [{ type: 'DRAIN_OBSTRUCTION', label_bn: 'ড্রেনের মুখ', confidence: 0.89, box: [14, 45, 35, 30] }, { type: 'STANDING_WATER', label_bn: 'পানি', confidence: 0.86, box: [31, 67, 54, 20] }, { type: 'WASTE', label_bn: 'বর্জ্য', confidence: 0.82, box: [59, 43, 24, 25] }], factors: { drain: 80, vector: 85, waste: 70, access: 75, recurrence: 90, evidence: 80, bonus: 10 } },
  { id: 'clean', title_bn: 'পরিচ্ছন্ন স্থান', summary_bn: 'এখানে উল্লেখযোগ্য কোনো সমস্যা দেখা যাচ্ছে না।', kind: 'image', hazard: 'STANDING_WATER', area_bn: 'পাইলট এলাকার উত্তর পথ', media_key: 'scenarios/clean.svg', detections: [], factors: { drain: 5, vector: 5, waste: 0, access: 10, recurrence: 5, evidence: 85, bonus: 0 } },
]

export function scoreFactors(f: ScoreFactors) {
  const parts = [
    ['ড্রেন ও পানি নিষ্কাশন', f.drain, .30], ['পানি জমে থাকার সম্ভাবনা', f.vector, .25],
    ['বর্জ্য', f.waste, .15], ['চলাচলে বাধা', f.access, .15],
    ['পুনরাবৃত্তি', f.recurrence, .10], ['তথ্যের স্পষ্টতা', f.evidence, .05],
  ] as const
  const score = Math.min(100, Math.round(parts.reduce((n, [, value, weight]) => n + value * weight, f.bonus)))
  const priority: Priority = score >= 80 ? 'critical' : score >= 60 ? 'high' : score >= 40 ? 'moderate' : 'low'
  return { score, priority, parts, bonus: f.bonus }
}

export const bn = (n: number) => new Intl.NumberFormat('bn-BD').format(n)
export const dateBn = (value: string) => new Intl.DateTimeFormat('bn-BD', { day: 'numeric', month: 'short', year: 'numeric', timeZone: 'Asia/Dhaka' }).format(new Date(value))
export const dateTimeBn = (value: string) => new Intl.DateTimeFormat('bn-BD', { day: 'numeric', month: 'short', year: 'numeric', hour: 'numeric', minute: '2-digit', timeZone: 'Asia/Dhaka' }).format(new Date(value))
