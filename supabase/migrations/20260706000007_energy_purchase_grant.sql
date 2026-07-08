-- Grant energy from a store purchase, once per transaction (idempotent), and
-- log it to energy_ledger via the existing trigger.

create table if not exists public.energy_purchases (
  id                   uuid primary key default gen_random_uuid(),
  user_id              uuid not null references auth.users(id) on delete cascade,
  store_transaction_id text not null,
  product_id           text not null,
  energy_amount        integer not null,
  created_at           timestamptz not null default now(),
  unique (store_transaction_id)
);
alter table public.energy_purchases enable row level security;
drop policy if exists energy_purchases_select_own on public.energy_purchases;
create policy energy_purchases_select_own on public.energy_purchases
  for select using (auth.uid() = user_id);

-- Server-side product -> energy map. Add your real product ids here; unknown
-- products return 0 and fall back to the client-provided amount (testing only).
create or replace function public.energy_for_product(p_product_id text)
returns integer language sql immutable as $fn$
  select case p_product_id
    when 'com.conquercircles.energy.10'  then 10
    when 'com.conquercircles.energy.50'  then 50
    when 'com.conquercircles.energy.100' then 100
    when 'com.conquercircles.energy.200' then 200
    when 'com.conquercircles.energy.300' then 300
    when 'com.conquercircles.energy.400' then 400
    else 0 end;
$fn$;

-- Idempotent grant for the signed-in user. Returns the new energy balance.
-- SECURITY NOTE: for production, prefer granting from the RevenueCat webhook
-- (service role, server-derived amount). The client `p_amount` fallback is a
-- testing convenience until the webhook is wired.
create or replace function public.grant_purchased_energy(
  p_product_id text,
  p_transaction_id text,
  p_amount integer default null
)
returns integer
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_uid uuid := auth.uid();
  v_amount integer;
  v_balance integer;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  v_amount := public.energy_for_product(p_product_id);
  if v_amount <= 0 then
    v_amount := coalesce(p_amount, 0);
  end if;
  if v_amount <= 0 then
    raise exception 'Unknown energy amount for product %', p_product_id;
  end if;

  insert into public.energy_purchases
    (user_id, store_transaction_id, product_id, energy_amount)
  values (v_uid, p_transaction_id, p_product_id, v_amount)
  on conflict (store_transaction_id) do nothing;

  if not found then
    -- transaction already processed; return current balance unchanged
    select coalesce(attack_energy, 0) into v_balance
      from public.profiles where id = v_uid;
    return v_balance;
  end if;

  perform set_config('app.energy_ctx',
    jsonb_build_object('type','purchase','description','Energy purchase')::text, true);
  update public.profiles
     set attack_energy = coalesce(attack_energy, 0) + v_amount,
         updated_at = now()
   where id = v_uid
   returning attack_energy into v_balance;

  return v_balance;
end;
$fn$;

revoke all on function public.grant_purchased_energy(text, text, integer) from public;
grant execute on function public.grant_purchased_energy(text, text, integer) to authenticated;
