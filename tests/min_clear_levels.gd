extends SceneTree
## Deterministic-combat balance tool (GDD §4.4): win pattern by level around
## each key stage's EXPECTED level (window ±4). Covers stages 1, 6, and 12 of
## every valley — the full sweep at 84 stages would take an hour; these are
## the load-bearing points. Balance target: trash W across the window; bosses
## block at expected level and clear contiguously 1-2 above.
## Run:  godot --headless --path . -s res://tests/min_clear_levels.gd

const TEAM := ["bram", "echo", "brand", "aria"]
const BOSS_TARGETS := [8, 15, 22, 29, 36, 42, 48]
const WINDOW := 4


func _initialize() -> void:
	var db: Node = root.get_node_or_null("Db")
	if db == null:
		db = preload("res://scripts/systems/database.gd").new()
		db.name = "Db"
		root.add_child(db)
	db.reload()

	var team_data: Array = []
	for id in TEAM:
		team_data.append(db.units[id])

	print("win pattern around expected level (E-4 .. E+4) | . = loss, W = win, E marks expected")
	print("NOTE: deterministic combat is NOT monotonic — check the whole window.")
	for stage: StageData in db.stage_order:
		if stage.index not in [1, 6, 12]:
			continue
		var expected := _expected_level(stage.valley, stage.index - 1)
		var pattern := ""
		for offset in range(-WINDOW, WINDOW + 1):
			var level := clampi(expected + offset, 1, 60)
			var mult := 1.0 + 0.04 * (level - 1)
			var enemy_data: Array = []
			for eid in stage.enemy_ids:
				enemy_data.append(db.units[eid])
			var mgr := BattleManager.new()
			mgr.auto_mode = true
			var out := {}
			mgr.battle_ended.connect(func(v: bool) -> void: out["v"] = v)
			mgr.setup(team_data, enemy_data, [mult, mult, mult, mult], stage.enemy_scale)
			var steps := 0
			while not mgr.ended and steps < 1500:
				mgr.step()
				steps += 1
			mgr.free()
			pattern += "W" if out.get("v", false) else "."
		print("  %d-%02d %-28s E=Lv%-3d  [%s]" % [
			stage.valley, stage.index, stage.display_name, expected, pattern])
	quit(0)


func _expected_level(v: int, i: int) -> int:
	var prev: float = 1.0 if v == 1 else float(BOSS_TARGETS[v - 2])
	return int(round(lerpf(prev, float(BOSS_TARGETS[v - 1]), float(i) / 11.0)))
