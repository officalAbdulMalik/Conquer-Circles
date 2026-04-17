-- Migration: Add RPC function to convert steps to XP with level progression
CREATE OR REPLACE FUNCTION public.convert_steps_to_xp(
  p_user_id UUID,
  p_steps_today INT
)
RETURNS TABLE (
  xp_gained INT,
  current_xp INT,
  current_level INT,
  xp_goal INT,
  level_up BOOLEAN
) AS $$
DECLARE
  v_xp_gained INT;
  v_current_xp INT;
  v_current_level INT;
  v_current_xp_goal INT;
  v_level_up BOOLEAN := FALSE;
  v_daily_bonus INT := 0;
BEGIN
  -- Calculate XP from steps (1 step = 0.1 XP per step)
  v_xp_gained := GREATEST(1, p_steps_today / 10);
  
  -- Add daily bonus (50 XP) if step goal reached (10000 steps)
  IF p_steps_today >= 10000 THEN
    v_daily_bonus := 50;
    v_xp_gained := v_xp_gained + v_daily_bonus;
  END IF;
  
  -- Get current profile stats
  SELECT xp, level, xp_goal 
  INTO v_current_xp, v_current_level, v_current_xp_goal
  FROM profiles
  WHERE id = p_user_id;
  
  -- Update profile with new XP
  UPDATE profiles
  SET xp = xp + v_xp_gained,
      updated_at = NOW()
  WHERE id = p_user_id;
  
  -- Add to current XP (simulate the update)
  v_current_xp := v_current_xp + v_xp_gained;
  
  -- Check for level up
  WHILE v_current_xp >= v_current_xp_goal LOOP
    v_level_up := TRUE;
    v_current_xp := v_current_xp - v_current_xp_goal;  -- Carry over excess XP
    v_current_level := v_current_level + 1;
    v_current_xp_goal := ROUND(v_current_xp_goal * 1.2);  -- 20% increase per level
    
    -- Update profile with new level and xp_goal
    UPDATE profiles
    SET 
      level = v_current_level,
      xp = v_current_xp,
      xp_goal = v_current_xp_goal,
      updated_at = NOW()
    WHERE id = p_user_id;
  END LOOP;
  
  RETURN QUERY SELECT v_xp_gained, v_current_xp, v_current_level, v_current_xp_goal, v_level_up;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add index for faster profile lookups
CREATE INDEX IF NOT EXISTS idx_profiles_xp ON public.profiles(xp DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_level ON public.profiles(level DESC);
