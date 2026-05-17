-- Existing tables (kept as-is for compatibility)

create table if not exists clients (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  name text,
  company text,
  created_at timestamptz default now()
);

create table if not exists projects (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references clients(id) on delete cascade,
  title text not null,
  status text not null default 'active',
  phase text,
  last_update text,
  notes text,
  created_at timestamptz default now()
);

create table if not exists invoices (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references clients(id) on delete cascade,
  label text not null,
  amount integer not null,
  status text not null default 'pending',
  due_date date,
  created_at timestamptz default now()
);

create table if not exists files (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references clients(id) on delete cascade,
  label text not null,
  url text not null,
  uploaded_at timestamptz default now()
);

-- New: profiles table for role management

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'client',
  created_at timestamptz default now()
);

-- RLS

alter table clients enable row level security;
alter table projects enable row level security;
alter table invoices enable row level security;
alter table files enable row level security;
alter table profiles enable row level security;

-- Client policies (unchanged from original)

do $$ begin
  if not exists (select 1 from pg_policies where tablename='clients' and policyname='clients: own row') then
    create policy "clients: own row" on clients for all using (auth.uid() = id);
  end if;
  if not exists (select 1 from pg_policies where tablename='projects' and policyname='projects: own rows') then
    create policy "projects: own rows" on projects for all using (auth.uid() = client_id);
  end if;
  if not exists (select 1 from pg_policies where tablename='invoices' and policyname='invoices: own rows') then
    create policy "invoices: own rows" on invoices for all using (auth.uid() = client_id);
  end if;
  if not exists (select 1 from pg_policies where tablename='files' and policyname='files: own rows') then
    create policy "files: own rows" on files for all using (auth.uid() = client_id);
  end if;
end $$;

-- Profiles policy: users can only read their own role

do $$ begin
  if not exists (select 1 from pg_policies where tablename='profiles' and policyname='profiles: own row') then
    create policy "profiles: own row" on profiles for all using (auth.uid() = id);
  end if;
end $$;

-- Trigger: auto-insert a profile row when a new auth user signs up

create or replace function handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, role)
  values (new.id, 'client')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();
