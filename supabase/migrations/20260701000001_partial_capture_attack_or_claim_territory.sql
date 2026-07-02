-- Partial territory capture.
--
-- Problem: when an attacker captured a defender's territory, the ENTIRE
-- defender polygon was transferred to the attacker (and then merged into the
-- attacker's land by merge_touching_owned_territories). The defender lost all
-- of their territory even though the attacker only walked over part of it.
--
-- Fix: the attacker now sends the polygon they covered on this walk
-- (p_attack_geom, a GeoJSON MultiPoint / LineString of the walk route). On a
-- successful capture we:
--   * take only the intersection of that covered area with the defender's
--     territory (the attacker's new piece), and
--   * leave the defender the remainder (ST_Difference) of their territory.
-- If the attacker covered (essentially) the whole territory, or no walk
-- geometry was supplied, we fall back to the previous whole-territory capture.

DROP FUNCTION IF EXISTS public.attack_or_claim_territory(uuid, uuid, double precision, double precision, double precision);

CREATE OR REPLACE FUNCTION public.attack_or_claim_territory(
  p_territory_id uuid,
  p_user_id uuid,
  p_speed_kmh double precision,
  p_lat double precision,
  p_lng double precision,
  p_attack_geom text DEFAULT NULL   -- GeoJSON MultiPoint/LineString of the attacker's walk route
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
  -- partial-capture helpers
  v_min_area CONSTANT DOUBLE PRECISION := 25;   -- m^2 threshold for a meaningful slice
  v_attack_area geometry;
  v_defender_geom geometry;
  v_overlap geometry;
  v_remainder geometry;
  v_partial BOOLEAN := FALSE;
  v_result_territory_id uuid;
  v_captured_area_m2 DOUBLE PRECISION := 0;
  v_new_territory_id uuid;
  v_attacker_session_id uuid;
  v_attacker_color TEXT;
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

  -- ── NEUTRAL: claim whole polygon (unchanged) ───────────────────────────
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

  -- ── OWN territory: reinforce (unchanged) ───────────────────────────────
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

  -- ── ENEMY territory: protection / cooldown / shield gates ──────────────
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

  -- Default: the acted-on territory is the original row.
  v_result_territory_id := p_territory_id;

  IF v_captured THEN
    SELECT p.username INTO v_defender_username
    FROM public.profiles p
    WHERE p.id = v_territory.user_id;

    -- Build the attacker's covered area as the convex hull of their walk route.
    v_attack_area := NULL;
    IF p_attack_geom IS NOT NULL THEN
      BEGIN
        v_attack_area := ST_MakeValid(
          ST_ConvexHull(ST_SetSRID(ST_GeomFromGeoJSON(p_attack_geom), 4326))
        );
        -- Only polygonal hulls can carve area (>= 3 non-collinear points).
        IF v_attack_area IS NULL
           OR GeometryType(v_attack_area) NOT IN ('POLYGON', 'MULTIPOLYGON') THEN
          v_attack_area := NULL;
        END IF;
      EXCEPTION WHEN OTHERS THEN
        v_attack_area := NULL;
      END;
    END IF;

    v_defender_geom := ST_MakeValid(v_territory.geom);

    IF v_attack_area IS NOT NULL AND NOT ST_IsEmpty(v_attack_area) THEN
      v_overlap := ST_CollectionExtract(
        ST_MakeValid(ST_Intersection(v_defender_geom, v_attack_area)), 3
      );
    ELSE
      v_overlap := NULL;
    END IF;

    IF v_overlap IS NOT NULL
       AND NOT ST_IsEmpty(v_overlap)
       AND ST_Area(v_overlap::geography) >= v_min_area THEN

      v_remainder := ST_CollectionExtract(
        ST_MakeValid(ST_Difference(v_defender_geom, v_overlap)), 3
      );

      IF v_remainder IS NULL
         OR ST_IsEmpty(v_remainder)
         OR ST_Area(v_remainder::geography) < v_min_area THEN
        -- Attacker covered essentially the whole territory: full capture.
        v_partial := FALSE;
      ELSE
        v_partial := TRUE;
      END IF;
    ELSE
      -- No walk geometry, or no meaningful overlap: full capture (legacy).
      v_partial := FALSE;
    END IF;

    IF v_partial THEN
      -- ── PARTIAL CAPTURE: defender keeps the remainder ──────────────────
      v_captured_area_m2 := ST_Area(v_overlap::geography);

      UPDATE public.territories
      SET
        geom         = ST_Multi(v_remainder)::geometry(MultiPolygon, 4326),
        area_m2      = ST_Area(v_remainder::geography),
        perimeter_m  = ST_Perimeter(v_remainder::geography),
        bbox_min_lat = ST_YMin(v_remainder),
        bbox_min_lng = ST_XMin(v_remainder),
        bbox_max_lat = ST_YMax(v_remainder),
        bbox_max_lng = ST_XMax(v_remainder),
        last_activity_time = NOW(),
        updated_at   = NOW()
      WHERE id = p_territory_id;

      -- Reuse the attacker's own most recent walking session for the new
      -- piece (falls back to the source session to satisfy the FK).
      SELECT id INTO v_attacker_session_id
      FROM public.walking_sessions
      WHERE user_id = p_user_id
      ORDER BY started_at DESC
      LIMIT 1;

      IF v_attacker_session_id IS NULL THEN
        v_attacker_session_id := v_territory.session_id;
      END IF;

      v_attacker_color := COALESCE(
        (SELECT color FROM public.territories
          WHERE user_id = p_user_id AND color IS NOT NULL
          LIMIT 1),
        '#2196F3'
      );

      INSERT INTO public.territories (
        user_id, session_id, geom, area_m2, perimeter_m,
        bbox_min_lat, bbox_min_lng, bbox_max_lat, bbox_max_lng,
        is_active, color, energy,
        capture_time, protected_until, protection_until, shield_until,
        last_activity_time, username, created_at, updated_at
      ) VALUES (
        p_user_id,
        v_attacker_session_id,
        ST_Multi(v_overlap)::geometry(MultiPolygon, 4326),
        v_captured_area_m2,
        ST_Perimeter(v_overlap::geography),
        ST_YMin(v_overlap), ST_XMin(v_overlap),
        ST_YMax(v_overlap), ST_XMax(v_overlap),
        TRUE,
        v_attacker_color,
        10,
        NOW(), NOW() + INTERVAL '12 hours', NOW() + INTERVAL '12 hours',
        NOW() + INTERVAL '24 hours',
        NOW(), v_attacker.username, NOW(), NOW()
      )
      RETURNING id INTO v_new_territory_id;

      v_result_territory_id := v_new_territory_id;
    ELSE
      -- ── FULL CAPTURE (legacy behavior) ─────────────────────────────────
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

      v_result_territory_id := p_territory_id;
    END IF;
  ELSE
    -- ── DAMAGED: energy reduced, no ownership/area change ────────────────
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
      'territory_id', v_result_territory_id,
      'source_territory_id', p_territory_id,
      'partial', v_partial,
      'captured_area_m2', ROUND(v_captured_area_m2::NUMERIC, 2),
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
$function$;
