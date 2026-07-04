extends Node
## Autoload "Game": the player profile — roster, currencies, Breath (stamina),
## stage progress, The Calling (deterministic token shop), and the save file.
##
## NOTE (GDD §13.3): summoning and the wallet MUST move behind a
## server-authoritative interface before any real-money launch. This local
## implementation is for the prototype economy only.

const SAVE_PATH := "user://save.json"

const BREATH_MAX := 60
const BREATH_REGEN_SECONDS := 360  # 1 Breath / 6 min (GDD §10)
const LEVEL_CAP := 60
const STARTERS := ["bram", "echo", "brand", "aria"]

# GAMBLING-FREE acquisition (GDD §9): all purchases are deterministic,
# fixed-price, in tiered tokens. No rolls, no rates, no pity — ever (§12.9).
const UNIT_COSTS := {
	3: { "currency": "marks", "amount": 300 },   # Novice — Silver Marks
	4: { "currency": "seals", "amount": 10 },    # Wayfarer — Violet Seals
	5: { "currency": "sigils", "amount": 6 },    # Luminary — Emerald Sigils
}
const SCROLL_COST_MARKS := 60
const MASTERY_CAP := 5
const MASTERY_BONUS_PER_LEVEL := 0.06  # +6% damage/heal output per mastery
## Stars: 1 = clear, 2 = + no companion falls, 3 = + within the stage's turn target.
const STAR_REWARD_MARKS := 20
const STAR_REWARD_SEALS := 1
const MINARET_UNLOCK_STAGE := "v1_s06"
const SANCTUM_UNLOCK_STAGE := "v1_s04"

# --- Season Pass (GDD §9.3.1): 30 tiers, 40 season-XP each ---
const SEASON_TIERS := 30
const TIER_XP := 40
const DEED_XP_DAILY := 10
const DEED_XP_WEEKLY := 25
const DEED_MARKS_DAILY := 20
const DEED_SEALS_WEEKLY := 1
## Reward tables (paid totals mirror the economy sim: 300 Marks, 2 Seals,
## 1 Sigil, 5 Scrolls + seasonal outfit placeholder at tier 30).
const PASS_FREE := {
	5: {"marks": 30}, 10: {"scrolls": 1}, 15: {"marks": 40},
	20: {"scrolls": 1}, 25: {"marks": 30}, 30: {"seals": 1},
}
const PASS_PAID := {
	2: {"marks": 30}, 4: {"scrolls": 1}, 6: {"marks": 30}, 8: {"seals": 1},
	10: {"scrolls": 1}, 12: {"marks": 40}, 14: {"scrolls": 1}, 16: {"marks": 40},
	18: {"seals": 1}, 20: {"scrolls": 1}, 22: {"marks": 40}, 24: {"scrolls": 1},
	26: {"marks": 60}, 28: {"marks": 60}, 30: {"sigils": 1},
}

## Deeds: 3 daily (rotating window over the pool) + 3 fixed weekly.
const DAILY_DEED_POOL := [
	{"id": "win3", "desc": "Win 3 battles", "goal": 3, "event": "win"},
	{"id": "breath24", "desc": "Spend 24 Breath", "goal": 24, "event": "breath"},
	{"id": "flawless", "desc": "Win a battle with no companion falling", "goal": 1, "event": "flawless"},
	{"id": "climb2", "desc": "Climb 2 Minaret floors", "goal": 2, "event": "climb"},
]
const WEEKLY_DEEDS := [
	{"id": "win12", "desc": "Win 12 battles", "goal": 12, "event": "win"},
	{"id": "refine", "desc": "Refine a technique (Mastery)", "goal": 1, "event": "refine"},
	{"id": "codex", "desc": "Read an entry in the Notebook", "goal": 1, "event": "codex"},
]

const SANCTUM_RUNS_PER_DAY := 2
const SANCTUM_BREATH_COST := 10
const SANCTUM_ORDERS := ["Naqshbandi", "Qadiri", "Rifai", "Mevlevi", "Shadhili", "Chishti", "Suhrawardi"]

var roster := {}   # id (String) -> {"level": int, "xp": int, "dupes": int}
var team: Array = STARTERS.duplicate()
var marks := 200   # Silver Marks
var seals := 0     # Violet Seals
var sigils := 0    # Emerald Sigils
var scrolls := 0   # Teaching Scrolls
var breath := BREATH_MAX
var breath_ts := 0
var cleared := {}  # stage id (String) -> true
var stars := {}    # stage id (String) -> best stars earned (1..3)
var minaret_floor := 0  # highest Minaret floor cleared

# --- lunar season / Deeds / Season Pass / Sanctum state (GDD §9.3.1) ---
var season := {}   # {"id", "tier_xp": int, "tier": int, "paid": bool}
var deeds := {}    # {"day_key", "week_key", "daily": [..], "weekly": [..]}
var sanctum := {}  # {"day_key", "runs": int}

## First-session tutorial progress: 0 intro → 1 stage select → 2 first
## battle → 3 first results → 4 systems reveal → 5 done.
var tutorial_step := 0
const TUTORIAL_DONE := 5


func tutorial_at(step: int) -> bool:
	return tutorial_step == step


func advance_tutorial(from_step: int) -> void:
	if tutorial_step == from_step:
		tutorial_step += 1
		save()

# Lazy sibling lookup (not @onready, not an absolute path) so headless tests
# that build the tree manually still work — autoloads and test doubles are
# both children of root, so the parent always has a "Db" sibling.
var _db_cache: Node = null
var db: Node:
	get:
		if _db_cache == null and get_parent() != null:
			_db_cache = get_parent().get_node_or_null("Db")
		return _db_cache


func _ready() -> void:
	load_save()


# --- roster & progression ---------------------------------------------------

func owns(id: String) -> bool:
	return roster.has(id)


func level_of(id: String) -> int:
	return roster[id]["level"] if roster.has(id) else 1


func level_mult(level: int) -> float:
	return 1.0 + 0.04 * (level - 1)


func xp_to_next(level: int) -> int:
	return 25 * level


## Grants XP, applying level-ups. Returns levels gained.
func add_xp(id: String, amount: int) -> int:
	if not roster.has(id):
		return 0
	var entry: Dictionary = roster[id]
	entry["xp"] += amount
	var gained := 0
	while entry["level"] < LEVEL_CAP and entry["xp"] >= xp_to_next(entry["level"]):
		entry["xp"] -= xp_to_next(entry["level"])
		entry["level"] += 1
		gained += 1
	return gained


## Adds a unit to the roster. Returns true if new, false if duplicate
## (duplicates convert to Teaching Scrolls).
func grant_unit(id: String) -> bool:
	if roster.has(id):
		roster[id]["dupes"] += 1
		scrolls += 1
		return false
	roster[id] = {"level": 1, "xp": 0, "dupes": 0, "mastery": 0}
	return true


# --- mastery (Teaching Scrolls spend, GDD §8) ---------------------------------

func mastery_of(id: String) -> int:
	return int(roster[id].get("mastery", 0)) if roster.has(id) else 0


func mastery_cost(current: int) -> int:
	return current + 1  # 1,2,3,4,5 scrolls -> 15 total to max a character


func skill_mult_of(id: String) -> float:
	return 1.0 + MASTERY_BONUS_PER_LEVEL * mastery_of(id)


## Spends Teaching Scrolls to raise a character's mastery. Deterministic.
func upgrade_mastery(id: String) -> bool:
	if not roster.has(id):
		return false
	var current := mastery_of(id)
	if current >= MASTERY_CAP:
		return false
	var cost := mastery_cost(current)
	if scrolls < cost:
		return false
	scrolls -= cost
	roster[id]["mastery"] = current + 1
	deed_event("refine")
	save()
	return true


# --- Breath (stamina) --------------------------------------------------------

func regen_breath() -> void:
	var now := int(Time.get_unix_time_from_system())
	if breath_ts <= 0:
		breath_ts = now
		return
	var ticks := (now - breath_ts) / BREATH_REGEN_SECONDS
	if ticks > 0 and breath < BREATH_MAX:
		breath = mini(BREATH_MAX, breath + ticks)
		breath_ts += ticks * BREATH_REGEN_SECONDS
	if breath >= BREATH_MAX:
		breath_ts = now


func spend_breath(cost: int) -> bool:
	regen_breath()
	if breath < cost:
		return false
	breath -= cost
	deed_event("breath", cost)
	save()
	return true


# --- stages -------------------------------------------------------------------

func is_unlocked(stage: StageData) -> bool:
	var prev: StageData = null
	for s: StageData in db.stage_order:
		if s.id == stage.id:
			return prev == null or cleared.has(String(prev.id))
		prev = s
	return false


## Applies rewards after a battle; returns a summary for the results screen.
## stats: {"deaths": int, "turns": int} from the battle, for star objectives.
func finish_stage(stage: StageData, victory: bool, stats: Dictionary = {}) -> Dictionary:
	var summary := {
		"victory": victory,
		"stage_name": stage.display_name,
		"xp_each": 0, "marks": 0, "first_clear_seals": 0, "first_clear_sigils": 0,
		"stars": 0, "new_stars": 0, "star_marks": 0, "star_seals": 0,
		"turn_target": stage.turn_target,
		"level_ups": [],
	}
	if victory:
		summary["xp_each"] = stage.xp_reward
		summary["marks"] = stage.marks_reward
		marks += stage.marks_reward
		if not cleared.has(String(stage.id)):
			cleared[String(stage.id)] = true
			summary["first_clear_seals"] = stage.first_clear_seals
			summary["first_clear_sigils"] = stage.first_clear_sigils
			seals += stage.first_clear_seals
			sigils += stage.first_clear_sigils
		# Star objectives (GDD §6.1) — deterministic, so a solvable puzzle:
		# clear / nobody falls / within the turn target.
		var earned := 1
		if int(stats.get("deaths", 99)) == 0:
			earned += 1
		if int(stats.get("turns", 99999)) <= stage.turn_target:
			earned += 1
		summary["stars"] = earned
		var prev := int(stars.get(String(stage.id), 0))
		if earned > prev:
			var delta := earned - prev
			stars[String(stage.id)] = earned
			summary["new_stars"] = delta
			summary["star_marks"] = STAR_REWARD_MARKS * delta
			summary["star_seals"] = STAR_REWARD_SEALS * delta
			marks += summary["star_marks"]
			seals += summary["star_seals"]
		for id in team:
			var gained := add_xp(id, stage.xp_reward)
			if gained > 0:
				summary["level_ups"].append("%s reached level %d" % [db.units[id].display_name, level_of(id)])
		deed_event("win")
		if int(stats.get("deaths", 99)) == 0:
			deed_event("flawless")
	save()
	return summary


# --- The Minaret (endless tower, GDD §7) ----------------------------------------

const MINARET_SETS := [
	["whisperling", "shadow_vermin"],
	["shadow_vermin", "ash_ghoul"],
	["whisperling", "whisperling", "ash_ghoul"],
	["ash_ghoul", "ash_ghoul", "shadow_vermin"],
	["whisperling", "ash_ghoul", "shadow_vermin", "whisperling"],
]


func minaret_unlocked() -> bool:
	return cleared.has(MINARET_UNLOCK_STAGE)


## Builds the stage for a Minaret floor in code — floors are formulaic,
## not authored. Every 10th floor is a Vice (Kibr) floor.
func make_minaret_stage(floor: int) -> StageData:
	var s := StageData.new()
	s.id = StringName("minaret_f%d" % floor)
	s.display_name = "The Minaret — Floor %d" % floor
	s.valley = 0
	s.breath_cost = 0
	s.turn_target = 999999  # no star objectives in the tower
	if floor % 10 == 0:
		s.enemy_ids = ["kibr"]
		s.index = 12  # boss music
	else:
		s.enemy_ids = MINARET_SETS[(floor - 1) % MINARET_SETS.size()]
		s.index = 1
	s.enemy_scale = 0.6 + 0.07 * floor  # steeper than campaign: the tower should wall
	return s


## Rewards for clearing a NEW highest floor. No Breath cost, no star system —
## the tower itself is the objective.
func finish_minaret(floor: int, victory: bool) -> Dictionary:
	var summary := {
		"victory": victory,
		"stage_name": "The Minaret — Floor %d" % floor,
		"xp_each": 0, "marks": 0, "first_clear_seals": 0, "first_clear_sigils": 0,
		"stars": 0, "new_stars": 0, "star_marks": 0, "star_seals": 0,
		"level_ups": [],
	}
	if victory and floor == minaret_floor + 1:
		minaret_floor = floor
		summary["marks"] = 30 + 5 * floor
		marks += summary["marks"]
		if floor % 5 == 0:
			summary["first_clear_seals"] = 2
			seals += 2
		if floor % 10 == 0:
			summary["first_clear_sigils"] = 1
			sigils += 1
		# Modest XP — economy sim showed rich tower XP collapses campaign pacing
		summary["xp_each"] = 10 + 2 * floor
		for id in team:
			var gained := add_xp(id, summary["xp_each"])
			if gained > 0:
				summary["level_ups"].append("%s reached level %d" % [db.units[id].display_name, level_of(id)])
		deed_event("climb")
	save()
	return summary


# --- The Calling (deterministic shop, GDD §9.1) --------------------------------

func currency_amount(currency: String) -> int:
	match currency:
		"marks": return marks
		"seals": return seals
		"sigils": return sigils
		_: return 0


func unit_cost(rarity: int) -> Dictionary:
	return UNIT_COSTS[rarity]


func can_afford_unit(unit: UnitData) -> bool:
	var cost: Dictionary = UNIT_COSTS[unit.rarity]
	return currency_amount(cost["currency"]) >= cost["amount"]


## Deterministic purchase of a CHOSEN unit. Returns "ok", "owned", or "poor".
func buy_unit(id: String) -> String:
	if roster.has(id):
		return "owned"
	var unit: UnitData = db.units[id]
	var cost: Dictionary = UNIT_COSTS[unit.rarity]
	if not can_afford_unit(unit):
		return "poor"
	match cost["currency"]:
		"marks": marks -= cost["amount"]
		"seals": seals -= cost["amount"]
		"sigils": sigils -= cost["amount"]
	grant_unit(id)
	save()
	return "ok"


func buy_scroll(count: int = 1) -> bool:
	var cost := SCROLL_COST_MARKS * count
	if marks < cost:
		return false
	marks -= cost
	scrolls += count
	save()
	return true


# --- lunar season, Deeds, Season Pass (GDD §9.3.1) -------------------------------

func now_unix() -> int:
	return int(Time.get_unix_time_from_system())


## Rolls season/deeds/sanctum state forward to the current moment.
## Call before reading any of them (screens call it via refresh).
func tick_time() -> void:
	var unix := now_unix()
	var sid := SeasonCalendar.season_id(unix)
	if season.get("id", "") != sid:
		season = { "id": sid, "tier_xp": 0, "tier": 0, "paid": false }
	var day_key := Time.get_date_string_from_unix_time(unix)
	if deeds.get("day_key", "") != day_key:
		var day_index := int(floor(unix / 86400.0))
		var daily: Array = []
		for i in 3:
			var def: Dictionary = DAILY_DEED_POOL[(day_index + i) % DAILY_DEED_POOL.size()]
			daily.append({ "id": def["id"], "desc": def["desc"], "goal": def["goal"],
				"event": def["event"], "progress": 0, "done": false })
		deeds["day_key"] = day_key
		deeds["daily"] = daily
	var week_key := str(int(floor(unix / (86400.0 * 7.0))))
	if deeds.get("week_key", "") != week_key:
		var weekly: Array = []
		for def: Dictionary in WEEKLY_DEEDS:
			weekly.append({ "id": def["id"], "desc": def["desc"], "goal": def["goal"],
				"event": def["event"], "progress": 0, "done": false })
		deeds["week_key"] = week_key
		deeds["weekly"] = weekly
	if sanctum.get("day_key", "") != day_key:
		sanctum = { "day_key": day_key, "runs": 0 }


## Feed a gameplay event into active Deeds. Kinds: win, breath, flawless,
## climb, refine, codex.
func deed_event(kind: String, amount: int = 1) -> void:
	tick_time()
	for list_name in ["daily", "weekly"]:
		for d in deeds.get(list_name, []):
			if d["event"] != kind or d["done"]:
				continue
			d["progress"] = mini(d["goal"], int(d["progress"]) + amount)
			if d["progress"] >= d["goal"]:
				d["done"] = true
				if list_name == "daily":
					marks += DEED_MARKS_DAILY
					_grant_season_xp(DEED_XP_DAILY)
				else:
					seals += DEED_SEALS_WEEKLY
					_grant_season_xp(DEED_XP_WEEKLY)
	save()


func _grant_season_xp(amount: int) -> void:
	season["tier_xp"] = int(season.get("tier_xp", 0)) + amount
	while season["tier"] < SEASON_TIERS and season["tier_xp"] >= TIER_XP * (int(season["tier"]) + 1):
		season["tier"] = int(season["tier"]) + 1
		_grant_tier_rewards(int(season["tier"]), false)
		if season.get("paid", false):
			_grant_tier_rewards(int(season["tier"]), true)


func _grant_tier_rewards(tier: int, paid_track: bool) -> void:
	var table: Dictionary = PASS_PAID if paid_track else PASS_FREE
	if not table.has(tier):
		return
	var reward: Dictionary = table[tier]
	marks += int(reward.get("marks", 0))
	seals += int(reward.get("seals", 0))
	sigils += int(reward.get("sigils", 0))
	scrolls += int(reward.get("scrolls", 0))


## Prototype pass unlock (real IAP in Phase 3). Retroactive per GDD §9.3.1:
## buying late grants all paid rewards for tiers already reached.
func unlock_season_pass() -> void:
	tick_time()
	if season.get("paid", false):
		return
	season["paid"] = true
	for t in range(1, int(season["tier"]) + 1):
		_grant_tier_rewards(t, true)
	save()


# --- daily Sanctum (GDD §7): today's order, Teaching Scrolls as material ----------

func sanctum_unlocked() -> bool:
	return cleared.has(SANCTUM_UNLOCK_STAGE)


func sanctum_runs_left() -> int:
	tick_time()
	return SANCTUM_RUNS_PER_DAY - int(sanctum.get("runs", 0))


func sanctum_order_today() -> String:
	return SANCTUM_ORDERS[SeasonCalendar.from_unix(now_unix())["day"] % SANCTUM_ORDERS.size()]


func make_sanctum_stage() -> StageData:
	var s := StageData.new()
	s.id = &"sanctum"
	s.display_name = "Sanctum of the %s" % sanctum_order_today()
	s.valley = 0
	s.index = 1
	s.breath_cost = SANCTUM_BREATH_COST
	s.turn_target = 999999
	var idx: int = SeasonCalendar.from_unix(now_unix())["day"] % MINARET_SETS.size()
	s.enemy_ids = MINARET_SETS[idx]
	# Adaptive: always a real fight, never a freebie — scales with the team.
	var top_level := 1
	for id in team:
		top_level = maxi(top_level, level_of(id))
	s.enemy_scale = 0.85 * level_mult(top_level)
	return s


func finish_sanctum(victory: bool) -> Dictionary:
	tick_time()
	var summary := {
		"victory": victory, "stage_name": "Sanctum of the %s" % sanctum_order_today(),
		"xp_each": 0, "marks": 0, "first_clear_seals": 0, "first_clear_sigils": 0,
		"stars": 0, "new_stars": 0, "star_marks": 0, "star_seals": 0,
		"scrolls": 0, "level_ups": [],
	}
	if victory and sanctum_runs_left() > 0:
		sanctum["runs"] = int(sanctum.get("runs", 0)) + 1
		scrolls += 1
		marks += 40
		summary["scrolls"] = 1
		summary["marks"] = 40
		summary["xp_each"] = 20
		for id in team:
			var gained := add_xp(id, 20)
			if gained > 0:
				summary["level_ups"].append("%s reached level %d" % [db.units[id].display_name, level_of(id)])
		deed_event("win")
	save()
	return summary


# --- save file ------------------------------------------------------------------

func save() -> void:
	var blob := {
		"save_version": 4,  # v3 stars/mastery/minaret; v4 season/deeds/sanctum
		"roster": roster, "team": team, "scrolls": scrolls,
		"marks": marks, "seals": seals, "sigils": sigils,
		"breath": breath, "breath_ts": breath_ts, "cleared": cleared,
		"stars": stars, "minaret_floor": minaret_floor,
		"season": season, "deeds": deeds, "sanctum": sanctum,
		"tutorial_step": tutorial_step,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(blob))


func load_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		var blob = JSON.parse_string(f.get_as_text())
		if blob is Dictionary:
			roster = blob.get("roster", {})
			team = blob.get("team", STARTERS.duplicate())
			scrolls = int(blob.get("scrolls", 0))
			marks = int(blob.get("marks", 200))
			seals = int(blob.get("seals", 0))
			sigils = int(blob.get("sigils", 0))
			# migration: pre-token saves held Pearls — convert 1 Pearl -> 10 Marks
			if blob.has("pearls"):
				marks += int(blob["pearls"]) * 10
			breath = int(blob.get("breath", BREATH_MAX))
			breath_ts = int(blob.get("breath_ts", 0))
			cleared = blob.get("cleared", {})
			stars = blob.get("stars", {})
			minaret_floor = int(blob.get("minaret_floor", 0))
			season = blob.get("season", {})
			deeds = blob.get("deeds", {})
			sanctum = blob.get("sanctum", {})
			# migration: pre-tutorial saves with progress skip the tutorial
			tutorial_step = int(blob.get("tutorial_step",
				TUTORIAL_DONE if not cleared.is_empty() else 0))
			for id in roster:  # v2 -> v3: mastery field
				if not roster[id].has("mastery"):
					roster[id]["mastery"] = 0
	if roster.is_empty():
		for id in STARTERS:
			grant_unit(id)
		save()
	regen_breath()


## Debug/testing helper: wipe progress back to a fresh profile.
func reset_profile() -> void:
	roster = {}
	team = STARTERS.duplicate()
	marks = 200
	seals = 0
	sigils = 0
	scrolls = 0
	breath = BREATH_MAX
	breath_ts = 0
	cleared = {}
	stars = {}
	minaret_floor = 0
	season = {}
	deeds = {}
	sanctum = {}
	tutorial_step = 0
	for id in STARTERS:
		grant_unit(id)
	tick_time()
	save()
