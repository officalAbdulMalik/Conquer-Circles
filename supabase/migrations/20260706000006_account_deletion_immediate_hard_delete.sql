-- Switch account deletion from soft-delete to immediate permanent deletion.
-- Deleting the auth user cascades to the profile and all owned rows. The only
-- foreign keys that would block this are territory_events.new_owner_id /
-- previous_owner_id (NO ACTION), so we null those references first.
drop function if exists public.request_account_deletion();

create function public.request_account_deletion()
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

  -- Clear the historical-log references that use ON DELETE NO ACTION.
  update public.territory_events set new_owner_id = null      where new_owner_id = v_uid;
  update public.territory_events set previous_owner_id = null where previous_owner_id = v_uid;

  -- Permanently delete the auth user; ON DELETE CASCADE handles the profile
  -- and every other user-owned table.
  delete from auth.users where id = v_uid;
end;
$fn$;

revoke all on function public.request_account_deletion() from public;
grant execute on function public.request_account_deletion() to authenticated;

comment on function public.request_account_deletion() is
  'Permanently deletes the calling user (auth.users row + cascaded data). Irreversible.';

-- Retire the soft-delete grace period: reactivate any accounts still flagged
-- under the old model and remove the now-obsolete scheduled purge job.
update public.profiles set deletion_requested_at = null where deletion_requested_at is not null;

do $do$
begin
  if exists (select 1 from cron.job where jobname = 'purge-accounts-pending-deletion') then
    perform cron.unschedule('purge-accounts-pending-deletion');
  end if;
end;
$do$;
