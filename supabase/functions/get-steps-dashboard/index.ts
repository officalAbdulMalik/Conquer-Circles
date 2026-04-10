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
    const supabase = createClient(
      "https://nnbqgqjduvjnhqgqjduv.supabase.co",
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5uYnFncWpkdXZqbmhxZ3FqZHV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM0MTg1NjYsImV4cCI6MjA1OTk5NDU2Nn0.b_08208z8s9k8s9k8s9k8s9k8s9k8s9k8s9k8s9k8",
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );

    // Get current user
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) throw new Error("Unauthorized");

    const userId = user.id;
    const today = new Date().toISOString().split('T')[0];

    // 1. Fetch Profile Info
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('username, level, xp, xp_goal, step_goal, daily_streak, attack_energy')
      .eq('id', userId)
      .single();

    if (profileError) throw profileError;

    // 2. Fetch Today's Steps
    const { data: stepsData, error: stepsError } = await supabase
      .from('daily_steps')
      .select('steps')
      .eq('user_id', userId)
      .eq('date', today)
      .maybeSingle();

    if (stepsError) throw stepsError;
    const steps = stepsData?.steps || 0;

    // 3. Fetch Weekly Steps (for charts)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 6);
    const { data: weeklyData, error: weeklyError } = await supabase
      .from('daily_steps')
      .select('date, steps')
      .eq('user_id', userId)
      .gte('date', sevenDaysAgo.toISOString().split('T')[0])
      .order('date', { ascending: true });

    if (weeklyError) throw weeklyError;

    // 4. Fetch Badges
    const { data: badges, error: badgesError } = await supabase
      .from('user_badges')
      .select('badge_id, unlocked_at')
      .eq('user_id', userId);

    if (badgesError) throw badgesError;

    // Calculate calories and distance (Conversion logic moved to backend)
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
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }
});
