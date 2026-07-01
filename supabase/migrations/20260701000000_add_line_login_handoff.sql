-- iOS gives a LINE web login's OAuth redirect to a plain Safari tab instead
-- of handing it back to the installed home-screen PWA, and — contrary to
-- what earlier fixes assumed — shares neither localStorage nor Cache
-- Storage reliably between the two contexts for the same origin. This
-- table lets the Safari tab (which completes the sign-in) hand the
-- resulting Supabase session to the PWA instance (which polls for it by
-- pairing_id) through the server instead of through any browser storage.

create table public.line_login_handoffs (
  pairing_id text primary key,
  session    jsonb not null,
  created_at timestamptz not null default now()
);

alter table public.line_login_handoffs enable row level security;

-- pairing_id is a 256-bit random token generated client-side and never
-- guessable — it IS the authorization here, same trust model as the OAuth
-- `state`/PKCE verifier already used elsewhere in this flow. Anyone who
-- knows it can create a handoff row; that's fine, it's write-only and
-- doesn't expose anything (a bogus pairing_id just never gets polled).
create policy "line_login_handoffs_insert" on public.line_login_handoffs
  for insert with check (pairing_id ~ '^[A-Za-z0-9_-]{16,64}$');

-- No select/delete policy — deliberately. Reads must go through the
-- get_line_login_handoff() RPC below (security definer), so a client can
-- only ever fetch the one row whose pairing_id it already knows, and can
-- never enumerate the table to steal someone else's in-flight session.

create function public.get_line_login_handoff(p_pairing_id text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_session jsonb;
begin
  -- Opportunistic cleanup — handoffs are only ever relevant for a couple
  -- of minutes after creation.
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
