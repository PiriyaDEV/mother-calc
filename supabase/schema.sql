-- ============================================================
-- Kidtang — Supabase Schema
-- Run this in Supabase SQL Editor
-- ============================================================

-- Enable UUID extension (usually already enabled)
create extension if not exists "uuid-ossp";

-- ============================================================
-- bills table
-- Each row = one bill owned by one user
-- The full bill data (members, items, settings) is stored as JSONB
-- ============================================================
create table if not exists public.bills (
  id          text        primary key,          -- same as Bill.id (client-generated)
  user_id     uuid        not null references auth.users(id) on delete cascade,
  title       text        not null default 'บิลใหม่',
  data        jsonb       not null,             -- full Bill object as JSON
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Index for fast lookup by user
create index if not exists bills_user_id_idx on public.bills(user_id);

-- ============================================================
-- Row Level Security (RLS)
-- Each user can only see/edit their own bills
-- ============================================================
alter table public.bills enable row level security;

-- SELECT: user can only read their own bills
create policy "Users can view own bills"
  on public.bills for select
  using (auth.uid() = user_id);

-- INSERT: user can only insert bills for themselves
create policy "Users can insert own bills"
  on public.bills for insert
  with check (auth.uid() = user_id);

-- UPDATE: user can only update their own bills
create policy "Users can update own bills"
  on public.bills for update
  using (auth.uid() = user_id);

-- DELETE: user can only delete their own bills
create policy "Users can delete own bills"
  on public.bills for delete
  using (auth.uid() = user_id);

-- ============================================================
-- Auto-update updated_at trigger
-- ============================================================
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger bills_updated_at
  before update on public.bills
  for each row execute procedure public.handle_updated_at();
