-- Migration to add sender_info JSONB column to circle_messages
-- This allows denormalizing user data (username, avatar, etc.) into the message record
-- for faster real-time updates and simplified client-side logic.

ALTER TABLE public.circle_messages 
ADD COLUMN IF NOT EXISTS sender_info JSONB DEFAULT '{}'::jsonb;

-- Optional: Update comment for clarity
COMMENT ON COLUMN public.circle_messages.sender_info IS 'Denormalized user profile data (e.g., username, avatar_url) at the time of message creation.';
