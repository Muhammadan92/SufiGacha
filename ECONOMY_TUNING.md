# Economy & Engagement Tuning Playbook — SEVEN SPRINGS

The living process for keeping **time-spent** and **revenue** on target as
content is added, through launch and every expansion. The measuring
instrument is `tests/simulate_economy.gd` (90-day deterministic player
careers against the full current game). **Nothing that touches the economy
ships without a sim run.**

```
godot --headless --path . -s res://tests/simulate_economy.gd
```

## 1. The model

Five player profiles, each a daily-policy automaton playing REAL battles
(engine-accurate, cached — deterministic combat makes outcomes a pure
function of stage × level × mastery):

| Profile | Breath/day | Pass | Pack budget/mo |
|---|---|---|---|
| f2p casual | 80 | – | $0 |
| f2p hardcore | 200 | – | $0 |
| pass holder | 110 | $5/mo | $0 |
| light spender | 110 | $5/mo | $15 |
| completionist | 200 | $5/mo | unbounded |

Daily policy: push campaign frontier (farm on 2 consecutive losses) → climb
the Minaret until first loss → spend tokens on the hero desire-list → buy at
most one real-money pack if a desired hero is blocked and budget remains →
convert surplus Marks into Scrolls into team Mastery.

## 2. Assumptions (change ONLY with a written reason, they move every number)

- `SECONDS_PER_TURN = 0.9`, `MENU_SECONDS_PER_RUN = 25`, 3 min/day overhead —
  calibrate these against real playtest timings when available.
- Team stays the four starters (conservative power floor; purchased heroes
  count for collection/revenue, not combat). Real players do better →
  real progression is slightly faster than simulated.
- Valleys 2–7 are synthesized from the Valley-1 curve until authored; the
  synth parameters in the sim ARE the draft economy for authoring them.
- No events/live-ops income modeled yet — add to the sim the day they ship.

## 3. KPI targets (grey-box; re-baseline at vertical slice)

| KPI | Target | Red flag |
|---|---|---|
| Session time, casual | 15–30 min/day | <10 (nothing to do) or >45 (chore) |
| Session time, hardcore | 40–70 min/day | >90 |
| Campaign clear, casual | 14–25 days (pre-staggered-release) | <10 days |
| F2P chosen-Luminary rate | 1 per 2–4 weeks steady-state | >1/week (over-generous) |
| Dry days (no progression) in 90 | < 15, none before day 30 | any before day 21 |
| Pass holder value feel | visibly ahead of f2p casual | indistinguishable |
| Light spender 90-day revenue | $40–60 (pass + ~$15/mo packs) | budget unspent (nothing worth buying) |
| Completionist ceiling | $250–350 to own every current hero | <$150 (roster too cheap) |
| Cost per chosen Luminary | $66–72 effective (bundle) | drifts from the $70–90 anchor |

**The revenue invariant** (GDD §9.3): expected spend to assemble a chosen
team composition stays anchored to the old genre expectation (~$70–90 per
Luminary). Generosity changes must preserve this — give *time*, give
*choice*, never quietly give the anchor away.

## 4. Tuning levers → what they move

| Lever (where) | Primarily moves | Couplings to watch |
|---|---|---|
| XP curve / `XP_VALLEY_BONUS` | days-to-clear, session count | faster levels → earlier walls beaten → shorter content runway |
| Breath budget & stage costs | session minutes, daily run count | more Breath → more Marks/day → more Scrolls → stronger teams |
| Stage token rewards (`.tres`) | F2P income rate | Seals/Sigils feed the Luminary rate directly |
| Star rewards (`STAR_*` in game_state) | early-game income burst | one-time income; safe-ish, but 36 stages × 3 add up |
| Minaret curve (+0.05 scale/floor) & rewards | steady-state income + dry-day suppressor | every-10th-floor Sigil is recurring F2P Luminary income — the main lever on that KPI |
| Unit prices (`UNIT_COSTS`) | everything monetary | changing these moves the anchor — GDD §9 decision, not a tuning knob |
| Pack prices/bundles (GDD §9.3) | $ per token → LTV | store-listed; change rarely, deliberately |
| Mastery costs (`mastery_cost`) | Marks sink depth, late-game goals | too cheap → Marks pile up → dead currency |
| Boss `enemy_scale` breakpoints | wall placement (grind or spend moments) | use tests/boss_scale_sweep.gd; watch non-monotonic cliffs |

## 5. The process (every economy-touching change)

1. Make the change (data files / constants).
2. Run the economy sim + `min_clear_levels` if difficulty was touched.
3. Compare against §3. Every KPI in band → ship. Out of band → either
   retune or **change the target with a written rationale in the GDD**.
4. Commit sim output summary in the commit message (the repo's history IS
   the tuning log).
5. Re-verify after: balance sims still hold (stage curve, comp patterns).

## 6. Expansion protocol (new content = new income AND new demand)

Adding anything that pays tokens or costs tokens shifts the equilibrium.
Checklist per expansion:

- **New valley/chapter**: author reward fields against the synth draft the
  sim already assumes (they're calibrated); re-run; check dry-day KPI moved
  LATER (content runway grew) without the Luminary-rate KPI accelerating.
- **New heroes**: extend `DESIRES` in the sim; completionist ceiling should
  RISE by ≈ the new heroes' anchor value (that's the expansion's revenue
  thesis — verify it, report it).
- **New modes** (trials, hard modes, events): model their income in the sim
  BEFORE shipping; recurring Sigil sources are the most dangerous lever —
  each one permanently raises F2P Luminary rate.
- **Part 2 (The Twelve Moons)**: rerun everything; the perma-buff reward
  (Fountain of Youth) also shifts min-clear levels — re-baseline difficulty.
- **Price changes**: never silently; GDD §9 edit + this doc's targets first.

## 7. Baseline — 2026-07-04 (grey-box, staggered release modeled)

| Profile | Camp clear | Min/day | Heroes bought (90d) | Revenue (90d) |
|---|---|---|---|---|
| f2p casual | ~day 90+ | 17 ✓ | 2 | $0 |
| f2p hardcore | day 90 | 32 ✓ | 3 | $0 |
| pass holder | day 90 | 21 ✓ | 4 | $15 ✓ |
| light spender | day 90 | 21 ✓ | 11 (all) | $51 ✓ |
| completionist | day 90 | 33 ✓ | 11 (all, day 30) | $345 ✓ |

Tuning applied to reach this: Minaret XP cut (15+3f → 10+2f), tower curve
steepened (0.05 → 0.07/floor), staggered valley release + gap-farming
modeled. Findings carried as open items:

1. **Dry-progression days remain high (~75/90)** — but minutes stay healthy
   because farming fills gaps; the metric counts "no NEW unlock" days. The
   real fix is the planned **daily material sanctums** (GDD §7) — build
   before soft launch, add to the sim the same day.
2. **Level cap 60 reached by ~day 30** via unbounded farm XP — fine while
   cap content doesn't exist; revisit XP curve or cap when Ascension ships.
3. **F2P chosen-Luminary rate ~2-3/90d** — at/below the low end of target;
   acceptable for a conservative starter-team model. Sanctums/events income
   must be priced against this (§6).

## 8. Known limitations (improve as the game matures)

- Starter-team-only power (floor estimate); no roster-swap modeling.
- Uniform team mastery; no per-character scroll strategy.
- No churn modeling — profiles play every day for 90 days; real retention
  shapes revenue heavily and arrives with real analytics (BACKEND.md §B.5).
- Engagement seconds are estimates until calibrated against device playtests.
