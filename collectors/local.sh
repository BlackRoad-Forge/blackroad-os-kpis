#!/bin/bash
# Collect local Mac KPIs: scripts, databases, packages, disk, processes

source "$(dirname "$0")/../lib/common.sh"

log "Collecting local Mac KPIs..."

OUT=$(snapshot_file local)

# Scripts in ~/bin
bin_count=$(ls -1 ~/bin/ 2>/dev/null | wc -l | tr -d ' ')
bin_size_mb=$(du -sm ~/bin/ 2>/dev/null | cut -f1 || echo 0)

# Shell scripts in home
home_scripts=$(ls -1 ~/*.sh 2>/dev/null | wc -l | tr -d ' ')

# Templates
template_count=$(ls -1 ~/Desktop/templates/ 2>/dev/null | wc -l | tr -d ' ')

# SQLite databases
db_count=$(find ~/.blackroad -name "*.db" -type f 2>/dev/null | wc -l | tr -d ' ')
db_size_mb=$(du -sm ~/.blackroad/ 2>/dev/null | cut -f1 || echo 0)

# Package managers
brew_count=$(brew list 2>/dev/null | wc -l | tr -d ' ' || echo 0)
pip_count=$(pip3 list 2>/dev/null | tail -n +3 | wc -l | tr -d ' ' || echo 0)
npm_global=$(npm list -g --depth=0 2>/dev/null | tail -n +2 | wc -l | tr -d ' ' || echo 0)

# Cron jobs
cron_count=$(crontab -l 2>/dev/null | grep -cv '^#\|^$' || echo 0)

# Git repos (local)
git_repos=$(find ~/ -maxdepth 3 -name ".git" -type d 2>/dev/null | wc -l | tr -d ' ')

# Disk usage
disk_used=$(df -g / | tail -1 | awk '{print $3}')
disk_total=$(df -g / | tail -1 | awk '{print $2}')
disk_pct=$(df / | tail -1 | awk '{print $5}' | tr -d '%')

# Processes
process_count=$(ps aux | wc -l | tr -d ' ')

# Network connections
net_connections=$(netstat -an 2>/dev/null | grep ESTABLISHED | wc -l | tr -d ' ' || echo 0)

# Downloads & Documents
downloads_count=$(ls -1 ~/Downloads/ 2>/dev/null | wc -l | tr -d ' ')
documents_count=$(ls -1 ~/Documents/ 2>/dev/null | wc -l | tr -d ' ')

# FTS5 memory index
fts_entries=0
if [ -f ~/.blackroad/markdown.db ]; then
  fts_entries=$(python3 -c "
import sqlite3
c = sqlite3.connect('$HOME/.blackroad/markdown.db')
try:
    r = c.execute('SELECT count(*) FROM markdown_fts').fetchone()
    print(r[0])
except:
    print(0)
" 2>/dev/null || echo 0)
fi

# Systems.db count
systems_count=0
if [ -f ~/.blackroad/systems.db ]; then
  systems_count=$(python3 -c "
import sqlite3
c = sqlite3.connect('$HOME/.blackroad/systems.db')
try:
    r = c.execute('SELECT count(*) FROM systems').fetchone()
    print(r[0])
except:
    print(0)
" 2>/dev/null || echo 0)
fi

cat > "$OUT" << ENDJSON
{
  "source": "local",
  "collected_at": "$TIMESTAMP",
  "date": "$TODAY",
  "scripts": {
    "bin_tools": $bin_count,
    "bin_size_mb": $bin_size_mb,
    "home_scripts": $home_scripts,
    "templates": $template_count
  },
  "databases": {
    "sqlite_count": $db_count,
    "blackroad_dir_mb": $db_size_mb,
    "fts5_entries": $fts_entries,
    "systems_registered": $systems_count
  },
  "packages": {
    "homebrew": $brew_count,
    "pip3": $pip_count,
    "npm_global": $npm_global
  },
  "automation": {
    "cron_jobs": $cron_count,
    "local_git_repos": $git_repos
  },
  "disk": {
    "used_gb": $disk_used,
    "total_gb": $disk_total,
    "pct": $disk_pct
  },
  "system": {
    "processes": $process_count,
    "net_connections": $net_connections
  },
  "files": {
    "downloads": $downloads_count,
    "documents": $documents_count
  }
}
ENDJSON

ok "Local: ${bin_count} tools, ${db_count} DBs, ${brew_count} brew, ${cron_count} crons, ${disk_pct}% disk"
