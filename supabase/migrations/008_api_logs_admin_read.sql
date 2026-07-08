do $$ begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'api_logs' and policyname = 'api_logs: admin read'
  ) then
    create policy "api_logs: admin read" on api_logs
      for select using (
        exists (
          select 1 from profiles
          where profiles.id = auth.uid()
          and profiles.role = 'admin'
        )
      );
  end if;
end $$;
