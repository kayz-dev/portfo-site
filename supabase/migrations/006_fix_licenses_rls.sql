drop policy if exists "licenses: read own" on licenses;

create policy "licenses: read own" on licenses
  for select using (
    email = auth.jwt() ->> 'email'
  );
