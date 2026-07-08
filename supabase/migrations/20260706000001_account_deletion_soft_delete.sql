-- Account deletion: soft-delete + 7-day scheduled purge.
-- Adds a deletion marker on profiles, auth-scoped request/cancel RPCs,
-- a purge function, and a daily pg_cron job.

-- 1. Soft-delete marker
alter table public.profiles
  add column if not exists deletion_requested_at timestamptz;

comment on column public.profiles.deletion_requested_at is
  'When set, the account is pending deletion. A scheduled job purges the auth user (cascading to this row) 7 days after this timestamp. NULL = active account.';

-- 2. Request deletion (auth-scoped; reversible within the grace period)
create or replace function public.request_account_deletion()
returns timestamptz
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_uid uuid := auth.uid();
  v_ts timestamptz;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  update public.profiles
     set deletion_requested_at = coalesce(deletion_requested_at, now()),
         notifications_enabled = false,
         updated_at = now()
   where id = v_uid
   returning deletion_requested_at into v_ts;

  if v_ts is null then
    raise exception 'Profile not found' using errcode = 'P0002';
  end if;

  return v_ts;
end;
$fn$;

-- 3. Cancel a pending deletion (reactivation)
create or replace function public.cancel_account_deletion()
returns void
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  update public.profiles
     set deletion_requested_at = null,
         updated_at = now()
   where id = v_uid;
end;
$fn$;

-- 4. Scheduled purge: hard-delete auth users past the 7-day grace period.
--    Deleting from auth.users cascades to public.profiles (FK on delete cascade).
create or replace function public.purge_accounts_pending_deletion()
returns integer
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_count integer;
begin
  with expired as (
    select id
      from public.profiles
     where deletion_requested_at is not null
       and deletion_requested_at < now() - interval '7 days'
  ), deleted as (
    delete from auth.users u
     using expired e
     where u.id = e.id
     returning u.id
  )
  select count(*) into v_count from deleted;

  return coalesce(v_count, 0);
end;
$fn$;

-- 5. Grants: users may request/cancel their own deletion; purge is service-only.
revoke all on function public.request_account_deletion() from public;
revoke all on function public.cancel_account_deletion() from public;
revoke all on function public.purge_accounts_pending_deletion() from public;
grant execute on function public.request_account_deletion() to authenticated;
grant execute on function public.cancel_account_deletion() to authenticated;
grant execute on function public.purge_accounts_pending_deletion() to service_role;

-- 6. Daily scheduled purge at 03:00 UTC.
do $cronblock$
begin
  if exists (select 1 from cron.job where jobname = 'purge-accounts-pending-deletion') then
    perform cron.unschedule('purge-accounts-pending-deletion');
  end if;
end;
$cronblock$;

select cron.schedule(
  'purge-accounts-pending-deletion',
  '0 3 * * *',
  $cron$ select public.purge_accounts_pending_deletion(); $cron$
);
