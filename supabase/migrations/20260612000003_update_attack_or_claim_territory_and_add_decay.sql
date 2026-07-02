-- Update territory attack/claim logic to include bonuses, home-base support,
-- hold/revisit bonuses, and correct shield/protection behavior.
-- Add support for stale territory decay after 3 days of inactivity.

CREATE TABLE IF NOT EXISTS public.territory_attack_cooldowns (
  attacker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  territory_id UUID NOT NULL REFERENCES public.territories(id) ON DELETE CASCADE,
  cooldown_until TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (attacker_id, territory_id)
);

ALTER TABLE public.territory_attack_cooldowns
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

CREATE UNIQUE INDEX IF NOT EXISTS idx_territory_attack_cooldowns_attacker_territory
  ON public.territory_attack_cooldowns (attacker_id, territory_id);

CREATE INDEX IF NOT EXISTS idx_territory_attack_cooldowns_until
  ON public.territory_attack_cooldowns (cooldown_until);

CREATE TABLE IF NOT EXISTS public.territory_attack_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  territory_id UUID NOT NULL REFERENCES public.territories(id) ON DELETE CASCADE,
  attacker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  defender_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL DEFAULT 'damaged',
  energy_used INT NOT NULL DEFAULT 0,
  energy_before INT,
  energy_after INT,
  captured BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.territory_attack_log
  ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS defender_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
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

ALTER TABLE public.territory_attack_cooldowns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.territory_attack_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own territory cooldowns" ON public.territory_attack_cooldowns;
CREATE POLICY "Users can view own territory cooldowns"
  ON public.territory_attack_cooldowns
  FOR SELECT
  USING (attacker_id = auth.uid());

DROP POLICY IF EXISTS "Users can view related territory attack logs" ON public.territory_attack_log;
CREATE POLICY "Users can view related territory attack logs"
  ON public.territory_attack_log
  FOR SELECT
  USING (attacker_id = auth.uid() OR defender_id = auth.uid());

CREATE OR REPLACE FUNCTION public.attack_or_claim_territory(
  p_territory_id UUID,
  p_user_id UUID,
  p_speed_kmh DOUBLE PRECISION,
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_territory territories%ROWTYPE;
  v_attacker profiles%ROWTYPE;
  v_defender profiles%ROWTYPE;
  v_is_own_territory BOOLEAN := FALSE;
  v_attacker_energy_before INT := 0;
  v_territory_energy_before INT := 0;
  v_territory_energy_after INT := 0;
  v_energy_to_consume INT := 0;
  v_energy_to_add INT := 0;
  v_energy_bonus INT := 0;
  v_revisit_bonus INT := 0;
  v_hold_bonus INT := 0;
  v_cluster_bonus INT := 0;
  v_home_bonus INT := 0;
  v_cluster_size INT := 0;
  v_absence_floor INT := 0;
  v_captured BOOLEAN := FALSE;
  v_defender_username TEXT;
  v_recent_steps INT := 0;
  v_distance_from_home_m NUMERIC;
  v_home_base_lat DOUBLE PRECISION;
  v_home_base_lng DOUBLE PRECISION;
  v_cooldown_until TIMESTAMPTZ;
BEGIN
  IF auth.uid() IS NULL OR auth.uid() <> p_user_id THEN
    RETURN jsonb_build_object(
      'action', 'error',
      'reason', 'unauthorized',
      'message', 'Unauthorized attacker context'
    );
  END IF;

  IF p_speed_kmh < 2.0 OR p_speed_kmh > 15.0 THEN
    RETURN jsonb_build_object(
      'action', 'error',
      'reason', 'invalid_speed',
      'speed_kmh', p_speed_kmh,
      'message', 'Walking speed must be between 2 and 15 km/h'
    );
  END IF;

  SELECT * INTO v_territory
  FROM public.territories
  WHERE id = p_territory_id
  FOR UPDATE;

  IF v_territory.id IS NULL THEN
    RETURN jsonb_build_object(
      'action', 'error',
      'reason', 'territory_not_found',
      'territory_id', p_territory_id
    );
  END IF;

  SELECT * INTO v_attacker
  FROM public.profiles
  WHERE id = p_user_id
  FOR UPDATE;

  IF v_attacker.id IS NULL THEN
    RETURN jsonb_build_object(
      'action', 'error',
      'reason', 'attacker_not_found'
    );
  END IF;

  v_is_own_territory := (v_territory.user_id = p_user_id);
  v_attacker_energy_before := COALESCE(v_attacker.attack_energy, 0);
  v_territory_energy_before := COALESCE(v_territory.energy, 0);

  IF v_territory.user_id IS NOT NULL THEN
    SELECT * INTO v_defender
    FROM public.profiles
    WHERE id = v_territory.user_id;
  END IF;

  SELECT home_base_lat, home_base_lng
  INTO v_home_base_lat, v_home_base_lng
  FROM public.profiles
  WHERE id = p_user_id;

  IF v_home_base_lat IS NOT NULL
     AND v_home_base_lng IS NOT NULL
     AND v_territory.geom IS NOT NULL THEN
    v_distance_from_home_m := ST_DistanceSphere(
      ST_SetSRID(ST_MakePoint(v_home_base_lng, v_home_base_lat), 4326),
      ST_Centroid(v_territory.geom)
    );
    IF v_distance_from_home_m IS NOT NULL
       AND v_distance_from_home_m <= 150 THEN
      v_home_bonus := 10;
    END IF;
  END IF;

  SELECT COUNT(*) INTO v_cluster_size
  FROM public.territories
  WHERE user_id = p_user_id
    AND id != p_territory_id
    AND ST_Touches(geom, v_territory.geom);

  IF v_cluster_size >= 15 THEN
    v_cluster_bonus := 20;
  ELSIF v_cluster_size >= 7 THEN
    v_cluster_bonus := 10;
  ELSIF v_cluster_size >= 3 THEN
    v_cluster_bonus := 5;
  END IF;

  IF v_is_own_territory THEN
    IF v_territory.last_activity_time IS NOT NULL
       AND DATE(v_territory.last_activity_time) = CURRENT_DATE THEN
      v_revisit_bonus := 5;
    END IF;

    IF v_territory.capture_time IS NOT NULL
       AND v_territory.capture_time <= NOW() - INTERVAL '48 hours' THEN
      v_hold_bonus := 10;
    END IF;
  END IF;

  v_energy_bonus := v_revisit_bonus + v_hold_bonus + v_cluster_bonus + v_home_bonus;
  v_energy_to_add := LEAST(v_attacker_energy_before, 20);

  IF v_territory.user_id IS NULL THEN
    v_territory_energy_after := LEAST(10 + v_energy_to_add + v_energy_bonus, 60);

    UPDATE public.territories
    SET
      user_id = p_user_id,
      energy = v_territory_energy_after,
      capture_time = NOW(),
      protected_until = NOW() + INTERVAL '12 hours',
      shield_until = NOW() + INTERVAL '24 hours',
      last_activity_time = NOW(),
      updated_at = NOW()
    WHERE id = p_territory_id;

    UPDATE public.profiles
    SET attack_energy = GREATEST(COALESCE(attack_energy, 0) - v_energy_to_add, 0)
    WHERE id = p_user_id;

    INSERT INTO public.territory_attack_log (
      territory_id, attacker_id, defender_id, action,
      energy_used, energy_before, energy_after, captured
    ) VALUES (
      p_territory_id, p_user_id, NULL, 'claimed',
      v_energy_to_add, COALESCE(v_territory.energy, 0),
      v_territory_energy_after, FALSE
    );

    RETURN jsonb_build_object(
      'action', 'claimed',
      'territory_id', p_territory_id,
      'territory_energy_before', COALESCE(v_territory.energy, 0),
      'territory_energy_after', v_territory_energy_after,
      'attacker_energy_left', GREATEST(v_attacker_energy_before - v_energy_to_add, 0),
      'energy_bonus', v_energy_bonus
    );
  END IF;

  IF v_is_own_territory THEN
    v_territory_energy_after := LEAST(v_territory_energy_before + v_energy_to_add + v_energy_bonus, 60);

    UPDATE public.territories
    SET
      energy = v_territory_energy_after,
      protected_until = GREATEST(protected_until, NOW() + INTERVAL '12 hours'),
      last_activity_time = NOW(),
      updated_at = NOW()
    WHERE id = p_territory_id;

    UPDATE public.profiles
    SET attack_energy = GREATEST(COALESCE(attack_energy, 0) - v_energy_to_add, 0)
    WHERE id = p_user_id;

    INSERT INTO public.territory_attack_log (
      territory_id, attacker_id, defender_id, action,
      energy_used, energy_before, energy_after, captured
    ) VALUES (
      p_territory_id, p_user_id, p_user_id, 'reinforced',
      v_energy_to_add, COALESCE(v_territory.energy, 0),
      v_territory_energy_after, FALSE
    );

    RETURN jsonb_build_object(
      'action', 'reinforced',
      'territory_id', p_territory_id,
      'territory_energy_before', COALESCE(v_territory.energy, 0),
      'territory_energy_after', v_territory_energy_after,
      'attacker_energy_left', GREATEST(v_attacker_energy_before - v_energy_to_add, 0),
      'energy_bonus', v_energy_bonus
    );
  END IF;

  IF v_territory.protected_until IS NOT NULL
     AND v_territory.protected_until > NOW() THEN
    RETURN jsonb_build_object(
      'action', 'protected',
      'reason', 'protection_active',
      'territory_id', p_territory_id,
      'hours_remaining', ROUND(EXTRACT(EPOCH FROM (v_territory.protected_until - NOW()))::NUMERIC / 3600, 1),
      'message', 'Territory is protected for now. Your walk was registered, but it cannot be attacked yet.'
    );
  END IF;

  SELECT c.cooldown_until
  INTO v_cooldown_until
  FROM public.territory_attack_cooldowns c
  WHERE c.attacker_id = p_user_id
    AND c.territory_id = p_territory_id
    AND c.cooldown_until > NOW();

  IF v_cooldown_until IS NOT NULL THEN
    RETURN jsonb_build_object(
      'action', 'cooldown',
      'reason', 'attack_cooldown_active',
      'territory_id', p_territory_id,
      'cooldown_until', v_cooldown_until,
      'minutes_remaining', ROUND(EXTRACT(EPOCH FROM (v_cooldown_until - NOW()))::NUMERIC / 60),
      'message', 'You must wait before attacking this territory again.'
    );
  END IF;

  SELECT COALESCE(MAX(ds.steps), 0)
  INTO v_recent_steps
  FROM public.daily_steps ds
  WHERE ds.user_id = v_territory.user_id
    AND ds.date >= CURRENT_DATE - INTERVAL '1 day';

  IF v_defender.id IS NOT NULL AND v_recent_steps > 0 THEN
    v_absence_floor := 20;
  END IF;

  IF v_attacker_energy_before <= 0 THEN
    RETURN jsonb_build_object(
      'action', 'no_energy',
      'reason', 'insufficient_attack_energy',
      'territory_id', p_territory_id,
      'current_energy', v_attacker_energy_before,
      'energy_needed', 1
    );
  END IF;

  v_energy_to_consume := v_attacker_energy_before;
  v_captured := (v_attacker_energy_before >= v_territory_energy_before AND v_absence_floor = 0);

  IF v_captured THEN
    v_territory_energy_after := 10;
  ELSE
    v_territory_energy_after := GREATEST(v_territory_energy_before - v_energy_to_consume, v_absence_floor);
  END IF;

  UPDATE public.profiles
  SET attack_energy = GREATEST(COALESCE(attack_energy, 0) - v_energy_to_consume, 0)
  WHERE id = p_user_id;

  IF v_captured THEN
    SELECT p.username INTO v_defender_username
    FROM public.profiles p
    WHERE p.id = v_territory.user_id;

    UPDATE public.territories
    SET
      user_id = p_user_id,
      energy = v_territory_energy_after,
      capture_time = NOW(),
      protected_until = NOW() + INTERVAL '12 hours',
      shield_until = NOW() + INTERVAL '24 hours',
      last_activity_time = NOW(),
      updated_at = NOW()
    WHERE id = p_territory_id;
  ELSE
    UPDATE public.territories
    SET
      energy = v_territory_energy_after,
      last_activity_time = NOW(),
      updated_at = NOW()
    WHERE id = p_territory_id;
  END IF;

  INSERT INTO public.territory_attack_log (
    territory_id, attacker_id, defender_id, action,
    energy_used, energy_before, energy_after, captured
  ) VALUES (
    p_territory_id,
    p_user_id,
    v_territory.user_id,
    CASE WHEN v_captured THEN 'captured' ELSE 'damaged' END,
    v_energy_to_consume,
    v_territory_energy_before,
    v_territory_energy_after,
    v_captured
  );

  INSERT INTO public.territory_attack_cooldowns (
    attacker_id, territory_id, cooldown_until, updated_at
  ) VALUES (
    p_user_id,
    p_territory_id,
    NOW() + INTERVAL '30 minutes',
    NOW()
  )
  ON CONFLICT (attacker_id, territory_id)
  DO UPDATE SET cooldown_until = EXCLUDED.cooldown_until,
                updated_at = NOW();

  IF v_captured THEN
    RETURN jsonb_build_object(
      'action', 'captured',
      'territory_id', p_territory_id,
      'previous_owner_id', v_territory.user_id,
      'defender_id', v_territory.user_id,
      'defender_username', COALESCE(v_defender_username, 'Unknown'),
      'territory_energy_before', v_territory_energy_before,
      'territory_energy_after', v_territory_energy_after,
      'attacker_energy_left', 0
    );
  END IF;

  IF v_absence_floor = 20 THEN
    RETURN jsonb_build_object(
      'action', 'shielded',
      'reason', 'absence_shield_active',
      'territory_id', p_territory_id,
      'territory_energy_before', v_territory_energy_before,
      'territory_energy_after', v_territory_energy_after,
      'attacker_energy_left', 0,
      'message', 'Your walk was registered, but the defender has recent activity so tile energy cannot drop below 20.'
    );
  END IF;

  RETURN jsonb_build_object(
    'action', 'damaged',
    'territory_id', p_territory_id,
    'defender_id', v_territory.user_id,
    'territory_energy_before', v_territory_energy_before,
    'territory_energy_after', v_territory_energy_after,
    'attacker_energy_left', 0
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.attack_or_claim_territory(UUID, UUID, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION)
TO authenticated;

CREATE OR REPLACE FUNCTION public.decay_stale_territories()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated INT := 0;
  v_neutralized INT := 0;
BEGIN
  WITH stale AS (
    SELECT
      id,
      energy,
      GREATEST(
        FLOOR(EXTRACT(EPOCH FROM NOW() - COALESCE(last_activity_time, capture_time, created_at)) / 86400) - 3,
        0
      ) AS decay_days
    FROM public.territories
    WHERE COALESCE(last_activity_time, capture_time, created_at) <= NOW() - INTERVAL '3 days'
      AND energy > 0
  ), updated AS (
    UPDATE public.territories t
    SET energy = GREATEST(t.energy - (s.decay_days * 2), 0),
        updated_at = NOW()
    FROM stale s
    WHERE t.id = s.id
    RETURNING t.id, t.energy
  ), neutralized AS (
    UPDATE public.territories t
    SET
      user_id = NULL,
      capture_time = NULL,
      protected_until = NULL,
      shield_until = NULL,
      last_activity_time = NULL,
      updated_at = NOW()
    FROM updated u
    WHERE t.id = u.id
      AND u.energy <= 0
    RETURNING t.id
  )
  SELECT COUNT(*) INTO v_updated FROM updated;

  SELECT COUNT(*) INTO v_neutralized FROM neutralized;

  RETURN jsonb_build_object(
    'updated_territories', v_updated,
    'neutralized_territories', v_neutralized
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.decay_stale_territories() TO authenticated;
