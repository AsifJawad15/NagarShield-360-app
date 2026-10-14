-- Refresh only curated demo copy. Keep user-entered notes and workflow state intact.
update public.departments set description_bn = case id
  when 'drainage' then 'ড্রেন পরিষ্কার ও পানি যাওয়ার পথ ঠিক রাখা'
  when 'waste' then 'জমে থাকা বর্জ্য সরানো'
  when 'health' then 'পানি জমে থাকা জায়গা দেখে প্রয়োজনীয় ব্যবস্থা নেওয়া'
  when 'footpath' then 'ফুটপাত ও চলার পথ ব্যবহারযোগ্য রাখা'
  when 'inspection' then 'একাধিক বিভাগের কাজের জন্য এলাকা পরিদর্শন'
  else description_bn end
where id in ('drainage','waste','health','footpath','inspection');

update public.scenarios set
  title_bn = case id when 'waste' then 'জমে থাকা বর্জ্য' else title_bn end,
  summary_bn = case id
    when 'drain' then 'বাজার সড়কের ড্রেনের মুখে বর্জ্য জমে আছে।'
    when 'water' then 'রাস্তার নিচু অংশে পানি জমে আছে।'
    when 'waste' then 'বাজারের পাশের গলিতে বর্জ্য জমে আছে।'
    when 'footpath' then 'ফুটপাত দিয়ে হাঁটার পথে বাধা আছে।'
    when 'mixed' then 'একই জায়গায় ড্রেন বন্ধ, পানি জমা ও বর্জ্য—তিনটি সমস্যার নমুনা।'
    when 'clean' then 'এখানে উল্লেখযোগ্য কোনো সমস্যা দেখা যাচ্ছে না।'
    else summary_bn end
where id in ('drain','water','waste','footpath','mixed','clean');

update public.infrastructure set label_bn='নমুনা পাইলট এলাকা'
where id='pilot-cell' and label_bn='ধারণামূলক পাইলট এলাকা';

-- Existing demo rows should read naturally without replacing presentation work.
update public.incidents i set title_bn=s.title_bn, description_bn=s.summary_bn
from public.scenarios s
where i.code ~ '^NS-[0-9]{3}$' and i.before_key=s.media_key
  and i.description_bn in (
    'বাজার সড়কের পাশে পানি নিষ্কাশনের মুখে দৃশ্যমান বর্জ্য।',
    'রাস্তার নিচু অংশে পানি জমার সম্ভাব্য স্থান।',
    'বাজারসংলগ্ন স্থানে বর্জ্য জমার নমুনা।',
    'পথচারী চলাচলের পথে অস্থায়ী বাধার নমুনা।',
    'ড্রেন, পানি ও বর্জ্য একই স্থানে দেখানোর ধারণামূলক দৃশ্য।',
    'সমস্যা না পাওয়ার তুলনামূলক নমুনা।'
  );
update public.observations o set title_bn=s.title_bn, description_bn=s.summary_bn
from public.scenarios s
where o.scenario_id=s.id and o.description_bn in (
  'বাজার সড়কের পাশে পানি নিষ্কাশনের মুখে দৃশ্যমান বর্জ্য।',
  'রাস্তার নিচু অংশে পানি জমার সম্ভাব্য স্থান।',
  'বাজারসংলগ্ন স্থানে বর্জ্য জমার নমুনা।',
  'পথচারী চলাচলের পথে অস্থায়ী বাধার নমুনা।',
  'ড্রেন, পানি ও বর্জ্য একই স্থানে দেখানোর ধারণামূলক দৃশ্য।',
  'সমস্যা না পাওয়ার তুলনামূলক নমুনা।'
);
update public.tasks set note='জায়গাটি দেখে প্রয়োজনীয় কাজ করুন।'
where note='ডেমো দায়িত্ব: স্থানটি পরিদর্শন করুন।';
update public.tasks set completion_note='নমুনা কাজ শেষ হয়েছে।'
where completion_note='নমুনা কাজ সম্পন্ন।';
update public.events set note='নমুনা ঘটনা তৈরি হয়েছে।'
where kind='seeded' and note='ডেমো ঘটনার নমুনা';
update public.notifications set text_bn='আপনাকে নতুন একটি কাজ দেওয়া হয়েছে।'
where text_bn='নতুন ডেমো দায়িত্ব দেওয়া হয়েছে';

create or replace function public.seed_demo() returns void
language plpgsql security definer set search_path=public as $$
declare
  n integer;
  v_s public.scenarios%rowtype;
  v_incident uuid;
  v_employee uuid;
  v_dept text;
  v_status text;
begin
  for n in 1..18 loop
    select * into v_s from public.scenarios where id=(array['mixed','drain','water','waste','footpath','drain'])[1+((n-1)%6)];
    v_dept:=v_s.department_id;
    v_status:=(array['verified','assigned','in_progress','verification_pending','resolved','verified'])[1+((n-1)%6)];
    v_incident:=('00000000-0000-4000-8000-' || lpad(n::text,12,'0'))::uuid;
    insert into public.incidents(id,code,title_bn,description_bn,hazard,department_id,status,score,priority,area_bn,lat,lng,escalated,before_key,after_key,created_at,updated_at)
    values(v_incident,'NS-'||lpad(n::text,3,'0'),v_s.title_bn,v_s.summary_bn,v_s.hazard,v_dept,v_status,v_s.score,v_s.priority,v_s.area_bn,
      v_s.lat+((n/6)*0.00015),v_s.lng+((n/6)*0.00012),n in (1,7),v_s.media_key,
      case when v_status='resolved' then 'scenarios/clean.svg' else null end,now()-(n||' days')::interval,now()-(n||' days')::interval);
    select id into v_employee from public.profiles where role='field_employee' and department_id=v_dept order by id limit 1;
    if v_status<>'verified' and v_employee is not null then
      insert into public.tasks(incident_id,department_id,team_id,assignee_id,status,note,completion_note,created_at)
      values(v_incident,v_dept,(select team_id from public.profiles where id=v_employee),v_employee,
        case when v_status='verification_pending' then 'action_submitted' when v_status='resolved' then 'resolved' else v_status end,
        'জায়গাটি দেখে প্রয়োজনীয় কাজ করুন।',case when v_status in ('verification_pending','resolved') then 'নমুনা কাজ শেষ হয়েছে।' else null end,now()-(n||' days')::interval);
    end if;
    insert into public.events(incident_id,kind,note,created_at) values(v_incident,'seeded','নমুনা ঘটনা তৈরি হয়েছে।',now()-(n||' days')::interval);
  end loop;
end $$;
revoke all on function public.seed_demo() from public,anon,authenticated;

-- The survey reset function uses the same copy as the initial seed.
create or replace function public.seed_survey_demo() returns void
language plpgsql security definer set search_path=public as $$
begin
  insert into public.survey_missions(id,kind,department_id,area_bn,site_label,capture_source,captured_at,flight_permission_ref,notes) values
    ('00000000-0000-4000-9000-000000000001','drone','drainage','মিরপুর বাজার সড়ক','বাজার সড়ক ড্রেন','imported',now()-interval '2 days','শুধু নমুনা; বাস্তব অনুমতি নয়','ডেমোর জন্য তৈরি ভিডিও; ড্রেনের মুখ বন্ধ এবং পানি জমে থাকার একটি নমুনা।'),
    ('00000000-0000-4000-9000-000000000002','gapscan','footpath','পাইলট এলাকার পূর্ব পথ','পূর্ব পথের সরু অংশ','imported',now()-interval '1 day',null,'ডেমোর জন্য তৈরি ছবি; পথচারীদের চলার জায়গার একটি নমুনা।');
  insert into public.observations(id,scenario_id,title_bn,description_bn,categories,department_id,status,score,priority,area_bn,lat,lng,media_key,source,report_code,mission_id,created_at)
  select '00000000-0000-4000-a000-000000000001',id,title_bn,summary_bn,array[hazard],department_id,'needs_review',score,priority,area_bn,lat,lng,media_key,'drone','SUR-001','00000000-0000-4000-9000-000000000001',now()-interval '2 days'
  from public.scenarios where id='mixed';
  insert into public.observations(id,scenario_id,title_bn,description_bn,categories,department_id,status,score,priority,area_bn,lat,lng,media_key,source,report_code,mission_id,created_at)
  select '00000000-0000-4000-a000-000000000002',id,title_bn,summary_bn,array[hazard],department_id,'needs_review',score,priority,area_bn,lat,lng,media_key,'gapscan','SUR-002','00000000-0000-4000-9000-000000000002',now()-interval '1 day'
  from public.scenarios where id='footpath';
end $$;
revoke all on function public.seed_survey_demo() from public,anon,authenticated;

update public.survey_missions set
  capture_source='imported',
  flight_permission_ref=case when kind='drone' then 'শুধু নমুনা; বাস্তব অনুমতি নয়' else flight_permission_ref end,
  notes=case kind
    when 'drone' then 'ড্রেনের মুখ বন্ধ এবং পানি জমে থাকার একটি নমুনা।'
    else 'পথচারীদের চলার জায়গার একটি নমুনা।' end
where id in ('00000000-0000-4000-9000-000000000001','00000000-0000-4000-9000-000000000002');
