-- Apply after mobile_extension.sql. Durable idempotency for retried staff actions.
create table if not exists public.mobile_action_receipts (
  actor_id uuid not null references auth.users(id),
  request_id uuid not null,
  action text not null,
  target_id uuid,
  payload jsonb not null,
  result_id uuid not null,
  created_at timestamptz not null default now(),
  primary key (actor_id,request_id)
);
alter table public.mobile_action_receipts enable row level security;

create or replace function public.perform_mobile_action(
  p_request_id uuid,p_action text,p_target uuid default null,p_payload jsonb default '{}'::jsonb
) returns uuid language plpgsql security definer set search_path=public as $$
declare v_receipt public.mobile_action_receipts%rowtype; v_result uuid;
begin
  if auth.uid() is null or public.my_role() is null or p_request_id is null
    or p_action is null or length(p_action)>64
    then raise exception 'Official action required'; end if;
  perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text||p_request_id::text,0));
  select * into v_receipt from public.mobile_action_receipts
    where actor_id=auth.uid() and request_id=p_request_id;
  if found then
    if v_receipt.action<>p_action or v_receipt.target_id is distinct from p_target
      or v_receipt.payload<>coalesce(p_payload,'{}'::jsonb)
      then raise exception 'Request ID reused with different action'; end if;
    return v_receipt.result_id;
  end if;
  if p_action in ('verify_intake','dismiss_intake') then
    v_result:=public.review_intake_observation(
      p_target,p_action='verify_intake',coalesce(p_payload->>'note',''));
  else
    v_result:=public.perform_demo_action(p_action,p_target,coalesce(p_payload,'{}'::jsonb));
  end if;
  insert into public.mobile_action_receipts(actor_id,request_id,action,target_id,payload,result_id)
  values(auth.uid(),p_request_id,p_action,p_target,coalesce(p_payload,'{}'::jsonb),v_result);
  return v_result;
end $$;
revoke all on function public.perform_mobile_action(uuid,text,uuid,jsonb) from public,anon;
grant execute on function public.perform_mobile_action(uuid,text,uuid,jsonb) to authenticated;

create or replace function public.submit_task_evidence(
  p_task_id uuid,p_note text,p_media_key text,p_mime_type text
) returns uuid language plpgsql security definer set search_path=public as $$
declare v_task public.tasks%rowtype; v_existing_key text;
begin
  select * into v_task from public.tasks where id=p_task_id for update;
  if not found or public.my_role()<>'field_employee' or v_task.assignee_id<>auth.uid()
    then raise exception 'Task evidence not allowed'; end if;
  if v_task.status in ('action_submitted','resolved') then
    select after_key into v_existing_key from public.incidents where id=v_task.incident_id;
    if v_existing_key=p_media_key and exists(
      select 1 from public.media_assets where task_id=p_task_id
        and storage_key=p_media_key and owner_uid=auth.uid())
      then return p_task_id; end if;
    raise exception 'Task changed before evidence retry';
  end if;
  if v_task.status<>'in_progress' or length(trim(coalesce(p_note,'')))<8
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

-- A canned web scenario cannot stand in for after-work evidence on mobile intake.
create or replace function public.reject_preset_evidence_for_mobile_intake() returns trigger
language plpgsql security definer set search_path=public as $$
begin
  if new.after_key like 'scenarios/%' and exists (
    select 1 from public.observations o where o.id=new.observation_id
      and o.source in ('public','drone','gapscan') and o.scenario_id is null
  ) then raise exception 'Mobile intake requires submitted task evidence'; end if;
  return new;
end $$;
drop trigger if exists incidents_mobile_evidence_guard on public.incidents;
create trigger incidents_mobile_evidence_guard before insert or update of after_key on public.incidents
  for each row execute function public.reject_preset_evidence_for_mobile_intake();
