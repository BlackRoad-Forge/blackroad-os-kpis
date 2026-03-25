<!-- BlackRoad SEO Enhanced -->

# ulackroad os kpis

> Part of **[BlackRoad OS](https://blackroad.io)** — Sovereign Computing for Everyone

[![BlackRoad OS](https://img.shields.io/badge/BlackRoad-OS-ff1d6c?style=for-the-badge)](https://blackroad.io)
[![BlackRoad Forge](https://img.shields.io/badge/Org-BlackRoad-Forge-2979ff?style=for-the-badge)](https://github.com/BlackRoad-Forge)
[![License](https://img.shields.io/badge/License-Proprietary-f5a623?style=for-the-badge)](LICENSE)

**ulackroad os kpis** is part of the **BlackRoad OS** ecosystem — a sovereign, distributed operating system built on edge computing, local AI, and mesh networking by **BlackRoad OS, Inc.**

## About BlackRoad OS

BlackRoad OS is a sovereign computing platform that runs AI locally on your own hardware. No cloud dependencies. No API keys. No surveillance. Built by [BlackRoad OS, Inc.](https://github.com/BlackRoad-OS-Inc), a Delaware C-Corp founded in 2025.

### Key Features
- **Local AI** — Run LLMs on Raspberry Pi, Hailo-8, and commodity hardware
- **Mesh Networking** — WireGuard VPN, NATS pub/sub, peer-to-peer communication
- **Edge Computing** — 52 TOPS of AI acceleration across a Pi fleet
- **Self-Hosted Everything** — Git, DNS, storage, CI/CD, chat — all sovereign
- **Zero Cloud Dependencies** — Your data stays on your hardware

### The BlackRoad Ecosystem
| Organization | Focus |
|---|---|
| [BlackRoad OS](https://github.com/BlackRoad-OS) | Core platform and applications |
| [BlackRoad OS, Inc.](https://github.com/BlackRoad-OS-Inc) | Corporate and enterprise |
| [BlackRoad AI](https://github.com/BlackRoad-AI) | Artificial intelligence and ML |
| [BlackRoad Hardware](https://github.com/BlackRoad-Hardware) | Edge hardware and IoT |
| [BlackRoad Security](https://github.com/BlackRoad-Security) | Cybersecurity and auditing |
| [BlackRoad Quantum](https://github.com/BlackRoad-Quantum) | Quantum computing research |
| [BlackRoad Agents](https://github.com/BlackRoad-Agents) | Autonomous AI agents |
| [BlackRoad Network](https://github.com/BlackRoad-Network) | Mesh and distributed networking |
| [BlackRoad Education](https://github.com/BlackRoad-Education) | Learning and tutoring platforms |
| [BlackRoad Labs](https://github.com/BlackRoad-Labs) | Research and experiments |
| [BlackRoad Cloud](https://github.com/BlackRoad-Cloud) | Self-hosted cloud infrastructure |
| [BlackRoad Forge](https://github.com/BlackRoad-Forge) | Developer tools and utilities |

### Links
- **Website**: [blackroad.io](https://blackroad.io)
- **Documentation**: [docs.blackroad.io](https://docs.blackroad.io)
- **Chat**: [chat.blackroad.io](https://chat.blackroad.io)
- **Search**: [search.blackroad.io](https://search.blackroad.io)

---


Daily collection of fleet health, GitHub activity, Cloudflare stats, and autonomy scores across the BlackRoad infrastructure.

## What it Does

Runs 14 collectors that SSH into 5 Raspberry Pi nodes, query GitHub/Gitea APIs, and probe Cloudflare resources. Results are stored as daily snapshots, posted to Slack, and pushed to Cloudflare KV for dashboard display.

## Collectors

| Collector | What it Measures |
|-----------|-----------------|
| `github.sh` | Repos, commits, stars, PRs (fork-excluded counts) |
| `github-deep.sh` | Per-repo stats across all orgs |
| `github-all-orgs.sh` | Multi-org aggregation |
| `gitea.sh` | Gitea repos, orgs, mirrors (Octavia :3100) |
| `fleet.sh` | SSH probe: CPU temp, RAM, disk, uptime per node |
| `fleet-probe.py` | Deep fleet health with service-level checks |
| `services.sh` | Port scanning and service status across fleet |
| `services-probe.py` | HTTP health checks on all endpoints |
| `autonomy.sh` | Self-healing event counts, restart frequency |
| `loc.sh` | Lines of code across all repos |
| `cloudflare.sh` | Pages, Workers, D1, KV, R2, tunnel counts |
| `traffic.sh` | Analytics data from sovereign analytics Worker |
| `local.sh` | Mac-side metrics (cron jobs, scripts, databases) |
| `collect-all.sh` | Runs all collectors in sequence |

## Reports

| Report | Destination |
|--------|-------------|
| `slack-notify.sh` | Daily Slack post with key metrics |
| `slack-alert.sh` | Threshold alerts (node down, disk full, etc.) |
| `slack-weekly.sh` | Weekly summary with trends |
| `daily-report.sh` | Markdown report to `data/` |
| `markdown-report.sh` | Formatted report for backlog |
| `push-kv.sh` | Push latest metrics to Cloudflare KV |
| `update-resumes.sh` | Update portfolio stats from live data |

## Schedule

```
# Mac crontab
0 6 * * * cd ~/blackroad-os-kpis && bash collectors/collect-all.sh
5 6 * * * cd ~/blackroad-os-kpis && bash reports/slack-notify.sh
```

Daily at 6 AM CST. GitHub Actions also runs collectors on push.

## First Collection (2026-03-12)

| Metric | Value |
|--------|-------|
| GitHub repos (non-fork) | 115 |
| Gitea repos | 207 |
| Total commits | 349 |
| Lines of code | 7.2M |
| Fleet nodes online | 4/5 |
| Ollama models | 27 |
| Cloudflare Pages | 95 |
| D1 databases | 8 |

## Setup

```bash
# Install collectors
git clone https://github.com/blackboxprogramming/blackroad-os-kpis.git
cd blackroad-os-kpis

# Install cron jobs
bash cron-install.sh

# Configure Slack (optional)
bash scripts/setup-slack.sh

# Run all collectors manually
bash collectors/collect-all.sh
```

## Data

Daily snapshots are stored in `data/` as timestamped JSON files. The `LATEST.md` file contains the most recent collection summary.

## License

Copyright 2026 BlackRoad OS, Inc. — Alexa Amundson. All rights reserved.
