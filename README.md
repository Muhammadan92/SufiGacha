# Seven Springs

A Sufi-inspired collectible turn-based RPG for mobile, built in Godot 4.

- **[GDD.md](GDD.md)** — the full game design document (start here)
- **[AI_ART_PIPELINE.md](AI_ART_PIPELINE.md)** — how art assets are produced

## Current status: Phase 2 — grey-box vertical slice (full game loop)

The complete core loop, all in grey-box UI: **Home → Journey (12 Valley 1
stages) → turn-meter battles → XP/levels → rewards → The Calling (summoning
with published rates + pity)**. All 14 launch-roster characters from GDD §3.4
are implemented as data, plus 3 enemy types and the Valley 1 boss *Kibr,
Father of Pride*. Local save file, Breath (stamina) with offline regen,
company (team) editing, roster details.

## Running it

1. Install Godot 4.3+ (`brew install godot` on macOS, or [godotengine.org](https://godotengine.org/download))
2. From this folder: `godot --path .`  (or `godot -e --path .` for the editor, then F5)
3. Start the Journey. Stage 1-12 is the boss wall — expected to be hard at
   low levels; grind, summon, and build a real comp.

## Headless testing & balance sims

```
godot --headless --path . -s res://tests/smoke.gd            # engine smoke test (one full auto-battle)
godot --headless --path . -s res://tests/simulate.gd         # comp-balance sweep vs the boss
godot --headless --path . -s res://tests/simulate_stages.gd  # Valley 1 difficulty curve at expected levels
godot --headless --path . -s res://tests/systems_test.gd     # save/XP/Breath/gacha rates+pity (restores your save)
```

Tuning targets (auto-AI win rates): balanced comp ~60-70% on the boss at
expected level, missing-role comps ≤20%, no-healer ~0%, trash stages ~100%.
Kibr's *Swell of Pride* stacks without bound as anti-stall enrage — turtle
comps lose long fights by design.

## Project layout (GDD §13)

```
data/units/       one .tres Resource per character/enemy (stats + skills) — content lives here, not in code
data/stages/      one .tres per campaign stage (enemies, scale, rewards)
scenes/           main entry scene (screens are code-built Controls)
scripts/data/     Resource class definitions (UnitData, SkillData, EffectBlock, StageData)
scripts/core/     battle engine (BattleManager state machine, BattleUnit, affinity math)
scripts/screens/  grey-box UI screens (home, stages, roster, team, calling, battle, results)
scripts/systems/  autoloads: Db (content), Game (profile/save/gacha), Screens (navigation)
```

Architecture rules: all game content is data (`.tres` files); the battle engine
emits signals and never touches UI; the UI listens and never touches battle
state.
