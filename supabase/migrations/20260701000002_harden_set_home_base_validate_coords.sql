-- Harden set_home_base against the "cooldown started but no location saved"
-- trap.
--
-- Bug: the previous version set home_base_set_at = NOW() (starting the 30-day
-- change cooldown) even when p_lat / p_lng were null or invalid. That left the
-- profile with a cooldown but no coordinates, so the app saw "no home base"
-- (and kept showing the setup sheet) while re-setting it was blocked by the
-- 30-day rule.
--
-- Fix:
--   * Reject null / out-of-range coordinates before writing anything.
--   * Only enforce the 30-day cooldown when a REAL home base (with
--     coordinates) is already set.

CREATE OR REPLACE FUNCTION public.set_home_base(p_user_id uuid, p_lat double precision, p_lng double precision)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_last_set TIMESTAMPTZ;
  v_has_home_base BOOLEAN;
BEGIN
  IF p_lat IS NULL OR p_lng IS NULL
     OR p_lat <  -90 OR p_lat >  90
     OR p_lng < -180 OR p_lng > 180 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error',   'Invalid home base coordinates'
    );
  END IF;

  SELECT
    home_base_set_at,
    (home_base_lat IS NOT NULL AND home_base_lng IS NOT NULL)
  INTO v_last_set, v_has_home_base
  FROM profiles
  WHERE id = p_user_id;

  IF v_last_set IS NOT NULL
     AND v_has_home_base
     AND v_last_set > NOW() - INTERVAL '30 days' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error',   'Home base can only be changed once every 30 days',
      'next_change_at', v_last_set + INTERVAL '30 days'
    );
  END IF;

  UPDATE profiles
     SET home_base_lat    = p_lat,
         home_base_lng    = p_lng,
         home_base_set_at = NOW()
   WHERE id = p_user_id;

  RETURN jsonb_build_object('success', true, 'lat', p_lat, 'lng', p_lng);
END;
$function$;

-- Repair any already-corrupted rows: a cooldown with no coordinates is not a
-- real home base, so clear the timestamp to unblock those users.
UPDATE public.profiles
SET home_base_set_at = NULL
WHERE home_base_set_at IS NOT NULL
  AND (home_base_lat IS NULL OR home_base_lng IS NULL);
