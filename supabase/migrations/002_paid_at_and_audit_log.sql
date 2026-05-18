-- Add paid_at to invoices
alter table invoices add column if not exists paid_at timestamptz;

-- Admin audit log
create table if not exists admin_log (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references clients(id) on delete cascade,
  action text not null,
  detail text,
  created_at timestamptz default now()
);

alter table admin_log enable row level security;
-- Only service role (admin client) can access; no client-facing policy needed
