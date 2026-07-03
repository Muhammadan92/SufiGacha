extends Node
## Autoload "Game": the player profile — roster, currencies, Breath (stamina),
## stage progress, summoning (The Calling) with pity, and the save file.
##
## NOTE (GDD §13.3): summoning and the wallet MUST move behind a
## server-authoritative interface before any real-money launch. This local
## implementation is for the prototype economy only.

const SAVE_PATH := "user://save.json"

const BREATH_MAX := 60
const BREATH_REGEN_SECONDS := 360  # 1 Breath / 6 min (GDD §10)
const LEVEL_CAP := 60
const STARTERS := ["bram", "echo", "brand", "aria"]

const PULL_COST := 10
const PITY_LIMIT := 70         # hard pity: guaranteed Luminary (GDD §9.1)
const RATE_LUMINARY := 0.03
const RATE_WAYFARER := 0.20

var roster := {}   # id (String) -> {"level": int, "xp": int, "dupes": int}
var team: Array = STARTERS.duplicate()
var pearls := 30
var scrolls := 0   # Teaching Scrolls, from duplicate summons
var breath := BREATH_MAX
var breath_ts := 0
var cleared := {}  # stage id (String) -> true
var pity := 0

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
		"xp_each": 0, "pearls": 0, "first_clear_pearls": 0,
		"level_ups": [],
	}
	if victory:
		summary["xp_each"] = stage.xp_reward
		summary["pearls"] = stage.pearls_reward
		pearls += stage.pearls_reward
		if not cleared.has(String(stage.id)):
			cleared[String(stage.id)] = true
			summary["first_clear_pearls"] = stage.first_clear_pearls
			pearls += stage.first_clear_pearls
		for id in team:
			var gained := add_xp(id, stage.xp_reward)
			if gained > 0:
				summary["level_ups"].append("%s reached level %d" % [db.units[id].display_name, level_of(id)])
	save()
	return summary


# --- The Calling (summoning) --------------------------------------------------

## Performs `count` summons. Returns [] if pearls are insufficient, else a
## list of {"unit": UnitData, "is_new": bool, "rarity": int}.
func pull(count: int) -> Array:
	var cost := PULL_COST * count
	if pearls < cost:
		return []
	pearls -= cost
	var results: Array = []
	for i in count:
		results.append(_pull_one())
	# 10-pull guarantee: at least one Wayfarer or better (GDD §9.1).
	if count >= 10:
		var has_good := false
		for r: Dictionary in results:
			if r["rarity"] >= 4:
				has_good = true
				break
		if not has_good:
			results[results.size() - 1] = _pull_rarity(4)
	save()
	return results


func _pull_one() -> Dictionary:
	pity += 1
	var roll := randf()
	if pity >= PITY_LIMIT:
		return _pull_rarity(5)
	if roll < RATE_LUMINARY:
		return _pull_rarity(5)
	if roll < RATE_LUMINARY + RATE_WAYFARER:
		return _pull_rarity(4)
	return _pull_rarity(3)


func _pull_rarity(rarity: int) -> Dictionary:
	if rarity == 5:
		pity = 0
	var pool: Array = db.playable_pool(rarity)
	var unit: UnitData = pool[randi() % pool.size()]
	var is_new := grant_unit(String(unit.id))
	return {"unit": unit, "is_new": is_new, "rarity": rarity}


# --- save file ------------------------------------------------------------------

func save() -> void:
	var blob := {
		"roster": roster, "team": team, "pearls": pearls, "scrolls": scrolls,
		"breath": breath, "breath_ts": breath_ts, "cleared": cleared, "pity": pity,
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
			pearls = int(blob.get("pearls", 30))
			scrolls = int(blob.get("scrolls", 0))
			breath = int(blob.get("breath", BREATH_MAX))
			breath_ts = int(blob.get("breath_ts", 0))
			cleared = blob.get("cleared", {})
			pity = int(blob.get("pity", 0))
	if roster.is_empty():
		for id in STARTERS:
			grant_unit(id)
		save()
	regen_breath()


## Debug/testing helper: wipe progress back to a fresh profile.
func reset_profile() -> void:
	roster = {}
	team = STARTERS.duplicate()
	pearls = 30
	scrolls = 0
	breath = BREATH_MAX
	breath_ts = 0
	cleared = {}
	pity = 0
	for id in STARTERS:
		grant_unit(id)
	save()
