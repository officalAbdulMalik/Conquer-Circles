-- Migration: Add helper RPCs for badge system logic

-- 1. Get weekend steps sum
CREATE OR REPLACE FUNCTION get_weekend_steps_sum(p_user_id UUID)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_sum INT;
BEGIN
    -- Sum steps for Saturday (6) and Sunday (0) of the current week
    SELECT SUM(steps) INTO v_sum
    FROM daily_steps
    WHERE user_id = p_user_id
    AND EXTRACT(DOW FROM date) IN (0, 6)
    AND date >= date_trunc('week', NOW() - INTERVAL '1 day');
    
    RETURN COALESCE(v_sum, 0);
END;
$$;

-- 2. Check consecutive days threshold
CREATE OR REPLACE FUNCTION check_consecutive_steps(p_user_id UUID, p_threshold INT, p_days INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM (
        SELECT 1
        FROM daily_steps
        WHERE user_id = p_user_id
        AND steps >= p_threshold
        AND date >= CURRENT_DATE - (p_days - 1) * INTERVAL '1 day'
    ) sub;
    
    RETURN v_count >= p_days;
END;
$$;

-- 3. Check early bird sessions
CREATE OR REPLACE FUNCTION check_early_bird_sessions(p_user_id UUID, p_threshold_hour INT, p_days INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(DISTINCT DATE(started_at)) INTO v_count
    FROM walking_sessions
    WHERE user_id = p_user_id
    AND EXTRACT(HOUR FROM started_at) < p_threshold_hour;
    
    RETURN v_count >= p_days;
END;
$$;

-- 4. Check night walker sessions
CREATE OR REPLACE FUNCTION check_night_walker_sessions(p_user_id UUID, p_threshold_hour INT, p_days INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(DISTINCT DATE(started_at)) INTO v_count
    FROM walking_sessions
    WHERE user_id = p_user_id
    AND EXTRACT(HOUR FROM started_at) >= p_threshold_hour;
    
    RETURN v_count >= p_days;
END;
$$;
