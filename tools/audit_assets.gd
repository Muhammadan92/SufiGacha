extends SceneTree
## Reports which art assets exist vs. are still placeholders/missing, per unit
## and per valley. The report distinguishes real art from generated
## placeholders by checking art_workbench/real_art.json (updated by
## tools/import_art.sh whenever real art is imported).
## Run:  godot --headless --path . -s res://tools/audit_assets.gd

const KINDS := ["portrait", "chibi", "icon"]


func _initialize() -> void:
	var db: Node = root.get_node_or_null("Db")
	if db == null:
		db = preload("res://scripts/systems/database.gd").new()
		db.name = "Db"
		root.add_child(db)
	db.reload()

	var real := {}
	if FileAccess.file_exists("res://art_workbench/real_art.json"):
		var parsed = JSON.parse_string(FileAccess.open("res://art_workbench/real_art.json", FileAccess.READ).get_as_text())
		if parsed is Dictionary:
			real = parsed

	print("%-16s %-10s %-10s %-10s" % ["unit", "portrait", "chibi", "icon"])
	var total := 0
	var have_real := 0
	var ids: Array = db.units.keys()
	ids.sort()
	for id in ids:
		var u: UnitData = db.units[id]
		var row := "%-16s" % id
		for kind in KINDS:
			if kind == "chibi" and u.is_enemy:
				row += " %-10s" % "-"
				continue
			total += 1
			var path := "res://assets/art/units/%s/%s.png" % [id, kind]
			var key := "%s/%s" % [id, kind]
			var cell := "MISSING"
			if real.has(key):
				cell = "REAL"
				have_real += 1
			elif FileAccess.file_exists(path):
				cell = "placeholder"
			row += " %-10s" % cell
		print(row)

	var valleys := {}
	for s: StageData in db.stage_order:
		valleys[s.valley] = true
	for v in valleys:
		total += 1
		var key := "valley_%d/background" % v
		var cell := "MISSING"
		if real.has(key):
			cell = "REAL"
			have_real += 1
		elif FileAccess.file_exists("res://assets/art/stages/valley_%d/background.png" % v):
			cell = "placeholder"
		print("%-16s %-10s" % ["valley_%d" % v, cell])

	print("\nreal art: %d / %d assets (%.0f%%) — everything else runs on placeholders" % [
		have_real, total, 100.0 * have_real / total])
	quit(0)
