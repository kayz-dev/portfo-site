alter table profiles add column if not exists avatar_url text;

-- Storage policies: authenticated users may manage files under their own
-- "avatars/{uid}/..." prefix in the public "assets" bucket. Public read is
-- already granted by the bucket's public=true flag at the API layer, but
-- storage.objects RLS still needs an explicit select policy.

do $$ begin
  if not exists (select 1 from pg_policies where tablename='objects' and schemaname='storage' and policyname='avatars: public read') then
    create policy "avatars: public read" on storage.objects for select
      using (bucket_id = 'assets' and (storage.foldername(name))[1] = 'avatars');
  end if;
  if not exists (select 1 from pg_policies where tablename='objects' and schemaname='storage' and policyname='avatars: own upload') then
    create policy "avatars: own upload" on storage.objects for insert to authenticated
      with check (bucket_id = 'assets' and (storage.foldername(name))[1] = 'avatars' and (storage.foldername(name))[2] = auth.uid()::text);
  end if;
  if not exists (select 1 from pg_policies where tablename='objects' and schemaname='storage' and policyname='avatars: own update') then
    create policy "avatars: own update" on storage.objects for update to authenticated
      using (bucket_id = 'assets' and (storage.foldername(name))[1] = 'avatars' and (storage.foldername(name))[2] = auth.uid()::text);
  end if;
  if not exists (select 1 from pg_policies where tablename='objects' and schemaname='storage' and policyname='avatars: own delete') then
    create policy "avatars: own delete" on storage.objects for delete to authenticated
      using (bucket_id = 'assets' and (storage.foldername(name))[1] = 'avatars' and (storage.foldername(name))[2] = auth.uid()::text);
  end if;
end $$;
