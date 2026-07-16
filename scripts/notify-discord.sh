#!/bin/bash
# Discord Webhook Notification Script
# Usage:
#   DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..." ./scripts/notify-discord.sh <status> <title> <description>
#
#   <status>    : "success" | "failure" | "skipped"
#   <title>     : Short title (e.g. "Test Results – MySQL")
#   <description>: Longer description (e.g. "3/3 tests passed")
#
# Example:
#   DISCORD_WEBHOOK_URL="${{ secrets.DISCORD_WEBHOOK_URL }}" \
#     ./scripts/notify-discord.sh "success" "CI Tests" "All tests passed."
#
# Environment variables:
#   DISCORD_WEBHOOK_URL  (required) — Discord webhook URL
#   GITHUB_SERVER_URL    (optional) — GitHub server URL (set by GH Actions)
#   GITHUB_REPOSITORY    (optional) — owner/repo (set by GH Actions)
#   GITHUB_RUN_ID        (optional) — run ID (set by GH Actions)
#   GITHUB_REF_NAME      (optional) — branch/tag name (set by GH Actions)
#   GITHUB_SHA           (optional) — commit SHA (set by GH Actions)
#   GITHUB_ACTOR         (optional) — who triggered the run (set by GH Actions)

set -euo pipefail

STATUS="${1:-}"
TITLE="${2:-}"
DESCRIPTION="${3:-}"

if [ -z "$DISCORD_WEBHOOK_URL" ]; then
  echo "::error::DISCORD_WEBHOOK_URL is not set. Skipping Discord notification."
  exit 0
fi

if [ -z "$STATUS" ] || [ -z "$TITLE" ]; then
  echo "::error::Usage: notify-discord.sh <status> <title> [description]"
  exit 1
fi

# Colour mapping
# Discord embed colours are decimal integers
COLOR_SUCCESS=5763719   # 0x57F287 — green
COLOR_FAILURE=15548997  # 0xED4245 — red
COLOR_SKIPPED=16705372  # 0xFEE75C — yellow
COLOR_UNKNOWN=5793266   # 0x5865F2 — blurple

case "$STATUS" in
  success) COLOR=$COLOR_SUCCESS; EMOJI="✅" ;;
  failure) COLOR=$COLOR_FAILURE; EMOJI="❌" ;;
  skipped) COLOR=$COLOR_SKIPPED; EMOJI="⚠️" ;;
  *)       COLOR=$COLOR_UNKNOWN; EMOJI="❓" ;;
esac

# Build GitHub run link if available
RUN_URL=""
if [ -n "${GITHUB_SERVER_URL:-}" ] && [ -n "${GITHUB_REPOSITORY:-}" ] && [ -n "${GITHUB_RUN_ID:-}" ]; then
  RUN_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
fi

# Build embed JSON
EMBED=$(cat <<EOF | jq -c .
{
  "embeds": [
    {
      "title": "${EMOJI} ${TITLE}",
      "description": $(echo "$DESCRIPTION" | jq -Rs .),
      "color": $COLOR,
      "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
      "footer": {
        "text": "cod2-testbench · $(date -u +%Y-%m-%dT%H:%M:%SZ)"
      },
      "fields": [
        $(if [ -n "${GITHUB_REF_NAME:-}" ]; then cat <<FIELDS
        {
          "name": "Branch",
          "value": "${GITHUB_REF_NAME}",
          "inline": true
        },
        {
          "name": "Commit",
          "value": "$(echo ${GITHUB_SHA:-unknown} | head -c 7)",
          "inline": true
        },
        {
          "name": "Triggered by",
          "value": "${GITHUB_ACTOR:-unknown}",
          "inline": true
        }
FIELDS
        fi)
      ]
    }
  ]
}
EOF
)

# Add run URL as a field or in the description if not already set
if [ -n "$RUN_URL" ]; then
  EMBED=$(echo "$EMBED" | jq \
    '.embeds[0].fields += [{"name": "Run URL", "value": "'"$RUN_URL"'", "inline": false}]')
fi

# Send to Discord
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Content-Type: application/json" \
  -X POST \
  -d "$EMBED" \
  "$DISCORD_WEBHOOK_URL" 2>/dev/null || echo "000")

if [ "$HTTP_STATUS" = "204" ] || [ "$HTTP_STATUS" = "200" ]; then
  echo "::notice::Discord notification sent (HTTP $HTTP_STATUS)"
else
  echo "::warning::Discord webhook returned HTTP $HTTP_STATUS"
fi