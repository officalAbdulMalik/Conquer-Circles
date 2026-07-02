-- ─────────────────────────────────────────────────────────────────────────────
-- Dissolve territory clusters into single territories.
--
-- Problem: when one player claims multiple touching territories, the map
-- showed each claim with its own border. Three root causes:
--   1. merge_touching_owned_territories used ST_UnaryUnion, which does NOT
--      dissolve polygons that merely touch or sit within the tolerance gap —
--      they stay as separate parts of a MultiPolygon.
--   2. The merge was not transitive: only rows touching the just-claimed
--      polygon merged, so chains (A–B–C) never fully collapsed.
--   3. get_territories_nearby flattened geometry with ST_DumpPoints, losing
--      ring/part structure, so the client couldn't draw merged shapes.
--
-- Fix:
--   • dissolve_owned_territory_cluster(): transitive cluster collection +
--     buffer-out/in (geography, metres) "morphological closing" that welds
--     touching/near-touching parts into one clean outer boundary.
--   • merge_touching_owned_territories(): same public signature as before,
--     now delegates to the dissolver (app code unchanged).
--   • get_territories_nearby(): adds a `geojson` column with the full,
--     ring-structured geometry; polygon_points becomes the exterior ring of
--     the largest part (sane legacy behaviour instead of a flat point dump).
--   • One-time data fix: dissolves every existing owner cluster.
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Internal dissolver (not callable by clients).
CREATE OR REPLACE FUNCTION public.dissolve_owned_territory_cluster(
  p_user_id uuid,
  p_territory_id uuid,
  p_tolerance_m double precision DEFAULT 2
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_tolerance double precision := GREATEST(COALESCE(p_tolerance_m, 2), 0.5);
  v_cluster_ids uuid[];
  v_new_ids uuid[];
  v_secondary_ids uuid[];
  v_target_id uuid;
  v_merged geometry;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.territories
    WHERE id = p_territory_id AND user_id = p_user_id
  ) THEN
    RETURN jsonb_build_object('success', FALSE, 'error', 'Owned territory not found');
  END IF;

  -- Transitive closure: keep absorbing owned territories within tolerance of
  -- ANY current cluster member until the cluster stops growing.
  v_cluster_ids := ARRAY[p_territory_id];
  LOOP
    SELECT ARRAY_AGG(t.id)
    INTO v_new_ids
    FROM public.territories t
    WHERE t.user_id = p_user_id
      AND NOT (t.id = ANY(v_cluster_ids))
      AND EXISTS (
        SELECT 1
        FROM public.territories c
        WHERE c.id = ANY(v_cluster_ids)
          AND ST_DWithin(t.geom::geography, c.geom::geography, v_tolerance)
      );
    EXIT WHEN v_new_ids IS NULL OR COALESCE(array_length(v_new_ids, 1), 0) = 0;
    v_cluster_ids := v_cluster_ids || v_new_ids;
  END LOOP;

  IF COALESCE(array_length(v_cluster_ids, 1), 0) <= 1 THEN
    RETURN jsonb_build_object(
      'success', TRUE,
      'action', 'separate',
      'territory_id', p_territory_id
    );
  END IF;

  PERFORM 1 FROM public.territories WHERE id = ANY(v_cluster_ids) FOR UPDATE;

  -- Dissolve: union, then buffer out/in (metres) to weld near-touching parts
  -- and erase internal borders, leaving one outer boundary per landmass.
  SELECT ST_Multi(
    ST_CollectionExtract(
      ST_MakeValid(
        ST_Buffer(
          ST_Buffer(ST_UnaryUnion(ST_Collect(geom))::geography, v_tolerance),
          -v_tolerance
        )::geometry
      ),
      3
    )
  )::geometry(MultiPolygon, 4326)
  INTO v_merged
  FROM public.territories
  WHERE id = ANY(v_cluster_ids);

  -- Defensive fallback: never lose land if the closing op yields nothing.
  IF v_merged IS NULL OR ST_IsEmpty(v_merged) THEN
    SELECT ST_Multi(ST_UnaryUnion(ST_Collect(geom)))::geometry(MultiPolygon, 4326)
    INTO v_merged
    FROM public.territories
    WHERE id = ANY(v_cluster_ids);
  END IF;

  SELECT id INTO v_target_id
  FROM public.territories
  WHERE id = ANY(v_cluster_ids)
  ORDER BY created_at, id
  LIMIT 1;

  SELECT ARRAY_AGG(id) INTO v_secondary_ids
  FROM public.territories
  WHERE id = ANY(v_cluster_ids) AND id <> v_target_id;

  UPDATE public.territories
  SET
    geom = v_merged,
    area_m2 = ST_Area(v_merged::geography),
    perimeter_m = ST_Perimeter(v_merged::geography),
    energy = LEAST(
      60,
      (SELECT COALESCE(SUM(energy), 0) FROM public.territories WHERE id = ANY(v_cluster_ids))
    ),
    protection_until = (SELECT MAX(protection_until) FROM public.territories WHERE id = ANY(v_cluster_ids)),
    protected_until = (SELECT MAX(protected_until) FROM public.territories WHERE id = ANY(v_cluster_ids)),
    shield_until = (SELECT MAX(shield_until) FROM public.territories WHERE id = ANY(v_cluster_ids)),
    last_activity_time = NOW(),
    updated_at = NOW()
  WHERE id = v_target_id;

  UPDATE public.territory_attack_log
  SET territory_id = v_target_id
  WHERE territory_id = ANY(v_secondary_ids);

  DELETE FROM public.territory_attack_cooldowns
  WHERE territory_id = ANY(v_secondary_ids);

  DELETE FROM public.territories
  WHERE id = ANY(v_secondary_ids);

  RETURN jsonb_build_object(
    'success', TRUE,
    'action', 'expanded',
    'territory_id', v_target_id,
    'merged_count', array_length(v_cluster_ids, 1)
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.dissolve_owned_territory_cluster(uuid, uuid, double precision)
  FROM PUBLIC, anon, authenticated;

-- 2. Public RPC keeps its exact signature; now transitive + dissolving.
CREATE OR REPLACE FUNCTION public.merge_touching_owned_territories(
  p_territory_id uuid,
  p_touch_tolerance_m double precision DEFAULT 2
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', FALSE, 'error', 'Not signed in');
  END IF;
  RETURN public.dissolve_owned_territory_cluster(v_user_id, p_territory_id, p_touch_tolerance_m);
END;
$function$;

-- 3. Nearby territories now return ring-structured GeoJSON. The return table
--    gains a column, so the old function must be dropped first.
DROP FUNCTION IF EXISTS public.get_territories_nearby(double precision, double precision, double precision);

CREATE FUNCTION public.get_territories_nearby(
  p_lat double precision,
  p_lng double precision,
  p_radius_m double precision DEFAULT 5000
)
RETURNS TABLE(
  id uuid,
  user_id uuid,
  username text,
  color text,
  energy integer,
  polygon_points jsonb,
  geojson jsonb,
  centroid jsonb,
  capture_time timestamp with time zone,
  last_activity_time timestamp with time zone,
  protected_until timestamp with time zone,
  shield_until timestamp with time zone,
  cooldown_until timestamp with time zone
)
LANGUAGE plpgsql
STABLE
AS $function$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    t.id,
    t.user_id,
    COALESCE(p.username, t.username) AS username,
    t.color,
    t.energy,
    -- Legacy field: exterior ring of the largest part (kept for widgets that
    -- still read a flat point list — no longer a broken multi-ring dump).
    (
      SELECT jsonb_agg(
        jsonb_build_object('lat', ST_Y((dp).geom), 'lng', ST_X((dp).geom))
      )
      FROM ST_DumpPoints(
        ST_ExteriorRing(
          (
            SELECT (d).geom
            FROM ST_Dump(t.geom) AS d
            ORDER BY ST_Area((d).geom) DESC
            LIMIT 1
          )
        )
      ) AS dp
    ) AS polygon_points,
    -- Full ring/part structure for correct rendering (holes, multiparts).
    ST_AsGeoJSON(t.geom)::jsonb AS geojson,
    jsonb_build_object(
      'lat', ST_Y(ST_Centroid(t.geom)),
      'lng', ST_X(ST_Centroid(t.geom))
    ) AS centroid,
    t.capture_time,
    t.last_activity_time,
    COALESCE(t.protected_until, t.protection_until) AS protected_until,
    t.shield_until,
    tac.cooldown_until
  FROM public.territories t
  LEFT JOIN public.profiles p ON p.id = t.user_id
  LEFT JOIN public.territory_attack_cooldowns tac ON (
    tac.attacker_id = v_user_id
    AND tac.territory_id = t.id
    AND tac.cooldown_until > NOW()
  )
  WHERE ST_DWithin(
    t.geom::geography,
    ST_MakePoint(p_lng, p_lat)::geography,
    p_radius_m
  )
  ORDER BY ST_Distance(
    t.geom::geography,
    ST_MakePoint(p_lng, p_lat)::geography
  );
END;
$function$;

GRANT EXECUTE ON FUNCTION public.get_territories_nearby(double precision, double precision, double precision)
  TO authenticated, service_role;

-- 4. One-time data fix: dissolve every existing cluster, per owner.
DO $do$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT t.id, t.user_id FROM public.territories t ORDER BY t.created_at, t.id
  LOOP
    -- Row may already have been absorbed by an earlier iteration.
    IF EXISTS (SELECT 1 FROM public.territories WHERE public.territories.id = r.id) THEN
      PERFORM public.dissolve_owned_territory_cluster(r.user_id, r.id, 2);
    END IF;
  END LOOP;
END;
$do$;
