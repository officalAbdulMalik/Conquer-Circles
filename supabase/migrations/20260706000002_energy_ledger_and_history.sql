-- Energy usage ledger: records every change to a player's attack_energy
-- (territory battles = spend, steps/milestones = gain) against the user,
-- so it can be shown in the Energy Usage screen.

-- 1. Ledger table
create table if not exists public.energy_ledger (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  delta         integer not null,
  balance_after integer,
  type          text not null default 'adjustment',
  description   text,
  metadata      jsonb not null default '{}'::jsonb,
  created_at    timestamptz not null default now()
);

create index if not exists energy_ledger_user_created_idx
  on public.energy_ledger (user_id, created_at desc);

comment on table public.energy_ledger is
  'Append-only history of attack_energy changes per user. Populated automatically by the trg_log_energy_change trigger on public.profiles.';

-- 2. RLS: a user may read only their own ledger. Inserts happen through the
--    SECURITY DEFINER trigger (runs as owner), so no insert policy is needed.
alter table public.energy_ledger enable row level security;
drop policy if exists energy_ledger_select_own on public.energy_ledger;
create policy energy_ledger_select_own on public.energy_ledger
  for select using (auth.uid() = user_id);

-- 3. Trigger: log every real change to profiles.attack_energy.
--    Optional per-transaction context (app.energy_ctx JSON: {type, description,
--    metadata}) lets callers label the entry; otherwise the sign of the delta
--    is used (in-app, the only spend path is territory combat).
create or replace function public.log_energy_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_delta integer;
  v_ctx   jsonb;
  v_type  text;
  v_desc  text;
begin
  if NEW.attack_energy is not distinct from OLD.attack_energy then
    return NEW;
  end if;

  v_delta := coalesce(NEW.attack_energy, 0) - coalesce(OLD.attack_energy, 0);

  begin
    v_ctx := nullif(current_setting('app.energy_ctx', true), '')::jsonb;
  exception when others then
    v_ctx := null;
  end;

  v_type := coalesce(
    v_ctx->>'type',
    case when v_delta < 0 then 'territory_battle' else 'energy_gain' end
  );
  v_desc := coalesce(
    v_ctx->>'description',
    case when v_delta < 0 then 'Territory battle' else 'Energy gained' end
  );

  insert into public.energy_ledger
    (user_id, delta, balance_after, type, description, metadata)
  values
    (NEW.id, v_delta, NEW.attack_energy, v_type, v_desc,
     coalesce(v_ctx->'metadata', '{}'::jsonb));

  return NEW;
end;
$fn$;

drop trigger if exists trg_log_energy_change on public.profiles;
create trigger trg_log_energy_change
  after update of attack_energy on public.profiles
  for each row execute function public.log_energy_change();

-- 4. Read API: paginated (keyset) history for the signed-in user.
create or replace function public.get_energy_history(
  p_limit integer default 50,
  p_before timestamptz default null
)
returns table(
  id uuid,
  delta integer,
  balance_after integer,
  type text,
  description text,
  metadata jsonb,
  created_at timestamptz
)
language sql
security definer
set search_path = public
as $fn$
  select l.id, l.delta, l.balance_after, l.type, l.description, l.metadata, l.created_at
  from public.energy_ledger l
  where l.user_id = auth.uid()
    and (p_before is null or l.created_at < p_before)
  order by l.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 200));
$fn$;

revoke all on function public.get_energy_history(integer, timestamptz) from public;
grant execute on function public.get_energy_history(integer, timestamptz) to authenticated;

-- 5. Backfill existing history so the screen isn't empty.
--    5a. Prior gains/spends recorded in the legacy energy_log.
insert into public.energy_ledger (user_id, delta, balance_after, type, description, created_at)
select el.user_id,
       el.delta,
       null,
       case when el.reason = 'steps'  then 'steps'
            when el.reason = 'attack' then 'territory_battle'
            else coalesce(el.reason, 'adjustment') end,
       case when el.reason = 'steps'  then 'Walking reward'
            when el.reason = 'attack' then 'Territory battle'
            else initcap(coalesce(el.reason, 'Adjustment')) end,
       el.created_at
from public.energy_log el;

--    5b. Territory combat spends recorded in territory_attack_log.
insert into public.energy_ledger (user_id, delta, balance_after, type, description, metadata, created_at)
select t.attacker_id,
       -abs(t.energy_used),
       t.energy_after,
       'territory_battle',
       case t.action
         when 'claimed'    then 'Territory claimed'
         when 'reinforced' then 'Territory reinforced'
         when 'captured'   then 'Territory captured'
         else 'Territory attack' end,
       jsonb_build_object('action', t.action, 'captured', t.captured, 'territory_id', t.territory_id),
       t.created_at
from public.territory_attack_log t
where t.energy_used > 0;
