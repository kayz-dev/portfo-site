-- Issue 1: Revoke public EXECUTE on handle_new_user (SECURITY DEFINER trigger function)
-- It only needs to run as a trigger, not be callable via RPC by anon/authenticated roles
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM anon, authenticated;

-- Issue 2: Replace the always-true "Admin full access" policy on project_updates
-- with a properly scoped admin policy and a client read policy

DROP POLICY IF EXISTS "Admin full access" ON public.project_updates;

-- Admin: full access only for users whose profile role is 'admin'
CREATE POLICY "project_updates: admin full access"
  ON public.project_updates
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
  );

-- Clients: read their own project updates
CREATE POLICY "project_updates: client read own"
  ON public.project_updates
  FOR SELECT
  USING (auth.uid() = client_id);
