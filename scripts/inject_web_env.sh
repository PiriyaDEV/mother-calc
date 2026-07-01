#!/bin/bash
# inject_web_env.sh
# Reads .env (if present) and injects GOOGLE_WEB_CLIENT_ID and ADSENSE_PUBLISHER_ID
# into web/index.html placeholders before a flutter build/run.
#
# Usage:
#   ./scripts/inject_web_env.sh          # inject from .env
#   ./scripts/inject_web_env.sh restore  # restore placeholders (undo)

set -e

INDEX="web/index.html"
GOOGLE_PLACEHOLDER="GOOGLE_WEB_CLIENT_ID_PLACEHOLDER"
ADSENSE_PLACEHOLDER="ADSENSE_PUBLISHER_ID_PLACEHOLDER"

if [[ "$1" == "restore" ]]; then
  # Restore placeholders (useful after local flutter run)
  sed -i.bak "s|content=\"[^\"]*\.apps\.googleusercontent\.com\"|content=\"$GOOGLE_PLACEHOLDER\"|g" "$INDEX"
  sed -i.bak "s|client=ca-pub-[0-9]*|client=$ADSENSE_PLACEHOLDER|g" "$INDEX"
  rm -f "${INDEX}.bak"
  echo "✓ Restored placeholders in $INDEX"
  exit 0
fi

# Load .env if it exists
if [[ -f ".env" ]]; then
  export $(grep -v '^#' .env | grep -v '^$' | xargs)
fi

# Inject GOOGLE_WEB_CLIENT_ID
if [[ -n "$GOOGLE_WEB_CLIENT_ID" && "$GOOGLE_WEB_CLIENT_ID" != "your-web-oauth-client-id.apps.googleusercontent.com" ]]; then
  sed -i.bak "s|$GOOGLE_PLACEHOLDER|$GOOGLE_WEB_CLIENT_ID|g" "$INDEX"
  echo "✓ Injected GOOGLE_WEB_CLIENT_ID into $INDEX"
else
  echo "⚠ GOOGLE_WEB_CLIENT_ID not set or is placeholder — skipping"
fi

# Inject ADSENSE_PUBLISHER_ID
if [[ -n "$ADSENSE_PUBLISHER_ID" && "$ADSENSE_PUBLISHER_ID" != "your-adsense-publisher-id" ]]; then
  sed -i.bak "s|$ADSENSE_PLACEHOLDER|$ADSENSE_PUBLISHER_ID|g" "$INDEX"
  echo "✓ Injected ADSENSE_PUBLISHER_ID into $INDEX"
else
  echo "⚠ ADSENSE_PUBLISHER_ID not set or is placeholder — skipping"
fi

rm -f "${INDEX}.bak"
echo "Done. Run 'flutter run -d chrome' or 'flutter build web' now."
echo "Run './scripts/inject_web_env.sh restore' to undo before committing."
