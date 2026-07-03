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
- [ ] Codex ("The Traveler's Notebook") first entries — the dawah layer (GDD §1.1)
- [ ] Content lifecycle (GDD §6.1): 3-star stage objectives, Hard-mode valley re-clears, The Minaret (now a pre-launch requirement), weekly Vice trials

### Roadmap notes (not scheduled)
- **Part 2 campaign: *The Twelve Moons*** — 12 chapters x 9 stages, stage 108
  ends at the Fountain of Abundance; completion reward "Fountain of Youth"
  perma-buff. Full notes: GDD §6.2. Design begins with Phase 3 planning.

### Deliberately deferred (Phase 3+)
Backend/server-authoritative pulls, IAP, PvP, Lodges (guilds), Valleys 2–7,
Talismans, scholar review (pre-launch requirement), localization.

## Balance targets (verified by sims — rerun after any data change)
- Trash stages: ~100% auto-win at expected level; boss stage: 60–70%
- Comp ordering on boss: balanced > missing-role comps > no-healer (~0%)
- Anti-stall: turtle comps must lose long fights (Kibr enrage)

## Testing commands
See README.md "Headless testing & balance sims". Run smoke + systems tests
before every commit; stage sims after any unit/stage data change.
