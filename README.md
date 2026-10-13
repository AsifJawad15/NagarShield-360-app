# Nagar Shield 360 — অফিসিয়াল ডেমো

Next.js ভিত্তিক বাংলাভাষী প্রোটোটাইপ। `/` হলো একমাত্র উন্মুক্ত পাতা। সাইন ইন ছাড়া ড্যাশবোর্ড, মানচিত্র, ঘটনা, মিডিয়া ও প্রতিবেদন দেখা যায় না। Supabase Auth, Postgres RLS এবং প্রাইভেট স্টোরেজ ব্যবহার করে ডেমো অ্যাকাউন্টগুলোর তথ্য একসঙ্গে রাখা হয়। Flutter অ্যাপ এই রিপোজিটরির অংশ নয়।

## চালু করার আগে

1. একটি **নতুন Supabase project** তৈরি করুন। Auth → Providers → Email-এ **Allow new users to sign up** বন্ধ করুন। Anonymous sign-ins-ও বন্ধ রাখুন।
2. `supabase/migrations/202610130001_prototype.sql` এবং তারপর `supabase/migrations/202610130002_reset_hotfix.sql` Supabase SQL Editor-এ চালান। প্রথমটি টেবিল, RLS, সার্ভার-নিয়ন্ত্রিত workflow, প্রাইভেট `demo-media` bucket এবং কাল্পনিক seed তৈরি করে; দ্বিতীয়টি reset function আপডেট করে। **প্রথম migration আগে চালিয়ে থাকলে শুধু দ্বিতীয়টি চালান।** প্রজেক্টে আগে থেকে একই নামের টেবিল বা policy থাকলে নতুন প্রজেক্ট ব্যবহার করুন।
3. `.env.example` কপি করে `.env.local` বানান। `NEXT_PUBLIC_SUPABASE_URL` ও `NEXT_PUBLIC_SUPABASE_ANON_KEY` Supabase project থেকে নিন। `SUPABASE_SERVICE_ROLE_KEY` কেবল স্থানীয় provision script-এর জন্য; এটি **Vercel-এ সেট করবেন না**, `NEXT_PUBLIC_` নাম দেবেন না এবং Git-এ রাখবেন না।
4. `demo-accounts.example.json` কপি করে `demo-accounts.local.json` বানান। নিজের নিয়ন্ত্রিত ডেমো ইমেইল ও প্রতিটি অ্যাকাউন্টের আলাদা, শক্ত পাসওয়ার্ড লিখুন। `example.test` ঠিকানাগুলো শুধু placeholder। এই স্থানীয় ফাইল Git-এ যাবে না।
5. `npm install`, তারপর `npm run demo:provision` চালান। স্ক্রিপ্ট প্রশাসনিক Auth API দিয়ে dummy account তৈরি/লিঙ্ক করে, ছয়টি ধারণামূলক দৃশ্য ও দুটি ছোট ভিডিও প্রাইভেট bucket-এ আপলোড করে এবং ১৮টি কাল্পনিক ঘটনা ও সংশ্লিষ্ট কাজ পুনরায় seed করে। আগে থেকে থাকা অ্যাকাউন্টের পাসওয়ার্ড স্ক্রিপ্ট পরিবর্তন করে না। Provision করলে বর্তমান ডেমো workflow মুছে নতুন করে শুরু হয়।
6. `npm run dev` চালিয়ে `http://localhost:3000` খুলুন। যাচাই: `npm run typecheck`, `npm run test:migration` এবং `npm run build`।

ডেমোর জন্য executive, drainage head, drainage supervisor এবং পাঁচ বিভাগের field employee টেমপ্লেটে আছে। চাইলে অন্য বিভাগে আরও head/supervisor যোগ করা যায়। কোনো পাসওয়ার্ড ওয়েবসাইটে দেখানো বা কোডে রাখা হয়নি।

## Vercel

এই Next.js রিপোজিটরি Vercel-এ যুক্ত করুন। শুধু `NEXT_PUBLIC_SUPABASE_URL` ও `NEXT_PUBLIC_SUPABASE_ANON_KEY` environment variable দিন। Supabase Auth redirect/site URL-এ deployment domain দিন। **Service role key ও account JSON Vercel-এ দেবেন না।** `next build` server runtime প্রয়োজন; static export করবেন না। ডেমো অ্যাকাউন্ট provision স্থানীয় প্রশাসনিক কম্পিউটার থেকে করা হয়।

## প্রদর্শনের পথ

1. নির্বাহী অ্যাকাউন্ট → সারসংক্ষেপ, মানচিত্র ও ঘটনা দেখুন।
2. মিডিয়া বিশ্লেষণে `mixed` দৃশ্য নির্বাচন করুন। স্কোর ও শনাক্তকরণ **সিমুলেটেড**। পর্যবেক্ষণ যাচাইয়ের তালিকায় পাঠান।
3. ঘটনা কেন্দ্রে পর্যবেক্ষণ যাচাই করে ঘটনা তৈরি করুন। একই ঘটনায় drainage ও waste বিভাগে আলাদা দায়িত্ব দিন।
4. মাঠকর্মীর অ্যাকাউন্টে সাইন ইন করে দায়িত্ব গ্রহণ, কাজ শুরু এবং বিবরণসহ পরের ডেমো দৃশ্য জমা দিন।
5. তত্ত্বাবধায়ক বা প্রধান ফল অনুমোদন বা পুনরায় কাজের জন্য পাঠান। নির্বাহী প্রতিবেদন ও সময়রেখায় পরিবর্তন দেখুন।
6. নির্বাহী অ্যাকাউন্টের “ডেমো পুনরায় শুরু” বোতাম দিয়ে শেয়ার করা গল্পটি রিসেট করা যায়।

নিজের ছবি বা ভিডিও নির্বাচনের UI কেবল এই ডিভাইসে প্রিভিউ দেখায়; ফাইল আপলোড বা বিশ্লেষণ করে না। দুটি ছোট ভিডিও দৃশ্যও সম্পূর্ণ কৃত্রিম; বাস্তব ভিডিও বিশ্লেষণ নেই। স্কোর, স্থানাঙ্ক ও ১৮টি ঘটনা কাল্পনিক। কোনো রোগ শনাক্তকরণ, বন্যার পূর্বাভাস, পৌর সংযোগ, ইমেইল বা push notification চালু নেই।

## নিরাপত্তা ও যাচাই

- Next proxy ও server data layer প্রতিটি অভ্যন্তরীণ পাতা যাচাই করে। Workflow পরিবর্তন শুধু `perform_demo_action` Postgres function-এ হয়; সরাসরি client write grant নেই। RLS একই তথ্যসীমা বজায় রাখে।
- Executive সব ডেমো তথ্য দেখেন; head নিজ বিভাগের; supervisor নিজের দলের নির্ধারিত ঘটনা ও কাজ; field employee নিজের কাজ ও সংশ্লিষ্ট ঘটনা দেখেন। নতুন পর্যবেক্ষণ যাচাই executive ও head করেন। প্রাইভেট মিডিয়া authenticated route এবং storage policy দিয়ে দেওয়া হয়।
- Incognito-তে `/dashboard`, `/incidents`, `/api/reports/export`, `/api/media/scenarios/drain.svg` পরীক্ষা করুন। কোনো অভ্যন্তরীণ তথ্য ফেরত আসা উচিত নয়। ভিন্ন role দিয়ে অন্য ঘটনার UUID বা task UUID পাঠিয়ে permission পরীক্ষা করুন।
- দুইটি browser/device-এ আলাদা account খুলে assignment ও status পরিবর্তন দেখুন। Invalid transition (যেমন গ্রহণ না করে কাজ শুরু) database প্রত্যাখ্যান করবে।
- প্রকৃত Supabase project/key ছাড়া build ও public landing যাচাই করা যায়; shared-state এবং RLS end-to-end পরীক্ষা করতে project setup প্রয়োজন।
- `npm run test:layout` চালাতে আগে `npm run dev` বা `npm run start` দিয়ে স্থানীয় সাইট চালু রাখুন। স্ক্রিপ্ট স্থানীয় Chrome দিয়ে ৩৯০ পিক্সেল mobile viewport ও sign-in অংশের ছবি যাচাই করে।
