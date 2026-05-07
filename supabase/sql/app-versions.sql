-- supabase/sql/app-versions.sql
-- Apply via Supabase dashboard SQL editor on each environment.
-- Idempotent: safe to re-run.

create table if not exists app_versions (
  platform              text primary key check (platform in ('ios','android')),
  latest_version        text not null,
  min_supported_version text not null,
  security_flag         boolean not null default false,
  release_notes_fr      text,
  store_url             text not null,
  updated_at            timestamptz not null default now()
);

alter table app_versions enable row level security;

drop policy if exists "public read" on app_versions;
create policy "public read"
  on app_versions for select
  to anon, authenticated
  using (true);

-- INSERT/UPDATE/DELETE intentionally not granted to anon/authenticated.
-- Edits happen via the dashboard (service_role).
