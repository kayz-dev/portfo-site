create table if not exists licenses (
  id              uuid primary key default gen_random_uuid(),
  key             text not null unique,
  email           text not null,
  domain          text,
  tier            text not null default 'standard',
  status          text not null default 'active',
  stripe_session_id text,
  created_at      timestamptz default now()
);

alter table licenses enable row level security;

-- Owners can read their own license by matching their auth email
do $$ begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'licenses' and policyname = 'licenses: read own'
  ) then
    create policy "licenses: read own" on licenses
      for select using (email = (select email from auth.users where id = auth.uid()));
  end if;
end $$;

-- Service role (used by webhook handler via SUPABASE_SERVICE_ROLE_KEY) bypasses RLS — no extra policy needed.

create index if not exists licenses_email_idx  on licenses (email);
create index if not exists licenses_key_idx    on licenses (key);
create index if not exists licenses_domain_idx on licenses (domain);
