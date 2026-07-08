create table if not exists api_logs (
  id         uuid primary key default gen_random_uuid(),
  route      text not null,
  method     text not null default 'POST',
  status     integer not null,
  key        text,
  domain     text,
  ip         text,
  error      text,
  created_at timestamptz default now()
);

alter table api_logs enable row level security;

-- Only service role can insert; no client access needed
-- Admin reads via service role key, so no RLS policy required for select

create index if not exists api_logs_created_at_idx on api_logs (created_at desc);
create index if not exists api_logs_route_idx      on api_logs (route);
create index if not exists api_logs_key_idx        on api_logs (key);
