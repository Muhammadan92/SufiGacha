# Creative Production Checklist — Kareem's Lane

Ordered, concrete steps for producing all art + audio. This is a *walkthrough*;
the policies and specs live in **AI_ART_PIPELINE.md** (referenced throughout —
read the linked section before each phase, they're short).

---

## Phase 0 — The Art Review site (DECIDED: Midjourney; start here)

Midjourney has no public API (Enterprise-only, and third-party "MJ APIs"
bot the platform against ToS — account-ban risk, so we don't use them).
Instead, the repo now has a local site that removes every manual step
except pasting prompts:

```
python3 tools/art_review/serve.py     ->  http://localhost:8787
```

- **Queue tab**: every missing asset (41 characters x portrait/chibi/icon
  + 7 valley backgrounds) with a ready-built prompt — click Copy, paste
  into Midjourney. Prompts are assembled from each unit's `art_notes` +
  the shared style fragments.
- Download keepers into **art_workbench/inbox/** (set it as the browser
  download folder while working, or drag files in).
- **Review tab**: every inbox image with assignment dropdowns
  (pre-guessed from the filename) — **Approve** resizes + imports it into
  the game and records it as real art; **Reject** moves it aside. Click
  **Godot reimport** when done.
- **Style tab**: the shared prompt fragments (style bible in executable
  form — saved to art_workbench/style.json, tracked in git). Lock your
  Phase 1 decisions here and every prompt updates.
- Consistency tip: approve a character's portrait first, then add
  `--cref <MJ image URL> --cw 100` to that character's chibi/icon prompts.

## Phase 1 — Style bible (one evening; blocks everything visual)

1. **Pick your tool** (AI_ART_PIPELINE.md §1): fastest on-ramp is a
   **Midjourney subscription using Niji mode** (~$10/mo); free/local
   alternative is **Draw Things** (Mac App Store, needs an anime SDXL model
   like Illustrious downloaded in-app).
2. Generate **~50 exploration images**. Base prompt to riff on (from §2):
   `stylized anime, painterly rendering, clean lineart, deep lapis blue and
   gold palette, ornamental rim light, dignified, mobile game character art,
   Persian miniature influence` — vary: character subjects, environments,
   lighting, framing.
3. **Pick 5–10 "north stars"** — images where you think "the game should
   look like THIS." Save them to `art_workbench/north_stars/` (gitignored).
4. Write `art_workbench/STYLE_BIBLE.md`: paste the north stars, note the
   exact prompt fragments that produced them, list palette hexes and any
   rules you notice ("thin gold rim light always", "no harsh blacks").
   Tell me when it exists — I'll fold the winning fragments into the brief
   generator so every future art task uses them automatically.

## Phase 2 — First character end-to-end: VALE (validates the whole pipeline)

Everything below is spelled out in AI_ART_PIPELINE.md §3; short version:

1. Open **`art_workbench/tasks/vale.md`** — his complete generation prompt is
   pre-composed from game data (style + Naqshbandi block + his emerald
   appearance notes). Generate 20–40 candidates; **lock ONE design**.
2. **Cultural check before anything else** (§3.1): compare the locked design
   against real Naqshbandi dress references; fix inaccuracies now.
3. Make the **reference sheet** (§3.2): front/¾/back + 3 expressions.
   Fastest: instruction-editing models ("same character, turn to back view,
   keep outfit identical"). Hand-fix drift in Krita (free).
4. **Train his LoRA** (§3.3): 15–30 curated images → CivitAI or fal.ai
   trainer (~$5), trigger word `vale4x`. Test with 10 new poses.
5. Produce the three files (§3.4) and import each:
   ```
   ./tools/import_art.sh unit vale portrait ~/path/to/final.png
   ./tools/import_art.sh unit vale chibi    ~/path/to/chibi.png
   ./tools/import_art.sh unit vale icon     ~/path/to/icon.png
   godot --headless --path . --import
   ```
   The game uses them instantly; the audit flips him to REAL.
6. Every shipped file gets the **paint-over pass** (§3.5) — it's what makes
   the art legally ours. Checklist: hands ✓ eyes ✓ no pseudo-script ✓
   palette ✓ reads at 64px ✓.

## Phase 3 — The rest of the roster (repeat Phase 2 × 18)

- Priority order: **starters first** (Bram, Echo, Brand, Ari — they're on
  screen from minute one), then Kibr + the 3 demons (every battle shows
  them), then Sage and the remaining Luminaries, then the rest.
- Each unit's brief is already waiting in `art_workbench/tasks/<id>.md`.
  Regenerate briefs any time data changes:
  `godot --headless --path . -s res://tools/export_art_tasks.gd`
- Track coverage: `godot --headless --path . -s res://tools/audit_assets.gd`

## Phase 4 — Backgrounds & UI (cheap wins, do alongside Phase 3)

- **Valley 1 background** (AI art's easiest win, §5): generate a
  2048-wide environment with the style-bible prompt + `no characters,
  environment concept art` → `./tools/import_art.sh valley 1 ~/bg.png`
- UI chrome stays vector/geometric — NOT diffusion (§6). Defer until the
  vertical slice art pass.

## Phase 5 — Audio (one afternoon for SFX; a weekend for BGM)

Policy + track list: **AI_ART_PIPELINE.md §11**. Steps:

1. **Subscribe to Suno Pro BEFORE generating anything that ships** (~$10/mo —
   commercial rights attach at generation time). Stable Audio is the recorded
   fallback; keep every prompt saved as a tool-agnostic brief (§11.1).
2. Generate the **§11.3 track list** (title, valley_1, battle, boss, calling,
   victory/defeat stingers). Prompt shape:
   `instrumental, no vocals — meditative Middle Eastern ambient, breathy ney
   flute, sparse frame drum daf, contemplative, seamless loop, game music`
   Expect to keep ~1 in 4. **HARD RULE (§11.2): instrumental or wordless
   vocables only — regenerate anything with lyric-like vocals.**
3. For the percussion-only toggle: generate a `battle_percussion` /
   `title_percussion` variant (same prompt, "percussion and wordless voice
   only, no melodic instruments").
4. Trim loop points in Audacity (free): find a zero-crossing bar boundary,
   trim, crossfade ~50ms. (~10 min/track after the first one.)
5. Import — placeholders are outranked automatically:
   ```
   ./tools/import_art.sh audio music battle ~/battle_final.mp3
   godot --headless --path . --import
   ```
6. **SFX** (ElevenLabs SFX, ~$5 tier): replace the 12 synthesized
   placeholders (list in tools/audit_assets output) — prompts like "deep
   frame drum impact, tight, dry" (hit), "shimmering rising chime,
   spiritual" (reveal_luminary). Import with `audio sfx <key>`.

## Ongoing rules (always)
- No AI-generated Arabic/pseudo-Arabic script, ever (art §0.3, audio §11.2).
- Save the generation ledger (§8): prompt + tool + date next to each keeper.
- After any import: run the audit; commit art + `art_workbench/real_art.json`.
