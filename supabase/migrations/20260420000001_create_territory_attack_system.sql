-- Territory attack system
-- Replaces old hex-tile combat flow with polygon territory combat.

CREATE TABLE IF NOT EXISTS public.territory_attack_cooldowns (
  attacker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  territory_id UUID NOT NULL REFERENCES public.territories(id) ON DELETE CASCADE,
  cooldown_until TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (attacker_id, territory_id)
);

CREATE INDEX IF NOT EXISTS idx_territory_attack_cooldowns_until
  ON public.territory_attack_cooldowns (cooldown_until);

CREATE TABLE IF NOT EXISTS public.territory_attack_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  territory_id UUID NOT NULL REFERENCES public.territories(id) ON DELETE CASCADE,
  attacker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  defender_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  energy_used INT NOT NULL DEFAULT 0,
  energy_before INT,
  energy_after INT,
  captured BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

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
  v_is_friend BOOLEAN := FALSE;
  v_is_own_territory BOOLEAN := FALSE;
  v_attacker_energy_before INT := 0;
  v_territory_energy_before INT := 0;
  v_territory_energy_after INT := 0;
  v_energy_to_consume INT := 0;
  v_energy_to_add INT := 0;
  v_defense_steps_today INT := 0;
  v_absence_floor INT := 0;
  v_captured BOOLEAN := FALSE;
  v_defender_username TEXT;
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

  -- Claim neutral territory
  IF v_territory.user_id IS NULL THEN
    v_energy_to_add := LEAST(COALESCE(v_attacker.attack_energy, 0), 20);

    UPDATE public.territories
    SET
      user_id = p_user_id,
      energy = GREATEST(10, LEAST(10 + v_energy_to_add, 60)),
      capture_time = NOW(),
      protected_until = NOW() + INTERVAL '12 hours',
      shield_until = NOW() + INTERVAL '24 hours',
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
      GREATEST(10, LEAST(10 + v_energy_to_add, 60)), FALSE
    );

    RETURN jsonb_build_object(
      'action', 'claimed',
      'territory_id', p_territory_id,
      'territory_energy_before', COALESCE(v_territory.energy, 0),
      'territory_energy_after', GREATEST(10, LEAST(10 + v_energy_to_add, 60)),
      'attacker_energy_left', GREATEST(COALESCE(v_attacker.attack_energy, 0) - v_energy_to_add, 0)
    );
  END IF;

  -- Reinforce own territory
  IF v_is_own_territory THEN
    v_energy_to_add := LEAST(COALESCE(v_attacker.attack_energy, 0), 20);

    UPDATE public.territories
    SET
      energy = LEAST(COALESCE(energy, 0) + v_energy_to_add, 60),
      protected_until = GREATEST(protected_until, NOW() + INTERVAL '12 hours'),
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
      LEAST(COALESCE(v_territory.energy, 0) + v_energy_to_add, 60), FALSE
    );

    RETURN jsonb_build_object(
      'action', 'reinforced',
      'territory_id', p_territory_id,
      'territory_energy_before', COALESCE(v_territory.energy, 0),
      'territory_energy_after', LEAST(COALESCE(v_territory.energy, 0) + v_energy_to_add, 60),
      'attacker_energy_left', GREATEST(COALESCE(v_attacker.attack_energy, 0) - v_energy_to_add, 0)
    );
  END IF;

  -- Friends-only attacks
  SELECT EXISTS (
    SELECT 1
    FROM public.invites i
    WHERE i.status = 'accepted'
      AND (
        (i.inviter_id = p_user_id AND i.invitee_id = v_territory.user_id)
        OR
        (i.invitee_id = p_user_id AND i.inviter_id = v_territory.user_id)
      )
  ) INTO v_is_friend;

  IF NOT v_is_friend THEN
    RETURN jsonb_build_object(
      'action', 'not_friends',
      'reason', 'not_friends',
      'message', 'You can only attack territories owned by your friends',
      'territory_owner_id', v_territory.user_id
    );
  END IF;

  -- Defender protection window
  IF v_territory.protection_until IS NOT NULL AND v_territory.protection_until > NOW() THEN
    RETURN jsonb_build_object(
      'action', 'protected',
      'reason', 'protection_active',
      'territory_id', p_territory_id,
      'hours_remaining', ROUND(EXTRACT(EPOCH FROM (v_territory.protection_until - NOW()))::NUMERIC / 3600, 1)
    );
  END IF;

  -- Absence shield (active shield + defender walked today = fully blocked)
  SELECT COALESCE(ds.steps, 0)
  INTO v_defense_steps_today
  FROM public.daily_steps ds
  WHERE ds.user_id = v_territory.user_id
    AND ds.date = CURRENT_DATE
  LIMIT 1;

  IF v_territory.shield_until IS NOT NULL
     AND v_territory.shield_until > NOW()
     AND v_defense_steps_today > 0 THEN
    RETURN jsonb_build_object(
      'action', 'shielded',
      'reason', 'absence_shield_active',
      'territory_id', p_territory_id,
      'hours_remaining', ROUND(EXTRACT(EPOCH FROM (v_territory.shield_until - NOW()))::NUMERIC / 3600, 1)
    );
  END IF;

  -- Cooldown per attacker + territory
  IF EXISTS (
    SELECT 1
    FROM public.territory_attack_cooldowns c
    WHERE c.attacker_id = p_user_id
      AND c.territory_id = p_territory_id
      AND c.cooldown_until > NOW()
  ) THEN
    RETURN jsonb_build_object(
      'action', 'cooldown',
      'reason', 'attack_cooldown_active',
      'territory_id', p_territory_id,
      'minutes_remaining', ROUND(
        EXTRACT(EPOCH FROM (
          (SELECT c.cooldown_until
           FROM public.territory_attack_cooldowns c
           WHERE c.attacker_id = p_user_id
             AND c.territory_id = p_territory_id)
          - NOW()
        ))::NUMERIC / 60
      )
    );
  END IF;

  v_attacker_energy_before := COALESCE(v_attacker.attack_energy, 0);
  v_territory_energy_before := COALESCE(v_territory.energy, 0);

  IF v_attacker_energy_before <= 0 THEN
    RETURN jsonb_build_object(
      'action', 'no_energy',
      'reason', 'insufficient_attack_energy',
      'territory_id', p_territory_id,
      'current_energy', v_attacker_energy_before,
      'energy_needed', 1
    );
  END IF;

  IF v_territory.shield_until IS NOT NULL
     AND v_territory.shield_until > NOW()
     AND v_defense_steps_today = 0 THEN
    v_absence_floor := 20;
  END IF;

  v_energy_to_consume := v_attacker_energy_before;
  v_captured := (v_attacker_energy_before >= v_territory_energy_before AND v_absence_floor = 0);

  IF v_captured THEN
    v_territory_energy_after := 10;
  ELSE
    v_territory_energy_after := GREATEST(v_territory_energy_before - v_attacker_energy_before, v_absence_floor);
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
      updated_at = NOW()
    WHERE id = p_territory_id;
  ELSE
    UPDATE public.territories
    SET
      energy = v_territory_energy_after,
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
  DO UPDATE
  SET cooldown_until = EXCLUDED.cooldown_until,
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
