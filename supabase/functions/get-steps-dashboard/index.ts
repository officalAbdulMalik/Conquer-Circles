import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

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

    // Get request body
    const { user_id } = await req.json();
    
    if (!user_id) {
      return new Response(
        JSON.stringify({ error: 'Missing user_id' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        }
      );
    }

    const userId = user_id;
    const today = new Date().toISOString().split('T')[0];

    // 1. Fetch Profile Info
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('username, level, xp, xp_goal, step_goal, daily_streak, attack_energy')
      .eq('id', userId)
      .single();

    if (profileError) {
      console.error('Profile error:', profileError);
      throw profileError;
    }

    // 2. Fetch Today's Steps
    const { data: stepsData, error: stepsError } = await supabaseAdmin
      .from('daily_steps')
      .select('steps')
      .eq('user_id', userId)
      .eq('date', today)
      .maybeSingle();

    if (stepsError) {
      console.error('Steps error:', stepsError);
      throw stepsError;
    }
    const steps = stepsData?.steps || 0;

    // 3. Fetch Weekly Steps (for charts)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 6);
    const { data: weeklyData, error: weeklyError } = await supabaseAdmin
      .from('daily_steps')
      .select('date, steps')
      .eq('user_id', userId)
      .gte('date', sevenDaysAgo.toISOString().split('T')[0])
      .order('date', { ascending: true });

    if (weeklyError) {
      console.error('Weekly error:', weeklyError);
      throw weeklyError;
    }

    // 4. Fetch Badges (enriched with metadata)
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

    if (badgesError) {
      console.error('Badges error:', badgesError);
      throw badgesError;
    }

    // Flatten the join result to make it cleaner for the frontend
    const badges = (userBadges || []).map((ub: any) => ({
      ...ub.badge,
      unlocked_at: ub.unlocked_at
    }));

    // Calculate calories and distance
    const calories = Math.round(steps * 0.04);
    const distanceKm = Number((steps * 0.00073).toFixed(2));

    return new Response(
      JSON.stringify({
        profile: {
          username: profile.username,
          level: profile.level,
          xp: profile.xp,
          xp_goal: profile.xp_goal,
          step_goal: profile.step_goal,
          streak: profile.daily_streak,
          attack_energy: profile.attack_energy
        },
        today: {
          steps: steps,
          calories: calories,
          distance_km: distanceKm
        },
        weekly_steps: weeklyData || [],
        badges: badges || []
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
