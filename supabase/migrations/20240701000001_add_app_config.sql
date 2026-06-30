-- ── app_config table ─────────────────────────────────────────────
-- Remote feature flags — toggle without releasing a new app version.
-- Toggle ads: UPDATE app_config SET value = 'true' WHERE key = 'ads_enabled';

CREATE TABLE IF NOT EXISTS app_config (
  key        text PRIMARY KEY,
  value      text NOT NULL,
  updated_at timestamptz DEFAULT now()
);

-- Ads start disabled — enable after AdMob setup is complete
INSERT INTO app_config (key, value)
VALUES ('ads_enabled', 'false')
ON CONFLICT (key) DO NOTHING;

-- Row-level security: anyone can read, only service_role can write
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public read app_config"
  ON app_config
  FOR SELECT
  USING (true);
