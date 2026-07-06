extends SceneTree
## Campaign difficulty-curve simulator: runs the starter company through all
## Valley 1 stages at the level a player is expected to have reached.
## Targets: early stages ~100%, ramping tension, boss stage ~60-70% (auto).
## Run:  godot --headless --path . -s res://tests/simulate_stages.gd

# Deterministic combat (GDD §4.4): one run per stage is exact.
const RUNS := 1
const TEAM := ["bram", "echo", "brand", "aria"]
## Expected level curve across all 7 valleys (boss targets per valley).
const BOSS_TARGETS := [8, 15, 22, 29, 36, 42, 48]


func _expected_level(v: int, i: int) -> int:
	var prev: float = 1.0 if v == 1 else float(BOSS_TARGETS[v - 2])
	return int(round(lerpf(prev, float(BOSS_TARGETS[v - 1]), float(i) / 11.0)))


func _initialize() -> void:
	# Reuse the autoload instance; _ready doesn't fire in script mode.
	var db: Node = root.get_node_or_null("Db")
	if db == null:
		db = preload("res://scripts/systems/database.gd").new()
		db.name = "Db"
		root.add_child(db)
	db.reload()

	print("%d runs per stage | starter company at expected level" % RUNS)
	for i in db.stage_order.size():
		var stage: StageData = db.stage_order[i]
		var level: int = _expected_level(stage.valley, stage.index - 1)
		var mult := 1.0 + 0.04 * (level - 1)
		var wins := 0
		var turn_sum := 0
		for r in RUNS:
			var res := BattleSim.run(db, TEAM, stage.enemy_ids, mult, stage.enemy_scale, 1.0, 2000)
			if res["win"]:
				wins += 1
			turn_sum += int(res["steps"])
		print("  %d-%02d %-24s Lv%-2d scale %.2f   win %5.1f%%  turns %5.1f" % [
			stage.valley, stage.index, stage.display_name, level, stage.enemy_scale,
			100.0 * wins / RUNS, float(turn_sum) / RUNS])
	quit(0)
