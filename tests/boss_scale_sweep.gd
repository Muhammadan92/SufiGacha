extends SceneTree
## Temporary tuning aid: boss stage win pattern (levels 1..14) across scales.

const TEAM := ["bram", "echo", "brand", "aria"]
const SCALES := [1.26, 1.28, 1.30, 1.31, 1.32, 1.33]


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
	var enemy_data: Array = [db.units["whisperling"], db.units["kibr"], db.units["whisperling"]]
	for scale in SCALES:
		var pattern := ""
		for level in range(1, 15):
			var mult := 1.0 + 0.04 * (level - 1)
			var mgr := BattleManager.new()
			mgr.auto_mode = true
			var out := {}
			mgr.battle_ended.connect(func(v: bool) -> void: out["v"] = v)
			mgr.setup(team_data, enemy_data, [mult, mult, mult, mult], scale)
			var steps := 0
			while not mgr.ended and steps < 1200:
				mgr.step()
				steps += 1
			mgr.free()
			pattern += "W" if out.get("v", false) else "."
		print("scale %.2f   %s" % [scale, pattern])
	quit(0)
