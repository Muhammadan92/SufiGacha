extends SceneTree
## Generates procedural placeholder art for every unit and valley so the game
## is fully visual before any real art exists: radial-gradient portraits in
## each unit's affinity color (rarity = number of rings), plus valley
## backgrounds. Real art overwrites these files via tools/import_art.sh.
## Run:  godot --headless --path . -s res://tools/gen_placeholders.gd
## Then: godot --headless --path . --import   (to import the new PNGs)

func _initialize() -> void:
	var db: Node = root.get_node_or_null("Db")
	if db == null:
		db = preload("res://scripts/systems/database.gd").new()
		db.name = "Db"
		root.add_child(db)
	db.reload()

	for id in db.units:
		var u: UnitData = db.units[id]
		var color: Color = Enums.AFFINITY_COLORS[u.affinity]
		var dir := "res://assets/art/units/%s" % id
		DirAccess.make_dir_recursive_absolute(dir)
		var portrait := _portrait(512, color, u.rarity, u.is_enemy)
		portrait.save_png(dir + "/portrait.png")
		var icon := portrait.duplicate()
		icon.resize(256, 256, Image.INTERPOLATE_LANCZOS)
		icon.save_png(dir + "/icon.png")
		print("placeholder: ", id)

	var valleys := {}
	for s: StageData in db.stage_order:
		valleys[s.valley] = true
	for v in valleys:
		var dir := "res://assets/art/stages/valley_%d" % v
		DirAccess.make_dir_recursive_absolute(dir)
		_background(1280, 720, v).save_png(dir + "/background.png")
		print("placeholder: valley_%d background" % v)
	print("DONE — run: godot --headless --path . --import")
	quit(0)


func _portrait(size: int, color: Color, rarity: int, is_enemy: bool) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	var max_d := size / 2.0 * 1.42
	var dark := color.darkened(0.72)
	var light := color.darkened(0.1) if is_enemy else color.lightened(0.15)
	# Playable units ring in their RARITY color (strongest = green, Enums
	# .RARITY_COLORS); enemies ring in their own affinity.
	var ring_color: Color = Enums.RARITY_COLORS.get(rarity, Color.WHITE) if not is_enemy else color.lightened(0.3)
	var rings: Array = []
	for i in maxi(1, rarity - 2):
		rings.append(0.5 + 0.13 * i)
	for y in size:
		for x in size:
			var d := clampf(Vector2(x, y).distance_to(center) / max_d, 0.0, 1.0)
			var c := dark.lerp(light, 1.0 - d * d)
			for r in rings:
				if absf(d - r) < 0.012:
					c = c.lerp(ring_color, 0.65)
			img.set_pixel(x, y, c)
	return img


func _background(w: int, h: int, valley: int) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	# Valley 1: dusk over the Valley of the Quest — deep blue to warm horizon.
	var top := Color(0.04, 0.06, 0.14)
	var horizon := Color(0.35, 0.22, 0.18).lerp(Color(0.87, 0.75, 0.42), 0.25)
	var disc := Vector2(w * 0.72, h * 0.34)
	for y in h:
		var t := float(y) / h
		var row := top.lerp(horizon, pow(t, 2.2))
		for x in w:
			var c := row
			var dd := Vector2(x, y).distance_to(disc)
			if dd < 46.0:
				c = c.lerp(Color(0.95, 0.9, 0.75), 0.85)
			elif dd < 90.0:
				c = c.lerp(Color(0.95, 0.9, 0.75), 0.25 * (1.0 - (dd - 46.0) / 44.0))
			img.set_pixel(x, y, c)
	return img
