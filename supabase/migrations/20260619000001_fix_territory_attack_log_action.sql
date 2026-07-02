-- Hotfix deployed databases where attack_or_claim_territory writes an action
-- value before territory_attack_log has the matching column.

ALTER TABLE public.territory_attack_log
  ADD COLUMN IF NOT EXISTS action TEXT,
  ADD COLUMN IF NOT EXISTS energy_used INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS energy_before INT,
  ADD COLUMN IF NOT EXISTS energy_after INT,
  ADD COLUMN IF NOT EXISTS captured BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE public.territory_attack_log
  ALTER COLUMN defender_id DROP NOT NULL,
  ALTER COLUMN action SET DEFAULT 'damaged';

UPDATE public.territory_attack_log
SET action = CASE
  WHEN captured THEN 'captured'
  WHEN defender_id IS NULL THEN 'claimed'
  WHEN attacker_id = defender_id THEN 'reinforced'
  ELSE 'damaged'
END
WHERE action IS NULL OR action = '';

ALTER TABLE public.territory_attack_log
  ALTER COLUMN action SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_territory_attack_log_attacker
  ON public.territory_attack_log (attacker_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_territory_attack_log_defender
  ON public.territory_attack_log (defender_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_territory_attack_log_territory
  ON public.territory_attack_log (territory_id, created_at DESC);
