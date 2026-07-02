-- Fix decay_stale_territories so counts are computed in scope and tiles that
-- decay to zero are neutralized in the same UPDATE.

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
        energy - (
          GREATEST(
            FLOOR(EXTRACT(EPOCH FROM NOW() - COALESCE(last_activity_time, capture_time, created_at)) / 86400) - 3,
            0
          ) * 2
        ),
        0
      ) AS energy_after_decay
    FROM public.territories
    WHERE COALESCE(last_activity_time, capture_time, created_at) <= NOW() - INTERVAL '3 days'
      AND energy > 0
  ), updated AS (
    UPDATE public.territories t
    SET energy = s.energy_after_decay,
        user_id = CASE WHEN s.energy_after_decay <= 0 THEN NULL ELSE t.user_id END,
        capture_time = CASE WHEN s.energy_after_decay <= 0 THEN NULL ELSE t.capture_time END,
        protected_until = CASE WHEN s.energy_after_decay <= 0 THEN NULL ELSE t.protected_until END,
        protection_until = CASE WHEN s.energy_after_decay <= 0 THEN NULL ELSE t.protection_until END,
        shield_until = CASE WHEN s.energy_after_decay <= 0 THEN NULL ELSE t.shield_until END,
        last_activity_time = CASE WHEN s.energy_after_decay <= 0 THEN NULL ELSE t.last_activity_time END,
        updated_at = NOW()
    FROM stale s
    WHERE t.id = s.id
    RETURNING t.id, t.energy, (s.energy_after_decay <= 0) AS neutralized
  )
  SELECT
    (SELECT COUNT(*) FROM updated),
    (SELECT COUNT(*) FROM updated WHERE neutralized)
  INTO v_updated, v_neutralized;

  RETURN jsonb_build_object(
    'updated_territories', v_updated,
    'neutralized_territories', v_neutralized
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.decay_stale_territories() TO authenticated;
