# Self-Hosted GitHub Actions Runner — Hands-On Tutorial

> How to run GitHub Actions CI jobs on your own machine (or any box you own)
> instead of paying for GitHub-hosted minutes. Written from a working RND setup.
>
> Status: proven working Oct 2026 — successful end-to-end runs, both jobs green.
> Companion spec: `self-hosted-runner-spec.md` (Hetzner Cloud rollout plan).

---

## 1. What we built

| Item | Value |
|---|---|
| Runner name | `fahmi-wsl-runner` |
| Runner version | 2.338.0 |
| Machine | WSL Ubuntu 24.04, 12 threads / 8 GB RAM, x86_64 |
| Registered to | `fahmiaga/wallet-app` (repository-level) |
| Labels | `self-hosted`, `linux`, `rnd-local` |
| Workflow | `.github/workflows/rnd-selfhosted.yml` |
| Final result | Run `39720111554` — `lint` 16s ✅, `scan_ruby` 15s ✅ |

## 2. The concept

```
Push ──▶ GitHub Actions ──▶ job queued for label [self-hosted, linux, rnd-local]
                                  │
          local runner polls ─────┘   (outbound HTTPS long-poll, no inbound needed)
                 │
                 ▼
   job executes on the runner box (_work/ dir) ──▶ results reported back
```

Key facts:

- The runner is a small agent that **long-polls GitHub over HTTPS (outbound only)**.
  No inbound ports required for CI. A firewall rule for SSH is all you need.
- **Labels are the routing mechanism.** The workflow declares
  `runs-on: [self-hosted, linux, rnd-local]`; GitHub dispatches the job to any
  online runner that carries that exact label set. No match = job sits queued.
- Self-hosted minutes are **unmetered** by GitHub today (a $0.002/min platform fee
  was announced, then postponed — and even if it lands, it draws down your plan's
  free quota first).
- Billing on hosted runners is **per job, not per run** — parallel matrix jobs bill
  3–5x their wall-clock time. A flat-cost self-hosted box caps this regardless.

## 3. Prerequisites

- A GitHub repo where you have **admin access** (registration tokens require it).
- `gh` CLI authenticated (`gh auth status`) — optional but everything below assumes it.
- The toolchain your jobs need (Ruby, Node, etc.) — ideally preinstalled and
  *baked into the box* (see section 7 for why this matters).

## 4. Install the runner (one-time)

```bash
# Latest release as of writing
RUNNER_VER=2.338.0
mkdir -p ~/actions-runner && cd ~/actions-runner

curl -O https://github.com/actions/runner/releases/download/v${RUNNER_VER}/actions-runner-linux-x64-${RUNNER_VER}.tar.gz
tar xzf actions-runner-linux-x64-${RUNNER_VER}.tar.gz && rm actions-runner-linux-x64-${RUNNER_VER}.tar.gz

# sanity check
./bin/Runner.Listener --version
```

## 5. Register the runner

The registration token expires after **1 hour** and requires **admin** on the repo.

Option A — generate it with `gh` (fastest, no clicking):

```bash
TOKEN=$(gh api --method POST repos/<owner>/<repo>/actions/runners/registration-token --jq '.token')
echo "${TOKEN:0:6}...(OK)"
```

Option B — GitHub UI: *Settings → Actions → Runners → New self-hosted runner*,
pick Linux / x64, and copy the `--token` value from the displayed `config.sh` command.

Then configure:

```bash
cd ~/actions-runner
./config.sh \
  --url https://github.com/<owner>/<repo> \
  --token "$TOKEN" \
  --name fahmi-wsl-runner \
  --labels self-hosted,linux,rnd-local \
  --unattended
```

`--unattended` skips the interactive prompts. The registration persists on disk
(`.runner`, `.credentials`) — a reboot does **not** require re-registering.

## 6. Run it (and keep it running)

For quick work — a `tmux` session survives terminal closure:

```bash
tmux new-session -d -s ghrunner "cd ~/actions-runner && ./run.sh"

# verify locally
tmux capture-pane -t ghrunner -p | grep -v '^$' | tail -4
# expect: "Listening for Jobs"

# verify from GitHub's side
gh api repos/<owner>/<repo>/actions/runners --jq '.runners[] | "\(.name): \(.status)"'
# expect: fahmi-wsl-runner: online
```

For a permanent server (recommended once this graduates from R&D), run it as a
**systemd service**: `sudo ./svc.sh install && sudo ./svc.sh start`
(the runner ships with `svc.sh` for exactly this; add `unattended-upgrades`).

> Stopping the runner is safe by design: jobs simply queue at GitHub and
> automatically resume when the runner comes back online.

## 7. Make a workflow target the runner

```yaml
# .github/workflows/rnd-selfhosted.yml
name: RND Self-Hosted Runner Test

on:
  push:
    branches: [ fahmi-rnd-self-hosted ]

jobs:
  scan_ruby:
    runs-on: [self-hosted, linux, rnd-local]   # ← this is the magic line
    steps:
      - uses: actions/checkout@v4
      - run: echo "Runner: $(hostname) | $(nproc) threads | $(free -h | awk '/Mem:/ {print $2}') RAM | $(ruby -v)"
      - run: bundle exec brakeman --no-pager
```

## 8. Operations cheat sheet

```bash
# runner status
gh api repos/<owner>/<repo>/actions/runners --jq '.runners[] | "\(.name): \(.status)"'

# start / stop
tmux new-session -d -s ghrunner "cd ~/actions-runner && ./run.sh"
tmux kill-session -t ghrunner

# trigger & inspect without opening a browser
cd <repo-clone>
gh run list --limit 3
gh run view $(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')
gh run rerun $(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')
```

## 9. Troubleshooting — everything we hit (and how we fixed it)

| # | Symptom | Root cause | Fix |
|---|---|---|---|
| 1 | `gh api ... runners/registration-token` → **404** | API requires repo **admin**; collaborator tokens with push-only access get 404 | Use the repo owner's account (`gh auth switch`), or grab the token from Settings UI |
| 2 | `Registration token expired` | Token lives **1 hour** | Generate a fresh one, immediately register |
| 3 | `Error: EACCES: permission denied, mkdir '/opt/hostedtoolcache'` | `setup-*` actions install toolchains into a **root-owned** dir; on self-hosted it doesn't exist | **Fix A (canonical, needs sudo once):** `sudo mkdir -p /opt/hostedtoolcache && sudo chown -R $USER /opt/hostedtoolcache`. **Fix B (no sudo):** skip `setup-ruby` and use a Ruby already installed under `$HOME` (rbenv) — see section 10 |
| 4 | Setting `RUNNER_TOOL_CACHE` via runner `.env` or workflow `env:` **doesn't work** | The runner treats it as a reserved variable and overrides both | Only section 9#3's fixes survive; don't fight it |
| 5 | `Runner connect error: Conflict` after a restart | An orphaned runner process from the previous kill still holds the GitHub session | Kill **all** runner processes cleanly (`pkill -f Runner.Listener` — careful: use a pattern that won't match your own shell), wait ~30s for the session to release, start one fresh instance |
| 6 | Jobs stuck "queued" forever | No online runner carries the required labels | Start the runner, or fix the `runs-on:` labels to match |
| 7 | Workflow uses `services:` (e.g. `postgres` container) fails | Service containers on self-hosted **require Docker** | Install Docker (`docker.io` + add user to `docker` group, relogin), or restructure the job |

## 10. The "warm toolchain" pattern (why job runs were 15s)

Hosted runners are *ephemeral*: every job re-installs Ruby (or whatever) from zero.
Self-hosted runners persist. Our RND workflow leans into this:

```yaml
- name: Add preinstalled Ruby to PATH
  run: |
    echo "$HOME/.rbenv/bin" >> "$GITHUB_PATH"
    echo "$HOME/.rbenv/shims" >> "$GITHUB_PATH"

- name: Install gems (bundle install)   # cached gems → seconds, not minutes
  run: bundle install
```

Result: `bundle install` + a full `brakeman` scan in ~15 seconds, because the
gems already live on the box. On the hosted runner, the same `Set up Ruby` step
downloads and bootstraps the toolchain on **every single job** — that per-job cold
setup is a large share of why the hosted bill inflated.

This mirrors the spec's promise: *"warm caches, no queue, no per-job cold setup"*.

## 11. Demo talking points

| Anti-argument | Proof from this RND |
|---|---|
| "Does it really run on our hardware?" | Actions log shows the workspace under the runner's `_work` path; `Print runner info` step prints the box's hostname/threads/RAM |
| "Is it fast?" | 15–16s per job with a warm toolchain |
| "Will the cheap box be big enough?" | This test box is 12 threads / 8 GB — bigger than the planned CX33 (4 vCPU / 8 GB), so the Hetzner capacity case is already covered |
| "What if it goes down?" | Stop the runner → GitHub shows jobs queued; start it → they auto-execute |
| "Security?" | Repo must stay private (never attach a self-hosted runner to a public repo — any PR would run arbitrary code on the box); firewall = SSH-in from office IP only; `unattended-upgrades` on |

## 12. Graduation path to Hetzner (per the original spec)

1. Terraform-provision a CX33 (provisioner/cloud-init: build deps, Docker if needed,
   actions-runner, systemd svc, `unattended-upgrades`).
2. `/opt/hostedtoolcache` fix via cloud-init (as root there — trivial).
3. Register per repo (repo-level runners; personal accounts can't do org-level).
4. Monitoring: poll the runners API for `online` status, alert on offline
   (dead-man switch), plus an optional nightly canary workflow.
5. Flip the highest-billing repo's workflow to `runs-on: [self-hosted, linux]`,
   watch for a week, compare billed minutes before/after.

## 13. Cost math, for the record

| Setup | Monthly |
|---|---|
| GitHub-hosted overage (current run-rate) | ~$27–30+, rising with test growth |
| **Hetzner CX33 self-hosted** | **~$10–11 flat** |
| AWS t3.large (verified, Sept 2026) | ~$71 |
| AWS spot ephemeral | ~$5–10 — only wins at ~10x current volume |

Break-even is already behind us; the box caps all future growth.
