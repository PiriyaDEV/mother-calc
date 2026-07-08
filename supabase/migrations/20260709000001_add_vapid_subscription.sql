-- Add vapid_subscription column to profiles for Web Push API (VAPID).
-- Stores the PushSubscription JSON (endpoint + keys) for each web browser session.
-- Native apps continue to use fcm_token; web uses this column instead.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS vapid_subscription text DEFAULT NULL;
