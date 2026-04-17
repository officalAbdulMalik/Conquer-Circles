-- Migration: Create badges metadata table and populate with definitions
CREATE TABLE IF NOT EXISTS public.badges (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL,
    rarity TEXT DEFAULT 'common',
    icon_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS for badges (public read)
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view badges" ON public.badges FOR SELECT USING (true);

-- Populate badges
INSERT INTO public.badges (id, name, description, category, rarity) VALUES
-- Steps
('rookie', 'Step Rookie', 'Walk 5,000 steps in one day', 'steps', 'common'),
('marathon_walker', 'Marathon Walker', 'Walk 42 km total in a season', 'steps', 'rare'),
('daily_grinder', 'Daily Grinder', '10,000 steps/day for 5 consecutive days', 'steps', 'uncommon'),
('consistency_hero', 'Consistency Hero', 'Walk every day for 14 days', 'steps', 'uncommon'),
('weekend_warrior', 'Weekend Warrior', '20k steps in one weekend', 'steps', 'uncommon'),

-- Time
('early_bird', 'Early Bird', 'Walk started before 07:00 for 7 days', 'time', 'common'),
('night_walker', 'Night Walker', 'Walk started after 22:00 for 5 days', 'time', 'common'),

-- Defense / Energy
('energy_hoarder', 'Energy Hoarder', 'Store maximum attack energy', 'defense', 'common'),
('fortress_master', 'Fortress Master', 'Hold a tile at 60 energy', 'defense', 'uncommon'),
('defense_architect', 'Defense Architect', '10 tiles at max (60) energy', 'defense', 'rare'),
('defender', 'Defender', 'Survive 10 incoming attacks', 'defense', 'uncommon'),

-- Territory
('territory_pioneer', 'Territory Pioneer', 'Own 10 tiles total', 'territory', 'common'),
('territory_builder', 'Territory Builder', 'Own 50 tiles simultaneously', 'territory', 'uncommon'),
('expansion_master', 'Expansion Master', 'Own 100 tiles simultaneously', 'territory', 'rare'),
('territory_emperor', 'Territory Emperor', 'Control 25 tiles simultaneously', 'territory', 'rare'),
('cluster_creator', 'Cluster Creator', 'Create a cluster of 7 tiles', 'territory', 'uncommon'),
('expansion_legend', 'Expansion Legend', 'Capture 10 new tiles in one day', 'territory', 'rare'),
('park_explorer', 'Park Explorer', 'Capture 5 park tiles', 'territory', 'uncommon'),
('comeback_king', 'Comeback King', 'Reclaim own territory within 24h of losing it', 'territory', 'uncommon'),
('street_king', 'Street King', 'Control an entire street cluster', 'territory', 'legendary'),
('territory_guardian', 'Territory Guardian', 'Hold territory for entire season', 'territory', 'legendary'),

-- Raid
('raid_initiator', 'Raid Initiator', 'First enemy tile attack ever', 'raid', 'common'),
('raid_champion', 'Raid Champion', 'Win 10 raids', 'raid', 'uncommon'),
('raid_destroyer', 'Raid Destroyer', 'Win 25 raids', 'raid', 'rare'),
('rival_slayer', 'Rival Slayer', 'Capture from same rival 5 times', 'raid', 'rare'),
('strategic_raider', 'Strategic Raider', 'Capture with exactly equal energy', 'raid', 'rare'),
('war_hero', 'War Hero', '15 raids won in war phase', 'raid', 'rare'),

-- Season
('circle_champion', 'Circle Champion', 'Finish top 3 in season leaderboard', 'season', 'rare'),
('grand_conqueror', 'Grand Conqueror', 'Finish #1 in circle leaderboard', 'season', 'legendary'),
('season_legend', 'Season Legend', 'Win #1 for 3 seasons', 'season', 'mythic')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    category = EXCLUDED.category,
    rarity = EXCLUDED.rarity;
