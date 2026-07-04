extends ScreenBase
## Stage select: Valley 1's stages in order, locked until the previous clears.

var notice: Label
var list: VBoxContainer
var current_diff := "normal"


func music_key() -> String:
	return "valley_1"


func _build() -> void:
	var root := make_root()
	add_header(root, "Valley of the Quest", "home")

	var team_row := HBoxContainer.new()
	team_row.add_theme_constant_override("separation", 12)
	root.add_child(team_row)
	var team_label := Label.new()
	var names: Array = []
	for id in game.team:
		names.append("%s Lv%d" % [db.units[id].display_name, game.level_of(id)])
	team_label.text = "Company: " + ", ".join(names)
	team_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	team_row.add_child(team_label)
	var edit := Button.new()
	edit.text = "Edit Company"
	edit.pressed.connect(func() -> void: screens.goto("team"))
	team_row.add_child(edit)

	notice = Label.new()
	root.add_child(notice)

	# Difficulty re-clears (GDD §6.1): Hard unlocks when the valley is
	# complete; Nightmare when Hard is complete.
	var diff_row := HBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 8)
	root.add_child(diff_row)
	for diff in game.DIFFICULTIES:
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = diff == current_diff
		b.text = game.DIFF_NAMES[diff]
		if not game.diff_unlocked(diff):
			b.disabled = true
			b.text += "  [complete %s first]" % ("the valley" if diff == "hard" else "Hard")
		b.pressed.connect(_on_diff_pressed.bind(diff))
		diff_row.add_child(b)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	_rebuild_list()

	if game.tutorial_at(1):
		show_tutorial([
			"Each stage costs Breath, and Breath returns with time — one every six minutes, even while you're away.\n\nVictory earns Silver Marks and XP; a stage's FIRST clear grants Violet Seals, and valley bosses guard Emerald Sigils.",
			"Every stage holds three stars: clear it, let no companion fall, and finish within the turn target. There are no dice in this world — a star you cannot reach today is a puzzle, not bad luck.\n\nBegin with 1-1: First Steps.",
		], func() -> void: game.advance_tutorial(1))
	elif game.tutorial_at(4):
		show_tutorial([
			"The Path widens as you walk it. The SANCTUM opens after stage 1-4 — a different order keeps it each day, and Teaching Scrolls earned there refine your companions' technique.",
			"The MINARET opens after 1-6: an endless climb, free of Breath, with treasures on every fifth floor.\n\nAnd each day brings DEEDS — find them under the season's name on the home screen. Fulfilling them raises your season tier, and the season's story waits in the Traveler's Notebook.\n\nWalk well, Seeker.",
		], func() -> void: game.advance_tutorial(4))


func _on_diff_pressed(diff: String) -> void:
	current_diff = diff
	_rebuild_list()


func _rebuild_list() -> void:
	for child in list.get_children():
		child.queue_free()
	for stage: StageData in db.stage_order:
		list.add_child(_stage_button(stage))


func _stage_button(stage: StageData) -> Button:
	var b := Button.new()
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, 44)
	var key: String = game.stage_key(String(stage.id), current_diff)
	var status := ""
	if current_diff == "normal":
		if game.cleared.has(key):
			var s: int = int(game.stars.get(String(stage.id), 1))
			status = "  " + "★".repeat(s) + "☆".repeat(3 - s)
	elif game.cleared.has(key):
		status = "  [cleared]"
	var mult_note := "" if current_diff == "normal" else "  x%.1f rewards" % game.DIFF_MARKS[current_diff]
	b.text = "%d-%d  %s   (%d foes, Breath %d, within %d turns)%s%s" % [
		stage.valley, stage.index, stage.display_name,
		stage.enemy_ids.size(), stage.breath_cost, stage.turn_target, mult_note, status]
	if not game.is_unlocked(stage, current_diff):
		b.disabled = true
		b.text += "  [locked]"
	b.pressed.connect(_on_stage_pressed.bind(stage))
	return b


func _on_stage_pressed(stage: StageData) -> void:
	if not game.spend_breath(stage.breath_cost):
		notice.text = "Not enough Breath — it returns with time (1 per 6 minutes)."
		return
	screens.goto("battle", {"stage_id": String(stage.id), "diff": current_diff})
