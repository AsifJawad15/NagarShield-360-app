# Nagar Shield 360 — demo test and recording plan

This is the **web preset-scenario rehearsal**. The web remains officials-only beyond its public landing, while the Flutter app handles citizen reporting and live test survey entry on the same Supabase project. Use [the combined plan](./INTEGRATION_TEST_AND_RECORDING_PLAN.md) for the primary hackathon workflow. Preset media, analysis, scores, seeded coordinates and seeded tasks are illustrative.

## 1. Prepare a reproducible run

1. Deploy the current Next.js commit to Vercel. Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` for the target Vercel environment, pointing to the **same** Supabase project used by local provisioning. Do not deploy the service role key or account JSON. Redeploy after changing environment variables.
2. On a fresh project apply web base and reset hotfix, then both Flutter SQL extensions, then web survey and Bangla copy migrations. On a populated project inspect migration history first. The shared order is in the combined plan and is checked by `npm run test:migration`.
3. Confirm Email sign-up and anonymous sign-in are disabled in Supabase Auth. Use the private `demo-accounts.local.json` passwords. Accounts created earlier are not given a new password when provisioning is rerun. The optional survey operator needs an entry added to that local file before provisioning.
4. Run `npm install`, `npm run typecheck`, `npm run test:migration`, `npm run build`. With `npm run dev` or `npm run start` running, run `npm run test:layout`.
5. Run `npm run demo:provision` **once immediately before the rehearsal**. It resets seeded scenario records for every signed-in device but preserves mobile citizen and survey submissions. Expect the final line `Shared fictional dataset reset and ready.` The seeded baseline is 18 incidents, 2 survey missions, and 2 observations awaiting review; totals may be higher if mobile records exist. Then run `npm run test:official-layout` against the running local site.
6. Open the deployed URL in a fresh private browser window. Check that the top bar identifies the demo environment. Disable password-manager overlays and browser notifications before recording. Use separate browser profiles or private windows for the executive, supervisor, and two field accounts.

Record the URL, deployed commit, migration filenames, test command results, browser version, viewport and test time in your rehearsal notes. Do not record passwords or service keys.

## 2. Access and security checks

| Test | Action | Expected result |
| --- | --- | --- |
| Public landing | Open `/` while signed out | Concept and official sign-in are visible; no public reporting form or operational data. |
| Protected pages | While signed out, open `/dashboard`, `/incidents`, `/map`, `/reports`, `/surveys`, and a copied `/incidents/<uuid>` URL | Return to landing/sign-in; no internal content flashes. |
| Protected downloads | While signed out, request `/api/reports/export` and `/api/media/scenarios/drain.svg` | No CSV or private image bytes; unauthorized response. |
| Invalid sign-in | Use a wrong password | Bangla error; protected pages remain unavailable. |
| Direct-link scope | Sign in as field employee and open an incident UUID assigned only to another employee | No detail or media access. |
| Role scope | Sign in as drainage head, drainage supervisor, drainage field employee, and optional survey operator | Head sees own department; supervisor sees own team; field employee sees own assignments; survey operator sees only their department's read-only survey records. |
| State tampering | Try an action before its preceding step, another employee's task ID, and a department/team mismatch through a direct RPC request | Database rejects each action and leaves records unchanged. |
| Signup | Visit any registration URL or try public Auth signup | No app registration flow; Supabase rejects public signup. |

Use browser developer tools only for the direct RPC tampering checks. Never paste service role credentials into a browser. A hidden navigation item alone is not a permission test.

## 3. Functional rehearsal

| Step | Account and page | Action | Expected evidence |
| --- | --- | --- | --- |
| 1 | Executive → `/dashboard` | Read cards and recent incidents | 18 baseline incidents; 2 items need review; all numbers marked as demo. |
| 2 | Executive → `/surveys` | Show the drone and narrow-space survey records | 2 missions with source, time and location; these are seeded illustrative records, not a live drone feed. |
| 3 | Executive → `/analysis` | Select the mixed scenario | Simulated detection boxes, contributing score factors, priority and disclosure are visible. A local file can be previewed and annotated, but does not change simulated results or upload. |
| 4 | Executive → `/analysis` | Send the mixed scenario to review | Review queue grows from 2 to 3. |
| 5 | Executive → `/incidents` | Open a review item, then verify the new scenario observation | Queue falls by 1; a new incident appears; total becomes 19; audit event is visible on its detail page. |
| 6 | Executive → new incident | Assign drainage field employee, then waste field employee | Two department task cards appear. The assignment picker only offers staff in the selected department and uses their matching team. |
| 7 | Drainage field employee → `/tasks` | Acknowledge, start, enter a completion note of at least 8 characters and choose the clean demo image | Task moves through assigned → acknowledged → in progress → submitted; before/after media and timeline update. |
| 8 | Drainage supervisor → incident | Request rework | Drainage task returns to in progress; audit timeline records rework. |
| 9 | Drainage field employee → incident | Submit revised note and demo evidence | Task returns to verification pending. |
| 10 | Drainage supervisor → incident | Approve task | Drainage task resolves; **incident remains open** because waste task is still outstanding. |
| 11 | Waste field employee → incident | Acknowledge, start and submit evidence | Waste task awaits verification. |
| 12 | Executive → incident | Approve waste task | Both tasks resolved; aggregate incident status becomes resolved. |
| 13 | Executive → `/reports` | Inspect charts, counts, before/after cards and download CSV | Counts reflect 19 visible incidents and the newly resolved case. CSV contains the same visible incident rows with Bangla labels. |
| 14 | Executive → incident | Reopen a resolved task | Task and incident reopen; report count changes after refresh. |

Additional branches to rehearse separately: select the clean analysis scenario, send it to review, confirm that verification is rejected and dismiss it; toggle an incident escalation flag; test map hazard filter and switch to tile map, then disconnect the network to check the schematic fallback; refresh two signed-in devices after one task action to verify shared state.

## 4. Visual and interaction checks

- At **1366×768**, check dashboard cards, incident list, review controls, map, analysis preview, survey missions and report charts. No horizontal scrolling or overlapping controls. The executive can read labels and values at normal browser zoom.
- At **390×844** and **320×700**, check landing sign-in, dashboard, task board and incident detail. Scroll the bottom navigation horizontally: all role-permitted links, including tasks and reports, remain reachable. Status and priority chips remain visible in incident rows.
- Use Tab and Shift+Tab to reach sign-in, navigation, filters, task actions and reset. Focus rings must be visible. Enter and Space should activate controls. Check image alternative text and video controls.
- Confirm Bangla headings, statuses, errors and dates are readable; the event timeline uses Dhaka time. The name **Nagar Shield 360** remains in English as the brand.
- On the analysis page, select a local PNG/JPEG/WebP or MP4/WebM. Check the size/type rejection message, preview, manual box/polygon controls, and that results remain labeled simulated. Do not present a local annotation as model inference.
- On missing database migration or failed reads, `/incidents` and `/surveys` must show a visible data-loading error, rather than silently claiming there are no records.

## 5. Recording run sheet (about 7–9 minutes)

| Time | Screen | Narration point |
| --- | --- | --- |
| 0:00–0:40 | Public landing → official sign-in | The public sees only the concept; access is for officials. Pause capture while entering credentials. |
| 0:40–1:25 | Executive dashboard and map | Point out the `ডেমো তথ্য` label, illustrative locations and baseline counts. |
| 1:25–2:05 | Survey page | Show two seeded survey records, capture source and permission reference; clarify that no aircraft is controlled here. |
| 2:05–3:05 | Analysis page | Select mixed scene, explain simulated boxes and transparent priority score. Show a local preview only if it helps; do not imply upload or AI inference. |
| 3:05–4:10 | Review queue and new incident | Verify the observation and show the audit timeline. |
| 4:10–5:05 | Incident assignment | Assign drainage and waste separately; show department-specific task cards. |
| 5:05–6:20 | Field and supervisor windows | Show acknowledgement, work, submission, rework and approval. Pause capture during account switching if emails should stay private. |
| 6:20–7:15 | Executive report | Show before/after, updated status, workload and CSV export. |
| 7:15–8:00 | Access proof and close | In a separate signed-out window, open a protected URL and show the sign-in requirement. State that all data and analysis are fictional. |

For a shorter recording, use the seeded drainage task to show one field workflow, but explicitly explain that the full multi-department incident requires every assigned department to finish before resolution.

## 6. Stop conditions and recovery

- If the review queue or surveys page shows a migration error, apply the pending migration and rerun provisioning before recording. Do not treat a blank queue as a successful test.
- If sign-in fails, verify Vercel environment variables point to the provisioned Supabase project and redeploy after changes. Check the existing user's actual password; provisioning does not overwrite it.
- If private media is blank, confirm the full provisioning command reached its final reset message and inspect the authenticated media response. The prototype has no public media bucket.
- If a step is clicked out of order, use the executive `ডেমো আবার শুরু করুন` button and confirm the reset. This resets the shared workflow for all connected devices; restart the recording sequence from baseline.
- Mark the demonstration **ready** only when access tests, the multi-role workflow, report/CSV consistency, and both viewport checks pass. A local build alone does not prove that Vercel, Supabase Auth, RLS or private storage are configured correctly.
