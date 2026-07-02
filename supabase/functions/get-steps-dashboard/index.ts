import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function readNumber(source: Record<string, unknown> | null | undefined, keys: string[], fallback = 0) {
  for (const key of keys) {
    const value = source?.[key];
    if (typeof value === 'number' && Number.isFinite(value)) return value;
    if (typeof value === 'boolean') return value ? 1 : 0;
    if (typeof value === 'string') {
      const parsed = Number(value);
      if (Number.isFinite(parsed)) return parsed;
    }
  }
  return fallback;
}

function readString(source: Record<string, unknown> | null | undefined, keys: string[], fallback = '') {
  for (const key of keys) {
    const value = source?.[key];
    if (typeof value === 'string' && value.trim().length > 0) return value.trim();
  }
  return fallback;
}

function roundTo(value: number, fractionDigits: number) {
  return Number(value.toFixed(fractionDigits));
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Get the authorization header
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401,
        }
      );
    }

    // Create admin client with service role key from environment
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!serviceRoleKey) {
      return new Response(
        JSON.stringify({ error: 'Service role key not configured' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 500,
        }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    if (!supabaseUrl) {
      return new Response(
        JSON.stringify({ error: 'SUPABASE_URL not configured' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 500,
        }
      );
    }

    const supabaseAdmin = createClient(
      supabaseUrl,
      serviceRoleKey,
    );

    const accessToken = authHeader.replace(/^Bearer\s+/i, '').trim();
    const { data: authData, error: authError } = await supabaseAdmin.auth.getUser(accessToken);
    if (authError || !authData.user) {
      return new Response(
        JSON.stringify({ error: 'Invalid authorization token' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401,
        }
      );
    }

    const userId = authData.user.id;
    const today = new Date().toISOString().split('T')[0];

    // 1. Fetch Profile Info. Use select('*') so the function follows the
    // currently deployed Supabase schema instead of assuming every optional
    // gamification column exists.
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .maybeSingle();

    if (profileError) {
      console.error('Profile error:', profileError);
      throw profileError;
    }

    // 2. Fetch Today's Steps
    const { data: stepsData, error: stepsError } = await supabaseAdmin
      .from('daily_steps')
      .select('*')
      .eq('user_id', userId)
      .eq('date', today)
      .maybeSingle();

    if (stepsError) {
      console.error('Steps error:', stepsError);
      throw stepsError;
    }
    const steps = Math.round(readNumber(stepsData, ['steps', 'step_count', 'total_steps']));

    // 3. Fetch Weekly Steps (for charts)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 6);
    const { data: weeklyData, error: weeklyError } = await supabaseAdmin
      .from('daily_steps')
      .select('*')
      .eq('user_id', userId)
      .gte('date', sevenDaysAgo.toISOString().split('T')[0])
      .order('date', { ascending: true });

    if (weeklyError) {
      console.error('Weekly error:', weeklyError);
      throw weeklyError;
    }

    // 4. Fetch Badges (enriched with metadata when the relationship exists).
    const { data: userBadges, error: badgesError } = await supabaseAdmin
      .from('user_badges')
      .select(`
        unlocked_at,
        badge:badges (
          id,
          name,
          description,
          category,
          rarity,
          icon_url
        )
      `)
      .eq('user_id', userId)
      .order('unlocked_at', { ascending: false });

    let badges: Record<string, unknown>[] = [];
    if (badgesError) {
      console.error('Badges error:', badgesError);
      const { data: fallbackBadges, error: fallbackBadgesError } = await supabaseAdmin
        .from('user_badges')
        .select('*')
        .eq('user_id', userId)
        .order('unlocked_at', { ascending: false });

      if (fallbackBadgesError) {
        console.error('Fallback badges error:', fallbackBadgesError);
      } else {
        badges = (fallbackBadges || []).map((ub: any) => ({
          id: ub.badge_id || ub.id,
          badge_id: ub.badge_id,
          unlocked_at: ub.unlocked_at,
        }));
      }
    } else {
      badges = (userBadges || []).map((ub: any) => ({
        ...(ub.badge || {}),
        id: ub.badge?.id || ub.badge_id,
        badge_id: ub.badge_id,
        unlocked_at: ub.unlocked_at,
      }));
    }

    // 5. Optional territory totals from the live schema. If territories is not
    // available in this project, the home page still gets stable zeroes.
    const { data: territories, error: territoriesError } = await supabaseAdmin
      .from('territories')
      .select('*')
      .eq('user_id', userId);

    if (territoriesError) {
      console.error('Territories error:', territoriesError);
    }

    const territoryRows = territoriesError ? [] : (territories || []);
    const storedAreaKm2 = territoryRows.reduce((sum: number, row: any) => {
      const km2 = readNumber(row, ['area_km2', 'total_area_km2', 'captured_area_km2']);
      if (km2 > 0) return sum + km2;
      const m2 = readNumber(row, ['area_m2', 'total_area_m2', 'captured_area_m2']);
      return sum + (m2 > 0 ? m2 / 1000000 : 0);
    }, 0);

    // 6. Recent territory activity involving the current user.
    const { data: territoryHistoryData, error: territoryHistoryError } = await supabaseAdmin
      .from('territory_attack_log')
      .select(`
        id,
        territory_id,
        attacker_id,
        defender_id,
        energy_used,
        energy_before,
        energy_after,
        captured,
        created_at
      `)
      .or(`attacker_id.eq.${userId},defender_id.eq.${userId}`)
      .order('created_at', { ascending: false })
      .limit(20);

    if (territoryHistoryError) {
      console.error('Territory history error:', territoryHistoryError);
    }

    const territoryHistory = (territoryHistoryError ? [] : (territoryHistoryData || []))
      .map((row: any) => ({
        ...row,
        action: row.captured
          ? 'captured'
          : row.defender_id == null
          ? 'claimed'
          : readNumber(row, ['energy_after']) > readNumber(row, ['energy_before'])
          ? 'reinforced'
          : 'damaged',
        is_defence: row.defender_id === userId && row.attacker_id !== userId,
      }));

    // Prefer measured columns from daily_steps when the live table has them;
    // otherwise derive lightweight estimates from step count.
    const calories = Math.round(
      readNumber(stepsData, ['calories', 'kcal', 'calories_burned'], steps * 0.04),
    );
    const distanceKm = roundTo(
      readNumber(stepsData, ['distance_km', 'total_distance_km'], steps * 0.00073),
      2,
    );
    const durationSeconds = Math.round(readNumber(
      stepsData,
      ['duration_seconds', 'active_seconds', 'walking_seconds'],
      steps <= 0
      ? 0
      : (Math.max(1, Math.round(steps / 1160)) * 60) + 39,
    ));
    const totalAreaKm2 = roundTo(
      readNumber(stepsData, ['total_area_km2', 'captured_area_km2'], storedAreaKm2),
      1,
    );
    const heartRate = readNumber(stepsData, ['heart_rate', 'avg_heart_rate'], 0);
    const attackEnergy = Math.round(readNumber(profile, ['attack_energy', 'energy']));
    const energyCap = Math.round(
      readNumber(profile, ['attack_energy_cap', 'energy_cap'], readNumber(profile, ['is_premium']) ? 600 : 400),
    );

    return new Response(
      JSON.stringify({
        profile: {
          username: readString(profile, ['username', 'full_name', 'display_name'], 'User'),
          level: Math.round(readNumber(profile, ['level', 'current_level'], 1)),
          xp: Math.round(readNumber(profile, ['xp', 'current_xp'])),
          xp_goal: Math.round(readNumber(profile, ['xp_goal', 'xp_target'], 1000)),
          step_goal: Math.round(readNumber(profile, ['step_goal', 'daily_steps_goal'], 10000)),
          streak: Math.round(readNumber(profile, ['daily_streak', 'streak', 'weekly_streak'])),
          attack_energy: attackEnergy,
          attack_energy_cap: energyCap,
          territory_count: territoryRows.length,
        },
        today: {
          steps: steps,
          calories: calories,
          distance_km: distanceKm,
          duration_seconds: durationSeconds,
          total_area_km2: totalAreaKm2,
          heart_rate: heartRate > 0 ? Math.round(heartRate) : null
        },
        weekly_steps: (weeklyData || []).map((row: any) => ({
          ...row,
          steps: Math.round(readNumber(row, ['steps', 'step_count', 'total_steps'])),
        })),
        badges: badges || [],
        territory_history: territoryHistory
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (error) {
    console.error('Error:', error);
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
});
