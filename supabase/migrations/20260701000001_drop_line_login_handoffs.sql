-- Migration: drop line_login_handoffs table and get_line_login_handoff RPC
--
-- The DB-polling handoff approach (pairing_id → line_login_handoffs table)
-- has been replaced by a same-origin cookie written by the Safari tab and
-- read by the PWA on resume/cold-start. Cookies are shared between a
-- standalone home-screen PWA and Safari for the same origin on iOS,
-- unlike localStorage/IndexedDB which are partitioned between the two.
-- No DB table or RPC is needed any more.

drop function if exists public.get_line_login_handoff(text) cascade;
drop table  if exists public.line_login_handoffs cascade;
