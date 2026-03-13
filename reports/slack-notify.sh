#!/bin/bash
# Post daily KPI report to Slack (blackroadosinc.slack.com)
# Requires SLACK_WEBHOOK_URL env var or ~/.blackroad/slack-webhook.env

source "$(dirname "$0")/../lib/common.sh"

# Load webhook URL
if [ -z "$SLACK_WEBHOOK_URL" ] && [ -f "$HOME/.blackroad/slack-webhook.env" ]; then
  source "$HOME/.blackroad/slack-webhook.env"
fi

if [ -z "$SLACK_WEBHOOK_URL" ]; then
  err "No SLACK_WEBHOOK_URL set. Create ~/.blackroad/slack-webhook.env with:"
  err "  SLACK_WEBHOOK_URL=https://hooks.slack.com/services/T.../B.../..."
  err ""
  err "To set up:"
  err "  1. Go to blackroadosinc.slack.com → Apps → Incoming Webhooks"
  err "  2. Add webhook to your #kpis or #general channel"
  err "  3. Save URL to ~/.blackroad/slack-webhook.env"
  exit 1
fi

DAILY=$(today_file)

if [ ! -f "$DAILY" ]; then
  err "No daily data for $TODAY. Run: npm run collect"
  exit 1
fi

# Build Slack message
payload=$(python3 << 'PYEOF'
import json, os

daily_file = os.path.join(os.environ.get('DATA_DIR', 'data'), 'daily', os.environ.get('TODAY', '') + '.json')
# Fallback
import glob
files = sorted(glob.glob('data/daily/*.json'))
if not files:
    files = sorted(glob.glob(os.path.expanduser('~/blackroad-os-kpis/data/daily/*.json')))
if files:
    daily_file = files[-1]

with open(daily_file) as f:
    data = json.load(f)

s = data['summary']

blocks = [
    {
        "type": "header",
        "text": {"type": "plain_text", "text": f"🛣 BlackRoad OS KPIs — {data['date']}"}
    },
    {
        "type": "section",
        "fields": [
            {"type": "mrkdwn", "text": f"*Commits Today*\n{s['commits_today']}"},
            {"type": "mrkdwn", "text": f"*PRs Merged Today*\n{s['prs_merged_today']}"},
            {"type": "mrkdwn", "text": f"*PRs Open*\n{s['prs_open']}"},
            {"type": "mrkdwn", "text": f"*Total LOC*\n{s['total_loc']:,}"},
        ]
    },
    {
        "type": "section",
        "fields": [
            {"type": "mrkdwn", "text": f"*Repos (GH + Gitea)*\n{s['repos_github']} + {s['repos_gitea']} = {s['repos_total']}"},
            {"type": "mrkdwn", "text": f"*Fleet*\n{s['fleet_online']}/{s['fleet_total']} online"},
            {"type": "mrkdwn", "text": f"*Docker*\n{s['docker_containers']} containers"},
            {"type": "mrkdwn", "text": f"*Ollama*\n{s['ollama_models']} models"},
        ]
    },
    {
        "type": "section",
        "fields": [
            {"type": "mrkdwn", "text": f"*Autonomy Score*\n{s['autonomy_score']}/100"},
            {"type": "mrkdwn", "text": f"*Avg Temp*\n{s['avg_temp_c']}°C"},
            {"type": "mrkdwn", "text": f"*Failed Units*\n{s['failed_units']}"},
            {"type": "mrkdwn", "text": f"*Throttled*\n{', '.join(s.get('throttled_nodes', [])) or 'None'}"},
        ]
    },
    {"type": "divider"},
    {
        "type": "context",
        "elements": [
            {"type": "mrkdwn", "text": f"Collected at {data['collected_at']} | blackroad-os-kpis"}
        ]
    }
]

payload = {"blocks": blocks}
print(json.dumps(payload))
PYEOF
)

log "Posting to Slack..."
response=$(curl -sf -X POST -H 'Content-type: application/json' \
  --data "$payload" \
  "$SLACK_WEBHOOK_URL" 2>&1)

if [ "$response" = "ok" ]; then
  ok "Posted to Slack"
else
  err "Slack post failed: $response"
  exit 1
fi
