#!/bin/bash
# Generate formatted daily KPI report

source "$(dirname "$0")/../lib/common.sh"

DAILY=$(today_file)

if [ ! -f "$DAILY" ]; then
  err "No daily data for $TODAY. Run: npm run collect"
  exit 1
fi

# Get yesterday's data for deltas
YESTERDAY=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d '1 day ago' +%Y-%m-%d)
YESTERDAY_FILE="$DATA_DIR/daily/${YESTERDAY}.json"

export DAILY YESTERDAY_FILE
python3 << 'PYEOF'
import json, os, sys

today_file = os.environ.get('DAILY', '')
yesterday_file = os.environ.get('YESTERDAY_FILE', '')

with open(today_file) as f:
    data = json.load(f)

yesterday = {}
if os.path.exists(yesterday_file or ''):
    with open(yesterday_file) as f:
        yesterday = json.load(f)

s = data['summary']
ys = yesterday.get('summary', {})

def delta(key):
    curr = s.get(key, 0)
    prev = ys.get(key, 0)
    if not prev:
        return ''
    diff = curr - prev
    if diff > 0:
        return f' \033[38;5;82m(+{diff})\033[0m'
    elif diff < 0:
        return f' \033[38;5;196m({diff})\033[0m'
    return ' (=)'

P = '\033[38;5;205m'
A = '\033[38;5;214m'
B = '\033[38;5;69m'
G = '\033[38;5;82m'
V = '\033[38;5;135m'
R = '\033[0m'

print(f"""
{P}╔══════════════════════════════════════════════════╗{R}
{P}║{R}  {A}BlackRoad OS — Daily KPIs{R}                        {P}║{R}
{P}║{R}  {B}{data['date']}{R}                                    {P}║{R}
{P}╠══════════════════════════════════════════════════╣{R}

{A}📊 CODE{R}
   Commits today:     {G}{s['commits_today']}{R}{delta('commits_today')}
   PRs open:          {s['prs_open']}{delta('prs_open')}
   PRs merged today:  {s['prs_merged_today']}{delta('prs_merged_today')}
   PRs merged total:  {s['prs_merged_total']}{delta('prs_merged_total')}
   Total LOC:         {s['total_loc']:,}{delta('total_loc')}

{A}📦 REPOS{R}
   GitHub:            {s['repos_github']}{delta('repos_github')}
   Gitea:             {s['repos_gitea']}{delta('repos_gitea')}
   Total:             {s['repos_total']}{delta('repos_total')}

{A}🖥  FLEET{R}
   Nodes online:      {s['fleet_online']}/{s['fleet_total']}
   Docker containers: {s['docker_containers']}{delta('docker_containers')}
   Ollama models:     {s['ollama_models']}{delta('ollama_models')}
   Avg temp:          {s['avg_temp_c']}°C
   Failed units:      {s['failed_units']}{delta('failed_units')}
   Throttled:         {', '.join(s.get('throttled_nodes', [])) or 'none'}

{A}🤖 AUTONOMY{R}
   Score:             {V}{s['autonomy_score']}/100{R}{delta('autonomy_score')}

{P}╚══════════════════════════════════════════════════╝{R}
""")
PYEOF
