-- Migration: Add gamification fields to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS level INT DEFAULT 1,
ADD COLUMN IF NOT EXISTS xp INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS xp_goal INT DEFAULT 1000,
ADD COLUMN IF NOT EXISTS step_goal INT DEFAULT 10000,
ADD COLUMN IF NOT EXISTS daily_streak INT DEFAULT 0;

-- Optional: Update existing users with default values
UPDATE public.profiles 
SET level = 1, xp = 0, xp_goal = 1000, step_goal = 10000, daily_streak = 0
WHERE level IS NULL;
