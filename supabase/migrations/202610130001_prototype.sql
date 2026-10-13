-- Fictional, shared prototype data. Apply with Supabase CLI before provisioning demo accounts.
create extension if not exists pgcrypto;

create table if not exists public.departments (
  id text primary key, name_bn text not null, description_bn text not null
);
create table if not exists public.teams (
  id text primary key, department_id text not null references public.departments(id), name_bn text not null
);
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  role text not null check (role in ('executive','department_head','supervisor','field_employee')),
  department_id text references public.departments(id),
  team_id text references public.teams(id),
  created_at timestamptz not null default now(),
  check (role = 'executive' or department_id is not null)
);
create table if not exists public.scenarios (
  id text primary key, title_bn text not null, summary_bn text not null,
  kind text not null check (kind in ('image','video')),
  hazard text not null, department_id text not null references public.departments(id),
  area_bn text not null, lat numeric(10,7) not null, lng numeric(10,7) not null,
  score integer not null check (score between 0 and 100), priority text not null,
  media_key text not null, detections jsonb not null default '[]'::jsonb,
  factors jsonb not null default '{}'::jsonb
);
create table if not exists public.observations (
  id uuid primary key default gen_random_uuid(), scenario_id text not null references public.scenarios(id),
  title_bn text not null, department_id text not null references public.departments(id),
  status text not null default 'needs_review' check (status in ('needs_review','verified','dismissed')),
  score integer not null, priority text not null, area_bn text not null,
  lat numeric(10,7) not null, lng numeric(10,7) not null, media_key text,
  created_by uuid references public.profiles(id), created_at timestamptz not null default now()
);
create table if not exists public.detections (
  id uuid primary key default gen_random_uuid(), observation_id uuid not null references public.observations(id) on delete cascade,
  type text not null, label_bn text not null, confidence numeric(4,3) not null, box jsonb not null
);
create table if not exists public.incidents (
  id uuid primary key default gen_random_uuid(), observation_id uuid references public.observations(id),
  code text not null unique, title_bn text not null, description_bn text not null,
  hazard text not null, department_id text not null references public.departments(id),
  status text not null check (status in ('verified','assigned','acknowledged','in_progress','action_submitted','verification_pending','resolved')),
  score integer not null check (score between 0 and 100), priority text not null,
  area_bn text not null, lat numeric(10,7) not null, lng numeric(10,7) not null,
  escalated boolean not null default false, before_key text, after_key text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(), incident_id uuid not null references public.incidents(id) on delete cascade,
  department_id text not null references public.departments(id), team_id text references public.teams(id),
  assignee_id uuid references public.profiles(id),
  status text not null check (status in ('assigned','acknowledged','in_progress','action_submitted','resolved')),
  note text, completion_note text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.events (
  id bigint generated always as identity primary key, incident_id uuid not null references public.incidents(id) on delete cascade,
  task_id uuid references public.tasks(id) on delete set null, actor_id uuid references public.profiles(id),
  kind text not null, note text, created_at timestamptz not null default now()
);
create table if not exists public.notifications (
  id bigint generated always as identity primary key, recipient_id uuid not null references public.profiles(id) on delete cascade,
  incident_id uuid references public.incidents(id) on delete cascade,
  text_bn text not null, read_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.infrastructure (
  id text primary key, type text not null, label_bn text not null, department_id text references public.departments(id),
  geometry jsonb not null
);

create index if not exists incidents_status_idx on public.incidents(status);
create index if not exists incidents_department_idx on public.incidents(department_id);
create index if not exists tasks_incident_idx on public.tasks(incident_id);
create index if not exists tasks_assignee_idx on public.tasks(assignee_id);
create index if not exists events_incident_idx on public.events(incident_id);

insert into public.departments(id,name_bn,description_bn) values
 ('drainage','ড্রেনেজ ও প্রকৌশল','পানি নিষ্কাশন এবং ড্রেন অবকাঠামো'),
 ('waste','বর্জ্য ব্যবস্থাপনা','দৃশ্যমান বর্জ্য অপসারণ'),
 ('health','জনস্বাস্থ্য','সম্ভাব্য পানি জমার স্থান পরিদর্শন'),
 ('footpath','ফুটপাত ও জনপরিসর','পথচারী চলাচল ও প্রবেশপথ'),
 ('inspection','সাধারণ নগর পরিদর্শন','সমন্বিত মাঠপর্যায়ের পর্যবেক্ষণ')
on conflict(id) do update set name_bn=excluded.name_bn,description_bn=excluded.description_bn;
insert into public.teams(id,department_id,name_bn) values
 ('drainage-a','drainage','ড্রেনেজ দল ক'), ('waste-a','waste','বর্জ্য দল ক'),
 ('health-a','health','স্বাস্থ্য দল ক'), ('footpath-a','footpath','ফুটপাত দল ক'),
 ('inspection-a','inspection','পরিদর্শন দল ক')
on conflict(id) do update set name_bn=excluded.name_bn;

-- Definer helpers prevent recursive RLS policies on profiles and tasks.
create or replace function public.my_role() returns text language sql stable security definer set search_path = public as $$
  select role from public.profiles where id=auth.uid() limit 1
$$;
create or replace function public.my_department() returns text language sql stable security definer set search_path = public as $$
  select department_id from public.profiles where id=auth.uid() limit 1
$$;
create or replace function public.my_team() returns text language sql stable security definer set search_path = public as $$
  select team_id from public.profiles where id=auth.uid() limit 1
$$;
create or replace function public.can_see_incident(p_id uuid) returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.incidents i where i.id=p_id and (
      public.my_role()='executive'
      or (public.my_role()='department_head' and (i.department_id=public.my_department() or exists(select 1 from public.tasks t where t.incident_id=i.id and t.department_id=public.my_department())))
      or (public.my_role()='supervisor' and exists(select 1 from public.tasks t where t.incident_id=i.id and t.team_id=public.my_team()))
      or (public.my_role()='field_employee' and exists(select 1 from public.tasks t where t.incident_id=i.id and t.assignee_id=auth.uid()))
    )
  )
$$;
create or replace function public.can_see_observation(p_id uuid) returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.observations o where o.id=p_id and (
    public.my_role()='executive' or
    (public.my_role()='department_head' and o.department_id=public.my_department()) or
    exists(select 1 from public.incidents i where i.observation_id=o.id and public.can_see_incident(i.id))
  ))
$$;

alter table public.departments enable row level security;
alter table public.teams enable row level security;
alter table public.profiles enable row level security;
alter table public.scenarios enable row level security;
alter table public.observations enable row level security;
alter table public.detections enable row level security;
alter table public.incidents enable row level security;
alter table public.tasks enable row level security;
alter table public.events enable row level security;
alter table public.notifications enable row level security;
alter table public.infrastructure enable row level security;

revoke all on all tables in schema public from anon;
grant select on public.departments,public.teams,public.profiles,public.scenarios,public.observations,public.detections,public.incidents,public.tasks,public.events,public.notifications,public.infrastructure to authenticated;
revoke all on function public.my_role(),public.my_department(),public.my_team(),public.can_see_incident(uuid),public.can_see_observation(uuid) from public;
grant execute on function public.my_role(),public.my_department(),public.my_team(),public.can_see_incident(uuid),public.can_see_observation(uuid) to authenticated;

create policy departments_read on public.departments for select to authenticated using (public.my_role() is not null);
create policy teams_read on public.teams for select to authenticated using (public.my_role() is not null);
create policy profiles_read on public.profiles for select to authenticated using (
  id=auth.uid() or public.my_role()='executive' or
  (public.my_role()='department_head' and department_id=public.my_department()) or
  (public.my_role()='supervisor' and team_id=public.my_team())
);
create policy scenarios_read on public.scenarios for select to authenticated using (public.my_role() in ('executive','department_head'));
create policy observations_read on public.observations for select to authenticated using (public.can_see_observation(id));
create policy detections_read on public.detections for select to authenticated using (public.can_see_observation(observation_id));
create policy incidents_read on public.incidents for select to authenticated using (public.can_see_incident(id));
create policy tasks_read on public.tasks for select to authenticated using (
  public.my_role()='executive' or
  (public.my_role()='department_head' and department_id=public.my_department()) or
  (public.my_role()='supervisor' and team_id=public.my_team()) or assignee_id=auth.uid()
);
create policy events_read on public.events for select to authenticated using (public.can_see_incident(incident_id));
create policy notifications_read on public.notifications for select to authenticated using (recipient_id=auth.uid());
create policy infrastructure_read on public.infrastructure for select to authenticated using (
  public.my_role()='executive' or
  (public.my_role() in ('department_head','supervisor') and (department_id=public.my_department() or department_id is null))
);

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('demo-media','demo-media',false,52428800,array['image/svg+xml','image/png','image/jpeg','video/mp4','video/webm'])
on conflict(id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
create policy demo_media_read on storage.objects for select to authenticated using (
  bucket_id='demo-media' and public.my_role() is not null and (
    name like 'scenarios/%' or exists (
      select 1 from public.incidents i where (i.before_key=name or i.after_key=name) and public.can_see_incident(i.id)
    )
  )
);

insert into public.scenarios(id,title_bn,summary_bn,kind,hazard,department_id,area_bn,lat,lng,score,priority,media_key,detections,factors) values
 ('drain','ড্রেনের মুখে বাধা','বাজার সড়কের পাশে পানি নিষ্কাশনের মুখে দৃশ্যমান বর্জ্য।','image','DRAIN_OBSTRUCTION','drainage','মিরপুর বাজার সড়ক',23.8071,90.3679,74,'high','scenarios/drain.svg','[{"type":"DRAIN_OBSTRUCTION","label_bn":"ড্রেনের মুখ","confidence":0.88,"box":[16,47,57,29]},{"type":"WASTE","label_bn":"বর্জ্য","confidence":0.81,"box":[47,54,31,22]}]','{"drain":85,"vector":55,"waste":75,"access":50,"recurrence":65,"evidence":80,"bonus":5}'),
 ('water','জমে থাকা পানি','রাস্তার নিচু অংশে পানি জমার সম্ভাব্য স্থান।','video','STANDING_WATER','health','মিরপুর ১০, দক্ষিণ পথ',23.8067,90.3690,71,'high','scenarios/water.webm','[{"type":"STANDING_WATER","label_bn":"জমে থাকা পানি","confidence":0.84,"box":[19,60,64,23]}]','{"drain":65,"vector":85,"waste":20,"access":55,"recurrence":75,"evidence":70,"bonus":8}'),
 ('waste','দৃশ্যমান বর্জ্য','বাজারসংলগ্ন স্থানে বর্জ্য জমার নমুনা।','image','WASTE','waste','বাজার গলি',23.8077,90.3687,51,'moderate','scenarios/waste.svg','[{"type":"WASTE","label_bn":"বর্জ্য","confidence":0.91,"box":[26,50,54,33]}]','{"drain":30,"vector":50,"waste":90,"access":35,"recurrence":60,"evidence":85,"bonus":0}'),
 ('footpath','ফুটপাতের বাধা','পথচারী চলাচলের পথে অস্থায়ী বাধার নমুনা।','image','FOOTPATH_OBSTRUCTION','footpath','পাইলট এলাকার পূর্ব পথ',23.8069,90.3701,37,'low','scenarios/footpath.svg','[{"type":"FOOTPATH_OBSTRUCTION","label_bn":"চলাচলের বাধা","confidence":0.86,"box":[41,32,34,53]}]','{"drain":15,"vector":10,"waste":40,"access":92,"recurrence":65,"evidence":80,"bonus":0}'),
 ('mixed','বাজার এলাকায় একাধিক সমস্যা','ড্রেন, পানি ও বর্জ্য একই স্থানে দেখানোর ধারণামূলক দৃশ্য।','video','DRAIN_OBSTRUCTION','drainage','মিরপুর বাজার সড়ক',23.8073,90.3683,90,'critical','scenarios/mixed.webm','[{"type":"DRAIN_OBSTRUCTION","label_bn":"ড্রেনের মুখ","confidence":0.89,"box":[14,45,35,30]},{"type":"STANDING_WATER","label_bn":"পানি","confidence":0.86,"box":[31,67,54,20]},{"type":"WASTE","label_bn":"বর্জ্য","confidence":0.82,"box":[59,43,24,25]}]','{"drain":80,"vector":85,"waste":70,"access":75,"recurrence":90,"evidence":80,"bonus":10}'),
 ('clean','পরিচ্ছন্ন স্থান','সমস্যা না পাওয়ার তুলনামূলক নমুনা।','image','STANDING_WATER','inspection','পাইলট এলাকার উত্তর পথ',23.8081,90.3697,9,'low','scenarios/clean.svg','[]','{"drain":5,"vector":5,"waste":0,"access":10,"recurrence":5,"evidence":85,"bonus":0}')
on conflict(id) do update set title_bn=excluded.title_bn,summary_bn=excluded.summary_bn,score=excluded.score,priority=excluded.priority,detections=excluded.detections,factors=excluded.factors;

insert into public.infrastructure(id,type,label_bn,department_id,geometry) values
 ('drain-a','drain','বাজার সড়ক ড্রেন','drainage','{"type":"LineString","coordinates":[[90.3675,23.8075],[90.3688,23.8068]]}'),
 ('footpath-a','footpath','পূর্ব ফুটপাত','footpath','{"type":"LineString","coordinates":[[90.3692,23.8079],[90.3704,23.8066]]}'),
 ('pilot-cell','pilot_area','ধারণামূলক পাইলট এলাকা',null,'{"type":"Polygon","coordinates":[[[90.3672,23.8063],[90.3706,23.8063],[90.3706,23.8084],[90.3672,23.8084],[90.3672,23.8063]]]}')
on conflict(id) do update set label_bn=excluded.label_bn,geometry=excluded.geometry;

create or replace function public.seed_demo() returns void language plpgsql security definer set search_path=public as $$
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
        'ডেমো দায়িত্ব: স্থানটি পরিদর্শন করুন।',case when v_status in ('verification_pending','resolved') then 'নমুনা কাজ সম্পন্ন।' else null end,now()-(n||' days')::interval);
    end if;
    insert into public.events(incident_id,kind,note,created_at) values(v_incident,'seeded','ডেমো ঘটনার নমুনা',now()-(n||' days')::interval);
  end loop;
end $$;
revoke all on function public.seed_demo() from public,anon,authenticated;

create or replace function public.reset_demo() returns void language plpgsql security definer set search_path=public as $$
begin
  if coalesce(auth.role(),'')<>'service_role' and coalesce(public.my_role(),'')<>'executive' then raise exception 'অনুমতি নেই'; end if;
  truncate table public.notifications, public.events, public.tasks,
    public.detections, public.incidents, public.observations;
  perform public.seed_demo();
end $$;
revoke all on function public.reset_demo() from public,anon;
grant execute on function public.reset_demo() to authenticated,service_role;

create or replace function public.perform_demo_action(p_action text,p_target uuid default null,p_payload jsonb default '{}'::jsonb)
returns uuid language plpgsql security definer set search_path=public as $$
declare
  v_role text:=public.my_role(); v_dept text:=public.my_department(); v_team text:=public.my_team();
  v_ob public.observations%rowtype; v_inc public.incidents%rowtype; v_task public.tasks%rowtype;
  v_s public.scenarios%rowtype; v_assignee public.profiles%rowtype;
  v_id uuid; v_department text; v_team_id text; v_key text; v_note text:=left(coalesce(p_payload->>'note',''),1000);
begin
  if auth.uid() is null or v_role is null then raise exception 'অফিসিয়াল অ্যাকাউন্ট প্রয়োজন'; end if;
  if p_action='create_observation' then
    if v_role not in ('executive','department_head') then raise exception 'অনুমতি নেই'; end if;
    select * into v_s from public.scenarios where id=p_payload->>'scenario_id';
    if not found then raise exception 'ডেমো দৃশ্য পাওয়া যায়নি'; end if;
    if v_role<>'executive' and v_s.department_id<>v_dept then raise exception 'এই বিভাগের অনুমতি নেই'; end if;
    insert into public.observations(scenario_id,title_bn,department_id,score,priority,area_bn,lat,lng,media_key,created_by)
    values(v_s.id,v_s.title_bn,v_s.department_id,v_s.score,v_s.priority,v_s.area_bn,v_s.lat,v_s.lng,v_s.media_key,auth.uid()) returning id into v_id;
    insert into public.detections(observation_id,type,label_bn,confidence,box)
    select v_id,d->>'type',d->>'label_bn',(d->>'confidence')::numeric,d->'box' from jsonb_array_elements(v_s.detections) d;
    return v_id;
  elsif p_action in ('verify_observation','dismiss_observation') then
    select * into v_ob from public.observations where id=p_target for update;
    if not found or v_ob.status<>'needs_review' then raise exception 'পর্যবেক্ষণটি যাচাইয়ের অপেক্ষায় নেই'; end if;
    if v_role not in ('executive','department_head') or (v_role<>'executive' and v_ob.department_id<>v_dept) then raise exception 'অনুমতি নেই'; end if;
    if p_action='dismiss_observation' then
      update public.observations set status='dismissed' where id=p_target;
      return p_target;
    end if;
    if v_ob.scenario_id='clean' then raise exception 'সমস্যা পাওয়া যায়নি; পর্যবেক্ষণটি বাতিল করুন'; end if;
    update public.observations set status='verified' where id=p_target;
    select * into v_s from public.scenarios where id=v_ob.scenario_id;
    insert into public.incidents(observation_id,code,title_bn,description_bn,hazard,department_id,status,score,priority,area_bn,lat,lng,before_key)
    values(v_ob.id,'NS-'||upper(substr(replace(v_ob.id::text,'-',''),1,6)),v_ob.title_bn,v_s.summary_bn,v_s.hazard,v_ob.department_id,'verified',v_ob.score,v_ob.priority,v_ob.area_bn,v_ob.lat,v_ob.lng,v_ob.media_key)
    returning id into v_id;
    insert into public.events(incident_id,actor_id,kind,note) values(v_id,auth.uid(),'verified_observation',v_note);
    return v_id;
  elsif p_action='assign_task' then
    select * into v_inc from public.incidents where id=p_target for update;
    if not found or v_inc.status='resolved' or not public.can_see_incident(p_target) then raise exception 'ঘটনায় দায়িত্ব দেওয়া যাবে না'; end if;
    v_department:=p_payload->>'department_id'; v_team_id:=nullif(p_payload->>'team_id','');
    if v_role not in ('executive','department_head','supervisor') or (v_role<>'executive' and v_department<>v_dept) or (v_role='supervisor' and v_team_id<>v_team) then raise exception 'অনুমতি নেই'; end if;
    select * into v_assignee from public.profiles where id=(p_payload->>'assignee_id')::uuid and role='field_employee' and department_id=v_department;
    if not found or (v_team_id is not null and v_assignee.team_id<>v_team_id) then raise exception 'মাঠকর্মী ও দল মিলছে না'; end if;
    if v_team_id is null then v_team_id:=v_assignee.team_id; end if;
    insert into public.tasks(incident_id,department_id,team_id,assignee_id,status,note) values(p_target,v_department,v_team_id,v_assignee.id,'assigned',v_note) returning id into v_id;
    update public.incidents set status='assigned',updated_at=now() where id=p_target;
    insert into public.events(incident_id,task_id,actor_id,kind,note) values(p_target,v_id,auth.uid(),'assigned',v_note);
    insert into public.notifications(recipient_id,incident_id,text_bn) values(v_assignee.id,p_target,'নতুন ডেমো দায়িত্ব দেওয়া হয়েছে');
    return v_id;
  elsif p_action in ('acknowledge_task','start_task','submit_task','approve_task','rework_task','reopen_task') then
    select * into v_task from public.tasks where id=p_target for update;
    if not found then raise exception 'দায়িত্ব পাওয়া যায়নি'; end if;
    select * into v_inc from public.incidents where id=v_task.incident_id for update;
    if p_action in ('acknowledge_task','start_task','submit_task') then
      if v_role<>'field_employee' or v_task.assignee_id<>auth.uid() then raise exception 'এই দায়িত্ব আপনার নয়'; end if;
      if p_action='acknowledge_task' and v_task.status='assigned' then
        update public.tasks set status='acknowledged',updated_at=now() where id=p_target;
        update public.incidents set status='acknowledged',updated_at=now() where id=v_task.incident_id;
      elsif p_action='start_task' and v_task.status='acknowledged' then
        update public.tasks set status='in_progress',updated_at=now() where id=p_target;
        update public.incidents set status='in_progress',updated_at=now() where id=v_task.incident_id;
      elsif p_action='submit_task' and v_task.status='in_progress' then
        v_key:=p_payload->>'media_key';
        if v_key not in ('scenarios/clean.svg','scenarios/drain.svg','scenarios/water.svg','scenarios/waste.svg','scenarios/footpath.svg','scenarios/mixed.svg') then raise exception 'ডেমো পরবর্তী প্রমাণ নির্বাচন করুন'; end if;
        if length(trim(v_note))<8 then raise exception 'সম্পন্ন কাজের বিবরণ লিখুন'; end if;
        update public.tasks set status='action_submitted',completion_note=v_note,updated_at=now() where id=p_target;
        update public.incidents set status='verification_pending',after_key=v_key,updated_at=now() where id=v_task.incident_id;
      else raise exception 'এই ধাপে কাজটি করা যাবে না'; end if;
    else
      if v_role not in ('executive','department_head','supervisor') or
        (v_role='department_head' and v_task.department_id<>v_dept) or
        (v_role='supervisor' and v_task.team_id<>v_team) then raise exception 'যাচাইয়ের অনুমতি নেই'; end if;
      if p_action in ('approve_task','rework_task') and v_task.status='action_submitted' then
        update public.tasks set status=case when p_action='approve_task' then 'resolved' else 'in_progress' end,updated_at=now() where id=p_target;
        update public.incidents set status=case when p_action='rework_task' then 'in_progress'
          when not exists(select 1 from public.tasks where incident_id=v_task.incident_id and status<>'resolved') then 'resolved'
          else 'in_progress' end,updated_at=now() where id=v_task.incident_id;
      elsif p_action='reopen_task' and v_task.status='resolved' and v_inc.status='resolved' then
        update public.tasks set status='assigned',updated_at=now() where id=p_target;
        update public.incidents set status='assigned',after_key=null,updated_at=now() where id=v_task.incident_id;
      else raise exception 'এই ধাপে যাচাই করা যাবে না'; end if;
    end if;
    insert into public.events(incident_id,task_id,actor_id,kind,note) values(v_task.incident_id,p_target,auth.uid(),p_action,v_note);
    return p_target;
  elsif p_action='toggle_escalation' then
    select * into v_inc from public.incidents where id=p_target for update;
    if not found or not public.can_see_incident(p_target) or v_role not in ('executive','department_head','supervisor') then raise exception 'অনুমতি নেই'; end if;
    update public.incidents set escalated=not escalated,updated_at=now() where id=p_target;
    insert into public.events(incident_id,actor_id,kind,note) values(p_target,auth.uid(),'escalation_changed',v_note);
    return p_target;
  end if;
  raise exception 'অজানা পদক্ষেপ';
end $$;
revoke all on function public.perform_demo_action(text,uuid,jsonb) from public,anon;
grant execute on function public.perform_demo_action(text,uuid,jsonb) to authenticated;

select public.seed_demo();


