-- SQL to ensure RLS for circle_messages is correctly configured.
-- Even though service_role should bypass RLS, these policies ensure correct behavior.

-- 1. Enable RLS
ALTER TABLE public.circle_messages ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing policies to avoid duplicates (optional, adapt if needed)
DROP POLICY IF EXISTS "Anyone can view circle messages" ON public.circle_messages;
DROP POLICY IF EXISTS "Authenticated users can insert messages" ON public.circle_messages;

-- 3. Create permissive policies for authentication
CREATE POLICY "Anyone can view circle messages"
ON public.circle_messages
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Authenticated users can insert messages"
ON public.circle_messages
FOR INSERT
TO authenticated
WITH CHECK (true);

-- 4. Specifically grant permissions to service_role (just in case)
GRANT ALL ON public.circle_messages TO service_role;
GRANT ALL ON public.circle_messages TO authenticated;
GRANT ALL ON public.circle_messages TO anon;
