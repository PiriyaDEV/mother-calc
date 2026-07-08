-- Drop the in-app notifications system.
-- The notifications screen has been removed from the app; group invites and
-- friend requests are now surfaced directly in their respective screens.

-- 1. Drop the push trigger first (depends on the function and the table)
drop trigger if exists push_on_notification_insert on public.notifications;

-- 2. Drop the trigger function
drop function if exists public.trigger_push_on_notification() cascade;

-- 3. Drop the table (cascades RLS policies and indexes)
drop table if exists public.notifications cascade;
