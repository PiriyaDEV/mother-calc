#!/bin/bash
# ─────────────────────────────────────────────────────────
#  deploy.sh — Commit & push to trigger a Netlify redeploy
#  Usage: ./deploy.sh                    (auto commit message)
#         ./deploy.sh "my commit msg"    (custom commit message)
# ─────────────────────────────────────────────────────────

set -e

MSG="${1:-deploy: update}"

# Restore web/index.html placeholders in case a local `run.sh web` left real
# secrets injected (inject_web_env.sh restore does this safely).
echo "▶ Restoring web/index.html placeholders..."
bash scripts/inject_web_env.sh restore

# Stage everything (excluding .env — it's in .gitignore)
echo "▶ Staging changes..."
git add -A

# Only commit if there's something to commit
if git diff --cached --quiet; then
  echo "   Nothing to commit — working tree clean."
else
  echo "▶ Committing: \"$MSG\""
  git commit -m "$MSG"
fi

# Push → triggers Netlify build automatically
echo "▶ Pushing to origin/$(git rev-parse --abbrev-ref HEAD)..."
git push

echo ""
echo "✓ Done! Netlify will pick up the push and redeploy automatically."
echo "  Monitor at: https://app.netlify.com"
