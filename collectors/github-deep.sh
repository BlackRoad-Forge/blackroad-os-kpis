#!/bin/bash
# Deep GitHub metrics: stars, forks, traffic, languages, profile stats

source "$(dirname "$0")/../lib/common.sh"

log "Collecting deep GitHub metrics..."

OUT=$(snapshot_file github-deep)

# Profile stats
profile=$(gh api users/$GITHUB_USER 2>/dev/null || echo '{}')
followers=$(echo "$profile" | python3 -c "import json,sys; print(json.load(sys.stdin).get('followers',0))" 2>/dev/null || echo 0)
following=$(echo "$profile" | python3 -c "import json,sys; print(json.load(sys.stdin).get('following',0))" 2>/dev/null || echo 0)
public_repos=$(echo "$profile" | python3 -c "import json,sys; print(json.load(sys.stdin).get('public_repos',0))" 2>/dev/null || echo 0)
public_gists=$(echo "$profile" | python3 -c "import json,sys; print(json.load(sys.stdin).get('public_gists',0))" 2>/dev/null || echo 0)

ok "Profile: $public_repos repos, $followers followers"

# Aggregate stars, forks, sizes across all repos
repo_stats=$(gh api "users/$GITHUB_USER/repos?per_page=100&type=owner" --paginate 2>/dev/null | python3 -c "
import json, sys

repos = []
for line in sys.stdin:
    try:
        repos.extend(json.loads(line))
    except:
        pass

total_stars = sum(r.get('stargazers_count', 0) for r in repos)
total_forks = sum(r.get('forks_count', 0) for r in repos)
total_watchers = sum(r.get('watchers_count', 0) for r in repos)
total_size_kb = sum(r.get('size', 0) for r in repos)
total_open_issues = sum(r.get('open_issues_count', 0) for r in repos)
archived = sum(1 for r in repos if r.get('archived'))
active = len(repos) - archived

# Languages
langs = {}
for r in repos:
    l = r.get('language')
    if l:
        langs[l] = langs.get(l, 0) + 1

# Most recently updated
recent = sorted(repos, key=lambda r: r.get('updated_at', ''), reverse=True)[:10]
recent_names = [r['full_name'] for r in recent]

# Largest repos
largest = sorted(repos, key=lambda r: r.get('size', 0), reverse=True)[:10]
largest_info = [{r['full_name']: round(r['size']/1024, 1)} for r in largest]

print(json.dumps({
    'total_stars': total_stars,
    'total_forks': total_forks,
    'total_watchers': total_watchers,
    'total_size_mb': round(total_size_kb / 1024, 1),
    'total_open_issues': total_open_issues,
    'archived': archived,
    'active': active,
    'languages': langs,
    'top_10_recent': recent_names,
    'top_10_largest_mb': largest_info
}))
" 2>/dev/null || echo '{}')

# Org stats
org_stats='{'
first=true
for org in $GITHUB_ORGS; do
  org_repos=$(gh api "orgs/$org/repos?per_page=100" --paginate --jq 'length' 2>/dev/null || echo 0)
  org_members=$(gh api "orgs/$org/members?per_page=100" --jq 'length' 2>/dev/null || echo 0)
  if [ "$first" = true ]; then
    org_stats="$org_stats\"$org\": {\"repos\": $org_repos, \"members\": $org_members}"
    first=false
  else
    org_stats="$org_stats, \"$org\": {\"repos\": $org_repos, \"members\": $org_members}"
  fi
done
org_stats="$org_stats}"

ok "Orgs: $org_stats"

python3 -c "
import json

repo_stats = json.loads('''$repo_stats''')
org_stats = json.loads('''$org_stats''')

output = {
    'source': 'github-deep',
    'collected_at': '$TIMESTAMP',
    'date': '$TODAY',
    'profile': {
        'followers': $followers,
        'following': $following,
        'public_repos': $public_repos,
        'public_gists': $public_gists
    },
    'repos': repo_stats,
    'orgs': org_stats
}

with open('$OUT', 'w') as f:
    json.dump(output, f, indent=2)
" 2>/dev/null

ok "Deep GitHub metrics collected"
