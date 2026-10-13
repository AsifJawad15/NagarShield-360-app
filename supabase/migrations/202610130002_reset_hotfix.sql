-- Apply this migration to projects that already ran 202610130001_prototype.sql.
-- Supabase safe updates rejects the original reset's DELETE statements without WHERE.
create or replace function public.reset_demo() returns void language plpgsql security definer set search_path=public as $$
begin
  if coalesce(auth.role(),'')<>'service_role' and coalesce(public.my_role(),'')<>'executive' then raise exception 'অনুমতি নেই'; end if;
  truncate table public.notifications, public.events, public.tasks,
    public.detections, public.incidents, public.observations;
  perform public.seed_demo();
end $$;
revoke all on function public.reset_demo() from public,anon;
grant execute on function public.reset_demo() to authenticated,service_role;
