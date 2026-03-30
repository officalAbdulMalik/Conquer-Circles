-- Add monetization fields to profiles if they don't exist
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_premium BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS has_season_pass BOOLEAN DEFAULT FALSE;

-- Create Season Recaps table
CREATE TABLE IF NOT EXISTS season_recaps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    season_id INT NOT NULL,
    season_name TEXT NOT NULL,
    total_steps INT DEFAULT 0,
    total_energy INT DEFAULT 0,
    tiles_conquered INT DEFAULT 0,
    raids_won INT DEFAULT 0,
    rewards_unlocked JSONB DEFAULT '[]'::jsonb,
    is_premium_unlocked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, season_id)
);

-- Enable RLS on season_recaps
ALTER TABLE season_recaps ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own recaps" 
ON season_recaps FOR SELECT 
USING (auth.uid() = user_id);

-- Update the energy conversion RPC to handle tier-based caps
CREATE OR REPLACE FUNCTION convert_steps_to_energy(steps_today INT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_is_premium BOOLEAN;
    v_energy_cap INT;
    v_current_energy INT;
    v_energy_to_add INT;
    v_final_energy INT;
BEGIN
    v_user_id := auth.uid();
    
    -- Get user's premium status and current energy
    SELECT is_premium, attack_energy 
    INTO v_is_premium, v_current_energy
    FROM profiles 
    WHERE id = v_user_id;
    
    -- Set cap based on tier
    v_energy_cap := CASE WHEN v_is_premium THEN 600 ELSE 400 END;
    
    -- 10 steps = 1 energy (adjust conversion rate as needed)
    v_energy_to_add := steps_today / 10;
    
    -- Calculate final energy without exceeding cap
    v_final_energy := LEAST(v_current_energy + v_energy_to_add, v_energy_cap);
    
    -- Actual energy added (cannot be negative)
    v_energy_to_add := GREATEST(0, v_final_energy - v_current_energy);
    
    -- Update profile
    UPDATE profiles 
    SET attack_energy = v_final_energy,
        total_steps_all = total_steps_all + steps_today,
        last_step_update = NOW()
    WHERE id = v_user_id;
    
    RETURN jsonb_build_object(
        'energy_added', v_energy_to_add,
        'new_total_energy', v_final_energy,
        'cap_reached', v_final_energy >= v_energy_cap
    );
END;
$$;
