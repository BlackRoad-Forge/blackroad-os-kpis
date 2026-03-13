#!/bin/bash
# Run all KPI collectors and aggregate into daily report

source "$(dirname "$0")/../lib/common.sh"

log "═══════════════════════════════════════"
log "  BlackRoad OS KPI Collection"
log "  $TODAY"
log "═══════════════════════════════════════"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Run all collectors
for collector in github gitea fleet autonomy loc; do
  log "Running $collector collector..."
  bash "$SCRIPT_DIR/$collector.sh" 2>&1 || err "Collector $collector failed"
  echo
done

# Aggregate into daily file
log "Aggregating daily KPIs..."

python3 -c "
import json, glob, os

data_dir = '$DATA_DIR'
today = '$TODAY'
snapshots = {}

for f in glob.glob(f'{data_dir}/snapshots/{today}-*.json'):
    source = os.path.basename(f).replace(f'{today}-', '').replace('.json', '')
    try:
        with open(f) as fh:
            snapshots[source] = json.load(fh)
    except:
        pass

# Build daily summary
gh = snapshots.get('github', {})
gt = snapshots.get('gitea', {})
fl = snapshots.get('fleet', {})
au = snapshots.get('autonomy', {})
lc = snapshots.get('loc', {})

daily = {
    'date': today,
    'collected_at': '$TIMESTAMP',
    'summary': {
        'commits_today': gh.get('commits', {}).get('today', 0) + gt.get('commits', {}).get('today', 0),
        'prs_open': gh.get('pull_requests', {}).get('open', 0),
        'prs_merged_today': gh.get('pull_requests', {}).get('merged_today', 0),
        'prs_merged_total': gh.get('pull_requests', {}).get('merged_total', 0),
        'repos_github': gh.get('repos', {}).get('total', 0),
        'repos_gitea': gt.get('repos', {}).get('total', 0),
        'repos_total': gh.get('repos', {}).get('total', 0) + gt.get('repos', {}).get('total', 0),
        'fleet_online': fl.get('fleet', {}).get('online', 0),
        'fleet_total': fl.get('fleet', {}).get('total_nodes', 4),
        'autonomy_score': au.get('autonomy_score', 0),
        'total_loc': lc.get('total_estimated_loc', 0),
        'docker_containers': fl.get('totals', {}).get('docker_containers', 0),
        'ollama_models': fl.get('totals', {}).get('ollama_models', 0),
        'avg_temp_c': fl.get('totals', {}).get('cpu_avg_temp_c', 0),
        'failed_units': fl.get('totals', {}).get('systemd_failed', 0),
        'throttled_nodes': fl.get('totals', {}).get('throttled_nodes', [])
    },
    'sources': snapshots
}

daily_file = f'{data_dir}/daily/{today}.json'
with open(daily_file, 'w') as f:
    json.dump(daily, f, indent=2)

print(f'Daily KPI file: {daily_file}')
"

log "═══════════════════════════════════════"
log "  Collection complete!"
log "═══════════════════════════════════════"

# Run report
bash "$(dirname "$0")/../reports/daily-report.sh"
