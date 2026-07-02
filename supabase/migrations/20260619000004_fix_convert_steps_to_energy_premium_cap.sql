-- Align step-to-energy premium cap with the profile fields used by the app.
-- Premium users receive a 600 daily attack-energy cap; free users receive 400.

CREATE OR REPLACE FUNCTION public.convert_steps_to_energy(
  p_user_id UUID,
  p_steps_today INTEGER
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_energy INT := 0;
  v_premium_tier INT := 0;
  v_is_premium BOOLEAN := FALSE;
  v_has_season_pass BOOLEAN := FALSE;
  v_cap INT;
  v_new_energy INT;
  v_gained INT;
BEGIN
  SELECT
    COALESCE(attack_energy, 0),
    COALESCE(premium_tier, 0),
    COALESCE(is_premium, FALSE),
    COALESCE(has_season_pass, FALSE)
  INTO v_current_energy, v_premium_tier, v_is_premium, v_has_season_pass
  FROM public.profiles
  WHERE id = p_user_id;

  v_cap := CASE
    WHEN v_is_premium OR v_has_season_pass OR v_premium_tier >= 1 THEN 600
    ELSE 400
  END;
  v_new_energy := LEAST(FLOOR(GREATEST(p_steps_today, 0) / 100.0)::INT, v_cap);
  v_gained := GREATEST(v_new_energy - v_current_energy, 0);

  IF v_gained > 0 THEN
    UPDATE public.profiles
    SET attack_energy = v_new_energy,
        last_active_at = NOW()
    WHERE id = p_user_id;

    INSERT INTO public.energy_log (user_id, delta, reason)
    VALUES (p_user_id, v_gained, 'steps');
  END IF;

  IF v_new_energy >= v_cap THEN
    PERFORM public.award_badge(
      p_user_id,
      'energy_hoarder',
      jsonb_build_object('energy', v_new_energy, 'cap', v_cap)
    );
  END IF;

  RETURN jsonb_build_object(
    'attack_energy', v_new_energy,
    'gained', v_gained,
    'cap', v_cap
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.convert_steps_to_energy(UUID, INTEGER)
TO authenticated;
