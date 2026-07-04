# Seven Springs — Progress Tracker

Single source of truth for project status. **Update this file in every commit
that changes status.** Roadmap definitions live in GDD.md §14.

## Phase status

| Phase | Status |
|---|---|
| 0 — Game Design Document | ✅ done (living doc — GDD.md) |
| 1 — Grey-box combat prototype | ✅ done |
| 2 — Vertical slice | 🔨 in progress |
| 3 — Content & backend | ⬜ not started |
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
- [x] **Deterministic combat (GDD §4.4)**: full randomness audit; crit→flat Precision, ±5% variance removed, debuffs always land scaled by potency (chance × Potency − Ward) and stack, Evasion→Veil (flat dmg reduction), Whispers→per-turn Fervor drain — all expected-value preserving. Only cosmetic randomness remains. New tuning tools: min_clear_levels (win patterns), boss_scale_sweep
- [x] **Monetization pivot — GAMBLING-FREE (GDD §9, charter §12.9)**: all %-roll acquisition removed as maysir. Tiered token currencies (Silver Marks / Violet Seals / Emerald Sigils), fixed-price deterministic Calling (player chooses the hero; ceremony kept), Teaching Scrolls sold directly, dupes/pity/rates deleted. Bundle pricing anchored to preserve expected revenue per team comp. Marketing identity: "the gambling-free hero collector"

### In progress
- [ ] Manual playtest pass on the visual build (feel, pacing, clarity) — **owner: Kareem**
- [ ] Style bible: ~50 explorations → north-star set → `art/STYLE_BIBLE.md` — **owner: Kareem, blocked on tool choice (Niji sub vs. Draw Things)**

### Next up (ordered)
- [ ] First real character through full art pipe (Vale: design→LoRA→portrait+chibi→import) — validates pipeline end to end
- [ ] Chibi battle sprites + Skeleton2D rig template (replaces card pulse animations with real skeletal animation)
- [ ] Teaching Scrolls spend: skill-up system
- [ ] Audio: Suno Pro subscription + generate launch BGM set per AI_ART_PIPELINE.md §11.3 (Stable Audio is the tracked fallback; review trigger = summer 2026 fair-use ruling) — **owner: Kareem**
- [ ] Mobile export test on a real device (do EARLY — GDD §13.4)
- [ ] Tutorial/first-session flow
- [ ] Codex ("The Traveler's Notebook") first entries — the dawah layer (GDD §1.1); lore research source: nurmuhammad.com per §1.1 (lesser-known tariqah teachings as inspiration, filtered through language policy + scholar review)
- [ ] Content lifecycle (GDD §6.1): 3-star stage objectives, Hard-mode valley re-clears, The Minaret (now a pre-launch requirement), weekly Vice trials

### Roadmap notes (not scheduled)
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
Near-term client prep from BACKEND.md §3: EconomyService interface seam,
save_version field, battle action-log recording.

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
