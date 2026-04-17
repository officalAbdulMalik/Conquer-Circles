import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }
    try {
        const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
        const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
        const supabaseClient = createClient(supabaseUrl, serviceRoleKey);

        const { circle_id , user_id } = await req.json();

        if (!circle_id) {
            return new Response(JSON.stringify({ error: 'circle_id is required' }), {
                status: 400,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            });
        }

        // 1. Fetch Circle Details
        const { data: circle, error: circleError } = await supabaseClient
            .from('circles')
            .select('*')
            .eq('id', circle_id)
            .single();

        if (circleError || !circle) {
            throw new Error(`Circle not found: ${circleError?.message}`);
        }

        // 2. Fetch Members and their Profiles
        const { data: members, error: membersError } = await supabaseClient
            .from('circle_members')
            .select('user_id, role, profiles(username, xp, level, avatar_url, attack_energy)')
            .eq('circle_id', circle_id);

        if (membersError) {
            throw new Error(`Failed to fetch members: ${membersError.message}`);
        }

        const memberIds = members.map(m => m.user_id);
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        const dateStr = thirtyDaysAgo.toISOString().split('T')[0];

        // 3. Aggregate Stats in Parallel
        const [stepsRes, territoryRes, attackRes] = await Promise.all([
            // Sum steps for last 30 days
            supabaseClient
                .from('daily_steps')
                .select('user_id, steps')
                .in('user_id', memberIds)
                .gte('date', dateStr),
            
            // Count territories
            supabaseClient
                .from('territories') // or 'hex_tiles'
                .select('user_id')
                .in('user_id', memberIds),

            // Count raids won
            supabaseClient
                .from('tile_attack_log')
                .select('attacker_id')
                .in('attacker_id', memberIds)
                .eq('captured', true)
                .gte('created_at', dateStr)
        ]);

        // 4. Process Aggregations
        const stepsMap = new Map<string, number>();
        stepsRes.data?.forEach(row => {
            stepsMap.set(row.user_id, (stepsMap.get(row.user_id) || 0) + row.steps);
        });

        const territoryMap = new Map<string, number>();
        territoryRes.data?.forEach(row => {
            territoryMap.set(row.user_id, (territoryMap.get(row.user_id) || 0) + 1);
        });

        const attackMap = new Map<string, number>();
        attackRes.data?.forEach(row => {
            attackMap.set(row.attacker_id, (attackMap.get(row.attacker_id) || 0) + 1);
        });

        // 5. Build Leaderboard
        const leaderboard = members.map(m => {
            const profile = m.profiles as any;
            return {
                user_id: m.user_id,
                username: profile?.username || 'Unknown',
                avatar_url: profile?.avatar_url,
                role: m.role,
                xp: profile?.xp || 0,
                level: profile?.level || 1,
                attack_energy: profile?.attack_energy || 0,
                steps: stepsMap.get(m.user_id) || 0,
                territories: territoryMap.get(m.user_id) || 0,
                raids_won: attackMap.get(m.user_id) || 0,
            };
        });

        // Default sort by Steps then XP
        leaderboard.sort((a, b) => (b.steps - a.steps) || (b.xp - a.xp));

        return new Response(JSON.stringify({
            circle,
            leaderboard,
            metadata: {
                period_days: 30,
                last_updated: new Date().toISOString()
            }
        }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
        });

    } catch (error) {
        console.error('Error fetching circle data:', error);
        return new Response(JSON.stringify({ error: error.message }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
    }
})
