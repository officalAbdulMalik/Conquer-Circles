-- Migration to add circle message reactions support.
-- A dedicated table tracks reactions on chat messages.

CREATE TABLE IF NOT EXISTS public.circle_message_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES public.circle_messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  emoji TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(message_id, user_id, emoji)
);

ALTER TABLE public.circle_message_reactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can select circle message reactions" ON public.circle_message_reactions;
CREATE POLICY "Authenticated users can select circle message reactions"
  ON public.circle_message_reactions
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert circle message reactions" ON public.circle_message_reactions;
CREATE POLICY "Authenticated users can insert circle message reactions"
  ON public.circle_message_reactions
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can delete own reaction" ON public.circle_message_reactions;
CREATE POLICY "Authenticated users can delete own reaction"
  ON public.circle_message_reactions
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

GRANT ALL ON public.circle_message_reactions TO service_role;
GRANT SELECT, INSERT, DELETE ON public.circle_message_reactions TO authenticated;
