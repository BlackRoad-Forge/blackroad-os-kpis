#!/bin/bash
# Collect fleet health KPIs from all Pi nodes
# Uptime, CPU, memory, disk, temps, services, Docker

source "$(dirname "$0")/../lib/common.sh"

log "Collecting fleet KPIs..."

OUT=$(snapshot_file fleet)

nodes_json="["
first=true

for entry in $FLEET_NODES; do
  node=$(echo "$entry" | cut -d: -f1)
  ip=$(echo "$entry" | cut -d: -f2)
  user=$(get_ssh_user "$node")

  log "Probing $node ($user@$ip)..."

  # Collect via SSH with timeout
  result=$(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$user@$ip" '
    echo "{"
    echo "\"hostname\": \"$(hostname)\","
    echo "\"uptime_seconds\": $(cat /proc/uptime | cut -d" " -f1 | cut -d. -f1),"
    echo "\"load_1m\": $(cat /proc/loadavg | cut -d" " -f1),"
    echo "\"load_5m\": $(cat /proc/loadavg | cut -d" " -f2),"
    echo "\"cpu_temp\": $(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0),"
    echo "\"mem_total_mb\": $(free -m | awk "/Mem:/ {print \$2}"),"
    echo "\"mem_used_mb\": $(free -m | awk "/Mem:/ {print \$3}"),"
    echo "\"disk_total_gb\": $(df / --output=size -BG | tail -1 | tr -d " G"),"
    echo "\"disk_used_gb\": $(df / --output=used -BG | tail -1 | tr -d " G"),"
    echo "\"disk_pct\": $(df / --output=pcent | tail -1 | tr -d " %"),"
    echo "\"docker_containers\": $(docker ps -q 2>/dev/null | wc -l | tr -d " "),"
    echo "\"docker_images\": $(docker images -q 2>/dev/null | wc -l | tr -d " "),"
    echo "\"systemd_failed\": $(systemctl --failed --no-legend 2>/dev/null | wc -l | tr -d " "),"
    echo "\"ollama_models\": $(curl -sf http://localhost:11434/api/tags 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin).get(\"models\",[])))" 2>/dev/null || echo 0),"
    echo "\"throttle_hex\": \"$(vcgencmd get_throttled 2>/dev/null | cut -d= -f2 || echo unknown)\","
    echo "\"governor\": \"$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo unknown)\""
    echo "}"
  ' 2>/dev/null)

  if [ -n "$result" ]; then
    # Convert CPU temp from millidegrees
    result=$(echo "$result" | python3 -c "
import json, sys
d = json.load(sys.stdin)
d['cpu_temp_c'] = round(d.get('cpu_temp', 0) / 1000, 1)
d['mem_pct'] = round(d['mem_used_mb'] / d['mem_total_mb'] * 100, 1) if d['mem_total_mb'] > 0 else 0
d['status'] = 'online'
d['node'] = '$node'
d['ip'] = '$ip'
print(json.dumps(d))
" 2>/dev/null)

    if [ "$first" = true ]; then
      nodes_json="$nodes_json$result"
      first=false
    else
      nodes_json="$nodes_json,$result"
    fi
    ok "$node: online"
  else
    offline="{\"node\": \"$node\", \"ip\": \"$ip\", \"status\": \"offline\"}"
    if [ "$first" = true ]; then
      nodes_json="$nodes_json$offline"
      first=false
    else
      nodes_json="$nodes_json,$offline"
    fi
    err "$node: offline"
  fi
done

nodes_json="$nodes_json]"

# Compute fleet summary
python3 -c "
import json

nodes = json.loads('''$nodes_json''')
online = [n for n in nodes if n.get('status') == 'online']
offline = [n for n in nodes if n.get('status') == 'offline']

summary = {
    'source': 'fleet',
    'collected_at': '$TIMESTAMP',
    'date': '$TODAY',
    'fleet': {
        'total_nodes': len(nodes),
        'online': len(online),
        'offline': len(offline),
        'offline_nodes': [n['node'] for n in offline]
    },
    'totals': {
        'cpu_avg_temp_c': round(sum(n.get('cpu_temp_c', 0) for n in online) / max(len(online), 1), 1),
        'mem_used_mb': sum(n.get('mem_used_mb', 0) for n in online),
        'mem_total_mb': sum(n.get('mem_total_mb', 0) for n in online),
        'disk_used_gb': sum(n.get('disk_used_gb', 0) for n in online),
        'disk_total_gb': sum(n.get('disk_total_gb', 0) for n in online),
        'docker_containers': sum(n.get('docker_containers', 0) for n in online),
        'ollama_models': sum(n.get('ollama_models', 0) for n in online),
        'systemd_failed': sum(n.get('systemd_failed', 0) for n in online),
        'throttled_nodes': [n['node'] for n in online if n.get('throttle_hex', '0x0') not in ('0x0', 'unknown')]
    },
    'nodes': nodes
}

with open('$OUT', 'w') as f:
    json.dump(summary, f, indent=2)
" 2>/dev/null

ok "Fleet: $(echo "$nodes_json" | python3 -c "import json,sys; n=json.load(sys.stdin); print(f\"{sum(1 for x in n if x.get('status')=='online')}/{len(n)} online\")")"
