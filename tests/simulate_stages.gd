extends SceneTree
## Campaign difficulty-curve simulator: runs the starter company through all
## Valley 1 stages at the level a player is expected to have reached.
## Targets: early stages ~100%, ramping tension, boss stage ~60-70% (auto).
## Run:  godot --headless --path . -s res://tests/simulate_stages.gd

# Deterministic combat (GDD §4.4): one run per stage is exact.
const RUNS := 1
const TEAM := ["bram", "echo", "brand", "aria"]
## Expected character level when first attempting stage 1..12 (one pass
## through the valley, no grinding).
const EXPECTED_LEVELS := [1, 1, 2, 2, 3, 3, 4, 5, 5, 6, 7, 8]


func _initialize() -> void:
	# Reuse the autoload instance; _ready doesn't fire in script mode.
	var db: Node = root.get_node_or_null("Db")
	if db == null:
		db = preload("res://scripts/systems/database.gd").new()
		db.name = "Db"
		root.add_child(db)
	db.reload()

	var team_data: Array = []
	for id in TEAM:
		team_data.append(db.units[id])

	print("%d runs per stage | starter company at expected level" % RUNS)
	for i in db.stage_order.size():
		var stage: StageData = db.stage_order[i]
		var level: int = EXPECTED_LEVELS[i] if i < EXPECTED_LEVELS.size() else 10
		var mult := 1.0 + 0.04 * (level - 1)
		var mults := [mult, mult, mult, mult]
		var enemy_data: Array = []
		for eid in stage.enemy_ids:
			enemy_data.append(db.units[eid])
		var wins := 0
		var turn_sum := 0
		for r in RUNS:
			var mgr := BattleManager.new()
			mgr.auto_mode = true
			var out := {}
			mgr.battle_ended.connect(func(v: bool) -> void: out["v"] = v)
			mgr.setup(team_data, enemy_data, mults, stage.enemy_scale)
			var steps := 0
			while not mgr.ended and steps < 2000:
				mgr.step()
				steps += 1
			if out.get("v", false):
				wins += 1
			turn_sum += steps
			mgr.free()
		print("  %d-%02d %-24s Lv%-2d scale %.2f   win %5.1f%%  turns %5.1f" % [
			stage.valley, stage.index, stage.display_name, level, stage.enemy_scale,
			100.0 * wins / RUNS, float(turn_sum) / RUNS])
	quit(0)
