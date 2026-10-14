-- Shared web/mobile survey records. Apply after the Flutter SQL extensions.
-- The public submission RPC is mobile-only; the web UI stays officials-only.
alter table public.survey_missions add column if not exists department_id text references public.departments(id);
alter table public.survey_missions alter column operator_id drop not null;
alter table public.survey_missions enable row level security;
revoke all on public.survey_missions from anon;
grant select on public.survey_missions to authenticated;
drop policy if exists missions_read on public.survey_missions;
drop policy if exists survey_missions_read on public.survey_missions;
create policy survey_missions_read on public.survey_missions for select to authenticated using (
  operator_id=auth.uid() or public.my_role()='executive' or
  (public.my_role() in ('department_head','survey_operator') and
    coalesce(department_id,(select p.department_id from public.profiles p where p.id=operator_id))=public.my_department())
);

create or replace function public.can_see_observation(p_id uuid) returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.observations o where o.id=p_id and (
    public.my_role()='executive' or
    (public.my_role()='department_head' and o.department_id=public.my_department()) or
    (public.my_role()='survey_operator' and o.source in ('drone','gapscan') and o.department_id=public.my_department()) or
    (o.source='public' and o.reporter_uid=auth.uid()) or
    exists(select 1 from public.incidents i where i.observation_id=o.id and public.can_see_incident(i.id))
  ))
$$;

-- An incident can have several department tasks. Keep its visible status in sync
-- with the whole task set, rather than whichever task was edited last.
create or replace function public.sync_incident_task_status() returns trigger language plpgsql security definer set search_path=public as $$
declare v_status text;
begin
  if not exists(select 1 from public.tasks where incident_id=new.id) then return new; end if;
  select case
    when bool_and(status='resolved') then 'resolved'
    when bool_or(status='action_submitted') then 'verification_pending'
    when bool_or(status='in_progress') then 'in_progress'
    when bool_or(status='acknowledged') then 'acknowledged'
    else 'assigned' end
  into v_status from public.tasks where incident_id=new.id;
  if new.status is distinct from v_status then
    update public.incidents set status=v_status where id=new.id;
  end if;
  return new;
end $$;
drop trigger if exists incidents_sync_task_status on public.incidents;
create trigger incidents_sync_task_status after update of status on public.incidents
  for each row execute function public.sync_incident_task_status();

create or replace function public.seed_survey_demo() returns void language plpgsql security definer set search_path=public as $$
begin
  insert into public.survey_missions(id,kind,department_id,area_bn,site_label,capture_source,captured_at,flight_permission_ref,notes) values
    ('00000000-0000-4000-9000-000000000001','drone','drainage','মিরপুর বাজার সড়ক','বাজার সড়ক ড্রেন','imported',now()-interval '2 days','ডেমো অনুমতি — বাস্তব নয়','কৃত্রিম ডেমো ফুটেজ; ড্রেন ও জমে থাকা পানির ধারণামূলক পর্যবেক্ষণ।'),
    ('00000000-0000-4000-9000-000000000002','gapscan','footpath','পাইলট এলাকার পূর্ব পথ','পূর্ব পথের সরু অংশ','imported',now()-interval '1 day',null,'কৃত্রিম ডেমো দৃশ্য; পথচারী চলাচলের স্থানের ধারণামূলক নথি।');
  insert into public.observations(id,scenario_id,title_bn,description_bn,categories,department_id,status,score,priority,area_bn,lat,lng,media_key,source,report_code,mission_id,created_at)
  select '00000000-0000-4000-a000-000000000001',id,title_bn,summary_bn,array[hazard],department_id,'needs_review',score,priority,area_bn,lat,lng,media_key,'drone','SUR-001','00000000-0000-4000-9000-000000000001',now()-interval '2 days'
  from public.scenarios where id='mixed';
  insert into public.observations(id,scenario_id,title_bn,description_bn,categories,department_id,status,score,priority,area_bn,lat,lng,media_key,source,report_code,mission_id,created_at)
  select '00000000-0000-4000-a000-000000000002',id,title_bn,summary_bn,array[hazard],department_id,'needs_review',score,priority,area_bn,lat,lng,media_key,'gapscan','SUR-002','00000000-0000-4000-9000-000000000002',now()-interval '1 day'
  from public.scenarios where id='footpath';
end $$;
revoke all on function public.seed_survey_demo() from public,anon,authenticated;

create or replace function public.reset_demo() returns void language plpgsql security definer set search_path=public as $$
begin
  if coalesce(auth.role(),'')<>'service_role' and coalesce(public.my_role(),'')<>'executive' then raise exception 'অনুমতি নেই'; end if;
  delete from public.incidents i where
    (i.code ~ '^NS-[0-9]{3}$' and i.observation_id is null) or
    exists(select 1 from public.observations o where o.id=i.observation_id and
      (o.source='scenario' or o.id in ('00000000-0000-4000-a000-000000000001','00000000-0000-4000-a000-000000000002')));
  delete from public.observations where source='scenario' or id in
    ('00000000-0000-4000-a000-000000000001','00000000-0000-4000-a000-000000000002');
  delete from public.survey_missions where id in
    ('00000000-0000-4000-9000-000000000001','00000000-0000-4000-9000-000000000002');
  perform public.seed_demo();
  perform public.seed_survey_demo();
end $$;
revoke all on function public.reset_demo() from public,anon;
grant execute on function public.reset_demo() to authenticated,service_role;

select public.seed_survey_demo();
