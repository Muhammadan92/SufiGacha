extends ScreenBase
## The Minaret — endless tower (GDD §7, §6.1). No Breath cost; each floor is
## harder than the last; every 5th floor pays Seals, every 10th a Sigil and a
## Vice guards the landing. This is the post-campaign home.

func music_key() -> String:
	return "valley_1"


func _build() -> void:
	var root := make_root()
	add_header(root, "The Minaret", "home")

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	center.add_child(v)

	if not game.minaret_unlocked():
		var locked := Label.new()
		locked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked.text = "The tower's door is sealed.\nClear stage 1-6 of the Journey to enter."
		v.add_child(locked)
		return

	var progress := Label.new()
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress.add_theme_font_size_override("font_size", 28)
	progress.text = "Highest floor: %d" % game.minaret_floor
	progress.add_theme_color_override("font_color", ACCENT)
	v.add_child(progress)

	var next_floor: int = game.minaret_floor + 1
	var stage: StageData = game.make_minaret_stage(next_floor)
	var info := Label.new()
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var foes: Array = []
	for eid in stage.enemy_ids:
		foes.append(db.units[eid].display_name)
	var reward_notes := "+%d Marks" % (30 + 5 * next_floor)
	if next_floor % 5 == 0:
		reward_notes += ", +2 Seals"
	if next_floor % 10 == 0:
		reward_notes += ", +1 SIGIL — a Vice guards this landing"
	info.text = "Floor %d:  %s\nReward: %s\nNo Breath cost — the climb is free; the tower is the test." % [
		next_floor, ", ".join(foes), reward_notes]
	v.add_child(info)

	var ascend := Button.new()
	ascend.text = "Ascend to Floor %d" % next_floor
	ascend.custom_minimum_size = Vector2(340, 52)
	ascend.pressed.connect(func() -> void:
		screens.goto("battle", {"minaret_floor": next_floor}))
	v.add_child(ascend)
