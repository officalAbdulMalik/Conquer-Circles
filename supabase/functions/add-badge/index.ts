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

        const supabaseClient = createClient(
            "https://dpvelnjzovjhxgpjvtay.supabase.co",
            serviceRoleKey,
        );


        const { user_id, event_type, payload } = await req.json()

        if (!user_id || !event_type) {
            throw new Error('user_id and event_type are required')
        }

        const newlyAwardedBadges: string[] = []
        const alreadyOwnedBadges: string[] = []
        const errors: string[] = []

        /**
         * Helper to award a badge if not already owned.
         */
        async function awardBadge(badgeId: string) {
            console.log(`Checking badge "${badgeId}" for user ${user_id}...`)
            const { data: existing, error: fetchError } = await supabaseClient
                .from('user_badges')
                .select('id')
                .eq('user_id', user_id)
                .eq('badge_id', badgeId)
                .maybeSingle()

            if (fetchError) {
                console.error(`Error checking badge ${badgeId}:`, fetchError)
                errors.push(`Failed to check badge ${badgeId}: ${fetchError.message}`)
                return
            }

            if (existing) {
                console.log(`User already has badge: ${badgeId}`)
                alreadyOwnedBadges.push(badgeId)
                return
            }

            const { error: insertError } = await supabaseClient
                .from('user_badges')
                .insert({ user_id, badge_id: badgeId })

            if (insertError) {
                console.error(`Error awarding badge ${badgeId}:`, insertError)
                errors.push(`Failed to award badge ${badgeId}: ${insertError.message}`)
            } else {
                newlyAwardedBadges.push(badgeId)
                console.log(`Badge awarded successfully: ${badgeId} to user ${user_id}`)
                
                // Send push notification
                try {
                    await sendBadgeNotification(user_id, badgeId);
                } catch (notifyError) {
                    console.error('Error triggering push notification:', notifyError);
                }
            }
        }

        function getBadgeTitle(id: string): string {
            const titles: Record<string, string> = {
                'step_rookie': 'Step Rookie',
                'daily_grinder': 'Daily Grinder',
                'marathon_walker': 'Marathon Walker',
                'territory_pioneer': 'Territory Pioneer',
                'territory_builder': 'Territory Builder',
                'expansion_master': 'Expansion Master',
                'raid_initiator': 'Raid Initiator',
                'raid_champion': 'Raid Champion',
                'raid_destroyer': 'Raid Destroyer',
                'defense_architect': 'Defense Architect',
                'fortress_master': 'Fortress Master',
                'cluster_creator': 'Cluster Creator',
                'territory_emperor': 'Territory Emperor',
                'comeback_king': 'Comeback King',
                'early_bird': 'Early Bird',
                'night_walker': 'Night Walker',
                'consistency_hero': 'Consistency Hero',
                'energy_hoarder': 'Energy Hoarder',
                'war_hero': 'War Hero',
                'expansion_legend': 'Expansion Legend',
                'defender': 'Defender',
                'rival_slayer': 'Rival Slayer',
                'territory_guardian': 'Territory Guardian',
                'park_explorer': 'Park Explorer',
                'street_king': 'Street King',
                'strategic_raider': 'Strategic Raider',
                'weekend_warrior': 'Weekend Warrior',
                'circle_champion': 'Circle Champion',
                'grand_conqueror': 'Grand Conqueror',
                'season_legend': 'Season Legend',
            };
            return titles[id] || 'Achievement Unlocked';
        }

        async function sendBadgeNotification(userId: string, badgeId: string) {
            const badgeTitle = getBadgeTitle(badgeId);
            const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
            
            console.log(`Triggering notification for user ${userId}, badge: ${badgeTitle}`);
            
            const response = await fetch(
                `${supabaseUrl}/functions/v1/send-push-notification`,
                {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${serviceRoleKey}`,
                    },
                    body: JSON.stringify({
                        user_id: userId,
                        title: 'New Badge Unlocked! 🏆',
                        body: `You've earned the ${badgeTitle} badge!`,
                        type: 'award'
                    }),
                }
            );

            if (!response.ok) {
                const errorData = await response.text();
                throw new Error(`Notification bridge error (${response.status}): ${errorData}`);
            }
            
            console.log(`Notification sent successfully for badge ${badgeId}`);
        }

        const todayStr = new Date().toISOString().split('T')[0]

        // === EVENT HANDLERS ===

        if (event_type === 'walking_session_complete') {
            // 👟 Step Rookie
            const { data: stepsEntry } = await supabaseClient
                .from('daily_steps')
                .select('steps')
                .eq('user_id', user_id)
                .eq('date', todayStr)
                .maybeSingle()
            if (stepsEntry && stepsEntry.steps >= 5000) await awardBadge('rookie')

            // 🏃 Marathon Walker
            const { data: profile } = await supabaseClient
                .from('profiles')
                .select('total_distance_m, daily_streak')
                .eq('id', user_id)
                .single()
            if (profile?.total_distance_m >= 42000) await awardBadge('marathon_walker')

            // 🔥 Daily Grinder
            const { data: isGrinder } = await supabaseClient.rpc('check_consecutive_steps', {
                p_user_id: user_id,
                p_threshold: 10000,
                p_days: 5
            })
            if (isGrinder) await awardBadge('daily_grinder')

            // 📅 Consistency Hero
            if (profile?.daily_streak >= 14) await awardBadge('consistency_hero')

            // 💪 Weekend Warrior
            const { data: weekendSum } = await supabaseClient.rpc('get_weekend_steps_sum', {
                p_user_id: user_id
            })
            if (weekendSum >= 20000) await awardBadge('weekend_warrior')

            // 🌅 Early Bird
            const { data: isEarlyBird } = await supabaseClient.rpc('check_early_bird_sessions', {
                p_user_id: user_id,
                p_threshold_hour: 7,
                p_days: 7
            })
            if (isEarlyBird) await awardBadge('early_bird')

            // 🌙 Night Walker
            const { data: isNightWalker } = await supabaseClient.rpc('check_night_walker_sessions', {
                p_user_id: user_id,
                p_threshold_hour: 22,
                p_days: 5
            })
            if (isNightWalker) await awardBadge('night_walker')
        }

        if (event_type === 'steps_synced') {
            // ⚡ Energy Hoarder
            if (payload?.is_at_cap) {
                await awardBadge('energy_hoarder')
            }
        }

        if (event_type === 'tile_captured' || event_type === 'tile_reinforced') {
            // 🗺️ Territory Pioneer / Builder / Expansion Master / Emperor
            const { count: tileCount } = await supabaseClient
                .from('hex_tiles') // or 'territories' depending on implementation
                .select('*', { count: 'exact', head: true })
                .eq('owner_id', user_id)

            if (tileCount >= 10) await awardBadge('territory_pioneer')
            if (tileCount >= 25) await awardBadge('territory_emperor')
            if (tileCount >= 50) await awardBadge('territory_builder')
            if (tileCount >= 100) await awardBadge('expansion_master')

            // 🔗 Cluster Creator
            const { data: cluster } = await supabaseClient
                .from('tile_clusters')
                .select('tile_count')
                .eq('owner_id', user_id)
                .gte('tile_count', 7)
                .maybeSingle()
            if (cluster) await awardBadge('cluster_creator')

            // 🚀 Expansion Legend
            const { count: todayCaptures } = await supabaseClient
                .from('tile_attack_log')
                .select('*', { count: 'exact', head: true })
                .eq('attacker_id', user_id)
                .eq('captured', true)
                .gte('created_at', todayStr)
            if (todayCaptures >= 10) await awardBadge('expansion_legend')

            // 🌳 Park Explorer
            const { count: parkCount } = await supabaseClient
                .from('hex_tiles')
                .select('*', { count: 'exact', head: true })
                .eq('owner_id', user_id)
                .eq('tile_type', 'park')
            if (parkCount >= 5) await awardBadge('park_explorer')

            // ⚔️ Raid Badges
            if (event_type === 'tile_captured') {
                const { count: totalRaids } = await supabaseClient
                    .from('tile_attack_log')
                    .select('*', { count: 'exact', head: true })
                    .eq('attacker_id', user_id)
                if (totalRaids === 1) await awardBadge('raid_initiator')

                const { data: userProfile } = await supabaseClient
                    .from('profiles')
                    .select('total_raids_won')
                    .eq('id', user_id)
                    .single()
                if (userProfile?.total_raids_won >= 10) await awardBadge('raid_champion')
                if (userProfile?.total_raids_won >= 25) await awardBadge('raid_destroyer')

                // 🗡️ Rival Slayer
                if (payload?.defender_id) {
                    const { count: rivalCaptures } = await supabaseClient
                        .from('tile_attack_log')
                        .select('*', { count: 'exact', head: true })
                        .eq('attacker_id', user_id)
                        .eq('defender_id', payload.defender_id)
                        .eq('captured', true)
                    if (rivalCaptures >= 5) await awardBadge('rival_slayer')
                }

                // 🎯 Strategic Raider
                if (payload?.attack_power === payload?.target_energy) {
                    await awardBadge('strategic_raider')
                }
            }

            // 🏰 Fortress Master / Defense Architect
            if (payload?.new_tile_energy === 60) {
                await awardBadge('fortress_master')
                const { count: maxEnergyTiles } = await supabaseClient
                    .from('hex_tiles')
                    .select('*', { count: 'exact', head: true })
                    .eq('owner_id', user_id)
                    .eq('tile_energy', 60)
                if (maxEnergyTiles >= 10) await awardBadge('defense_architect')
            }
        }

        if (event_type === 'tile_attacked') {
            // 🔒 Defender
            if (payload?.captured === false) {
                const { count: defendedCount } = await supabaseClient
                    .from('tile_attack_log')
                    .select('*', { count: 'exact', head: true })
                    .eq('defender_id', user_id)
                    .eq('captured', false)
                if (defendedCount >= 10) await awardBadge('defender')
            }
        }

        if (event_type === 'territory_recaptured') {
            // ↩️ Comeback King
            if (payload?.reclaimed_within_24h) {
                await awardBadge('comeback_king')
            }
        }

        if (event_type === 'war_phase_victory') {
            // 🎖️ War Hero
            const { count: warWins } = await supabaseClient
                .from('tile_attack_log')
                .select('*', { count: 'exact', head: true })
                .eq('attacker_id', user_id)
                .eq('captured', true)
            // assuming war phase is tracked elsewhere or passed in payload
            if (warWins >= 15) await awardBadge('war_hero')
        }

        if (event_type === 'season_closed') {
            // 🥉 Circle Champion / 🥇 Grand Conqueror / 🌠 Season Legend
            if (payload?.rank <= 3) await awardBadge('circle_champion')
            if (payload?.rank === 1) {
                await awardBadge('grand_conqueror')
                const { count: winsCount } = await supabaseClient
                    .from('leaderboard_entries')
                    .select('*', { count: 'exact', head: true })
                    .eq('user_id', user_id)
                    .eq('rank_tiles', 1)
                if (winsCount >= 3) await awardBadge('season_legend')
            }

            // 🌟 Territory Guardian
            if (payload?.held_entire_season) await awardBadge('territory_guardian')

            // 🏙️ Street King
            if (payload?.owns_entire_street) await awardBadge('street_king')
        }

        if (event_type === 'test_award') {
            const badge_id = payload?.badge_id ?? 'step_rookie'
            await awardBadge(badge_id)
        }

        return new Response(
            JSON.stringify({
                success: errors.length === 0,
                user_id,
                event_type,
                awarded: newlyAwardedBadges,
                already_owned: alreadyOwnedBadges,
                errors: errors.length > 0 ? errors : undefined
            }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

    } catch (error) {
        console.error('Error awarding badges:', error)
        return new Response(
            JSON.stringify({ error: error.message }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})
