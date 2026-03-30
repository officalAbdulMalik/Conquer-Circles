-- SQL Migration: Add monetization fields to profiles table
-- Run this in the Supabase SQL Editor

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS is_premium BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS has_season_pass BOOLEAN DEFAULT FALSE;

-- Optional: If you want to track circles count for limit enforcement on the DB side as well
-- (Though we are doing it in the Flutter app for now)
-- ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS circles_count INT DEFAULT 0;
