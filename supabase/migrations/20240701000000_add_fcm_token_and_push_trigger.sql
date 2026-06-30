-- ── 1. Add fcm_token column to profiles ─────────────────────────
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS fcm_token text;

-- ── 2. Enable pg_net extension (HTTP calls from PostgreSQL) ──────
-- Must be enabled in Supabase dashboard under Extensions, OR run this:
CREATE EXTENSION IF NOT EXISTS pg_net;

-- ── 3. Push notification trigger function ────────────────────────
-- Fires after every INSERT into notifications table and calls
-- the send-push Edge Function.
CREATE OR REPLACE FUNCTION public.trigger_push_on_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_title text;
  v_body  text;
BEGIN
  -- Map notification type → Thai push message
  CASE NEW.type
    WHEN 'group_invite' THEN
      v_title := 'คำเชิญกลุ่ม 👥';
      v_body  := COALESCE(
        (NEW.data->>'invited_by_display_name'),
        '@' || COALESCE(NEW.data->>'invited_by_username', 'ผู้ใช้')
      ) || ' เชิญคุณเข้าร่วมกลุ่ม ' ||
        COALESCE(NEW.data->>'group_name', '');
    WHEN 'friend_request' THEN
      v_title := 'คำขอเป็นเพื่อน 🤝';
      v_body  := COALESCE(
        NEW.data->>'display_name',
        '@' || COALESCE(NEW.data->>'username', 'ผู้ใช้')
      ) || ' ส่งคำขอเป็นเพื่อน';
    WHEN 'friend_accepted' THEN
      v_title := 'ยอมรับคำขอเป็นเพื่อน ✅';
      v_body  := COALESCE(
        NEW.data->>'display_name',
        '@' || COALESCE(NEW.data->>'username', 'ผู้ใช้')
      ) || ' ยอมรับคำขอเป็นเพื่อนของคุณแล้ว';
    WHEN 'bill_paid' THEN
      v_title := 'มีคนจ่ายบิล 💸';
      v_body  := COALESCE(NEW.data->>'payer_name', 'สมาชิก') ||
        ' จ่ายเงินในบิล ' || COALESCE(NEW.data->>'bill_name', '') || ' แล้ว';
    WHEN 'bill_completed' THEN
      v_title := 'บิลจ่ายครบแล้ว 🎉';
      v_body  := 'สมาชิกทุกคนจ่ายเงินครบในบิล ' ||
        COALESCE(NEW.data->>'bill_name', '') || ' แล้ว';
    ELSE
      v_title := 'การแจ้งเตือนใหม่';
      v_body  := COALESCE(NEW.data->>'message', '');
  END CASE;

  -- Call Edge Function (fire-and-forget via pg_net)
  PERFORM net.http_post(
    url     := current_setting('app.supabase_url') || '/functions/v1/send-push',
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'Authorization', 'Bearer ' || current_setting('app.service_role_key')
               ),
    body    := jsonb_build_object(
                 'userId', NEW.user_id,
                 'title',  v_title,
                 'body',   v_body,
                 'data',   jsonb_build_object('type', NEW.type)
               )::text
  );

  RETURN NEW;
END;
$$;

-- ── 4. Attach trigger to notifications table ─────────────────────
DROP TRIGGER IF EXISTS push_on_notification_insert ON notifications;
CREATE TRIGGER push_on_notification_insert
  AFTER INSERT ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_push_on_notification();

-- ── 5. Set app-level settings (run these separately in SQL editor) ─
-- Replace YOUR_PROJECT_REF and YOUR_SERVICE_ROLE_KEY with real values.
--
-- ALTER DATABASE postgres
--   SET app.supabase_url = 'https://YOUR_PROJECT_REF.supabase.co';
-- ALTER DATABASE postgres
--   SET app.service_role_key = 'YOUR_SERVICE_ROLE_KEY';
--
-- See PUSH_NOTIFICATION_SETUP.md — Step 5 for instructions.
