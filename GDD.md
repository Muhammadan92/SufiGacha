# SEVEN SPRINGS
## Game Design Document — v0.1

*A Sufi-themed collectible turn-based RPG for mobile.*

| | |
|---|---|
| **Genre** | Turn-based team RPG with gacha collection |
| **Platform** | iOS + Android (portrait or landscape — TBD, see §13) |
| **Engine** | Godot 4.x (GDScript) |
| **Art style** | Stylized 2D anime with Islamic ornamental framing (geometry, illumination, calligraphy motifs in UI) |
| **Monetization** | Premium-currency gacha with pity system + battle pass (see §9) |
| **Audience** | Western gacha RPG players 16+. Primarily a **dawah project**: an accessible, welcoming introduction to Sufi spirituality for a general Western audience (see §1.1) |

---

## 1. High Concept

Darkness — the *waswās*, whispers of corruption — is spreading across the land, feeding on the untamed lower self (*nafs*) of humanity. The player is a **Seeker** who gathers a company of fictional dervishes from the great Sufi orders. Each order is a "class" with its own combat identity rooted in that order's real practices: the silent meditation of the Naqshbandis, the thunderous vocal dhikr of the Qadiris, the whirling of the Mevlevis.

The campaign is structured on **Attar's *Conference of the Birds***: seven chapters, one per valley of the spiritual journey. Enemies are demons, whisper-imps, and personified vices — never people.

**Design pillars:**
1. **Authentic flavor, fictional cast** — real orders, real practices as ability inspiration; zero depiction of real saints, prophets, or scripture in gameplay.
2. **The path is the progression** — leveling, ascension, and rarity all use the vocabulary of the Sufi path (maqāmāt, sulūk, himma) so mechanics reinforce theme.
3. **Genre-competent combat** — a turn-based system that stands on its own against Epic Seven / AFK Journey players' expectations.
4. **Accessible mysticism (Western-first)** — English-first language and a universal spiritual register; Arabic terminology reserved as rare, deliberate seasoning (§1.1).

### 1.1 Language & Tone Policy (Western-first)

This game is primarily a **dawah project aimed at a Western audience**: the goal is that players absorb the ideas — taming the ego, remembrance, the journey toward the Divine — through play, and get curious enough to look further on their own. Terminology must never be a wall.

- **English-first everywhere players read**: UI, tutorials, system terms, item names, dialogue. The mystical register comes from the established English translations of Sufi literature — *the Path, Remembrance, the Beloved, Stations, unveiling, polishing the heart* — vocabulary that is both authentic and already familiar to Western readers from Rumi translations.
- **Dialogue rule**: characters speak natural, contemporary English. No transliterated greetings or sprinkled loanwords (no "salaam alaykum," "shukran," etc. in text). Warmth, courtesy, and piety are shown through *behavior* — hospitality, humility, patience — not vocabulary.
- **Character naming rule**: playable names are neutral, Western-leaning, and mystical-sounding (short nature/light/sound-derived names — Vale, Echo, Isla); epithets carry the flavor ("the Silent," "the Unburnt"). Explicitly Islamic given names are avoided for the playable cast.
- **Arabic as seasoning, by allowlist only**: (1) the seven order names, as proper nouns; (2) select 5★ ultimate names, always with an English subtitle (e.g., *Khalwa — Seclusion*); (3) boss true-names as titles (e.g., *Kibr, Father of Pride*); (4) the Codex.
- **The Codex is the dawah vehicle**: an optional in-game encyclopedia (working name: *The Traveler's Notebook*), unlocked through play, giving the real history, terminology, poetry, and figures behind each order, valley, and concept. Depth on tap for the curious; invisible to players who just want to play.
- **Show, don't preach**: the story never proselytizes — it dramatizes a universal spiritual struggle. Success metric: players googling Rumi and "Sufism" unprompted.
- **Doc convention**: this GDD keeps source terms where useful for design precision; the table below fixes what players actually see.

| Source concept | Player-facing term |
|---|---|
| dhikr | **Remembrance** (skill slot) |
| wird | **Litany** (basic attack) |
| ḥāl | **Trance** (ultimate) |
| adab | **Discipline** (passive) |
| himma | **Fervor** (ultimate gauge) |
| maqāmāt / sulūk | **Stations** / **the Path** (ascension) |
| nafas | **Breath** (stamina) |
| bay'ah | **The Calling** (summoning) |
| zawiya | **Lodge** (guild) |
| ijāza | **Teaching Scroll** (skill-up item) |
| nafs | **the Ego** |
| waswās | **Whispers** (debuff) / **Whisperlings** (fodder enemies) |
| murīd / sālik / 'ārif | **Novice / Wayfarer / Luminary** (rarity ranks) |

---

## 2. The Seven Orders (Character Types)

Each character belongs to one order. Orders define **affinity**, **visual identity**, and **kit tendencies** (not hard roles — a Qadiri healer can exist, but rarely).

| Order | Affinity | Theme source | Combat identity | Typical roles |
|---|---|---|---|---|
| **Naqshbandi** | **Heart** — neutral | Silent dhikr, *khalwat dar anjuman* (solitude in the crowd), the subtle centers (*laṭā'if*) | Meditation & mind: team-wide buffs, barriers, turn-meter and tempo manipulation, "unseen" (untargetable) states | Buffer, enabler, apex units |
| **Qadiri** | **Thunder** | Loud vocal dhikr, the "Ghawth" (supreme helper) archetype of spiritual power | Raw power: lightning and sound, highest single-target burst, armor-shattering shouts | Nuker, breaker |
| **Rifai** | **Ember** | Renowned for feats of bodily invulnerability during dhikr (fire, blades) | Unbreakable body: taunts, damage immunity windows, burning retaliation | Tank, bruiser |
| **Mevlevi** | **Wind** | The samā' whirling ceremony | Continuous motion: spinning AoE damage, evasion, damage-over-turns, never staying still | AoE DPS, evader |
| **Shadhili** | **Sea** | The great litanies (aḥzāb), esp. the Litany of the Sea recited for protection on voyages | Protective recitation: cleansing debuffs, sustained regen, tide-like shields that grow over turns | Sustain support, cleanser |
| **Chishti** | **Harmony** | Samā' (spiritual music), radical hospitality, love and service | The open table: healing, revival, sharing HP/buffs between allies | Healer, binder |
| **Suhrawardi** | **Light** | Illuminationist (*ishrāqī*) philosophy of light *(note: the order and the philosopher are distinct historical strands — we borrow the light aesthetic, flagged in lore as inspiration)* | Revelation: exposing enemies (defense down, mark for death), true-sight vs stealth, precision crits | Debuffer, sniper |

### 2.1 Affinity Triangle

Six affinities form three pairs in a rock-paper-scissors triangle; **Heart sits outside it**:

```
        POWER (Thunder, Ember)
         ↑ strong vs      ↘
   SPIRIT (Harmony, Light) ← FLOW (Wind, Sea)
```

- **Power > Flow > Spirit > Power** — +30% damage dealt, −15% damage taken vs the weaker group.
- **Heart (Naqshbandi)**: no weakness, no bonus vs the triangle, but **+20% vs Corrupted** (boss/elite tag). This is the mechanical justification for Naqshbandi as the premium order: never a bad pick, best against the hardest content.
- Enemies carry the same six affinities plus **Corruption** (strong vs the triangle, weak to Heart and to nothing else).

**Balance note:** Naqshbandi units should be *reliable*, not oppressive — their edge is consistency and boss content, not raw numbers. Keep their damage multipliers ~10% under equivalent-rarity triangle units.

---

## 3. Characters

### 3.1 Rarity Tiers (spiritual ranks)

| Rarity | Rank name | Source concept | Gacha rate | Notes |
|---|---|---|---|---|
| ★★★ | **Novice** | *murīd* — committed student | 77% | Farmable, fodder-adjacent but a few hidden gems (genre tradition) |
| ★★★★ | **Wayfarer** | *sālik* — traveler on the path | 20% | Backbone of most teams |
| ★★★★★ | **Luminary** | *'ārif* — the knower | 3% | Banner units; all launch Naqshbandis live here or high 4★ |

### 3.2 Stats

`HP · ATK · DEF · SPD · Crit Rate · Crit Damage · Effectiveness · Resilience`

Keep it to eight. SPD drives a **turn-meter queue** (see §4.1). Effectiveness/Resilience gate debuff landing — this is what makes Suhrawardi debuffers and Shadhili cleansers matter.

### 3.3 Kit Structure (every character)

| Slot | Player-facing name | Source | Behavior |
|---|---|---|---|
| Basic | **Litany** | *wird* | No cooldown, small Fervor gain |
| Skill | **Remembrance** | *dhikr* | 2–4 turn cooldown, order-flavored effect |
| Ultimate | **Trance** | *ḥāl* | Costs full **Fervor gauge**; the big cinematic moment |
| Passive | **Discipline** | *adab* | Always-on conditional effect |

**Fervor** (from *himma*, spiritual aspiration) is the ultimate meter: gained by acting, taking damage, and from ally support effects. It replaces generic "energy" and gives supports a themed job (Chishti units share Fervor — the open table). Individual Trance *names* are where the Arabic-seasoning allowance applies: a 5★'s ultimate may carry a source-term name with an English subtitle (*Khalwa — Seclusion*).

### 3.4 Launch Roster Sketch (names are placeholders — all fictional)

Two examples per order; full launch roster target: **28 characters** (7 orders × 4, mixed rarity). Names follow the §1.1 naming rule: short, neutral, Western-leaning and mystical-sounding, with epithets carrying the flavor. Include women in every order — Sufi history has towering female figures (the Rābi'a al-'Adawiyya archetype: the lover-ascetic) to draw *inspiration* from without depicting them.

| Character | Order | ★ | Role | Kit hook |
|---|---|---|---|---|
| **Vale, the Silent** | Naqshbandi | 5 | Buffer | Trance *Khalwa — Seclusion*: team untargetable 1 turn, +40% ATK after |
| **Seren** (f) | Naqshbandi | 4 | Shielder | Barriers that convert absorbed damage into Fervor |
| **Bram, Voice of Thunder** | Qadiri | 5 | ST nuker | Trance: colossal single hit, ignores 50% DEF |
| **Echo** (f) | Qadiri | 4 | Breaker | Sound-wave attacks that reduce DEF and echo (second hit at 40%) |
| **Brand, the Unburnt** | Rifai | 5 | Tank | Trance: 2-turn team damage immunity, attackers burn |
| **Flint** | Rifai | 3 | Bruiser | Counterattacks while above 50% HP |
| **Gale, the Turning Sky** (f) | Mevlevi | 5 | AoE DPS | Gains *Spin* stacks each turn; Trance damage scales with stacks |
| **Rowan** | Mevlevi | 4 | Evader | Dodge chance aura; extra turn on dodge |
| **Isla, the Returning Tide** (f) | Shadhili | 5 | Cleanser | Removes debuffs team-wide; each removed debuff heals |
| **Dylan** | Shadhili | 3 | Sustain | Small regen litany, stacks over turns |
| **Aria** (f) | Chishti | 5 | Healer | Trance revives one ally at 50% HP with 50 Fervor |
| **Ansel, the Open Door** | Chishti | 4 | Binder | Links two allies to share damage and healing |
| **Lucia** (f) | Suhrawardi | 5 | Debuffer | *Illuminate*: marked enemy takes +25% from all sources |
| **Sol** | Suhrawardi | 3 | Sniper | High crit vs debuffed enemies |

### 3.5 Visual Guidelines

- Traditional dress by order: Mevlevi *sikke* (tall felt cap) and whirling skirts; Naqshbandi understated turbans and muted robes; Qadiri green accents; Rifai black/iron tones. Beards for most adult men; women in dignified modest dress (hijab styles varied by region — Turkic, Maghrebi, South Asian, West African for diversity across orders).
- **Modesty is the art direction**, not a limitation: flowing cloth, calligraphy-pattern auras, light and geometry do the visual spectacle work that skin does in other gacha games. This is also a market differentiator.
- Ability VFX language: each order gets a signature motif — Naqshbandi = expanding concentric circles of script; Qadiri = lightning + sound rings; Mevlevi = spiral trails; Suhrawardi = rays/lens flares; Shadhili = water calligraphy; Chishti = musical geometry; Rifai = embers/molten cracks.

---

## 4. Combat System

### 4.1 Core Loop
- Team of **4** + 1 borrowed friend unit (social hook), vs 1–5 enemies.
- **Speed-based turn meter**: each unit's bar fills at SPD rate; act at 100%. (Genre-proven, enables SPD manipulation kits — Naqshbandi tempo identity.)
- On your unit's turn: Litany / Remembrance (if off cooldown) / Trance (if Fervor full). Target selection by tap.
- Auto-battle and 2× speed from day one — non-negotiable for the genre.

### 4.2 Status Effects (launch set — keep it tight)
Buffs: ATK↑, DEF↑, SPD↑, Barrier, Regen, Immunity, Evasion, Unseen (untargetable).
Debuffs: ATK↓, DEF↓, SPD↓, Burn, Silence (no Remembrance), **Whispers** (30% chance to lose turn — the signature themed debuff, used *by enemies on you*, and cleansed by Shadhili).

### 4.3 Win/Lose
Standard: all enemies down = win (3-star rating by conditions: no deaths, under N turns); team wipe = retry with no stamina refund.

---

## 5. Enemies

Demons and personified vices only — never human, never anything resembling worship targets.

| Tier | Examples |
|---|---|
| Fodder | **Whisperlings** (whisper wisps), shadow-vermin, ash ghouls |
| Elite | **Mirror shades** (dark doubles of the player's own units — reuses rigs, cheap content), smoke serpents, hollow brutes |
| Chapter bosses | **The Seven Vices**, one per valley: Pride, Envy, Wrath, Greed, Sloth, Worldliness, Despair — English names in all UI; each boss additionally bears an Arabic **true-name** as a title (e.g., *Kibr, Father of Pride*), the sanctioned §1.1 flavor use |
| Final arc | **The Whisperer** — an archdemon of despair (Iblis-*inspired*, deliberately not named as such — see §12) |

Boss design rule: each Vice boss mechanically embodies its vice (Pride reflects buffs back as damage unless dispelled; Envy steals your buffs; Despair drains Fervor) — so counterplay teaches the order system.

---

## 6. Campaign Structure — The Seven Valleys

Direct structural borrow from *Manṭiq al-Ṭayr* (Attar). Seven chapters × ~12 stages + boss:

1. **Valley of the Quest** — tutorial arc
2. **Valley of Love** — Chishti-focused story chapter
3. **Valley of Knowledge** — Suhrawardi chapter
4. **Valley of Detachment** — Shadhili/Rifai chapter
5. **Valley of Unity** — Qadiri chapter
6. **Valley of Wonder** — Mevlevi chapter
7. **Valley of the Passing-Away** — Naqshbandi chapter, final boss

Chapter titles are pure English (the valley names are already the standard translations of Attar's originals); each valley's Codex entry gives the source name and the poem's context — the §1.1 depth-on-tap pattern.

Each chapter spotlights an order's story characters — this doubles as the banner release schedule (chapter N launch = order N banner).

Story tone: earnest, warm, lightly humorous between battles; the *journey inward* framing (the demons grow stronger as they get more personal) gives gacha grinding an actual arc.

---

## 7. Game Modes (launch)

| Mode | Purpose | Stamina |
|---|---|---|
| Campaign (7 valleys) | Story, first-clear gems | Yes (**Breath**) |
| Material sanctums (daily rotation) | Ascension materials per order | Yes |
| **The Minaret** (endless tower) | Endgame ladder, monthly reset | No |
| Trial of the Vices (weekly boss) | Gear/talisman source | Limited entries |
| *Post-launch:* Arena PvP, guild (**Lodge**) content | Retention | — |

---

## 8. Progression Systems

- **Character level** (1–60 at launch) — EXP items from campaign.
- **Ascension — the Stations**: 6 promotion steps along the Path (from *maqāmāt*), each raising level cap and at steps 3/5 unlocking passive upgrades. Materials: order-specific (e.g., Qadiri units need *Thunder Litanies* from Tuesday sanctum).
- **Skill-ups**: duplicate characters OR universal *Teaching Scrolls* (crucial: dupes must not be the only path, softens gacha pain).
- **Talismans**: 3 equip slots (Body/Breath/Spirit), substat rolling kept SHALLOW at launch — gear grind depth is a live-ops lever for later, and deep substat RNG at launch kills small games.
- **Player account level** gates modes; stamina cap grows with it.

---

## 9. Gacha & Monetization

### 9.1 Summoning — "The Calling"
Thematic frame (from *bay'ah*, the pledge): you don't "pull" a character — you **send out a call**, and a companion answers it and joins your company. Summon animation: a figure answering the call at a lodge doorway; rarity tell = the color of the light in the doorway.

- **Currency**: *Pearls* (premium, bought + earned) · *Pearl of the Path* (earned-only variant for standard banner).
- **Rates**: 5★ 3% · 4★ 20% · 3★ 77%. Rate-up banner: 50/50 then guaranteed (Genshin-proven, players trust it).
- **Pity**: hard pity at **70** pulls, carries across a banner cycle; visible counter in UI (transparency as brand value).
- **10-pull** guarantees ≥1 4★.

### 9.2 Revenue lines
1. Pearl packs (first-purchase double bonus)
2. **Monthly Traveler's Pass** (~$5: daily Pearl drip — best value, whale-independent baseline revenue)
3. Battle pass per chapter-season (~$10: cosmetics, materials, a 4★ selector — no exclusive power)
4. Cosmetics: outfit variants, lodge (home screen) decorations

### 9.3 Compliance & guardrails (required, not optional)
- **Publish exact odds** in-game (Apple App Store 3.1.1 / Google Play both require disclosed loot-box odds).
- **Belgium & Netherlands**: paid loot boxes are legally restricted — plan to geo-disable paid summons or don't ship there at launch.
- Age rating will carry a gambling-mechanics descriptor (ESRB/PEGI in-game purchases + random items label).
- House rules for our own conscience given the theme: visible pity counter, no "you almost got it!" near-miss animations, no limited-time countdown pressure on first-time buyers, monthly spend-limit setting the player can turn on. *(Flagged earlier and acknowledged: paid randomized gacha sits badly with maysir concerns for part of this game's natural audience. These guardrails are the mitigation; a fuller halal-certification review with a scholar before launch is strongly recommended — see §12.)*

---

## 10. Economy Sketch (tune in spreadsheets later)

- F2P income target: ~60–70 pulls/month first month (launch generosity), ~35–40/month steady state.
- One full pity ≈ $70–90 of Pearls (genre-typical anchor).
- Stamina: 1 Breath/6 min regen, campaign stage = 8–12 Breath.
- Every currency, cost, and drop table lives in **data files, not code** (see §13) so the economy is tunable without client patches.

---

## 11. Art & Audio Direction

- **Characters**: stylized anime, painterly rendering; portrait (bust) art for menus/gacha, chibi-proportioned battle sprites with 2D skeletal animation (Godot's Skeleton2D, or Spine if budget allows). Bust art + chibi rig is the cheapest path to "looks like a real gacha."
- **Production method: AI-generated base + mandatory human paint-over**, per the full pipeline in **`AI_ART_PIPELINE.md`** — style bible first, one LoRA per character for consistency, manual layer-cutting and rigging for battle sprites, vector work (not AI) for UI chrome. The paint-over pass is required on every shipped asset (copyright + quality), and AI-generated Arabic script is banned outright (see §12.8).
- **UI**: deep blues/golds, girih geometric patterns, arabesque frames, thuluth-style ornamental (non-scriptural!) calligraphy motifs. UI is where the Islamic-art identity lives most cheaply.
- **Audio**: ney flute, daf/bendir percussion, oud; vocal layers as *vocables* not sacred text. **Settings option: "percussion & voice only" mode** — some of the Muslim audience avoids melodic instruments; a one-toggle respect feature nobody else in the genre has.
- **Never in art or audio**: Qur'anic text, hadith text, names of God as decoration, depictions of prophets or angels or real saints. Calligraphy is ornamental/poetic (e.g., original couplets) only.

## 12. Cultural & Religious Sensitivity Charter

This section is load-bearing — the theme is the product, and mishandling it is the #1 project risk.

1. All playable characters are **fictional**. No real saint, founder, or scholar is depicted, named, or statted. Founders may be *referenced* in codex flavor text respectfully, as history, never as game content.
2. Orders are portrayed by their **publicly documented practices** (dhikr styles, samā', litanies) at a poetic-fantasy remove; no depiction of actual ritual liturgy verbatim.
3. Enemies are demons/vices only. No human faction is "the enemy," no sectarian framing (and note: Sufi orders span the Muslim world — the game should never imply orders fight *each other*; affinity advantage is framed as harmony/complementarity, "each path illuminates a different darkness").
4. No worship mechanics: characters never pray *to* anything on screen; abilities are framed as discipline, breath, sound, motion, and light.
5. The Iblis-inspired final antagonist is unnamed and abstract ("The Whisperer") to stay in folklore register rather than theology.
6. **Before public launch: paid review by 1–2 scholars/community advisors** (ideally one with tariqa affiliation) covering names, art, monetization, and story. Budget line item, not a favor.
7. Community positioning: "inspired by the heritage of tasawwuf," made with love — never claiming to *represent* any living order.
8. **AI art guardrails**: no AI-generated Arabic or calligraphic script ever ships (models produce gibberish pseudo-Arabic that could mangle or accidentally evoke sacred text) — ornament is real vetted geometry or clearly non-linguistic invented glyphs, reviewed by a native reader. Every AI-based character design gets a human cultural-accuracy check against real regional dress references before production (models default to Orientalist costume clichés). Full policy in `AI_ART_PIPELINE.md` §0 and §7.

---

## 13. Technical Design (Godot 4.x)

You can program but are new to games — this architecture is chosen to keep game-specific complexity in a few well-known patterns.

### 13.1 Principles
- **Data-driven everything**: characters, skills, enemies, stages, banners, and drop tables are Godot `Resource` files (`.tres`) — content is added by creating data files, not writing code. Skills compose from a small library of **effect blocks** (Damage, Heal, ApplyStatus, ModifyTurnMeter, Summon…) with parameters; ~15 effect blocks cover the whole launch kit list in §3.4.
- **Battle = state machine + event queue**: `BattleManager` runs states (RoundStart → UnitTurn → ResolveAction → CheckEnd); all effects emit events; UI listens to events, never touches battle state. This separation is the single most important architectural decision — it makes auto-battle, replays, and later server-side battle validation possible.
- **Screens as scenes**: Home / Summon / Roster / CharacterDetail / StageSelect / Battle / Results, swapped by a root `ScreenManager` autoload.

### 13.2 Project layout
```
res://
  data/          characters/ skills/ enemies/ stages/ banners/  (.tres)
  scenes/        screens/ battle/ ui_components/
  scripts/       core/ (battle engine)  systems/ (gacha, save, economy)
  assets/        art/ audio/ fonts/
```

### 13.3 Save & backend (the real-money consequence)
- **Prototype/vertical slice**: local save (JSON, lightly obfuscated). Fine while no money exists.
- **Before any real-money launch**, the game MUST become server-authoritative for: accounts, gacha pulls (pull RNG happens on the server), currency balances, and IAP receipt validation — otherwise the economy is trivially hackable and Apple/Google refund fraud will eat you. Recommended: **Nakama** (open-source game backend, self-host or cloud) or **Supabase + edge functions**. Design the client from day one so `GachaSystem` and `Wallet` are interfaces that can swap local → remote implementations.
- Analytics + crash reporting before soft launch (e.g., PostHog/Sentry).

### 13.4 Godot-specific notes
- GDScript throughout; typed GDScript (`var hp: int`) for sanity.
- Godot 4.x mobile export: test iOS/Android export pipeline in week 1, not month 6.
- 2D skeletal animation via `Skeleton2D` + `AnimationPlayer`; VFX via `GPUParticles2D` + shaders.

---

## 14. Production Roadmap

**Phase 0 — this document.** Iterate until the roster, affinity math, and economy sketch feel right.

**Phase 1 — Combat prototype (grey-box), ~4–6 weeks part-time.**
Battle engine with placeholder art (colored rectangles with names): turn meter, 4 characters × 2 orders, 6 skills, 3 enemy types, one boss. **Exit criteria: fighting the Pride boss with a bad team comp is hard and with a good comp feels smart.** If combat isn't fun in grey-box, nothing else matters.

**Phase 2 — Vertical slice, ~2–3 months.**
Valley 1 complete with real art for 6–8 characters, summon screen with animation, roster/level-up screens, local save, stamina. This is the "show people and watch their faces" build.

**Phase 3 — Content & backend, ~3–4 months.**
Valleys 2–7, 28-character roster, talismans, Minaret, Nakama integration, IAP sandbox, scholar review (§12.6), localization plan (English + Turkish/Indonesian/Urdu are the obvious markets).

**Phase 4 — Soft launch** in 1–2 test markets → tune economy/retention → global.

**Open items to resolve during Phase 1** (decisions needed, not blocking the prototype):
- ~~Working title~~ **Decided: *Seven Springs***. (Campaign chapters currently keep Attar's "valley" naming per §6 — deciding whether chapters become *springs* to match the title is an open story-framing question.)
- Art production: **AI-generated base + human paint-over pipeline** (see `AI_ART_PIPELINE.md`) — cuts the roster art cost from ~$10–20k commissioned to ~$150 compute + your cleanup/rigging time. Decisions still open: local generation (Draw Things/ComfyUI on Mac) vs. cloud GPU vs. Midjourney subscription; and the small remaining human-artist budget (1 calligrapher for fixed ornamental pieces, 1 finishing artist for chapter key art / marketing splashes)
- Portrait vs. landscape orientation (portrait = casual reach, landscape = spectacle; genre is split)
- Solo dev vs. bringing collaborators before Phase 3 (content phase is where solo timelines usually die)

---
*v0.1 — 2026-07-03. Everything here is a starting position, not a contract with ourselves.*
