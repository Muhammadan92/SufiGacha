extends SceneTree
## Player-progression simulator: models an optimal player's day-by-day career
## through the full 7-valley campaign, using REAL battles (the actual engine)
## for every stage attempt. Valley 1 uses authored stage data; valleys 2-7 are
## synthesized from the same curve shape until they're authored (the synth
## parameters below ARE the draft economy for authoring them).
##
## Player policy: attempt the furthest uncleared stage; after 2 consecutive
## losses, grind the best cleared stage for XP until a team level-up, then
## retry. Pulls are tracked as income but the team stays the starters —
## a conservative floor (real players improve their roster).
##
## Run:  godot --headless --path . -s res://tests/simulate_progression.gd

const TEAM := ["bram", "echo", "brand", "aria"]
const LEVEL_CAP := 60
const STEP_CAP := 800
const MAX_DAYS := 150

## Daily Breath budgets per player profile (cap-aware realistic collection).
const PROFILES := { "hardcore": 200, "casual": 80 }

## Target team level at each valley's boss — the difficulty spine for
## authoring valleys 2-7.
const BOSS_TARGET_LEVELS := [8, 15, 22, 29, 36, 42, 48]

## XP reward growth per valley (multiplier on the valley-1 XP curve).
## This is THE economy lever: raise it to soften grind walls.
const XP_VALLEY_BONUS := 0.5

## Non-boss stage pressure relative to expected player power (from valley 1
## tuning: early stages ~0.72x, late ~1.0x of player level-mult).
const SYNTH_ENEMY_SETS := [
	["whisperling", "whisperling"],
	["whisperling", "shadow_vermin"],
	["shadow_vermin", "shadow_vermin", "whisperling"],
	["ash_ghoul", "shadow_vermin"],
	["whisperling", "whisperling", "ash_ghoul"],
	["ash_ghoul", "ash_ghoul", "shadow_vermin"],
]

var db: Node
var team_levels := {}
var team_xp := {}


func _initialize() -> void:
	db = root.get_node_or_null("Db")
	if db == null:
		db = preload("res://scripts/systems/database.gd").new()
		db.name = "Db"
		root.add_child(db)
	db.reload()

	var stages := _build_campaign()
	print("campaign: %d stages across 7 valleys (v1 authored, v2-7 synthesized)" % stages.size())
	print("boss level targets: %s | xp valley bonus: %.2f\n" % [str(BOSS_TARGET_LEVELS), XP_VALLEY_BONUS])
	for profile in PROFILES:
		_run_career(profile, PROFILES[profile], stages)
	quit(0)


func _level_mult(l: int) -> float:
	return 1.0 + 0.04 * (l - 1)


func _expected_level(v: int, i: int) -> int:
	var prev: float = 1.0 if v == 1 else float(BOSS_TARGET_LEVELS[v - 2])
	return int(round(lerpf(prev, float(BOSS_TARGET_LEVELS[v - 1]), float(i) / 11.0)))


## Each stage: {valley, index, name, enemy_ids, scale, breath, xp, marks, fc_seals, fc_sigils}
func _build_campaign() -> Array:
	var out: Array = []
	for s: StageData in db.stage_order:  # authored valley 1
		out.append({
			"valley": s.valley, "index": s.index, "name": s.display_name,
			"enemy_ids": s.enemy_ids, "scale": s.enemy_scale, "breath": s.breath_cost,
			"xp": s.xp_reward, "marks": s.marks_reward,
			"fc_seals": s.first_clear_seals, "fc_sigils": s.first_clear_sigils,
		})
	for v in range(2, 8):
		for i in 12:
			var is_boss := i == 11
			var pressure := 1.0 if is_boss else 0.72 + 0.28 * float(i) / 11.0
			var enemy_ids: Array = [
				"whisperling", "kibr", "whisperling"] if is_boss else SYNTH_ENEMY_SETS[i % SYNTH_ENEMY_SETS.size()]
			out.append({
				"valley": v, "index": i + 1,
				"name": "Valley %d-%d%s" % [v, i + 1, " BOSS" if is_boss else ""],
				"enemy_ids": enemy_ids,
				"scale": _level_mult(_expected_level(v, i)) * pressure,
				"breath": 10 if is_boss else (6 if i < 6 else 8),
				"xp": int((26 + 6 * i) * (1.0 + XP_VALLEY_BONUS * (v - 1))),
				"marks": 50 if is_boss else (20 if i < 6 else 30),
				"fc_seals": 3 if is_boss else (2 if i == 10 else 1),
				"fc_sigils": 2 if is_boss else 0,
			})
	return out


func _run_battle(stage: Dictionary) -> bool:
	var mgr := BattleManager.new()
	mgr.auto_mode = true
	var out := {}
	mgr.battle_ended.connect(func(v: bool) -> void: out["v"] = v)
	var player_data: Array = []
	var mults: Array = []
	for id in TEAM:
		player_data.append(db.units[id])
		mults.append(_level_mult(team_levels[id]))
	var enemy_data: Array = []
	for eid in stage["enemy_ids"]:
		enemy_data.append(db.units[eid])
	mgr.setup(player_data, enemy_data, mults, stage["scale"])
	var steps := 0
	while not mgr.ended and steps < STEP_CAP:
		mgr.step()
		steps += 1
	mgr.free()
	return out.get("v", false)


func _grant_xp(amount: int) -> bool:
	var leveled := false
	for id in TEAM:
		team_xp[id] += amount
		while team_levels[id] < LEVEL_CAP and team_xp[id] >= 25 * team_levels[id]:
			team_xp[id] -= 25 * team_levels[id]
			team_levels[id] += 1
			leveled = true
	return leveled


func _run_career(profile: String, daily_breath: int, stages: Array) -> void:
	for id in TEAM:
		team_levels[id] = 1
		team_xp[id] = 0
	var cleared := {}
	var marks := 200
	var seals := 0
	var sigils := 0
	var total_runs := 0
	var fail_streak := 0
	var next_idx := 0
	var walls: Array = []
	var boss_days := {}

	print("=== profile: %s (%d Breath/day) ===" % [profile, daily_breath])
	var day := 1
	var days_on_current := 0
	while day <= MAX_DAYS and next_idx < stages.size():
		var budget := daily_breath
		days_on_current += 1
		while next_idx < stages.size():
			var target: Dictionary = stages[next_idx]
			var farm_mode := fail_streak >= 2
			var stage: Dictionary = target
			if farm_mode:
				# best cleared stage by xp/breath (later cleared stages win)
				stage = stages[maxi(0, next_idx - 1)] if next_idx > 0 else target
			if budget < stage["breath"]:
				break
			budget -= stage["breath"]
			total_runs += 1
			var won := _run_battle(stage)
			if won:
				marks += stage["marks"]
				var leveled := _grant_xp(stage["xp"])
				if not farm_mode:
					if not cleared.has(next_idx):
						seals += stage["fc_seals"]
						sigils += stage["fc_sigils"]
						cleared[next_idx] = true
					if target["index"] == 12:
						boss_days[target["valley"]] = [day, team_levels["bram"], days_on_current]
						if days_on_current > 3:
							walls.append("valley %d boss: %d days" % [target["valley"], days_on_current])
						days_on_current = 0
					next_idx += 1
					fail_streak = 0
				elif leveled:
					fail_streak = 0  # leveled up — retry the target tomorrow's loop
			else:
				if not farm_mode:
					fail_streak += 1
		day += 1

	print("  full clear: %s | total runs: %d" % [
		("day %d" % (day - 1)) if next_idx >= stages.size() else "NOT in %d days (stuck at %s)" % [MAX_DAYS, stages[next_idx]["name"]],
		total_runs])
	print("  tokens earned: %d Marks, %d Seals, %d Sigils -> affords %d Novices + %d Wayfarers + %d Luminaries (GDD 9.2 draft prices)" % [
		marks, seals, sigils, marks / 300, seals / 10, sigils / 6])
	for v in boss_days:
		print("  valley %d boss: day %-3d team L%-2d (%d days in valley)" % [
			v, boss_days[v][0], boss_days[v][1], boss_days[v][2]])
	if not walls.is_empty():
		print("  WALLS (>3 days on a valley): " + ", ".join(walls))
	print("")
