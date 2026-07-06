# SEVEN SPRINGS
## Game Design Document — v0.1

*A Sufi-themed collectible turn-based RPG for mobile.*

| | |
|---|---|
| **Genre** | Turn-based team RPG with gacha collection |
| **Platform** | iOS + Android (portrait or landscape — TBD, see §13) |
| **Engine** | Godot 4.x (GDScript) |
| **Art style** | Stylized 2D anime with Islamic ornamental framing (geometry, illumination, calligraphy motifs in UI) |
| **Monetization** | **Gambling-free**: fixed-price tiered token shop (no random paid acquisition — see §9). Marketed as a gambling-free hero collector |
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
- **Character naming rule (revised 2026-07-06)**: playable names are **tariqah-inspired mystical fantasy** — short words drawn from the path's own vocabulary (Fana, Sirr, Sama, Ishraq, Bahr, Barq) that read as pure fantasy names to Western players and as depth to the curious. Sacred names, Divine Names, and honored titles are NEVER used as character names. Epithets carry additional flavor.
- **Roster structure**: 9 companions per order — one 5-star shaykh (the order's "boss character") + 3 Wayfarers + 5 Novices (63 playable + Sage). **Fana**, the Naqshbandi shaykh, is the game's pinnacle character and uniquely wears **black robes** (the annihilated one — no color remains) with a single emerald thread.
- **Female companions**: 1-2 per order, always healer/support archetypes, always modest dress.
- **Arabic as seasoning, by allowlist only**: (1) the seven order names, as proper nouns; (2) select 5★ ultimate names, always with an English subtitle (e.g., *Khalwa — Seclusion*); (3) boss true-names as titles (e.g., *Kibr, Father of Pride*); (4) the Codex.
- **The Codex is the dawah vehicle**: an optional in-game encyclopedia (working name: *The Traveler's Notebook*), unlocked through play, giving the real history, terminology, poetry, and figures behind each order, valley, and concept. Depth on tap for the curious; invisible to players who just want to play.
- **Lore research source**: for ALL lore portions of the game (Codex entries, valley/chapter framing, boss true-names, item flavor, Part 2), mine **[nurmuhammad.com](https://nurmuhammad.com)** for interesting, lesser-known tariqah-rooted teachings (the realities of the months, number mysticism, the subtle centers, light-and-veil cosmology) — these make far better lore notes than encyclopedia-level material. Always as *inspiration*: everything passes through this language policy on the way in, and the §12.6 scholar review covers all Codex/lore content before launch.
- **STRICT lore caveat (decided 2026-07, enforced structurally)**: the game
  is **never a teaching authority**. All lore is written as in-world
  *fantasy* — abstract, mythic, attributed to "the wayfarers of this world"
  and "the old songs," never asserted as doctrine. Every sourced element is
  framed **"Inspired by" + link** (the Codex renders this caveat and label
  on every page automatically). The design goal is *curiosity*: world-building
  interesting enough that players follow the threads to the source and learn
  there — not here. One bridge entry ("The Orders of the Path") states the
  inspired-by relationship plainly; everything else stays in costume.
  - Source pages used so far: [the mystical number 108 → the Fountain](https://nurmuhammad.com/mystical-number-108-kawthar-haq-and-reality-of-sacrifice/) and [the twelfth month](https://nurmuhammad.com/12-dhul_hijjah/) (Part 2, §6.2); [Spiritual Dragons Protecting Believers](https://nurmuhammad.com/spiritual-dragons-protecting-believers-sufi-meditation-center/?playlist=17074) and [Thuban & the Fiery Guardian](https://nurmuhammad.com/thuban-and-the-fiery-guardian-sayyidina-malik-as/) (Guardians, §3.6).
  - **Decided (2026-07): the in-game Codex hyperlinks out to source pages** ("Learn more" links) — the strongest dawah funnel. Each Codex entry carries its source URLs in data. The §12.6 scholar/advisor review still covers the linked content before launch.
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

| Order | Affinity | Signature color | Theme source | Combat identity | Typical roles |
|---|---|---|---|---|---|
| **Naqshbandi** | **Heart** — neutral | **Deep emerald green** (the strongest order carries the strongest color — see §3.1) | Silent dhikr, *khalwat dar anjuman* (solitude in the crowd), the subtle centers (*laṭā'if*) | Meditation & mind: team-wide buffs, barriers, turn-meter and tempo manipulation, "unseen" (untargetable) states | Buffer, enabler, apex units |
| **Qadiri** | **Thunder** | Turquoise | Loud vocal dhikr, the "Ghawth" (supreme helper) archetype of spiritual power | Raw power: lightning and sound, highest single-target burst, armor-shattering shouts | Nuker, breaker |
| **Rifai** | **Ember** | Red | Renowned for feats of bodily invulnerability during dhikr (fire, blades) | Unbreakable body: taunts, damage immunity windows, burning retaliation | Tank, bruiser |
| **Mevlevi** | **Wind** | Pearl white (the whirling robes) | The samā' whirling ceremony | Continuous motion: spinning AoE damage, evasion, damage-over-turns, never staying still | AoE DPS, evader |
| **Shadhili** | **Sea** | Deep royal blue | The great litanies (aḥzāb), esp. the Litany of the Sea recited for protection on voyages | Protective recitation: cleansing debuffs, sustained regen, tide-like shields that grow over turns | Sustain support, cleanser |
| **Chishti** | **Harmony** | Rose | Samā' (spiritual music), radical hospitality, love and service | The open table: healing, revival, sharing HP/buffs between allies | Healer, binder |
| **Suhrawardi** | **Light** | Radiant yellow (the only order in the gold family — UI accent gold stays distinct) | Illuminationist (*ishrāqī*) philosophy of light *(note: the order and the philosopher are distinct historical strands — we borrow the light aesthetic, flagged in lore as inspiration)* | Revelation: exposing enemies (defense down, mark for death), true-sight vs stealth, precision crits | Debuffer, sniper |

Enemy **Corruption** signals dark blood-red/black. Canonical values: `Enums.AFFINITY_COLORS`. (Battle-UI state colors stay clear of the order palette: current actor = accent gold, target selection = cyan, boss-ultimate warning = bright warning red.)

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

| Rarity | Rank name | Source concept | Signal color | Gacha rate | Notes |
|---|---|---|---|---|---|
| ★★★ | **Novice** | *murīd* — committed student | Silver | 77% | Farmable, fodder-adjacent but a few hidden gems (genre tradition) |
| ★★★★ | **Wayfarer** | *sālik* — traveler on the path | Violet | 20% | Backbone of most teams |
| ★★★★★ | **Luminary** | *'ārif* — the knower | **Emerald green** | 3% | Banner units; all launch Naqshbandis live here or high 4★ |

Rarity signal colors are deliberate: **the strongest color is green** — the
noblest color in the source tradition — not gacha-standard gold. Gold remains
the general UI accent (§11 palette); green means *rarity and attainment*.
Canonical values: `Enums.RARITY_COLORS`.

### 3.2 Stats

`HP · ATK · DEF · SPD · Precision · Potency · Ward`

SPD drives a **turn-meter queue** (see §4.1). All stats are deterministic
(§4.4): **Precision** is a flat damage bonus (folded from the old crit
rate × crit damage — same expected value, zero dice); **Potency**
(effectiveness) strengthens the debuffs you inflict; **Ward** (resilience)
shrinks the debuffs you receive. Data fields keep their old names
(crit_rate/crit_damage/effectiveness/resilience) as inputs.

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
| **Fana, the Silent** | Naqshbandi | 5 | Buffer | Trance *Khalwa — Seclusion*: team untargetable 1 turn, +40% ATK after |
| **Sirr** (m) | Naqshbandi | 4 | Shielder | Barriers that convert absorbed damage into Fervor |
| **Rad, Voice of Thunder** | Qadiri | 5 | ST nuker | Trance: colossal single hit, ignores 50% DEF |
| **Sada** (m) | Qadiri | 4 | Breaker | Sound-wave attacks that reduce DEF and echo (second hit at 40%) |
| **Thabit, the Unburnt** | Rifai | 5 | Tank | Trance: 2-turn team damage immunity, attackers burn |
| **Jamr** | Rifai | 3 | Bruiser | Counterattacks while above 50% HP |
| **Sama, the Turning Sky** (m) | Mevlevi | 5 | AoE DPS | Gains *Spin* stacks each turn; Trance damage scales with stacks |
| **Dawran** | Mevlevi | 4 | Evader | Dodge chance aura; extra turn on dodge |
| **Bahr, the Returning Tide** (m) | Shadhili | 5 | Cleanser | Removes debuffs team-wide; each removed debuff heals |
| **Sahil** | Shadhili | 3 | Sustain | Small regen litany, stacks over turns |
| **Karam** (m) | Chishti | 5 | Healer | Trance revives one ally at 50% HP with 50 Fervor |
| **Ansel, the Open Door** | Chishti | 4 | Binder | Links two allies to share damage and healing |
| **Ishraq** (m) | Suhrawardi | 5 | Debuffer | *Illuminate*: marked enemy takes +25% from all sources |
| **Ziya** | Suhrawardi | 3 | Sniper | High crit vs debuffed enemies |

### 3.5 Visual Guidelines

- Traditional dress by order, **keyed to the §2 signature colors** (outfits mostly match faction color; iconic exceptions like the honey-felt Mevlevi sikke stay): Naqshbandi deep emerald, understated; Qadiri turquoise accents on storm greys; Rifai black/iron with deep red; Mevlevi white whirling skirts; Shadhili royal blue; Chishti rose/ochre warmth; Suhrawardi pale gold sun-ray patterns. Beards for most adult men; women in dignified modest dress (hijab styles varied by region — Turkic, Maghrebi, South Asian, West African for diversity across orders).
- **Modesty is the art direction**, not a limitation: flowing cloth, calligraphy-pattern auras, light and geometry do the visual spectacle work that skin does in other gacha games. This is also a market differentiator.
- Ability VFX language: each order gets a signature motif — Naqshbandi = expanding concentric circles of script; Qadiri = lightning + sound rings; Mevlevi = spiral trails; Suhrawardi = rays/lens flares; Shadhili = water calligraphy; Chishti = musical geometry; Rifai = embers/molten cracks.

### 3.6 Guardians — the Dragons of the Springs

Dragons fight **on the side of light**. This is grounded in the source
tradition: the research source (§1.1) teaches of *spiritual dragons
protecting believers*, and of the prophetic staff become a dragon that
**devours illusion and falsehood** — while Persian miniature painting (our
§11 art anchor) supplies the *azhdaha* serpent-dragon silhouette.

- **Guardians are a rare summonable class outside the seven orders** — each
  is the ancient protector of one of the Seven Springs (finally putting the
  title's springs into the fiction). Roadmap: seven Guardians total,
  released across the live-ops calendar; they are the collection's crown
  pieces.
- **Mechanical identity: protection and the devouring of falsehood** —
  barriers, cleansing, taunts, and (future effect block) *stripping enemy
  buffs*, the staff-dragon devouring the sorcerers' works.
- First Guardian shipped: **Sage, Guardian of the First Spring**
  (`data/units/sage.tres`) — Luminary, Heart affinity, protective
  support kit.
- Codex entry: dragons-as-protectors is prime dawah lore — a discovery even
  for Muslim players (§1.1 research source; internal refs: "Spiritual
  Dragons Protecting Believers," the Thuban teachings).

---

## 4. Combat System

### 4.1 Core Loop
- Team of **4** + 1 borrowed friend unit (social hook), vs 1–5 enemies.
- **Speed-based turn meter**: each unit's bar fills at SPD rate; act at 100%. (Genre-proven, enables SPD manipulation kits — Naqshbandi tempo identity.)
- On your unit's turn: Litany / Remembrance (if off cooldown) / Trance (if Fervor full). Target selection by tap.
- Auto-battle and 2× speed from day one — non-negotiable for the genre.

### 4.2 Status Effects (launch set — keep it tight)
Buffs: ATK↑, DEF↑, SPD↑, Barrier, Regen, Immunity, **Veil** (reduces damage taken by its magnitude — the deterministic evolution of evasion), Unseen (untargetable).
Debuffs: ATK↓, DEF↓, SPD↓, Burn, Silence (no Remembrance), **Whispers** (drains a fixed amount of Fervor every turn — doubt gnawing at resolve; the signature themed debuff, used *by enemies on you*, and cleansed by Shadhili).

### 4.4 Determinism principle — no dice, anywhere

**All combat outcomes are deterministic** (decided 2026-07, extending the §9
gambling-free ruling): random outcomes exert a subtle pull on the heart —
hoping instead of planning — and they hide information players deserve.
Every number is knowable before you act:

- No crit rolls (→ Precision), no damage variance, no dodge rolls (→ Veil),
  no debuff-landing rolls — debuffs **always land, scaled by potency**
  (skill potency × attacker Potency − defender Ward) and **stack** with
  repeated application, so partial debuffs reach full strength through
  planned, repeated use.
- Consequence embraced: identical inputs give identical battles. Combat is a
  **puzzle** — the player's choices are the only variance. Auto-battle
  becomes a reproducible baseline; manual mastery beats it by planning.
- Allowed randomness: cosmetic only (VFX jitter, ambient art) — nothing that
  changes an outcome.

### 4.3 Win/Lose
Standard: all enemies down = win (3-star rating by conditions: no deaths, under N turns); team wipe = retry with no stamina refund.

---

## 5. Enemies

Demons and personified vices only — never human, never anything resembling worship targets.

| Tier | Examples |
|---|---|
| Fodder | **Whisperlings** (whisper wisps), shadow-vermin, ash ghouls |
| Elite | **Mirror shades** (dark doubles of the player's own units — reuses rigs, cheap content), smoke serpents, hollow brutes |
| Chapter bosses | **The Seven Vices**, one per valley — English vice names in all UI; each bears an Arabic **true-name** as a title (sanctioned §1.1 flavor). ALL SEVEN SHIPPED (Phase 3): *Kibr, Father of Pride* (v1) · *Hasad, Devourer of Blessings* (v2 — DISPELS your blessings, feeds on them) · *Ghadab, the Blazing* (v3 — fast unbounded-feeling enrage + burns) · *Hirs, the Hollow Maw* (v4 — drains Fervor, hoards its own) · *Kasal, the Unmoving* (v5 — the heal-race: stacking regen behind stone) · *Zeenah, the Gilded* (v6 — gilds her escorts in barriers, dazzles your strength away) · *Ya's, the Last Whisper* (v7 — silence and despair-drain; the hardest wall) |
| Final arc | **The Whisperer** — an archdemon of despair (Iblis-*inspired*, deliberately not named as such — see §12) |

Boss design rule: each Vice boss mechanically embodies its vice (Pride reflects buffs back as damage unless dispelled; Envy steals your buffs; Despair drains Fervor) — so counterplay teaches the order system.

Dragons are explicitly **not** enemies — see §3.6: they fight on the side of
light.

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

Chapter titles are pure English (the valley names are already the standard translations of Attar's originals); each valley's Codex entry gives the source name and the poem's context — the §1.1 depth-on-tap pattern. Codex/lore content draws on the §1.1 lore research source (nurmuhammad.com) for its lesser-known material.

Each chapter spotlights an order's story characters — this doubles as the banner release schedule (chapter N launch = order N banner).

Story tone: earnest, warm, lightly humorous between battles; the *journey inward* framing (the demons grow stronger as they get more personal) gives gacha grinding an actual arc.

### 6.1 Content lifecycle & cadence

**Sim-verified pacing** (tests/simulate_progression.gd, real-engine battles,
day-by-day player model): at current curves a hardcore player full-clears all
7 valleys in **~7 days**, a casual player in **~14**. The campaign is the
spine, not the retention — long-term play comes from the layers below, in
priority order:

1. **Staggered release**: launch with Valleys 1–4; release 5–7 monthly, each
   with its order's banner (§6's chapter-spotlight structure = the live-ops
   calendar for the first 3 months free).
2. **The Minaret** (endless tower, monthly reset — §7): promote to
   **pre-launch requirement**. It's where players go when the campaign ends.
3. **Hard/Nightmare valley re-clears**: same stages at raised `enemy_scale`
   with better drops — nearly free with data-driven stages; 84 stages → 252.
4. **3-star stage objectives** (no deaths / under N turns / 3-unit clear)
   with Pearl rewards — triples the goals per stage, rewards mastery.
5. **Weekly Vice trials**: scaling boss re-fights reusing the Vice roster.
6. **Roster depth as true endgame**: dupes, skill-ups, ascension materials in
   daily sanctums, talismans (§8) — collection games retain through building.

Economy levers live in the progression sim (`XP_VALLEY_BONUS`, boss level
targets, Breath costs); rerun it before shipping any curve change.

### 6.2 Part 2 campaign — roadmap note (not yet designed)

Genre precedent is strong: FGO's Part 2 (new-arc campaign years post-launch),
Epic Seven's episodic campaigns, AFK Arena's rolling chapters — a second
campaign as a flagship content update is a proven anniversary-scale beat.

Concept notes (to be designed when Phase 3 planning begins):
- **Working title: *The Twelve Moons*** — 12 chapters, one per lunar month of
  the journey year; **9 stages per chapter; the final stage is stage 108**,
  where the road ends at **the Fountain of Abundance**.
- Synergy with live-ops (§9.3.1): the seasonal calendar already walks the
  Twelve Moons every lunar year — Part 2 turns the calendar players have
  been living into the campaign they finally travel. The Moon of the
  Fountain (season 12) foreshadows it annually.
- Structural numerology as lore seasoning: 12 × 9 = 108; the destination
  shares its number with the 108th chapter of the source tradition — kept as
  discoverable Codex depth, never surfaced as doctrine (§1.1).
- **Completion reward: the "Fountain of Youth"** — a small *permanent,
  account-wide* buff active in every game mode (exact effect TBD; must be
  minor enough not to warp tower/PvP balance — e.g. small starting-Fervor or
  regen bonus). Genre precedent: account-level passives.
- Language policy applies in full (§1.1), with flavor drawn from
  lesser-known tariqa concepts rather than mainstream vocabulary — the
  seasoning should feel like a discovery even to Muslim players.
- Internal research/inspiration source: nurmuhammad.com teachings on the
  twelve months and the mystical number 108 → the Fountain (inspiration
  only; all player-facing text passes §1.1 and the §12 charter, and the §12.6
  scholar review covers this campaign's framing explicitly).

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

## 9. Acquisition & Monetization — GAMBLING-FREE

**Ruling-driven redesign (2026-07): percentage-based paid acquisition — loot
boxes, gacha rolls, pity systems — is maysir and has been removed entirely.**
Nothing a player buys resolves by chance. All acquisition is deterministic,
fixed-price purchase. This is also the marketing identity: **the
gambling-free hero collector** — all the genre's spectacle, none of its
gambling.

### 9.1 The Calling (deterministic)
The ceremony survives; the dice do not. Thematic frame (from *bay'ah*, the
pledge): the player **chooses** the companion to call, pays their fixed price
in tier tokens, and the door-of-light ceremony plays. No rates, no pity, no
duplicates — skill-ups come from Teaching Scrolls, purchased directly.

### 9.2 Tiered token currencies
Three token currencies, keyed to the rarity signal colors (§3.1):

| Token | Buys | Earned in play by | Real-money anchor |
|---|---|---|---|
| **Silver Marks** | Novices, Teaching Scrolls | every stage clear | fractions of a cent–bulk packs |
| **Violet Seals** | Wayfarers | stage first-clears, weeklies | ~$1.20–1.80 each |
| **Emerald Sigils** | Luminaries (incl. Guardians) | valley-boss first-clears, achievements, events | ~$10–12 each |

Draft fixed prices (tune via the progression sim): **Novice 300 Marks ·
Wayfarer 10 Seals · Luminary 6 Sigils · Teaching Scroll 60 Marks.**

### 9.3 Revenue lines (all fixed-price, zero randomness — §12.9)
1. **Token packs** — singles at anchor price, bundles discounted (e.g.
   Sigils 1/$12 · 3/$33 · 6/$66). Bundle pricing puts a chosen Luminary at
   ≈ $66–72 — deliberately matched to the old expected pity cost ($70–90),
   so **expected revenue per team composition is preserved** while variance
   (and the gambling) disappears. Deterministic choice is *worth* the price:
   players buy exactly the hero they want.
2. **Monthly Traveler's Pass** ($4.99: daily token drip — baseline revenue)
3. **Season Pass** ($9.99 per season) — full spec in §9.3.1. **Seasons are
   the months of the lunar calendar** (29/30 days): the live-ops year IS the
   Twelve Moons.
4. **Cosmetics catalog** — the long-term ceiling (the Fortnite thesis:
   deterministic item shops out-earn gacha at scale). Outfit variants
   ($4.99–7.99), Trance VFX variants ($2.99), lodge decorations
   ($1.99–4.99), Guardian skins ($9.99). **Permanent catalog** — a weekly
   *featured* slot rotates visibility, but items never expire (guardrail:
   rotation without expiry pressure). The LoRA-per-character art pipeline
   makes outfit production genuinely cheap.
5. **Company Chest** mixed bundles (Marks+Seals+Sigils) at deeper discount;
   milestone value packs (one-time, contents shown exactly).

### 9.3.1 Season Pass spec — the Twelve Moons calendar

**A season is one lunar month** (29/30 days), starting on the 1st of each
Hijri month. Boundaries use a fixed *tabular* calendar (authored schedule
shipped via config, Umm al-Qura reference) — deterministic and global, no
regional sighting differences in-game; flag for §12.6 scholar review.

**The twelve season names are drawn from the research source's teaching for
each month** (its entry-way number and the reality it opens), presented per
§1.1. **The game itself never names the real months** (decided 2026-07):
each season's Codex entry carries teachings from the source's article on
that month plus a Learn-more link — the link carries the depth (entries in
`data/codex/moon_01..12.tres`). The names (canonical:
`SeasonCalendar.SEASON_NAMES`): **The Door** (1), **The Cave** (2, the cave
month), **The Kingdom** (3, the Beloved's birth), **The Straight Path** (4,
the heart-chapter month), **The Kneeling** (5, chapter 45), **The Moon**
(6, chapter 54), **The Ascent** (7, the Month of God), **The Beloved**
(8, the Beloved's own month), **The Light** (9 — the flagship generosity
season: gift events, lightened Deeds for fasting players, no purchase
pressure), **The Binary Code** (10 — ten as the one and
the dot, the code beneath all things), **The Shaking** (11 — chapter 99:
what is hidden comes out only when shaken),
and **The Fountain** (12 — 108, each year's climax, foreshadowing
Part 2 §6.2).

**Structure**: 30 tiers earned via **Deeds** (3 daily + 3 weekly objectives —
clear stages, earn stars, climb the Minaret, refine mastery, read a Codex
entry). ~1 tier/casual day; tier 30 reachable by ~day 24. Deeds double as
the daily-purpose loop (ECONOMY_TUNING §7 finding).

| | Free track | Paid track ($9.99) |
|---|---|---|
| Tokens | ~100 Marks, 1 Seal | 300 Marks, 2 Seals, 1 Sigil (tier 30) |
| Scrolls | 2 | 5 |
| Cosmetics | 1 lodge decoration | Seasonal outfit + Trance VFX + profile flourish |

Perceived paid value ≈ $26 for $9.99 (the healthy ~2.5x pass ratio).

**Ethics rules**: no power on the paid track (the Sigil is freely earnable
elsewhere); no tier-skips sold; buying late retroactively grants earned
tiers; seasonal "exclusives" enter the permanent catalog after two Moons at
a higher standalone price — **scarcity of timing, never scarcity of
possibility**. Lunar-year note: 12 seasons per 354 days ≈ 12.4 per solar
year (~3% cadence uplift vs Gregorian; sim approximates 30-day seasons).

### 9.3.2 Content cadence = revenue cadence
Under deterministic pricing **the catalog is the revenue ceiling**, so the
business plan is a content plan: target **2 new heroes/month** (~$140/month
added to the completionist ceiling), **1 season pass/month**, **3–4
cosmetics/month**. Every release's revenue contribution is verified in the
economy sim before shipping (ECONOMY_TUNING.md §6). Year-one completionist
ceiling at this cadence: ≈ $2,000+ cumulative — genre-competitive without a
single dice roll.

### 9.4 Compliance & positioning
- **No loot boxes** → no odds-disclosure requirements, no Belgium/Netherlands
  restrictions, no gambling age-rating descriptors. Ship everywhere.
- **Advertise it loudly**: "the gambling-free hero collector" is both a dawah
  statement and a store-listing differentiator nobody else in the genre has.
  Parents, regulators, and recovering gacha players are all the audience.
- Guardrails retained: optional monthly spend-limit setting, no countdown
  pressure on first-time buyers, all prices visible before purchase.
- **Scope rule**: superseded 2026-07 — combat is now ALSO fully
  deterministic (§4.4), not because gameplay dice were maysir (no stake),
  but to promote strategy and quiet the heart-pull of random outcomes. The
  whole game is now dice-free: outcomes from choices, everywhere. The
  standing charter rule (§12.9) covers money; §4.4 covers everything else.

---

## 10. Economy Sketch (tune in spreadsheets + progression sim)

- F2P income target: one full campaign pass earns ~2 chosen Luminaries' worth
  of Sigils (valley-boss first-clears + achievements); steady state ~1
  Luminary per 6–8 weeks for a dailies player.
- Honest whale ceiling: a full chosen-Luminary comp ≈ $260–290 — comparable
  to old expected gacha spend for the same outcome, with zero variance.
- Stamina: 1 Breath/6 min regen, campaign stage = 6–10 Breath.
- Every currency, cost, and reward lives in **data files, not code** (see
  §13); rerun `tests/simulate_progression.gd` after any economy change.

---

## 11. Art & Audio Direction

- **Characters**: stylized anime, painterly rendering; portrait (bust) art for menus/gacha, chibi-proportioned battle sprites with 2D skeletal animation (Godot's Skeleton2D, or Spine if budget allows). Bust art + chibi rig is the cheapest path to "looks like a real gacha."
- **Production method: AI-generated base + mandatory human paint-over**, per the full pipeline in **`AI_ART_PIPELINE.md`** — style bible first, one LoRA per character for consistency, manual layer-cutting and rigging for battle sprites, vector work (not AI) for UI chrome. The paint-over pass is required on every shipped asset (copyright + quality), and AI-generated Arabic script is banned outright (see §12.8).
- **UI**: deep blues/golds, girih geometric patterns, arabesque frames, thuluth-style ornamental (non-scriptural!) calligraphy motifs. UI is where the Islamic-art identity lives most cheaply.
- **Audio**: ney flute, daf/bendir percussion, oud; vocal layers as *vocables* not sacred text. **Settings option: "percussion & voice only" mode** — some of the Muslim audience avoids melodic instruments; a one-toggle respect feature nobody else in the genre has. Production: AI-generated — **Suno primary, Stable Audio designated fallback** — per `AI_ART_PIPELINE.md` §11 (tool-agnostic briefs, instrumental-only hard rule, identity pieces earmarked for composer commission).
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
9. **No paid randomness, ever**: anything money touches resolves deterministically (§9). Percentage-based paid acquisition is maysir — this determination is permanent and applies to all future systems (events, cosmetics, talisman rolls, anything).

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
Full plan: **`BACKEND.md`**. Summary: local save through the vertical slice;
before any real-money launch the economy (wallet, roster, purchases, IAP
receipt validation) becomes server-authoritative on **Nakama** (Godot 4 SDK,
built-in wallet/IAP/leaderboards; ~$30/mo VPS at soft-launch scale). Our
gambling-free economy removes the need for server-side RNG entirely, and
deterministic combat (§4.4) gives free anti-cheat via replay verification —
the server re-simulates any battle with our actual engine and gets the exact
result. Analytics + crash reporting (PostHog/Sentry) land before soft launch.

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
