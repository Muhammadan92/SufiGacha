# Seven Springs

A Sufi-inspired collectible turn-based RPG for mobile, built in Godot 4.

- **[GDD.md](GDD.md)** — the full game design document (start here)
- **[AI_ART_PIPELINE.md](AI_ART_PIPELINE.md)** — how art assets are produced

## Current status: Phase 1 — grey-box combat prototype

Turn-meter battle engine with 4 playable characters (Bram, Echo, Brand, Aria),
3 enemy types, and the first Vice boss (*Kibr, Father of Pride*). No art —
buttons and text bars only. The goal of this phase (GDD §14): fighting the
Pride boss with a bad team comp should be hard, and with a good comp should
feel smart.

## Running it

1. Install Godot 4.3+ (`brew install godot` on macOS, or [godotengine.org](https://godotengine.org/download))
2. Open the project: `godot -e --path .` (or import the folder in the Project Manager)
3. Run (F5). Pick an encounter: **Valley Patrol** (easy) or **Kibr, Father of Pride** (boss).

## Headless testing & balance sims

```
godot --headless --path . -s res://tests/smoke.gd      # engine smoke test (one full auto-battle)
godot --headless --path . -s res://tests/simulate.gd   # 3000-battle balance sweep across team comps
```

Current boss-fight tuning targets (auto-AI win rates): balanced comp ~60-70%,
missing-role comps ≤20%, no-healer ~0%. Kibr's *Swell of Pride* stacks without
bound as anti-stall enrage — turtle comps lose long fights by design.

## Project layout (GDD §13)

```
data/units/       one .tres Resource per character/enemy (stats + skills) — content lives here, not in code
scenes/           screens and battle scenes
scripts/data/     Resource class definitions (UnitData, SkillData, EffectBlock)
scripts/core/     battle engine (BattleManager state machine, BattleUnit, affinity math)
scripts/battle/   grey-box battle UI
scripts/systems/  gacha, save, economy (later phases)
```

Architecture rules: all game content is data (`.tres` files); the battle engine
emits signals and never touches UI; the UI listens and never touches battle
state.
