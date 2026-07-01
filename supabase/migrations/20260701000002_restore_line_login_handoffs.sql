-- Restore line_login_handoffs table and get_line_login_handoff RPC.
--
-- Run this if your DB previously ran the original (DROP) version of
-- 20260701000001_drop_line_login_handoffs.sql.  If the table/function
-- already exist (fresh DB from schema.sql or from migration 000000),
-- the IF NOT EXISTS / OR REPLACE guards make this idempotent.

create table if not exists public.line_login_handoffs (
  pairing_id text primary key,
  session    jsonb not null,
  created_at timestamptz not null default now()
);

alter table public.line_login_handoffs enable row level security;

-- Insert policy: pairing_id must look like a base64url token (16-64 chars).
-- Idempotent — drop first so re-running doesn't error.
drop policy if exists "line_login_handoffs_insert" on public.line_login_handoffs;
create policy "line_login_handoffs_insert" on public.line_login_handoffs
  for insert with check (pairing_id ~ '^[A-Za-z0-9_-]{16,64}$');

-- RPC: returns and deletes the session for the given pairing_id.
-- security definer so the client can't enumerate the table directly.
create or replace function public.get_line_login_handoff(p_pairing_id text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_session jsonb;
begin
  -- Opportunistic cleanup of stale rows.
  delete from public.line_login_handoffs where created_at < now() - interval '10 minutes';

  select session into v_session
  from public.line_login_handoffs
  where pairing_id = p_pairing_id;

  if v_session is not null then
    delete from public.line_login_handoffs where pairing_id = p_pairing_id;
  end if;

  return v_session;
end;
$$;

grant execute on function public.get_line_login_handoff(text) to anon, authenticated;
