extends Node
## Autoload "Db": loads all content resources at startup and provides
## id -> resource lookup. Content is added by dropping .tres files into
## data/ — nothing here needs editing for new units or stages.

var units := {}   # id (String) -> UnitData
var stages := {}  # id (String) -> StageData
var stage_order: Array = []  # StageData sorted by (valley, index)


func _ready() -> void:
	reload()


func reload() -> void:
	units.clear()
	stages.clear()
	stage_order.clear()
	for path in _resource_paths("res://data/units"):
		var u: UnitData = load(path)
		units[String(u.id)] = u
	for path in _resource_paths("res://data/stages"):
		var s: StageData = load(path)
		stages[String(s.id)] = s
		stage_order.append(s)
	stage_order.sort_custom(func(a: StageData, b: StageData) -> bool:
		return a.index < b.index if a.valley == b.valley else a.valley < b.valley)


# --- art resolution -----------------------------------------------------------
# Art is convention-addressed: assets/art/units/<id>/{portrait,chibi,icon}.png
# and assets/art/stages/valley_<n>/background.png. Anything missing returns
# null and the UI falls back to procedural placeholders — the game always
# runs, whatever state the art is in. See AI_ART_PIPELINE.md §10.

func unit_art(id: String, kind: String) -> Texture2D:
	return _load_art("res://assets/art/units/%s/%s.png" % [id, kind])


func stage_background(stage: StageData) -> Texture2D:
	# Per-stage override wins over the valley default.
	var specific := _load_art("res://assets/art/stages/%s/background.png" % String(stage.id))
	if specific != null:
		return specific
	return _load_art("res://assets/art/stages/valley_%d/background.png" % stage.valley)


func _load_art(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null


func playable_pool(rarity: int) -> Array:
	var pool: Array = []
	for u: UnitData in units.values():
		if not u.is_enemy and u.rarity == rarity:
			pool.append(u)
	return pool


func _resource_paths(dir_path: String) -> Array:
	var out: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("Db: cannot open " + dir_path)
		return out
	for f in dir.get_files():
		# In exported builds resources may appear as .tres.remap.
		var name := f.trim_suffix(".remap")
		if name.ends_with(".tres"):
			out.append(dir_path + "/" + name)
	out.sort()
	return out
