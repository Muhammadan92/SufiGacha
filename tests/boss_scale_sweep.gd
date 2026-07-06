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
	var enemy_ids: Array = ["whisperling", "kibr", "whisperling"]
	for scale in SCALES:
		var pattern := ""
		for level in range(1, 15):
			var mult := 1.0 + 0.04 * (level - 1)
			var r := BattleSim.run(db, TEAM, enemy_ids, mult, scale, 1.0, 1200)
			pattern += "W" if r["win"] else "."
		print("scale %.2f   %s" % [scale, pattern])
	quit(0)
