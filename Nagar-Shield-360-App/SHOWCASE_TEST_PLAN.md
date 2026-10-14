# NagarShield 360 showcase and full workflow test

This script uses the shared Supabase project. A phone submits a complaint, web officials verify and assign it, a named field worker finishes it in Flutter, a supervisor approves it on the web, and the original phone sees the result. Keep the same report code visible across devices. Use [the shared run sheet](./INTEGRATION_TEST_AND_RECORDING_PLAN.md) for the full acceptance matrix and primary recording plan.

## Prepare the demonstration

1. Connect the web computer and both phones to the internet. Start the web project in the sibling `NagarShield-360` folder with `npm run dev` and open `http://localhost:3000`. The web computer must have its existing `.env.local` for the shared project.
2. Install the **same** `dist/nagarshield-showcase-universal.apk` on both phones. On first entry to **সমস্যা জানান**, choose public demo identity **A** on the citizen phone and **B** on the second phone. The letter is stored for that installation. Smaller ABI builds of the same app are also in `dist/`.
3. Allow the phone to pick a photo. Prepare two different, non-identifying images of a drain: one showing the obstruction and one showing the cleaned result. Gallery images make the recording predictable. A camera is also available for the worker's after photo.
4. Sign in to the web once with `executive@example.test` / `123456`, then sign out. Confirm the dashboard, incidents, tasks, map, and reports load. On the app landing page, confirm the system overview, **সমস্যা জানান**, and **কর্মকর্তা হিসেবে সাইন ইন** open as expected.
5. Run `node scripts/check_showcase_data.mjs` and `node scripts/check_official_views.mjs` in this app directory if you want a fresh preflight. These checks only read shared data. Counts include existing demo records, so record the starting totals instead of assuming zero.
6. Use a unique title for each rehearsal, such as `বাজার সড়কের ড্রেন বন্ধ — প্রদর্শনী ১৪ অক্টোবর`. Do not use the web **ডেমো পুনরায় শুরু** control during the live run. Flutter's **Reset Demo** applies only to the separate offline presentation scenario.

### Test accounts

| Role | Sign-in | Use in the showcase |
| --- | --- | --- |
| Executive | `executive@example.test` / `123456` | Review a new complaint; view citywide reports |
| Drainage head | `drainage.head@example.test` / `123456` | Optional department view and review |
| Drainage supervisor | `drainage.supervisor@example.test` / `123456` | Review the assigned team's completed work |
| Drainage worker | `drainage.field@example.test` / `123456` | Accept, start, and submit after evidence |
| Waste worker | `waste.field@example.test` / `123456` | Confirm another team's task is hidden |
| Survey operator | See ignored `config/survey-operator.local.json` | Optional drone/GapScan branch |
| Citizen A and B | Open **সমস্যা জানান** in the same APK and choose a different letter on each installation; no public password form | A submits; B checks isolation |

The A/B/C identities are controlled demo accounts in one APK. Anyone selecting the same letter shares that letter's reports. To change a phone's letter, clear that app's data first; this also removes local drafts and queued work. Do not use personal photos or sensitive location details in this prototype.

## Main live chain: complaint to approved work

| Step | Actor and screen | Action | Expected result to capture |
| --- | --- | --- | --- |
| 1 | Citizen A · mobile landing → **সমস্যা জানান** | Choose **ড্রেনের সমস্যা**. Enter title `বাজার সড়কের ড্রেন বন্ধ — প্রদর্শনী ১৪ অক্টোবর`, details `ড্রেনের মুখে ময়লা আটকে আছে। রাস্তার পাশে পানি জমেছে, পথচারীদের চলতে অসুবিধা হচ্ছে।`, and area `মিরপুর বাজার সড়ক, গলি ৩`. Add the before image. Enter latitude `23.8071`, longitude `90.3679`, and choose approximate location. Review the privacy preview and accept the notice. | The form shows category, evidence, location, and privacy choice. |
| 2 | Citizen A · **আমার প্রতিবেদন** | Submit. If queued, tap **অপেক্ষার প্রতিবেদন পাঠান** with internet on. Write down the `NS-P-...` code. | One report appears as **কর্মকর্তার যাচাই বাকি**. There is no incident or assigned worker yet. |
| 3 | Executive · web sign-in → **ঘটনা কেন্দ্র** | Find the same code under **যাচাইয়ের অপেক্ষায়**. Read the complaint and before image. Add a review note, then choose **ঘটনা তৈরি ও যাচাই**. | The review item leaves the queue and an incident with the same report code appears as **যাচাই হয়েছে**. The official decision, not a simulated detection, created the incident. |
| 4 | Executive · open that incident on web or Flutter | Assign department **পানিনিষ্কাশন**, team `drainage-a`, and the named worker **ড্রেনেজ মাঠকর্মী** (`drainage.field@example.test`). Enter `ড্রেনের মুখ পরিষ্কার করুন, পানি নামছে কি না দেখুন, কাজ শেষে ছবি দিন।` | Incident and task become **কাজ দেওয়া হয়েছে**. The assignee name and instruction are visible in task detail. Record the code and worker name together. |
| 5 | Drainage worker · Flutter official sign-in → **আমার কাজ** | Open the task with that code, tap **গ্রহণ করুন**, then **শুরু করুন**. | Task moves through accepted to **কাজ চলছে**. The citizen's status follows the incident's latest state after refresh. |
| 6 | Drainage worker · incident detail | Tap **কাজ শেষে ছবি জমা দিন**, select the after image, and write `ড্রেনের মুখের ময়লা সরিয়ে পানি চলাচল স্বাভাবিক করেছি।` Submit. | Before and after evidence appear in the incident. Task is **কাজ শেষে যাচাই বাকি**; incident is awaiting completion review. The worker cannot approve their own work. |
| 7 | Drainage supervisor · web sign-in → **কাজের বোর্ড** | Open the same code. Compare before/after evidence and the worker's completion note. Choose **ফল যাচাই ও অনুমোদন**. | Task and incident become **কাজ শেষ, অনুমোদিত**. The audit timeline records assignment, worker actions, evidence, and approval. If the result is poor, choose **আবার কাজের জন্য পাঠান** instead and continue from step 5 on a separate rehearsal report. |
| 8 | Citizen A · mobile **আমার প্রতিবেদন** | Tap **অপেক্ষার প্রতিবেদন পাঠান** to refresh the list. | The same `NS-P-...` code now shows **কাজ শেষ, অনুমোদিত** and the full progress bar. Citizen A sees only their own report history. |
| 9 | Executive · web **প্রতিবেদন** and Flutter **প্রতিবেদন** | Refresh. Show total incidents, resolved count, department breakdown, and the completed incident. Open its audit timeline. | Resolved total is one higher than the starting count, if no other user changed shared data during the recording. The metrics are scoped to each role's permissions. |

**Handoff rule:** A newly verified, unassigned complaint may not be visible to the team supervisor yet. Have the executive or drainage head assign it to `drainage-a` first; the supervisor then sees and reviews that team's task.

## Suggested 7-minute screen recording

| Time | Screen | Spoken point in natural Bangla |
| --- | --- | --- |
| 0:00–0:35 | Mobile landing and system overview | “নাগরিক সমস্যা জানাতে পারেন; কর্মকর্তারা একই নথিতে কাজ করেন।” |
| 0:35–1:30 | Citizen form, privacy preview, submitted code | “ছবি ও জায়গা দিয়ে অভিযোগ জমা হলো। এটি আগে একজন কর্মকর্তা যাচাই করবেন।” |
| 1:30–2:20 | Executive web review and incident creation | “কর্মকর্তা বিবরণ ও প্রমাণ দেখে ঘটনাটি গ্রহণ করলেন।” |
| 2:20–3:10 | Named assignment, web task board, map marker | “কাজটি নির্দিষ্ট বিভাগ, দল ও মাঠকর্মীর কাছে গেল।” |
| 3:10–4:20 | Worker mobile accept, start, after photo | “মাঠকর্মী কাজের অগ্রগতি ও শেষের ছবি জমা দিলেন।” |
| 4:20–5:20 | Supervisor before/after review and approval | “তদারককারী প্রমাণ মিলিয়ে কাজ শেষের সিদ্ধান্ত দিলেন।” |
| 5:20–6:20 | Citizen status, executive report, audit timeline | “নাগরিক ফল দেখতে পাচ্ছেন; কর্তৃপক্ষও কাজের হিসাব ও প্রতিটি পদক্ষেপ দেখছেন।” |
| 6:20–7:00 | Optional Media Studio or GapScan cutaway | “এখানকার শনাক্তকরণ ও স্কোর ডেমোর নমুনা; বাস্তব যাচাই মানুষের হাতেই।” |

Capture the same report code at the handoff points. Hide passwords during screen recording. Keep the phone language in Bangla for the primary showcase; switch briefly to English only if demonstrating localization.

## Additional acceptance passes

### Permissions and privacy

1. On the second phone, choose B and open **আমার প্রতিবেদন**. Citizen A's new report code must be absent. B can submit a separate report and should see only B's history. Since these are demo accounts, two phones selecting A will share A's records.
2. Sign in as `waste.field@example.test`; the drainage task must not appear in **আমার কাজ**. The drainage worker must not see waste or health tasks. The survey operator must not see incident or task boards.
3. Check executive, drainage head, and drainage supervisor screens. Executive sees citywide records; drainage head sees its department; supervisor sees its team and can review work in scope. Attempting an out-of-scope action must be rejected by the server even if a stale screen still shows a button.
4. Confirm evidence opens for authorized officials and that the public tracking screen exposes status, not private staff notes or another citizen's media.

### Rework and conflict

1. Use a **separate** new report for the rework branch. Have the worker submit an after photo, then have the supervisor return the work with a reason. Confirm the worker sees the active task again and can submit a corrected photo; approve the corrected result.
2. Open the same task on two devices. Let one manager approve it. On the stale device, attempt the old review action. The server must reject the conflicting transition; check **পাঠানোর তালিকা** for a rejected action and refresh the incident.
3. Retry the same queued public submission and worker evidence after a connection interruption. Confirm only one report and one task transition are created.

### Offline, permissions, and languages

1. Start a citizen report, enter category, text, coordinates, and photo, then close and reopen the app. The draft and selected photo should return. With airplane mode on, submit and check the local queue; reconnect and retry. The report code should appear once.
2. Queue a permitted staff action while offline, restart, reconnect, and open **পাঠানোর তালিকা**. Confirm it syncs or shows a server rejection that can be reviewed.
3. Deny location access and enter coordinates manually. Deny camera access for worker evidence and choose an after image from the gallery.
4. Repeat landing, public form, tracking, dashboard, task, incident detail, and reports in English. Check that the Bangla version reads naturally and that small screens do not overflow.
5. Turn off internet completely and run the **স্থানীয় ডেমো** chain. Confirm its own report → verification → assignment → worker evidence → approval → public result. Reset that presentation data and verify the live Supabase record remains intact.

### Media, map, and survey branch

1. In **Media Studio**, open all six presets, including the two videos. Show the **simulated** label. Import one image and one MP4; draw a manual box/polygon and add a time range to the video annotation. Reopen the saved import.
2. On the map, tap the new incident marker near the recorded coordinates. Mention that map tiles need internet and demo locations are illustrative.
3. As survey operator, record a **GapScan** for a named narrow-gap site, then repeat an observation for the same site. Record source, location, media, and manual annotation. As an optional drone example, enter area, capture source, operator time, and permission reference. This records a mission; it does not fly a drone or run AI inference.
4. As executive, verify a survey observation in the review queue. Confirm the resulting incident can follow the same assignment and approval chain. Use a separate survey record so the primary public story stays easy to follow.

## Build and release checks

From the `NagarShield App` folder:

```powershell
flutter analyze
flutter test
powershell -File scripts/build_public_demo_apks.ps1
```

The build script runs `flutter build apk --split-per-abi` once, copies those ABI variants, and produces a universal APK for one-file installation on all test phones. On the web project, run `npm run typecheck` and `npm run build`. The iOS build runs through `.github/workflows/ios.yml` on a macOS runner. Finish with a physical two-phone rehearsal, since automated API and widget checks cannot prove camera prompts, installation, real mobile layout, or a screen recording.
