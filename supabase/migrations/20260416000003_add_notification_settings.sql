-- Migration: Add notification settings to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS notifications_enabled BOOLEAN DEFAULT true;

-- Update existing users
UPDATE public.profiles 
SET notifications_enabled = true 
WHERE notifications_enabled IS NULL;
