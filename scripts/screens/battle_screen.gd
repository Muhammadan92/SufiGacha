extends ScreenBase
## Battle screen: grey-box UI over BattleManager. Reads the stage from
## Screens.payload {"stage_id": ...}; team and levels come from Game.

var manager: BattleManager
var timer: Timer
var stage: StageData
var unit_panels := {}  # BattleUnit -> Button
var skill_buttons: Array = []
var pending_skill: SkillData = null
var finished_summary: Dictionary = {}

var player_column: VBoxContainer
var enemy_column: VBoxContainer
var log_label: RichTextLabel
var skill_bar: HBoxContainer
var prompt_label: Label
var auto_check: CheckButton


func _build() -> void:
	stage = db.stages[screens.payload["stage_id"]]

	manager = BattleManager.new()
	add_child(manager)
	manager.log_message.connect(_on_log)
	manager.state_refreshed.connect(_refresh_panels)
	manager.awaiting_input.connect(_on_awaiting_input)
	manager.battle_ended.connect(_on_battle_ended)

	timer = Timer.new()
	timer.wait_time = 0.7
	timer.timeout.connect(_on_tick)
	add_child(timer)

	_build_layout()
	_start_battle()


func _build_layout() -> void:
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	player_column = _make_column(root, "YOUR COMPANY")

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_stretch_ratio = 1.6
	root.add_child(center)

	var stage_label := Label.new()
	stage_label.text = "%d-%d  %s" % [stage.valley, stage.index, stage.display_name]
	center.add_child(stage_label)

	log_label = RichTextLabel.new()
	log_label.scroll_following = true
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(log_label)

	prompt_label = Label.new()
	center.add_child(prompt_label)

	skill_bar = HBoxContainer.new()
	skill_bar.custom_minimum_size = Vector2(0, 48)
	center.add_child(skill_bar)

	var controls := HBoxContainer.new()
	center.add_child(controls)
	auto_check = CheckButton.new()
	auto_check.text = "Auto"
	auto_check.toggled.connect(_on_auto_toggled)
	controls.add_child(auto_check)
	var speed := CheckButton.new()
	speed.text = "2x Speed"
	speed.toggled.connect(func(on: bool) -> void: timer.wait_time = 0.35 if on else 0.7)
	controls.add_child(speed)

	enemy_column = _make_column(root, "THE DARKNESS")


func _make_column(parent: Control, title: String) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	parent.add_child(col)
	var header := Label.new()
	header.text = title
	col.add_child(header)
	return col


func _start_battle() -> void:
	var player_data: Array = []
	var mults: Array = []
	for id in game.team:
		player_data.append(db.units[id])
		mults.append(game.level_mult(game.level_of(id)))
	var enemy_data: Array = []
	for eid in stage.enemy_ids:
		enemy_data.append(db.units[eid])
	manager.setup(player_data, enemy_data, mults, stage.enemy_scale)
	_build_unit_panels()
	timer.start()


func _build_unit_panels() -> void:
	unit_panels.clear()
	for unit: BattleUnit in manager.players:
		unit_panels[unit] = _make_panel(player_column, unit)
	for unit: BattleUnit in manager.enemies:
		unit_panels[unit] = _make_panel(enemy_column, unit)
	_refresh_panels()


func _make_panel(col: VBoxContainer, unit: BattleUnit) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 92)
	b.disabled = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(_on_panel_pressed.bind(unit))
	col.add_child(b)
	return b


func _bar(value: float, maximum: float, width: int = 12) -> String:
	var filled := 0
	if maximum > 0.0:
		filled = clampi(int(round(width * value / maximum)), 0, width)
	return "█".repeat(filled) + "░".repeat(width - filled)


func _refresh_panels() -> void:
	for unit: BattleUnit in unit_panels:
		var b: Button = unit_panels[unit]
		var marker := "► " if unit == manager.current_actor and not manager.ended else ""
		var affinity: String = Enums.AFFINITY_NAMES[unit.data.affinity]
		if not unit.is_alive():
			b.text = "%s%s\n— fallen —" % [marker, unit.data.label()]
			b.modulate = Color(1, 1, 1, 0.35)
			continue
		b.modulate = Color.WHITE
		b.text = "%s%s  [%s]\nHP %s %d/%d\nFV %s %d\n%s" % [
			marker, unit.data.label(), affinity,
			_bar(unit.hp, unit.max_hp), unit.hp, unit.max_hp,
			_bar(unit.fervor, BattleUnit.FERVOR_MAX), int(unit.fervor),
			unit.status_line(),
		]


func _on_tick() -> void:
	if manager.ended or manager.awaiting_player:
		return
	manager.step()


func _on_awaiting_input(actor: BattleUnit) -> void:
	prompt_label.text = "%s's turn — choose an ability:" % actor.data.label()
	_clear_skill_buttons()
	for skill: SkillData in actor.data.skills:
		var b := Button.new()
		var suffix := ""
		if skill.slot == Enums.Slot.TRANCE:
			suffix = "  (Fervor %d/100)" % int(actor.fervor)
		elif actor.cooldowns.get(skill.id, 0) > 0:
			suffix = "  (cooldown %d)" % actor.cooldowns[skill.id]
		b.text = "[%s] %s%s" % [Enums.SLOT_NAMES[skill.slot], skill.full_name(), suffix]
		b.disabled = not actor.skill_ready(skill)
		b.pressed.connect(_on_skill_pressed.bind(skill))
		skill_bar.add_child(b)
		skill_buttons.append(b)


func _on_skill_pressed(skill: SkillData) -> void:
	var candidates := manager.valid_targets(manager.current_actor, skill)
	if candidates.is_empty():
		_submit(skill, null)
		return
	pending_skill = skill
	prompt_label.text = "Choose a target for %s:" % skill.full_name()
	for unit: BattleUnit in candidates:
		unit_panels[unit].disabled = false


func _on_panel_pressed(unit: BattleUnit) -> void:
	if pending_skill != null:
		_submit(pending_skill, unit)


func _submit(skill: SkillData, target: BattleUnit) -> void:
	pending_skill = null
	prompt_label.text = ""
	_clear_skill_buttons()
	for u in unit_panels:
		unit_panels[u].disabled = true
	manager.submit_player_action(skill, target)


func _clear_skill_buttons() -> void:
	for b in skill_buttons:
		b.queue_free()
	skill_buttons.clear()


func _on_auto_toggled(on: bool) -> void:
	manager.auto_mode = on
	if on and manager.awaiting_player:
		pending_skill = null
		prompt_label.text = ""
		_clear_skill_buttons()
		for u in unit_panels:
			unit_panels[u].disabled = true
		manager.force_auto_current()


func _on_log(text: String) -> void:
	log_label.append_text(text + "\n")


func _on_battle_ended(victory: bool) -> void:
	timer.stop()
	finished_summary = game.finish_stage(stage, victory)
	prompt_label.text = "VICTORY — the darkness recedes" if victory else "DEFEAT — try a different approach"
	var cont := Button.new()
	cont.text = "Continue"
	cont.pressed.connect(func() -> void: screens.goto("results", finished_summary))
	skill_bar.add_child(cont)
	skill_buttons.append(cont)
