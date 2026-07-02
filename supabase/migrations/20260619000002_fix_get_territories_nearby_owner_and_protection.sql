-- Return live owner/profile and protection data from map-load RPC.
-- The attack_or_claim_territory RPC updates territories.user_id and
-- territories.protected_until; the map loader must reflect those fields.

CREATE OR REPLACE FUNCTION public.get_territories_nearby(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_radius_m DOUBLE PRECISION DEFAULT 5000
)
RETURNS TABLE(
  id UUID,
  user_id UUID,
  username TEXT,
  color TEXT,
  energy INTEGER,
  polygon_points JSONB,
  centroid JSONB,
  capture_time TIMESTAMPTZ,
  last_activity_time TIMESTAMPTZ,
  protected_until TIMESTAMPTZ,
  shield_until TIMESTAMPTZ,
  cooldown_until TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
AS $$
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
    (
      SELECT jsonb_agg(
        jsonb_build_object('lat', ST_Y((dp).geom), 'lng', ST_X((dp).geom))
      )
      FROM ST_DumpPoints(t.geom) AS dp
    ) AS polygon_points,
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
$$;

GRANT EXECUTE ON FUNCTION public.get_territories_nearby(
  DOUBLE PRECISION,
  DOUBLE PRECISION,
  DOUBLE PRECISION
) TO authenticated;
