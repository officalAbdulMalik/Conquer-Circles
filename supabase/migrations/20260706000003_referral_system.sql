-- Referral system: every user gets a unique referral_code; when a new user
-- signs up with someone's code, the referrer earns +10 attack energy and the
-- referral is recorded in referral_events.

-- 1. Columns
alter table public.profiles
  add column if not exists referral_code text,
  add column if not exists referred_by  uuid references public.profiles(id) on delete set null;

-- 2. Unique code generator (unambiguous alphabet: no I, O, 0, 1)
create or replace function public.generate_referral_code()
returns text
language plpgsql
as $fn$
declare
  v_alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_code text;
  v_i int;
begin
  loop
    v_code := '';
    for v_i in 1..6 loop
      v_code := v_code || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from public.profiles where referral_code = v_code);
  end loop;
  return v_code;
end;
$fn$;

-- 3. Backfill existing profiles (row-by-row so codes are unique within the txn)
do $do$
declare
  r record;
  v_code text;
begin
  for r in select id from public.profiles where referral_code is null loop
    v_code := public.generate_referral_code();
    update public.profiles set referral_code = v_code where id = r.id;
  end loop;
end;
$do$;

-- 4. Enforce uniqueness + auto-assign on insert
create unique index if not exists profiles_referral_code_key
  on public.profiles (referral_code);

create or replace function public.set_referral_code()
returns trigger
language plpgsql
as $fn$
begin
  if NEW.referral_code is null or NEW.referral_code = '' then
    NEW.referral_code := public.generate_referral_code();
  end if;
  return NEW;
end;
$fn$;

drop trigger if exists trg_set_referral_code on public.profiles;
create trigger trg_set_referral_code
  before insert on public.profiles
  for each row execute function public.set_referral_code();

-- 5. Referral events (one credit per referred user)
create table if not exists public.referral_events (
  id             uuid primary key default gen_random_uuid(),
  referrer_id    uuid not null references public.profiles(id) on delete cascade,
  referred_id    uuid not null references public.profiles(id) on delete cascade,
  referred_name  text,
  energy_awarded integer not null default 10,
  created_at     timestamptz not null default now(),
  unique (referred_id)
);
create index if not exists referral_events_referrer_idx
  on public.referral_events (referrer_id, created_at desc);

alter table public.referral_events enable row level security;
drop policy if exists referral_events_select_own on public.referral_events;
create policy referral_events_select_own on public.referral_events
  for select using (auth.uid() = referrer_id);

-- 6. Core crediting logic (internal; used by signup trigger and redeem RPC)
create or replace function public.credit_referral(
  p_referred uuid,
  p_code text,
  p_referred_name text
)
returns void
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_referrer uuid;
  v_award constant integer := 10;
begin
  if p_code is null or btrim(p_code) = '' then
    return;
  end if;

  select id into v_referrer
  from public.profiles
  where upper(referral_code) = upper(btrim(p_code))
  limit 1;

  -- must exist, not be self, and the referred user must be new to referrals
  if v_referrer is null or v_referrer = p_referred then
    return;
  end if;
  if exists (select 1 from public.referral_events where referred_id = p_referred) then
    return;
  end if;

  update public.profiles
     set referred_by = v_referrer
   where id = p_referred and referred_by is null;

  perform set_config('app.energy_ctx',
    jsonb_build_object('type','referral','description','Referral bonus')::text, true);
  update public.profiles
     set attack_energy = coalesce(attack_energy, 0) + v_award,
         updated_at = now()
   where id = v_referrer;

  insert into public.referral_events (referrer_id, referred_id, referred_name, energy_awarded)
  values (v_referrer, p_referred, nullif(btrim(coalesce(p_referred_name, '')), ''), v_award);
end;
$fn$;

-- 7. Summary for the referral screen
create or replace function public.get_referral_summary()
returns jsonb
language sql
security definer
set search_path = public
as $fn$
  select jsonb_build_object(
    'code', (select referral_code from public.profiles where id = auth.uid()),
    'total_earned', coalesce(
      (select sum(energy_awarded) from public.referral_events where referrer_id = auth.uid()), 0),
    'history', coalesce((
      select jsonb_agg(jsonb_build_object(
        'name', coalesce(re.referred_name, 'New member'),
        'energy', re.energy_awarded,
        'created_at', re.created_at
      ) order by re.created_at desc)
      from public.referral_events re
      where re.referrer_id = auth.uid()
    ), '[]'::jsonb)
  );
$fn$;

-- 8. Optional: let an existing user redeem a code once (if not entered at signup)
create or replace function public.redeem_referral_code(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_uid uuid := auth.uid();
  v_referrer uuid;
  v_existing uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select referred_by into v_existing from public.profiles where id = v_uid;
  if v_existing is not null then
    return jsonb_build_object('success', false, 'error', 'You have already used a referral code');
  end if;

  select id into v_referrer
  from public.profiles
  where upper(referral_code) = upper(btrim(p_code))
  limit 1;

  if v_referrer is null then
    return jsonb_build_object('success', false, 'error', 'Invalid referral code');
  end if;
  if v_referrer = v_uid then
    return jsonb_build_object('success', false, 'error', 'You cannot use your own code');
  end if;

  perform public.credit_referral(
    v_uid, p_code,
    (select coalesce(full_name, username) from public.profiles where id = v_uid)
  );
  return jsonb_build_object('success', true);
end;
$fn$;

-- 9. Grants
revoke all on function public.credit_referral(uuid, text, text) from public;
revoke all on function public.generate_referral_code() from public;
grant execute on function public.get_referral_summary() to authenticated;
grant execute on function public.redeem_referral_code(text) to authenticated;

-- 10. Credit the referrer when a new user signs up with a referral code passed
--     in signup metadata (raw_user_meta_data.referral_code). Referral failures
--     never block account creation.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
as $fn$
declare
  v_name text := btrim(coalesce(NEW.raw_user_meta_data->>'full_name',
                                NEW.raw_user_meta_data->>'name', ''));
  v_code text := btrim(coalesce(NEW.raw_user_meta_data->>'referral_code', ''));
begin
  insert into public.profiles (id, username)
  values (NEW.id, split_part(NEW.email, '@', 1))
  on conflict (id) do nothing;

  if v_code <> '' then
    begin
      perform public.credit_referral(NEW.id, v_code, nullif(v_name, ''));
    exception when others then
      -- never block signup on a bad/duplicate referral code
      null;
    end;
  end if;

  return NEW;
end;
$fn$;
