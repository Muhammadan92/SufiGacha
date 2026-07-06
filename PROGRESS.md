# Seven Springs — Progress Tracker

Single source of truth for project status. **Update this file in every commit
that changes status.** Roadmap definitions live in GDD.md §14.

## Phase status

| Phase | Status |
|---|---|
| 0 — Game Design Document | ✅ done (living doc — GDD.md) |
| 1 — Grey-box combat prototype | ✅ done |
| 2 — Vertical slice | 🔨 systems complete; awaiting art/audio (Kareem) + mobile test |
| 3 — Content & backend | 🔨 in progress — **campaign content COMPLETE** (all 7 valleys authored & tuned); backend awaits Stage 0 (Kareem) |
| 4 — Soft launch | ⬜ not started |

## Phase 2 — vertical slice checklist

### Done
- [x] Battle engine: turn meter, Fervor, statuses, affinity triangle, barriers, evasion, cleanse
- [x] Balance sim harness + tuned boss (comp ordering correct; boss 62% auto at expected level)
- [x] Full game loop: Home → Journey → battle → results → progression
- [x] Save file, Breath stamina (offline regen), XP/levels
- [x] The Calling: rates + 70-pity + 10-pull guarantee, dupes → Teaching Scrolls
- [x] All 14 launch characters + 4 enemies as data, with `art_notes` art briefs
- [x] Valley 1: 12 stages, tuned difficulty curve
- [x] Headless test suite: engine smoke, comp sims, stage-curve sims, systems tests
- [x] Battle presentation layer: unit cards, HP/Fervor bars, hit/heal animations, floating damage, Trance banners, boss-ultimate warning
- [x] Art pipeline automation: placeholder generator, data→prompt brief exporter, asset audit, import script (see AI_ART_PIPELINE.md §10)
- [x] Player-progression simulator (tests/simulate_progression.gd): day-by-day career model, real-engine battles — verdict: full campaign clears in ~7d hardcore / ~14d casual → content lifecycle plan in GDD §6.1
- [x] AudioManager: convention-loaded music (crossfades, per-screen keys) + SFX pool wired to battle signals; "percussion & voice only" toggle + volume settings on Home (persisted)
- [x] Placeholder audio generator (tools/gen_placeholder_audio.gd): 12 synthesized SFX + 6 seamless loops — game fully audible with zero real tracks; real imports (.ogg/.mp3) auto-outrank placeholder .wav
- [x] Summon reveal: sequential door-of-light animation on The Calling (rarity-colored, Luminary full-screen flash, tap-to-advance, Skip)
- [x] Asset audit extended to audio (70 tracked assets total)
- [x] **Code review (rf+rq) fixes**: season tier 30 was mathematically unreachable (TIER_XP 40→30; sim now models real XP/tier progression + warns if the track can't complete); uncompletable "climb" daily no longer dealt pre-Minaret; corrupt saves backed up to save.json.corrupt.bak before any overwrite; results Continue returns to origin screen; Journey difficulty survives rebuilds; economy sim reads game constants directly (hand-copied tables removed — they hid the tier bug); 3 regression tests added
- [x] **Launch roster COMPLETE: 28 playable heroes** (GDD §3.4) — 13 new (every order gets a full bench; first turn-meter tempo kit on Wren); Calling shop/sims/briefs updated; expansion protocol verified: completionist ceiling $495→$536, baseline LTV $0.96→$1.03/install net
- [x] **Web export working**: `build/web/` (43MB, browser-playable) — export preset + project icon committed; serve with `python3 -m http.server -d build/web`
- [x] Codex: 7 per-order entries ("The Silent Way" ... "The Way of Light"), inspired-by framing
- [x] Waymarks: 15 lifetime milestones w/ 5 lifetime Sigils — GDD §9.2's achievements income + the deliberate week-2 retention beat (15 stars → Sigil at ~day 10); Season screen tracking, results fanfare, sim-mirrored
- [x] CI: GitHub Actions runs systems + smoke + replay tests on every push (pinned headless Godot, cached)
- [x] Replay verification proven in-repo: a 96-turn battle reproduced exactly from its action log (BACKEND.md §0.2's anti-cheat, tested before any server exists)
- [x] **PHASE 3 CONTENT: all 7 valleys authored** — 72 new stages (v2-7) on the sim-calibrated curves; 6 new Vice bosses with vice-embodying kits (Hasad dispels blessings — new DISPEL effect; Ghadab's burning enrage; Hirs's Fervor-hoarding; Kasal's heal-race; Zeenah's gilded escorts; Ya's silence/despair) + 3 new trash enemies; all boss walls validated to E±1 contiguous via win-pattern sweeps (4 tuning passes); economy re-run on authored data: KPIs hold, minutes into band
- [x] Content lifecycle complete (GDD §6.1): Hard/Nightmare valley re-clears (x2.2/x3.2 scale, x2/x3 rewards, +1 Sigil per boss tier, chain-gated) + weekly Vice Trial (5 tiers vs Pride, weekly-claimable, no Sigils). Economy sim re-run: KPIs hold
- [x] Tutorial/first-session flow: 5-step guided intro (framing → Breath/stars → battle abilities & enemy-Trance warning → tokens/Calling → systems reveal) in the §1.1 register; per-screen overlay panels; save migration skips it for existing progress
- [x] **The daily loop (GDD §9.3.1 + §7)**: lunar season calendar (tabular Hijri, verified vs real date), Deeds (3 daily rotating + 3 weekly → Marks/Seals + season XP), Season Pass scaffolding (30 tiers, free/paid tracks matching the sim, retroactive prototype unlock), daily Sanctum (today's order, adaptive difficulty, 2 runs/day → Scrolls+Marks). Sim re-run: revenue/KPIs hold, F2P Luminary rate unchanged
- [x] **Revenue roadmap** (GDD §9.3, §9.3.1 (season pass), §9.3.2 (cadence) + ECONOMY_TUNING.md §6b): season pass, permanent cosmetics catalog, content cadence as the growth curve — all deterministic. Simulated: light spender $99/90d, completionist $495 + ~$150/mo cadence growth, blended ≈ $1.58 ARPU/mo retained (~$1.35 net); break-even ≈ 370 retained actives at solo cost base
- [x] **Economy & Engagement simulator** (tests/simulate_economy.gd, supersedes the progression sim) + **ECONOMY_TUNING.md playbook** (KPI targets, tuning levers, expansion protocol). Baseline recorded; first tuning pass applied (Minaret XP/curve). Verdict: minutes/day and revenue in band under staggered release; daily sanctums are the missing recurring loop
- [x] Teaching Scrolls spend: mastery system (5 ranks, +6% dmg/heal each, escalating scroll costs, roster UI)
- [x] 3-star stage objectives (clear / no falls / within turn target) with token rewards, per-stage best persisted, stage-select + results display
- [x] The Codex — "The Traveler's Notebook": 6 entries with Learn-more hyperlinks to recorded source pages; data-driven (data/codex/)
- [x] The Minaret: endless tower, no Breath cost, Vice floors every 10th, Seals/Sigils income, unlocks after 1-6
- [x] Comp-sim redesigned for determinism (win-pattern-by-level vs the real boss stage): balanced contiguous from L9 ✓, missing-role comps lag 3-5 levels ✓, turtle self-punishing at 358 turns
- [x] **Deterministic combat (GDD §4.4)**: full randomness audit; crit→flat Precision, ±5% variance removed, debuffs always land scaled by potency (chance × Potency − Ward) and stack, Evasion→Veil (flat dmg reduction), Whispers→per-turn Fervor drain — all expected-value preserving. Only cosmetic randomness remains. New tuning tools: min_clear_levels (win patterns), boss_scale_sweep
- [x] **Monetization pivot — GAMBLING-FREE (GDD §9, charter §12.9)**: all %-roll acquisition removed as maysir. Tiered token currencies (Silver Marks / Violet Seals / Emerald Sigils), fixed-price deterministic Calling (player chooses the hero; ceremony kept), Teaching Scrolls sold directly, dupes/pity/rates deleted. Bundle pricing anchored to preserve expected revenue per team comp. Marketing identity: "the gambling-free hero collector"

### In progress
- [ ] Manual playtest pass on the visual build (feel, pacing, clarity) — **owner: Kareem**
- [ ] Style bible: ~50 explorations → north-star set → `art/STYLE_BIBLE.md` — **owner: Kareem, blocked on tool choice (Niji sub vs. Draw Things)**

### Next up (ordered)
- [ ] First real character through full art pipe (Vale) — **owner: Kareem, walkthrough: CREATIVE_CHECKLIST.md**
- [ ] Audio: Suno Pro + launch BGM set — **owner: Kareem, walkthrough: CREATIVE_CHECKLIST.md Phase 5**
- [ ] Mobile export test (joint session — needs device + platform tooling)
- [ ] Chibi battle sprites + Skeleton2D rig template (needs Phase 2 art)
- [ ] Season pass IAP + real cosmetics (Phase 3, with backend)
- [ ] Comp-sim tuning backlog: no-tank L8 breakpoint quirk; turtle wins early but at 358 turns (enrage = time punishment; acceptable for grey-box, revisit with real kits)

### Roadmap notes (not scheduled)
- **Studio sync with Orders of Light: DROPPED** (2026-07-04, Kareem) — the
  two games are built fully independently.
- **Guardians (dragon allies)** — GDD §3.6: seven Guardian dragons, one per
  Spring, released across live-ops; first (Sage, Guardian of the First
  Spring) is in the summon pool now. Future engine work: buff-strip effect
  ("devours illusion"). Lore refs: nurmuhammad.com spiritual-dragons +
  Thuban teachings.
- **Part 2 campaign: *The Twelve Moons*** — 12 chapters x 9 stages, stage 108
  ends at the Fountain of Abundance; completion reward "Fountain of Youth"
  perma-buff. Full notes: GDD §6.2. Design begins with Phase 3 planning.

### Deliberately deferred (Phase 3+)
Backend build-out (fully planned in **BACKEND.md** — Nakama, authoritative
wallet, IAP validation, replay-verification anti-cheat; build with first
IAP), PvP, Lodges (guilds), Valleys 2–7, Talismans, scholar review
(pre-launch requirement), localization.
Near-term client prep from BACKEND.md §3: EconomyService interface seam
(done: save_version field, battle action-log recording).
Full build order + manual-step checklists: **BACKEND_IMPLEMENTATION.md**
(stage 0 accounts/VPS/secrets is all Kareem-manual and review-latency-bound —
start it ~a month before first IAP).

## Balance targets (DETERMINISTIC combat — GDD §4.4; rerun sims after any data change)
- Combat has zero dice: identical inputs = identical battles. The balance
  metric is now the **win pattern by level** (tests/min_clear_levels.gd),
  not win %. Non-monotonic breakpoints exist — always check the full
  pattern, never just the first winning level.
- Trash stages: W from level 1. Boss stages: contiguous W starting one level
  ABOVE natural arrival (Kibr: arrive L8, auto clears L9+ — grind one level
  or beat it at 8 with manual play).
- Follow-up owed: comp-comparison sim (tests/simulate.gd) predates
  determinism — redesign around per-comp min-clear levels; re-verify comp
  ordering and turtle anti-stall at actual stage scales.

## Testing commands
See README.md "Headless testing & balance sims". Run smoke + systems tests
before every commit; stage sims after any unit/stage data change.
