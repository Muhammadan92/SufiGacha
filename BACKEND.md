# Backend & Server Infrastructure Plan — SEVEN SPRINGS

Companion to GDD §13.3. Status: **planned, not built** — deliberately. The
backend becomes mandatory the moment real money enters (Phase 3); building it
earlier is wasted motion while systems still change shape.

## 0. What our design decisions already bought us

Two recent rulings simplified this plan dramatically:

1. **Gambling-free (GDD §9)** — the #1 reason gacha games need servers is
   server-side RNG (clients can't be trusted to roll dice). We have no dice.
   The server's economy job reduces to: an **authoritative wallet + inventory
   with atomic, idempotent transactions**. Purchases are verifiable
   arithmetic, not protected randomness.
2. **Deterministic combat (GDD §4.4)** — identical inputs → identical
   battles. Anti-cheat becomes **replay verification**: the client submits a
   compact action log (team, levels, stage, chosen skills/targets per turn);
   the server can re-simulate any battle and confirm the result exactly. No
   heuristics, no fuzzy tolerance. Very few games get this for free.

## 1. Phases

### Phase A — now → vertical slice (CURRENT)
- Local save only (`user://save.json`), no accounts, no network.
- **One obligation**: keep the seams clean. `Game` (wallet/roster/progress)
  is the single choke point for all economy mutations — no screen touches
  currencies directly. This is already true; keep it true.

### Phase B — pre-soft-launch (with first IAP)  ← the real build
1. **Accounts & cloud save**: device-anonymous login first (frictionless),
   optional email/Apple/Google link. Save blob versioned; server holds truth,
   client caches for offline play (campaign playable offline; SHOP requires
   online).
2. **Authoritative economy**: wallet (Marks/Seals/Sigils/Scrolls), roster,
   and all purchases move server-side. Endpoints: `earn` (stage rewards,
   validated), `purchase_unit`, `purchase_scroll`, `grant_iap`. All
   idempotent (client retries safely).
3. **IAP receipt validation**: App Store / Play receipts verified
   server-side before tokens are granted. Never trust the client's word
   that money happened.
4. **Stage-reward validation**: cheap sanity first (stage unlocked? Breath
   paid? rewards match stage data? clear-rate plausible?); deterministic
   replay verification (see §0.2) reserved for flagged accounts /
   leaderboard submissions rather than every battle.
5. **Telemetry & crash reporting**: PostHog (events: stage attempts/clears,
   purchases, session length) + Sentry. Wired BEFORE soft launch or the
   launch teaches nothing.
6. **Remote config**: prices, stage rewards, and balance scales fetchable
   from server-side config so economy tuning needs no client release
   (our data-driven .tres discipline maps directly onto this).

### Phase C — live-ops scale
- The Minaret leaderboards (replay-verified — deterministic combat means a
  submitted climb can be *proven*), events calendar, gifts/codes.
- Lodges (guilds), PvP (async: defense teams simulated deterministically —
  again free integrity), chat (heavy moderation burden — defer as long as
  possible).
- Compliance: GDPR/CCPA data export & deletion, COPPA posture (13+ rating),
  privacy policy. No loot-box compliance needed anywhere — gambling-free.

## 2. Stack recommendation

**Nakama** (open-source game backend) — primary recommendation:
- Built-in: auth (device/email/social), wallet with atomic transactions,
  storage (cloud save), IAP receipt validation (Apple/Google), leaderboards,
  groups (→ Lodges), remote config via storage objects.
- **Official Godot 4 client SDK** — first-class fit.
- Server logic in TypeScript/Go/Lua modules (purchase endpoints, reward
  validation live here).
- Hosting: self-host Docker on a small VPS (~$20–40/mo) for soft launch;
  Heroic Cloud managed later if scale demands.

Fallback: Supabase (Postgres + edge functions) if we outgrow Nakama's data
model or want SQL-first analytics; Firebase explicitly avoided (vendor
lock-in, weak fit for authoritative game economies).

Battle replay verification service: a headless Godot instance running our
actual `BattleManager` behind a tiny HTTP wrapper — the exact engine, not a
reimplementation. Deterministic combat makes this a ~day of work when needed.

## 3. Client-side preparation (do during Phase A/B boundary)
- Extract `Game`'s economy mutations behind an interface
  (`EconomyService.local` → `EconomyService.nakama`), per GDD §13.3.
- Add a `client_version` + `save_version` to the save blob now (already
  cheap; migration proved out with the Pearls→Marks conversion).
- Battle action-log recording (list of {actor, skill, target} per turn) —
  trivial to emit from BattleManager signals; needed for replays, useful for
  bug reports immediately.

## 4. Cost envelope (soft launch scale, <10k DAU)
- VPS for Nakama + Postgres: ~$20–40/mo
- PostHog/Sentry free tiers: $0
- Apple/Google dev accounts: $99/yr + $25 once
- Total infra: **under $50/mo** until the game earns it.

## 5. Explicitly NOT planned
- Realtime multiplayer (no design need), server-side matchmaking, chat at
  launch, custom infra/Kubernetes before scale forces it.
