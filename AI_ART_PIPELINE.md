# AI Art Pipeline

> **2026-07-07 PIVOT**: art direction is now **western 2D illustration**
> (not anime); primary generator is **Recraft** via the Art Review site
> (tools/art_review/). Anime/Niji/SDXL sections below are historical
> reference; the LoRA plan is superseded by Recraft custom styles unless
> we return to local generation. — SEVEN SPRINGS
*Companion to GDD.md §11. How every visual asset gets made, with AI generation as the base layer and human curation/paint-over as the finish layer.*

---

## 0. The Honest Preamble (read first)

Three realities shape everything below:

1. **Copyright**: Under current US Copyright Office guidance, *purely* AI-generated images are not copyrightable; images with substantial human authorship (paint-over, composition, layered editing) can be. Our pipeline therefore always ends in a human editing pass — it's not optional polish, it's what makes the assets ours.
2. **Community**: The gacha audience is the most AI-art-hostile gaming community there is; several gacha games have had PR fires over even suspected AI assets. Our policy: **use it, refine it, and disclose it honestly if asked** — never deny, never ship raw generations for hero content.
3. **Culture**: AI models hallucinate Arabic script. Generated "calligraphy" is gibberish pseudo-Arabic that could accidentally resemble (or mangle) sacred text. **Hard rule: no AI-generated Arabic/calligraphic script ever ships.** Ornamental text comes from real vetted sources or pure geometry (see §7). Models also default to Orientalist costume clichés — every character design gets a human cultural-accuracy check against real regional dress references.

---

## 1. Tool Stack

| Purpose | Primary tool | Alternative | Cost |
|---|---|---|---|
| Concept exploration & hero art | **Midjourney / Niji mode** (anime-tuned) | Any frontier image model | ~$10–30/mo |
| Production generation (consistency) | **ComfyUI + Illustrious-family anime checkpoint** + per-character LoRA + ControlNet | Draw Things (free, Mac-native, simpler) | Free local, or cloud below |
| Character-consistent edits ("same character, new pose/expression") | **Gemini image editing** or **gpt-image-1** — instruction-based edits of a reference image | ComfyUI IPAdapter | API pennies/image |
| LoRA training | **CivitAI on-site trainer** or **fal.ai LoRA trainer** (no local GPU needed) | kohya_ss locally | ~$1–5/character |
| Cleanup, paint-over, layer cutting | **Krita** (free) + Krita AI Diffusion plugin for inpainting | Photoshop, Procreate | Free |
| Upscaling | ComfyUI Ultimate SD Upscale | Topaz Gigapixel | Free / $ |
| Cloud GPU (if Mac is too slow) | **RunPod / fal.ai / Replicate** | — | ~$0.30–0.70/hr |

**Mac note (you're on macOS):** ComfyUI and Draw Things both run on Apple Silicon; SDXL-class generation is workable (~20–60s/image on M-series, slower than NVIDIA but fine for a solo pipeline). Start local and free with Draw Things; graduate to ComfyUI when you need ControlNet/LoRA workflows; rent cloud GPU hours only for batch production weeks. Verify current model/tool versions when you start — this space moves monthly.

**Model choice for our style:** the Illustrious/NoobAI family of SDXL anime checkpoints is the community standard for consistent stylized-anime characters and has the LoRA ecosystem we need. Midjourney's Niji mode gives the most beautiful single images but weaker precise control — hence: **explore in Niji, produce in ComfyUI**.

---

## 2. The Golden Rule: Style Bible Before Any Production

Before generating character #1 for real, lock the game's look:

1. Generate ~50 style exploration images (Niji/MJ) riffing on: *stylized anime, painterly rendering, Persian miniature color palette, deep lapis blue and gold, ornamental light, dignified dress*.
2. Pick 5–10 "north star" images. These become the **style reference set**.
3. Encode the style for production, two mechanisms used together:
   - A **fixed prompt template** (see §3.1) used verbatim in every generation.
   - Later, once ~30 finished/approved assets exist, train a **style LoRA** on them so the game's own art defines the style going forward (self-reinforcing consistency).
4. Write down the palette hexes, line-weight rules, and rendering notes in `art/STYLE_BIBLE.md`. Every asset gets checked against it.

---

## 3. Character Pipeline (the core workflow)

Per character, expect **2–4 hours of active work + training time**, vs. hundreds of dollars commissioned. Do it in this order:

### 3.1 Design lock (exploration)
- Prompt template skeleton:
  `[style block — fixed] · [order block — per-order] · [character block — unique]`
  - *Style block* (same for everyone): `stylized anime, painterly, clean lineart, deep blue and gold palette, ornamental rim light, dignified, mobile game character art`
  - *Order block* (from GDD §3.5), e.g. Mevlevi: `tall honey-colored sikke felt cap, flowing white whirling tennure skirt, black hırka cloak`
  - *Character block*: age, build, expression, signature item, VFX motif color.
- Generate 20–40 candidates, pick ONE design. Get the cultural-accuracy check done *now*, before investing in consistency (wrong turban style is cheap to fix at this stage, expensive after LoRA training).

### 3.2 Reference sheet (consistency bootstrap)
- Using the chosen image as reference, produce a **character sheet**: front / three-quarter / back, 3 expressions, weapon/prop detail. Two good methods:
  - Instruction-editing models (Gemini image editing / gpt-image-1): "same character, turn to back view, keep outfit identical" — currently the fastest way to bootstrap consistency.
  - ComfyUI IPAdapter + ControlNet openpose with reference image.
- Hand-fix discrepancies in Krita (outfit details WILL drift — fix them now; the LoRA will learn whatever you feed it, errors included).

### 3.3 Character LoRA
- Build a training set of **15–30 images**: the corrected sheet views + varied poses/backgrounds/lighting generated from them. Curate ruthlessly — 15 clean beats 30 sloppy.
- Caption each image (trigger word = character codename, e.g. `v4le`, plus tags for what varies: pose, expression, background).
- Train on CivitAI/fal.ai trainer (SDXL LoRA, default settings are fine to start). Test: generate 10 new poses; if outfit/face hold, ship it; if not, fix the worst training images and retrain.
- **This LoRA is the character's permanent identity.** All future art of them — new skins, event art, marketing — starts from it.

### 3.4 Production assets per character
| Asset | Spec | Method |
|---|---|---|
| **Bust portrait** (roster, dialogue) | ~1024×1024, transparent bg | LoRA gen → upscale 2× → Krita paint-over pass (eyes, hands, fabric folds, remove artifacts) → background removal |
| **Full-body gacha splash** | ~2048 tall, with FX/background | LoRA + ControlNet pose → inpaint details → paint-over → this is the highest-polish asset, budget the most human hours here |
| **Battle chibi** | ~512, A-pose, flat colors | Chibi-style LoRA/prompt (`chibi, full body, A-pose, simple shading`) of the same character → **manual layer cutting** (§4) |
| **Head icon** | 256×256 | Crop of bust, cleanup |

### 3.5 The paint-over pass (what makes it yours — and copyrightable)
Minimum human pass on every shipped character asset, in Krita:
- Fix hands, eyes, ears, jewelry symmetry (AI's chronic weak spots).
- Repaint any garbled ornament/pattern areas; replace pseudo-script with real geometric motifs (§7).
- Unify palette to the style bible (color-balance layer).
- Sign-off checklist in `art/CHECKLIST.md`: anatomy ✓ cultural dress ✓ no pseudo-script ✓ palette ✓ silhouette reads at chibi size ✓.

---

## 4. Battle Sprites & Animation (AI can't do this part)

AI image models output flat stills; **rigging and animation remain manual** — this is the honest cost center of the pipeline:

1. Generate the chibi in a clean A-pose, neutral lighting, simple shading (prompt for it — heavy shading makes layer cutting hell).
2. In Krita, **cut into layers**: head, hair-front/back, torso, upper/lower arms ×2, hands, upper/lower legs ×2, cloak/skirt, props. Paint in the occluded areas behind each cut (AI inpainting helps here: mask the gap, "continue the fabric").
3. Export layered → rig in **Godot Skeleton2D** (bones + polygons), or Spine if you later want fancier deformation (Mevlevi whirling skirts will want mesh deformation).
4. Animation set per character: idle, attack, skill, hit, KO — 5 animations, reuse skeleton across all characters of similar build. **Build ONE rig template per body type (M/F/large) and re-skin it** — this is the single biggest time-saver in the whole art plan.
5. AI video generation for sprites: not production-ready for game sprite sheets — revisit later, don't plan around it.

---

## 5. Backgrounds & Environments (AI's easiest win)

- Stage backdrops, valley vistas, the lodge home screen: generate at 2048+ wide with the style block + `no characters, environment concept art, painterly`. MJ/Flux-class models excel here; consistency matters less than for characters (each valley *should* look distinct).
- Parallax: generate the scene → cut into 2–3 depth layers in Krita → inpaint behind → cheap parallax scrolling in Godot.
- Per valley: 1 vista, 2–3 battle backdrops, 1 boss arena = ~35 environment images for the whole campaign. A weekend of generation + a week of cleanup.

## 6. UI, Icons, Items

- **Item/material icons**: AI is excellent — batch-generate on transparent-friendly plain backgrounds, cleanup, done. Keep one icon prompt template for visual family resemblance.
- **UI chrome (frames, buttons, panels)**: do NOT diffuse these. Precise geometry, nine-patch scaling, and crisp edges want **vector work** (Figma/Inkscape) using girih/arabesque patterns — see §7. AI can generate *inspiration* boards for UI, not shipping UI.
- **VFX**: Godot particles + shaders (GDD §13.4). AI can generate particle *texture sheets* (smoke puffs, light glyphs, ember sprites) — useful; generate on black, use additive blending.

## 7. Islamic Ornament & Script — Special Handling

- **Geometric patterns (girih, arabesque)**: use mathematically correct sources — public-domain pattern plates (e.g., Bourgoin's *Arabic Geometrical Pattern and Design*, long out of copyright), or construct in vector tools. AI approximations of girih are subtly wrong in ways pattern-literate players notice instantly.
- **Calligraphy**: per the hard rule — never AI-generated. Options: purely abstract "light-script" glyphs (invented, clearly non-linguistic, flowing shapes that evoke script without being it — safest and it's a fantasy game), or commission one real calligrapher for a handful of ornamental pieces (original poetry, order names) as a small fixed budget item.
- Every shipped asset containing anything script-like gets a native-reader review before release (fold into the GDD §12.6 scholar review).

---

## 8. Asset Management & Reproducibility

- Keep a **generation ledger**: for every shipped asset, save the workflow JSON (ComfyUI embeds it in the PNG), prompt, seed, model+LoRA versions. Store alongside the asset: `assets/art/characters/vale/bust.png` + `bust.gen.json` + `bust.kra` (layered working file).
- Never delete a character's LoRA + training set — archive to cloud storage. Losing them means the character can never be drawn again.
- Version the style bible; when the style LoRA gets retrained, re-check 3 old assets against it for drift.

## 9. Budget & Time Reality

| | Commissioned (old plan) | AI pipeline (this plan) |
|---|---|---|
| Per character (bust + splash + chibi) | $300–800 + weeks of turnaround | ~$5 compute + 6–12 hrs of your time |
| 28-character launch roster | $10–20k | ~$150 compute + ~2–3 months part-time labor |
| Still worth paying humans for | — | 1 calligrapher (fixed pieces), 1 finishing artist for the 7 chapter-key-art splashes + marketing art (the assets that get screenshotted), cultural/script review |

The money savings are real; the *time* cost migrates into cleanup, layer-cutting, and rigging — plan Phase 2 (vertical slice) around that.

## 10. Automated Integration Pipeline (IMPLEMENTED)

The game side of this pipeline is built and running. The loop:

1. **Character data is the single source of truth.** Every unit's `.tres` file
   has an `art_notes` field (appearance description). The GDD order blocks
   live as constants in `tools/export_art_tasks.gd` — edit them and the GDD
   together.
2. **Briefs are generated, never hand-written**:
   `godot --headless --path . -s res://tools/export_art_tasks.gd`
   → one markdown brief per unit in `art_workbench/tasks/` with the full
   composed prompt (style block + order block + art_notes + affinity hex),
   required file list, and the hard rules. Add a character to the game → its
   art tasks appear automatically. Data and art briefs cannot drift.
3. **Generate externally** (Niji/ComfyUI per §1–3), paint over, then import:
   `./tools/import_art.sh unit vale portrait ~/Downloads/vale_final.png`
   — resizes with macOS `sips`, places it at the convention path, and records
   it as REAL art in `art_workbench/real_art.json` (repo-tracked).
4. **Audit coverage** any time:
   `godot --headless --path . -s res://tools/audit_assets.gd`
   → per-unit table of REAL / placeholder / MISSING.
5. **The game never blocks on art.** `tools/gen_placeholders.gd` generates
   procedural affinity-colored portraits and valley backgrounds for every
   unit; `Db.unit_art()` resolves real art → placeholder → null with UI
   fallbacks at every call site. Convention paths:
   `assets/art/units/<id>/{portrait,chibi,icon}.png`,
   `assets/art/stages/valley_<n>/background.png` (per-stage override:
   `assets/art/stages/<stage_id>/background.png`).

Animation note: battle presentation (lunges, hit flashes, floating numbers,
Trance banners) is driven by engine signals and works identically with
placeholder or final art. When chibi sprites arrive, they replace the card
portrait and gain Skeleton2D rigs (§4) without touching battle logic.

## 11. Audio Pipeline (BGM & SFX)

**Decision (2026-07): Suno is the primary BGM tool. Stable Audio is the
designated fallback** if Suno becomes unusable (adverse fair-use ruling,
license change, or takedown risk — the UMG/Sony litigation ruling expected
summer 2026 is the review trigger). Sound effects: ElevenLabs SFX or Stable
Audio — the SFX category is legally clean either way.

### 11.1 Fallback-safe workflow (do these from day one)
- **Subscribe to Suno Pro before generating anything that ships** — commercial
  rights attach to the paid tier at generation time.
- **Keep every track brief tool-agnostic**: mood, instrumentation, tempo, and
  reference notes in `art_workbench/audio_tasks/` — never Suno-specific
  prompt syntax as the only record. If we must regenerate the whole soundtrack
  on Stable Audio later, the briefs are the soundtrack; the tool is a detail.
- **Generation ledger applies to audio** (same as §8): save prompt, tool,
  date, and raw output file alongside each shipped track.
- Don't hang the game's *musical identity* on any single un-reproducible
  track. The 2–3 identity pieces (title theme, Kibr's theme) should be the
  first candidates for a human composer commission anyway — that also solves
  stems for the percussion-only toggle, which AI handles poorly.

### 11.2 Hard rules (audio mirror of §0.3)
- **Instrumental or wordless vocables ONLY.** AI music tools hallucinate
  lyrics; hallucinated pseudo-Arabic singing is the audio version of
  pseudo-script — it could accidentally resemble or mangle sacred text.
  Prompt for instrumental; any track containing voice gets a full
  listen-through review before shipping.
- Never any sampled adhan, recitation, or liturgy. Ever.
- Instrument palette per GDD §11: ney, daf/bendir, oud; percussion-and-voice
  variants needed for the settings toggle.

### 11.3 Launch track list (BGM)
| Key | Track | Notes |
|---|---|---|
| `title` | Title / home lodge theme | identity piece — composer candidate |
| `valley_1` | Valley of the Quest ambience | calm, sparse ney |
| `battle` | Standard battle loop | daf-driven, mid tempo |
| `boss` | Kibr / Vice boss theme | identity piece — composer candidate |
| `calling` | The Calling ambience + reveal sting | wonder, restraint |
| `victory` / `defeat` | Result stingers | 5–10 s |

Loops: trim + crossfade loop points manually (Audacity, ~10 min/track).
Integration: `assets/audio/music/<key>.ogg`, `assets/audio/sfx/<key>.ogg`,
loaded by convention with graceful silence when missing (same pattern as art,
§10). AudioManager autoload: tracked in PROGRESS.md.

## 12. Disclosure & Store Policy

- Apple App Store and Google Play currently permit AI-generated assets (no disclosure requirement at time of writing — re-verify at submission).
- If ever ported to Steam: Valve requires AI-content disclosure at submission — our ledger (§8) makes that trivial.
- Public stance, decided now so it's never improvised under fire: *"Character and environment art is produced with AI generation as a base, with human design, correction, and paint-over on every shipped asset; all script and sacred-adjacent ornament is human-made and reviewed."* True, specific, defensible.
