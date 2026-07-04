extends SceneTree
## Deterministic-combat balance metric (GDD §4.4): the minimum starter-team
## level at which auto-battle clears each stage. The "wall" is the gap
## between a stage's min-clear level and the level a player naturally has.
## Run:  godot --headless --path . -s res://tests/min_clear_levels.gd

const TEAM := ["bram", "echo", "brand", "aria"]


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

	print("stage                          win pattern by level 1..14 (W/l, auto, starters)")
	print("NOTE: deterministic combat is NOT monotonic in level — turn-sequence")
	print("breakpoints can flip. Balance target: contiguous W from the expected level up.")
	for stage: StageData in db.stage_order:
		var enemy_data: Array = []
		for eid in stage.enemy_ids:
			enemy_data.append(db.units[eid])
		var pattern := ""
		for level in range(1, 15):
			var mult := 1.0 + 0.04 * (level - 1)
			var mgr := BattleManager.new()
			mgr.auto_mode = true
			var out := {}
			mgr.battle_ended.connect(func(v: bool) -> void: out["v"] = v)
			mgr.setup(team_data, enemy_data, [mult, mult, mult, mult], stage.enemy_scale)
			var steps := 0
			while not mgr.ended and steps < 1200:
				mgr.step()
				steps += 1
			mgr.free()
			pattern += "W" if out.get("v", false) else "."
		print("  %d-%02d %-24s %s" % [stage.valley, stage.index, stage.display_name, pattern])
	quit(0)
