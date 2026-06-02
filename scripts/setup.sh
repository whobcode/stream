#!/usr/bin/env bash
# One-shot setup: creates the KV namespace this Worker needs, writes the
# generated IDs into wrangler.jsonc, then optionally sets secrets.
# Safe to re-run: namespaces are only created while the placeholders remain.
set -euo pipefail
cd "$(dirname "$0")/.."
CONFIG="wrangler.jsonc"
command -v npx >/dev/null || { echo "npx (Node) is required"; exit 1; }

echo "==> Checking Cloudflare login"
npx wrangler whoami >/dev/null 2>&1 || npx wrangler login

if grep -q '"placeholder_id"' "$CONFIG"; then
  echo "==> Creating KV namespace STREAM_CACHE (production + preview)"
  PROD_ID=$(npx wrangler kv namespace create STREAM_CACHE 2>&1 | grep -oE '[a-f0-9]{32}' | head -1)
  PREV_ID=$(npx wrangler kv namespace create STREAM_CACHE --preview 2>&1 | grep -oE '[a-f0-9]{32}' | head -1)
  if [ -n "${PROD_ID:-}" ] && [ -n "${PREV_ID:-}" ]; then
    sed -i.bak "s/\"placeholder_id\"/\"$PROD_ID\"/; s/\"placeholder_preview_id\"/\"$PREV_ID\"/" "$CONFIG" && rm -f "$CONFIG.bak"
    echo "==> Wrote KV ids (prod=$PROD_ID preview=$PREV_ID)"
  else
    echo "!! Could not auto-parse ids; run 'npx wrangler kv namespace create STREAM_CACHE' and paste the id into $CONFIG"
  fi
else
  echo "==> KV ids already set, skipping"
fi

echo "==> Optional secrets"
for s in NVR_PASSWORD CLOUDFLARE_ACCOUNT_ID CLOUDFLARE_API_TOKEN; do
  read -rp "Set secret $s now? [y/N] " a
  [[ "$a" =~ ^[Yy]$ ]] && npx wrangler secret put "$s" || echo "  skipped $s"
done
echo "==> Done. Deploy with: npm run deploy"
