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

var roster := {}   # id (String) -> {"level": int, "xp": int, "dupes": int}
var team: Array = STARTERS.duplicate()
var marks := 200   # Silver Marks
var seals := 0     # Violet Seals
var sigils := 0    # Emerald Sigils
var scrolls := 0   # Teaching Scrolls
var breath := BREATH_MAX
var breath_ts := 0
var cleared := {}  # stage id (String) -> true

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
	roster[id] = {"level": 1, "xp": 0, "dupes": 0}
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
func finish_stage(stage: StageData, victory: bool) -> Dictionary:
	var summary := {
		"victory": victory,
		"stage_name": stage.display_name,
		"xp_each": 0, "marks": 0, "first_clear_seals": 0, "first_clear_sigils": 0,
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
		for id in team:
			var gained := add_xp(id, stage.xp_reward)
			if gained > 0:
				summary["level_ups"].append("%s reached level %d" % [db.units[id].display_name, level_of(id)])
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


# --- save file ------------------------------------------------------------------

func save() -> void:
	var blob := {
		"roster": roster, "team": team, "scrolls": scrolls,
		"marks": marks, "seals": seals, "sigils": sigils,
		"breath": breath, "breath_ts": breath_ts, "cleared": cleared,
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
	for id in STARTERS:
		grant_unit(id)
	save()
