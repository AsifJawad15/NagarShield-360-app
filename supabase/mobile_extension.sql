-- Apply to the same Supabase project as NagarShield-360 after its 202610130002 migration.
-- Kept in the Flutter app repository at the user's requested location.
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check check
  (role in ('executive','department_head','supervisor','field_employee','survey_operator'));
alter table public.observations alter column scenario_id drop not null;
alter table public.observations add column source text not null default 'scenario'
  check (source in ('scenario','public','drone','gapscan'));
alter table public.observations add column reporter_uid uuid references auth.users(id);
alter table public.observations add column report_code text unique;
alter table public.observations add column description_bn text;
alter table public.observations add column categories text[] not null default '{}';
alter table public.observations add column location_precision text not null default 'approximate'
  check (location_precision in ('exact','approximate'));
alter table public.observations add column client_request_id uuid unique;
create index observations_reporter_idx on public.observations(reporter_uid);

create table public.survey_missions (
  id uuid primary key default gen_random_uuid(),
  operator_id uuid not null references public.profiles(id),
  kind text not null check (kind in ('drone','gapscan')),
  area_bn text not null,
  site_label text,
  capture_source text not null check (capture_source in ('drone','phone','360','imported')),
  flight_permission_ref text,
  notes text,
  captured_at timestamptz not null,
  created_at timestamptz not null default now()
);
alter table public.observations add column mission_id uuid references public.survey_missions(id);
create index observations_mission_idx on public.observations(mission_id);

create table public.media_assets (
  id uuid primary key default gen_random_uuid(),
  observation_id uuid references public.observations(id) on delete cascade,
  incident_id uuid references public.incidents(id) on delete cascade,
  task_id uuid references public.tasks(id) on delete cascade,
  owner_uid uuid not null references auth.users(id),
  storage_key text not null unique,
  redacted_key text,
  mime_type text not null,
  stage text not null check (stage in ('report','survey','before','after')),
  created_at timestamptz not null default now(),
  check (observation_id is not null or incident_id is not null or task_id is not null)
);
create table public.media_annotations (
  id uuid primary key default gen_random_uuid(),
  media_id uuid not null references public.media_assets(id) on delete cascade,
  label text not null,
  shape text not null check (shape in ('box','polygon')),
  points jsonb not null,
  from_ms integer,
  to_ms integer,
  source text not null check (source in ('manual','simulated')),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  check (from_ms is null or from_ms >= 0),
  check (to_ms is null or (from_ms is not null and to_ms > from_ms))
);
create index media_assets_observation_idx on public.media_assets(observation_id);
create index media_assets_task_idx on public.media_assets(task_id);
create index media_annotations_media_idx on public.media_annotations(media_id);

alter table public.survey_missions enable row level security;
alter table public.media_assets enable row level security;
alter table public.media_annotations enable row level security;
grant select on public.survey_missions,public.media_assets,public.media_annotations to authenticated;
create policy missions_read on public.survey_missions for select to authenticated using (
  operator_id=auth.uid() or public.my_role()='executive' or
  (public.my_role()='department_head' and public.my_department()='inspection'));
create policy media_assets_read on public.media_assets for select to authenticated using (
  owner_uid=auth.uid() or
  (observation_id is not null and public.can_see_observation(observation_id)) or
  (incident_id is not null and public.can_see_incident(incident_id)) or
  (task_id is not null and exists(select 1 from public.tasks t
    where t.id=task_id and public.can_see_incident(t.incident_id))));
create policy media_annotations_read on public.media_annotations for select to authenticated using (
  exists(select 1 from public.media_assets m where m.id=media_id));
create policy public_observations_read on public.observations for select to authenticated using (
  source='public' and reporter_uid=auth.uid());
create policy operator_observations_read on public.observations for select to authenticated using (
  public.my_role()='survey_operator' and created_by=auth.uid());
create policy scenarios_survey_read on public.scenarios for select to authenticated using (
  public.my_role()='survey_operator');

create or replace function public.can_see_observation(p_id uuid) returns boolean
language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.observations o where o.id=p_id and (
    public.my_role()='executive' or
    (public.my_role()='department_head' and o.department_id=public.my_department()) or
    (public.my_role()='survey_operator' and o.created_by=auth.uid()) or
    exists(select 1 from public.incidents i where i.observation_id=o.id and public.can_see_incident(i.id))))
$$;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('evidence','evidence',false,52428800,array['image/png','image/jpeg','image/webp','video/mp4'])
on conflict(id) do update set public=false,file_size_limit=excluded.file_size_limit,
  allowed_mime_types=excluded.allowed_mime_types;
create policy evidence_upload on storage.objects for insert to authenticated with check (
  bucket_id='evidence' and (storage.foldername(name))[1] in ('public','survey','task') and
  (storage.foldername(name))[2]=auth.uid()::text and
  lower(storage.extension(name)) in ('jpg','jpeg','png','webp','mp4'));
create policy evidence_update on storage.objects for update to authenticated using (
  bucket_id='evidence' and (storage.foldername(name))[2]=auth.uid()::text
) with check (
  bucket_id='evidence' and (storage.foldername(name))[1] in ('public','survey','task') and
  (storage.foldername(name))[2]=auth.uid()::text and
  lower(storage.extension(name)) in ('jpg','jpeg','png','webp','mp4'));
create policy evidence_read on storage.objects for select to authenticated using (
  bucket_id='evidence' and (
    (storage.foldername(name))[2]=auth.uid()::text or
    exists(select 1 from public.media_assets m where
      (m.storage_key=name or m.redacted_key=name) and
      ((m.observation_id is not null and public.can_see_observation(m.observation_id)) or
       (m.incident_id is not null and public.can_see_incident(m.incident_id)) or
       (m.task_id is not null and exists(select 1 from public.tasks t
         where t.id=m.task_id and public.can_see_incident(t.incident_id)))))));

create or replace function public.submit_public_report(
  p_request_id uuid,p_title text,p_description text,p_categories text[],
  p_area text,p_lat numeric,p_lng numeric,p_precision text,
  p_media_key text default null,p_mime_type text default null
) returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid; v_category text; v_department text;
begin
  if auth.uid() is null or public.my_role() is not null then
    raise exception 'Public session required'; end if;
  select id into v_id from public.observations where client_request_id=p_request_id;
  if found then
    if (select reporter_uid from public.observations where id=v_id)<>auth.uid()
      then raise exception 'Request ID in use'; end if;
    return v_id;
  end if;
  if p_request_id is null or length(trim(coalesce(p_title,'')))<4 or length(p_title)>120
    or length(coalesce(p_description,''))>2000
    or coalesce(array_length(p_categories,1),0) not between 1 and 6
    or p_lat is null or p_lat not between -90 and 90
    or p_lng is null or p_lng not between -180 and 180
    or length(trim(coalesce(p_area,'')))<3
    or p_precision not in ('exact','approximate') then raise exception 'Invalid report'; end if;
  if p_media_key is null and length(trim(coalesce(p_description,'')))<12
    then raise exception 'Add evidence or explain the problem'; end if;
  if p_media_key is not null and (
    p_media_key not like 'public/'||auth.uid()::text||'/%' or
    p_mime_type not in ('image/jpeg','image/png','image/webp') or
    not exists(select 1 from storage.objects where bucket_id='evidence' and name=p_media_key)
  ) then raise exception 'Invalid report media'; end if;
  if exists(select 1 from unnest(p_categories) c where c is null or c not in
    ('DRAIN_OBSTRUCTION','STANDING_WATER','WASTE','FOOTPATH_OBSTRUCTION','ACCESS_OBSTRUCTION','WATER_CONTAINER'))
    then raise exception 'Invalid category'; end if;
  v_category:=p_categories[1];
  v_department:=case v_category when 'DRAIN_OBSTRUCTION' then 'drainage'
    when 'STANDING_WATER' then 'health' when 'WATER_CONTAINER' then 'health'
    when 'WASTE' then 'waste' else 'footpath' end;
  insert into public.observations(scenario_id,source,reporter_uid,client_request_id,report_code,
    title_bn,description_bn,categories,department_id,score,priority,area_bn,lat,lng,location_precision,media_key)
  values(null,'public',auth.uid(),p_request_id,'NS-P-'||upper(substr(replace(p_request_id::text,'-',''),1,8)),
    trim(p_title),trim(coalesce(p_description,'')),p_categories,v_department,0,'low',
    left(trim(p_area),160),
    case when p_precision='approximate' then round(p_lat,3) else p_lat end,
    case when p_precision='approximate' then round(p_lng,3) else p_lng end,
    p_precision,p_media_key)
  returning id into v_id;
  if p_media_key is not null then
    insert into public.media_assets(observation_id,owner_uid,storage_key,mime_type,stage)
    values(v_id,auth.uid(),p_media_key,p_mime_type,'report');
  end if;
  return v_id;
end $$;
revoke all on function public.submit_public_report(uuid,text,text,text[],text,numeric,numeric,text,text,text) from public,anon;
grant execute on function public.submit_public_report(uuid,text,text,text[],text,numeric,numeric,text,text,text) to authenticated;

create or replace function public.public_report_status()
returns table(id uuid,code text,title text,status text,updated_at timestamptz)
language sql stable security definer set search_path=public as $$
  select o.id,o.report_code,o.title_bn,
    coalesce(i.status,case when o.status='dismissed' then 'dismissed' else 'needs_review' end),
    coalesce(i.updated_at,o.created_at)
  from public.observations o left join public.incidents i on i.observation_id=o.id
  where o.source='public' and o.reporter_uid=auth.uid()
  order by o.created_at desc
$$;
revoke all on function public.public_report_status() from public,anon;
grant execute on function public.public_report_status() to authenticated;

create or replace function public.create_survey_mission(
  p_kind text,p_area text,p_site text,p_capture_source text,p_captured_at timestamptz,
  p_permission_ref text default null,p_notes text default null
) returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid;
begin
  if public.my_role()<>'survey_operator' or p_kind not in ('drone','gapscan')
    or p_capture_source not in ('drone','phone','360','imported')
    or length(trim(coalesce(p_area,'')))<3
    or (p_kind='gapscan' and length(trim(coalesce(p_site,'')))<3)
    or (p_capture_source='drone' and length(trim(coalesce(p_permission_ref,'')))<3)
    then raise exception 'Invalid survey mission'; end if;
  insert into public.survey_missions(operator_id,kind,area_bn,site_label,capture_source,
    flight_permission_ref,notes,captured_at)
  values(auth.uid(),p_kind,left(trim(p_area),160),left(trim(p_site),160),p_capture_source,
    left(trim(p_permission_ref),160),left(trim(p_notes),1000),p_captured_at)
  returning id into v_id;
  return v_id;
end $$;
revoke all on function public.create_survey_mission(text,text,text,text,timestamptz,text,text) from public,anon;
grant execute on function public.create_survey_mission(text,text,text,text,timestamptz,text,text) to authenticated;

create or replace function public.submit_survey_observation(
  p_request_id uuid,p_mission_id uuid,p_title text,p_description text,p_category text,
  p_lat numeric,p_lng numeric,p_media_key text,p_mime_type text
) returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid; v_mission public.survey_missions%rowtype;
begin
  if public.my_role()<>'survey_operator' then raise exception 'Survey operator required'; end if;
  select id into v_id from public.observations where client_request_id=p_request_id;
  if found then
    if (select created_by from public.observations where id=v_id)<>auth.uid()
      then raise exception 'Request ID in use'; end if;
    return v_id;
  end if;
  select * into v_mission from public.survey_missions
    where id=p_mission_id and operator_id=auth.uid();
  if not found or p_request_id is null or length(trim(coalesce(p_title,'')))<4
    or length(p_title)>120
    or p_category not in ('DRAIN_OBSTRUCTION','STANDING_WATER','WASTE','FOOTPATH_OBSTRUCTION','ACCESS_OBSTRUCTION','WATER_CONTAINER')
    or p_lat is null or p_lat not between -90 and 90
    or p_lng is null or p_lng not between -180 and 180
    or p_media_key not like 'survey/'||auth.uid()::text||'/%'
    or p_mime_type not in ('image/jpeg','image/png','image/webp','video/mp4')
    or not exists(select 1 from storage.objects where bucket_id='evidence' and name=p_media_key)
    then raise exception 'Invalid survey observation'; end if;
  insert into public.observations(scenario_id,source,mission_id,client_request_id,title_bn,
    description_bn,categories,department_id,score,priority,area_bn,lat,lng,media_key,created_by)
  values(null,v_mission.kind,v_mission.id,p_request_id,trim(p_title),left(trim(p_description),2000),
    array[p_category],'inspection',0,'low',v_mission.area_bn,p_lat,p_lng,p_media_key,auth.uid())
  returning id into v_id;
  insert into public.media_assets(observation_id,owner_uid,storage_key,mime_type,stage)
  values(v_id,auth.uid(),p_media_key,p_mime_type,'survey');
  return v_id;
end $$;
revoke all on function public.submit_survey_observation(uuid,uuid,text,text,text,numeric,numeric,text,text) from public,anon;
grant execute on function public.submit_survey_observation(uuid,uuid,text,text,text,numeric,numeric,text,text) to authenticated;

create or replace function public.review_intake_observation(
  p_id uuid,p_approve boolean,p_note text default ''
) returns uuid language plpgsql security definer set search_path=public as $$
declare v_ob public.observations%rowtype; v_incident uuid;
begin
  select * into v_ob from public.observations where id=p_id for update;
  if not found or v_ob.source='scenario' or v_ob.status<>'needs_review'
    or public.my_role() not in ('executive','department_head')
    or (public.my_role()='department_head' and public.my_department()<>v_ob.department_id)
    then raise exception 'Review not allowed'; end if;
  if not p_approve then
    update public.observations set status='dismissed' where id=p_id;
    return p_id;
  end if;
  update public.observations set status='verified' where id=p_id;
  insert into public.incidents(observation_id,code,title_bn,description_bn,hazard,department_id,
    status,score,priority,area_bn,lat,lng,before_key)
  values(p_id,coalesce(v_ob.report_code,'NS-'||upper(substr(replace(p_id::text,'-',''),1,8))),
    v_ob.title_bn,coalesce(v_ob.description_bn,''),coalesce(v_ob.categories[1],'DRAIN_OBSTRUCTION'),
    v_ob.department_id,'verified',v_ob.score,v_ob.priority,v_ob.area_bn,v_ob.lat,v_ob.lng,v_ob.media_key)
  returning id into v_incident;
  insert into public.events(incident_id,actor_id,kind,note)
  values(v_incident,auth.uid(),'verified_observation',left(p_note,1000));
  return v_incident;
end $$;
revoke all on function public.review_intake_observation(uuid,boolean,text) from public,anon;
grant execute on function public.review_intake_observation(uuid,boolean,text) to authenticated;

create or replace function public.submit_task_evidence(
  p_task_id uuid,p_note text,p_media_key text,p_mime_type text
) returns uuid language plpgsql security definer set search_path=public as $$
declare v_task public.tasks%rowtype;
begin
  select * into v_task from public.tasks where id=p_task_id for update;
  if not found or public.my_role()<>'field_employee' or v_task.assignee_id<>auth.uid()
    or v_task.status<>'in_progress' or length(trim(coalesce(p_note,'')))<8
    or p_media_key not like 'task/'||auth.uid()::text||'/%'
    or p_mime_type not in ('image/jpeg','image/png','image/webp')
    or not exists(select 1 from storage.objects where bucket_id='evidence' and name=p_media_key)
    then raise exception 'Task evidence not allowed'; end if;
  insert into public.media_assets(incident_id,task_id,owner_uid,storage_key,mime_type,stage)
  values(v_task.incident_id,p_task_id,auth.uid(),p_media_key,p_mime_type,'after');
  update public.tasks set status='action_submitted',completion_note=left(trim(p_note),1000),updated_at=now()
  where id=p_task_id;
  update public.incidents set status='verification_pending',after_key=p_media_key,updated_at=now()
  where id=v_task.incident_id;
  insert into public.events(incident_id,task_id,actor_id,kind,note)
  values(v_task.incident_id,p_task_id,auth.uid(),'submit_task',left(trim(p_note),1000));
  return p_task_id;
end $$;
revoke all on function public.submit_task_evidence(uuid,text,text,text) from public,anon;
grant execute on function public.submit_task_evidence(uuid,text,text,text) to authenticated;

create or replace function public.save_media_annotation(
  p_media_id uuid,p_label text,p_shape text,p_points jsonb,
  p_from_ms integer default null,p_to_ms integer default null
) returns uuid language plpgsql security definer set search_path=public as $$
declare v_media public.media_assets%rowtype; v_id uuid; v_point jsonb; v_number jsonb;
begin
  select * into v_media from public.media_assets where id=p_media_id;
  if not found or v_media.owner_uid<>auth.uid() or public.my_role()<>'survey_operator'
    or p_shape not in ('box','polygon') or length(trim(coalesce(p_label,'')))<2
    or jsonb_typeof(p_points)<>'array'
    or (p_shape='box' and jsonb_array_length(p_points)<>4)
    or (p_shape='polygon' and jsonb_array_length(p_points)<3)
    or (p_from_ms is not null and p_from_ms<0)
    or (p_to_ms is not null and (p_from_ms is null or p_to_ms<=p_from_ms))
    then raise exception 'Invalid annotation'; end if;
  for v_point in select value from jsonb_array_elements(p_points) loop
    if p_shape='box' then
      v_number:=v_point;
      if jsonb_typeof(v_number)<>'number' or (v_number::text)::numeric not between 0 and 1
        then raise exception 'Coordinates must be normalized'; end if;
    else
      if jsonb_typeof(v_point)<>'array' or jsonb_array_length(v_point)<>2
        then raise exception 'Invalid polygon point'; end if;
      for v_number in select value from jsonb_array_elements(v_point) loop
        if jsonb_typeof(v_number)<>'number' or (v_number::text)::numeric not between 0 and 1
          then raise exception 'Coordinates must be normalized'; end if;
      end loop;
    end if;
  end loop;
  if p_shape='box' and (
    ((p_points->>0)::numeric+(p_points->>2)::numeric)>1 or
    ((p_points->>1)::numeric+(p_points->>3)::numeric)>1)
    then raise exception 'Box exceeds image'; end if;
  insert into public.media_annotations(media_id,label,shape,points,from_ms,to_ms,source,created_by)
  values(p_media_id,left(trim(p_label),80),p_shape,p_points,p_from_ms,p_to_ms,'manual',auth.uid())
  returning id into v_id;
  return v_id;
end $$;
revoke all on function public.save_media_annotation(uuid,text,text,jsonb,integer,integer) from public,anon;
grant execute on function public.save_media_annotation(uuid,text,text,jsonb,integer,integer) to authenticated;

-- Reset presentation data only. Real public and survey reports survive.
create or replace function public.reset_demo() returns void language plpgsql security definer set search_path=public as $$
begin
  if coalesce(auth.role(),'')<>'service_role' and coalesce(public.my_role(),'')<>'executive'
    then raise exception 'Permission denied'; end if;
  delete from public.notifications where incident_id in (
    select id from public.incidents where code ~ '^NS-[0-9]{3}$' and observation_id is null);
  delete from public.incidents where code ~ '^NS-[0-9]{3}$' and observation_id is null;
  perform public.seed_demo();
end $$;
