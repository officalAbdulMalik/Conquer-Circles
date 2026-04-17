import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401 }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

    const { user_id } = await req.json();
    if (!user_id) {
      return new Response(
        JSON.stringify({ error: 'Missing user_id' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      );
    }

    const userId = user_id;

    // 1. Fetch Profile Info
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('username, avatar_url, level, xp, daily_streak, notifications_enabled, created_at')
      .eq('id', userId)
      .single();

    if (profileError) throw profileError;

    // 2. Fetch All-Time Stats
    const { data: allTimeStepsData, error: allTimeError } = await supabaseAdmin
      .from('daily_steps')
      .select('steps')
      .eq('user_id', userId);

    if (allTimeError) throw allTimeError;
    const totalSteps = (allTimeStepsData || []).reduce((acc: number, curr: { steps: number }) => acc + curr.steps, 0);

    // 3. Fetch Weekly Analytics (7 days)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 6);
    const { data: weeklyData, error: weeklyError } = await supabaseAdmin
      .from('daily_steps')
      .select('date, steps')
      .eq('user_id', userId)
      .gte('date', sevenDaysAgo.toISOString().split('T')[0])
      .order('date', { ascending: true });

    if (weeklyError) throw weeklyError;

    // 4. Fetch Monthly Analytics (30 days)
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 29);
    const { data: monthlyData, error: monthlyError } = await supabaseAdmin
      .from('daily_steps')
      .select('date, steps')
      .eq('user_id', userId)
      .gte('date', thirtyDaysAgo.toISOString().split('T')[0])
      .order('date', { ascending: true });

    if (monthlyError) throw monthlyError;

    // 5. Fetch Badges
    const { data: userBadges, error: badgesError } = await supabaseAdmin
      .from('user_badges')
      .select('badge_id, unlocked_at')
      .eq('user_id', userId)
      .order('unlocked_at', { ascending: false });

    if (badgesError) throw badgesError;

    const badges = (userBadges || []).map((ub: any) => ({
      badge_id: ub.badge_id,
      unlocked_at: ub.unlocked_at
    }));

    // Calculate calories and distance (all-time)
    const totalCalories = Math.round(totalSteps * 0.04);
    const totalDistanceKm = Number((totalSteps * 0.00073).toFixed(2));

    return new Response(
      JSON.stringify({
        profile: {
          username: profile.username,
          avatar_url: profile.avatar_url,
          level: profile.level,
          xp: profile.xp,
          daily_streak: profile.daily_streak,
          notifications_enabled: profile.notifications_enabled,
          created_at: profile.created_at
        },
        stats: {
          total_steps: totalSteps,
          total_calories: totalCalories,
          total_distance_km: totalDistanceKm
        },
        analytics: {
          weekly: weeklyData || [],
          monthly: monthlyData || []
        },
        badges: badges || []
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (error: any) {
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
