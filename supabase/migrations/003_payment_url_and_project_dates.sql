alter table invoices add column if not exists payment_url text;
alter table projects add column if not exists start_date date;
alter table projects add column if not exists target_date date;
