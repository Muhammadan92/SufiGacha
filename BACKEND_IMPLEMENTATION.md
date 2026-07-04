# Backend Implementation Guide — SEVEN SPRINGS

Step-by-step build order for the plan in `BACKEND.md`. Execute when the first
IAP approaches (Phase 3). Steps tagged **[MANUAL — Kareem]** are actions only
a human account-holder can perform; everything else is code/config work that
can be done in-session. UI navigation notes are as of mid-2026 — expect
drift; the *artifact* each step produces is what matters.

Estimated total effort: **2–3 weeks part-time** for Phase B, most of it
waiting on store review processes, not engineering.

---

## Stage 0 — Accounts & assets (all manual, do first; reviews take days)

### 0.1 [MANUAL — Kareem] Apple Developer Program
1. Enroll at developer.apple.com ($99/yr). Use an entity/DBA name you want
   publicly visible as the seller.
2. In **App Store Connect → Apps → New App**: create the Seven Springs app
   record (bundle id e.g. `com.<yourorg>.sevensprings` — decide once, it's
   permanent).
3. **App Store Connect → Users and Access → Integrations → In-App Purchase**:
   generate an **In-App Purchase key** (.p8 file) and note the Key ID +
   Issuer ID. This is what the server uses to verify receipts (App Store
   Server API). Store the .p8 in the secrets vault (§0.5) — it downloads
   exactly once.

### 0.2 [MANUAL — Kareem] Google Play Console
1. Register at play.google.com/console ($25 once).
2. Create the app record (same package name as the bundle id).
3. **Setup → API access**: create/link a Google Cloud project, create a
   **service account** with the "Service Account User" role, grant it
   Financial Data permission in Play Console, and download its JSON key →
   secrets vault. This key lets the server verify purchases via the Play
   Developer API.

### 0.3 [MANUAL — Kareem] IAP products (both stores)
Create the token packs from GDD §9.3, same product ids on both stores:

| Product id | Contents | Price tier |
|---|---|---|
| `sigils_1` | 1 Emerald Sigil | $11.99 |
| `sigils_3` | 3 Emerald Sigils | $32.99 |
| `sigils_6` | 6 Emerald Sigils | $65.99 |
| `seals_10` | 10 Violet Seals | $17.99 |
| `marks_1000` | 1000 Silver Marks | $4.99 |
| `chest_company` | 6 Sigils + 20 Seals + 2000 Marks | $89.99 |
| `pass_monthly` | Traveler's Pass (auto-renewing sub) | $4.99/mo |

All **consumables** except the Pass (subscription). Mark all as
"contains no random items" wherever the forms ask.

### 0.4 [MANUAL — Kareem] VPS + domain
1. Rent a VPS: 2 vCPU / 4 GB RAM / 40 GB disk (Hetzner CX22 ~$8/mo or
   DigitalOcean ~$24/mo). Pick a region near your expected first players.
2. Buy/assign a domain (e.g. `api.sevensprings.game`) and point an A record
   at the VPS IP.
3. Create a non-root user, disable password SSH (key-only), enable a
   firewall allowing 22/80/443 only. (Standard hardening — say the word and
   I'll generate the exact commands for your distro.)

### 0.5 [MANUAL — Kareem] Secrets vault + telemetry accounts
1. Create a password-manager vault entry (or `pass`/1Password) holding: the
   .p8 key, Play service-account JSON, Postgres password, Nakama server key,
   Sentry DSN, PostHog key. **Nothing secret ever enters the git repo.**
2. Sign up: **Sentry** (free tier) → create a Godot project → note DSN.
   **PostHog** (free tier) → note project API key + host.

---

## Stage 1 — Server: Nakama on the VPS

### 1.1 Deploy (code/config — assisted)
Directory on the VPS: `/opt/sevensprings/`. Files (I generate these when we
execute; committed to a private `infra/` repo, NOT this one):

```yaml
# docker-compose.yml (shape)
services:
  postgres:
    image: postgres:16
    environment: [POSTGRES_PASSWORD from .env]
    volumes: [pgdata:/var/lib/postgresql/data]
  nakama:
    image: registry.heroiclabs.com/heroiclabs/nakama:latest
    depends_on: [postgres]
    entrypoint: migrate-then-run with --config /nakama/data/config.yml
    volumes: [./modules:/nakama/data/modules, ./config.yml:/nakama/data/config.yml]
    ports: ["127.0.0.1:7350:7350"]   # gRPC/HTTP API, localhost only
  caddy:
    image: caddy:2
    ports: ["80:80", "443:443"]      # TLS termination -> nakama:7350
```

Key config decisions:
- Nakama API exposed **only** through Caddy TLS on 443; console (7351)
  reachable via SSH tunnel only, never public.
- `socket.server_key` = random 32+ chars (client "public" key), admin
  console password = strong + vaulted.

### 1.2 [MANUAL — Kareem] Bring-up checklist
1. `docker compose up -d`, confirm `https://api.<domain>/healthcheck` = ok.
2. SSH-tunnel to the Nakama console, log in, change default credentials.
3. Set up the nightly backup cron: `pg_dump` to a compressed file, synced
   off-box (rclone → any object storage). **Test one restore before launch.**

### 1.3 Server modules (TypeScript — I write these)
`modules/economy.ts` — the authoritative economy, mirroring `game_state.gd`:
- RPC `earn_stage_reward(stage_id, action_log_hash)`: validates stage
  unlocked + Breath ledger + rewards from server-held stage table (mirrors
  data/stages); idempotency key = (user, stage, attempt-counter).
- RPC `purchase_unit(unit_id)` / `purchase_scroll(count)`: fixed prices from
  server config; atomic wallet ops via Nakama's wallet ledger.
- RPC `grant_iap(receipt)`: verifies with Apple App Store Server API / Play
  Developer API (keys from §0.1/0.2), grants tokens once per transaction id.
- Storage collections: `profile` (roster/levels/cleared — the save blob,
  versioned per BACKEND.md §3), `config` (prices, stage rewards → remote
  config the client fetches on boot).
- Anti-abuse: server-side Breath ledger (regen computed from timestamps
  server-side); flagged accounts get action-log replay verification (§3).

---

## Stage 2 — Client: Godot integration (code — I write this)

1. **Nakama Godot SDK**: add the official addon; a thin `Net` autoload wraps
   session + socket + retry.
2. **EconomyService seam** (BACKEND.md §3): extract every mutation in `Game`
   (earn/spend/grant) behind `EconomyService`. Two implementations:
   `EconomyLocal` (today's behavior — remains the offline/dev path) and
   `EconomyNakama` (RPC calls, optimistic UI with server reconciliation).
   Selected by a single flag in project settings.
3. **Auth flow**: silent device-id login on boot → profile fetched/merged.
   First login migrates the local save (client submits blob; server accepts
   roster/progress once, wallet starts from server truth + a goodwill grant).
   Settings screen later offers email/Apple/Google linking.
4. **Offline mode**: campaign playable offline on cached profile; The
   Calling and IAP require connection; earned rewards queue and reconcile
   (idempotency keys make retries safe).
5. **IAP plugins**: official Godot iOS StoreKit + Android Play Billing
   plugins; purchase flow = store purchase → receipt → `grant_iap` →
   tokens appear. **[MANUAL — Kareem]**: sandbox test accounts on both
   stores (App Store Connect → Sandbox Testers; Play → License Testers),
   then one real end-to-end purchase each on TestFlight/Internal testing.
6. **Telemetry**: Sentry Godot SDK (crashes) + a 20-line PostHog HTTP
   client (events: session, stage_attempt/clear, purchase, calling_open).

---

## Stage 3 — Replay verification service (code — I write this, ~1 day)

A headless Godot container running our actual `BattleManager`:
- HTTP wrapper (Godot's HTTPServer or a 30-line sidecar) accepting
  `{team, levels, stage_id, action_log}` → re-simulates → returns result.
- Deterministic combat (GDD §4.4) guarantees exact reproduction; any
  mismatch = cheating or version skew (log both, punish only after review).
- Called async for: flagged accounts, top-N Minaret leaderboard entries.
  NOT in the hot path of normal play.

---

## Stage 4 — Cutover & launch readiness

1. **Staging first**: a second compose stack (`api-staging.<domain>`) —
   client dev builds point here; store review builds point at prod.
2. Dry-run checklist before soft launch:
   - [ ] restore-from-backup rehearsal done
   - [ ] sandbox IAP verified on both platforms **[MANUAL — Kareem]**
   - [ ] kill-switch tested: server `config.min_client_version` blocks old clients
   - [ ] load smoke: 200 simulated clients (script) against staging
   - [ ] Sentry receiving crashes from a TestFlight build
   - [ ] privacy policy URL live (required by both stores) **[MANUAL — Kareem]**
   - [ ] GDPR endpoints: export + delete RPCs implemented and tested
3. Soft-launch region config **[MANUAL — Kareem]**: pick 1–2 markets
   (classic: Philippines/Nordics; note: as a gambling-free title we have no
   region exclusions to worry about), set store availability accordingly.

---

## Execution order summary

| # | What | Who | Blocks |
|---|---|---|---|
| 1 | §0.1–0.5 accounts, VPS, secrets | Kareem | everything below |
| 2 | §1 Nakama deploy + economy module | me (+ Kareem runs 1.2 checklist) | 1 |
| 3 | §2 client integration + EconomyService | me | 2 |
| 4 | §2.5 sandbox IAP verification | Kareem | 3 |
| 5 | §3 replay verification service | me | 2 (parallel with 3–4) |
| 6 | §4 staging, dry-run checklist, soft launch | both | all |
