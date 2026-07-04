extends ScreenBase
## Battle screen v2: portrait cards, real HP/Fervor bars, and a presentation
## layer (lunges, hit flashes, floating numbers, Trance banners) driven purely
## by BattleManager's structured signals. Works identically with final art or
## the procedural placeholders — cards read from Db.unit_art with fallback.

var manager: BattleManager
var timer: Timer
var stage: StageData
var minaret_floor := 0  # >0 when this is a Minaret climb
var player_deaths := 0
var cards := {}  # BattleUnit -> Dictionary of card parts
var skill_buttons: Array = []
var pending_skill: SkillData = null
var targeting_units: Array = []

var player_column: VBoxContainer
var enemy_column: VBoxContainer
var log_label: RichTextLabel
var skill_bar: HBoxContainer
var prompt_label: Label
var overlay: Control
var banner: Label

const CARD_BG := Color(0.09, 0.11, 0.18, 0.92)


func music_key() -> String:
	return "boss" if stage != null and stage.index == 12 else "battle"


var is_sanctum := false


func _build() -> void:
	if screens.payload.has("minaret_floor"):
		minaret_floor = int(screens.payload["minaret_floor"])
		stage = game.make_minaret_stage(minaret_floor)
	elif screens.payload.has("sanctum"):
		is_sanctum = true
		stage = game.make_sanctum_stage()
	else:
		stage = db.stages[screens.payload["stage_id"]]

	var art: Texture2D = db.stage_background(stage)
	if art != null:
		var bg := TextureRect.new()
		bg.texture = art
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(bg)

	manager = BattleManager.new()
	add_child(manager)
	manager.log_message.connect(_on_log)
	manager.state_refreshed.connect(_refresh_cards)
	manager.awaiting_input.connect(_on_awaiting_input)
	manager.battle_ended.connect(_on_battle_ended)
	manager.action_started.connect(_on_action_started)
	manager.damage_dealt.connect(_on_damage_dealt)
	manager.unit_healed.connect(_on_unit_healed)
	manager.unit_evaded.connect(_on_unit_evaded)
	manager.unit_died.connect(_on_unit_died)

	timer = Timer.new()
	timer.wait_time = 0.7
	timer.timeout.connect(_on_tick)
	add_child(timer)

	_build_layout()
	_start_battle()


func _build_layout() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	player_column = _make_column(root, "YOUR COMPANY")

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_stretch_ratio = 1.3
	root.add_child(center)

	var stage_label := Label.new()
	stage_label.text = "%d-%d  %s" % [stage.valley, stage.index, stage.display_name]
	stage_label.add_theme_color_override("font_color", ACCENT)
	center.add_child(stage_label)

	log_label = RichTextLabel.new()
	log_label.scroll_following = true
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label.modulate = Color(1, 1, 1, 0.75)
	center.add_child(log_label)

	prompt_label = Label.new()
	center.add_child(prompt_label)

	skill_bar = HBoxContainer.new()
	skill_bar.custom_minimum_size = Vector2(0, 48)
	center.add_child(skill_bar)

	var controls := HBoxContainer.new()
	center.add_child(controls)
	var auto_check := CheckButton.new()
	auto_check.text = "Auto"
	auto_check.toggled.connect(_on_auto_toggled)
	controls.add_child(auto_check)
	var speed := CheckButton.new()
	speed.text = "2x Speed"
	speed.toggled.connect(func(on: bool) -> void: timer.wait_time = 0.35 if on else 0.7)
	controls.add_child(speed)

	enemy_column = _make_column(root, "THE DARKNESS")

	# Float-text layer sits above everything and never blocks input.
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	banner = Label.new()
	banner.add_theme_font_size_override("font_size", 40)
	banner.add_theme_color_override("font_color", ACCENT)
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	banner.position.y = 60
	banner.modulate.a = 0.0
	overlay.add_child(banner)


func _make_column(parent: Control, title: String) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)
	parent.add_child(col)
	var header := Label.new()
	header.text = title
	header.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	col.add_child(header)
	return col


func _start_battle() -> void:
	var player_data: Array = []
	var mults: Array = []
	var skill_mults: Array = []
	for id in game.team:
		player_data.append(db.units[id])
		mults.append(game.level_mult(game.level_of(id)))
		skill_mults.append(game.skill_mult_of(id))
	var enemy_data: Array = []
	for eid in stage.enemy_ids:
		enemy_data.append(db.units[eid])
	if OS.get_environment("SS_AUTO") != "":
		manager.auto_mode = true
	manager.setup(player_data, enemy_data, mults, stage.enemy_scale, skill_mults)
	for unit: BattleUnit in manager.players:
		cards[unit] = _make_card(player_column, unit)
	for unit: BattleUnit in manager.enemies:
		cards[unit] = _make_card(enemy_column, unit)
	_refresh_cards()
	if game.tutorial_at(2) and minaret_floor == 0 and not is_sanctum:
		show_tutorial([
			"Your company stands on the left; the darkness on the right. The card with the GOLD border acts now — speed decides the order, and the bars show each fighter's health and Fervor.",
			"Each companion carries three abilities:\n\nLITANY — always ready; builds Fervor.\nREMEMBRANCE — stronger, with a cooldown.\nTRANCE — their ultimate, unleashed when the Fervor bar fills.",
			"Watch the enemy's Fervor too: when a foe's bar burns red with warning, their Trance is coming — plan for it.\n\nThere are no dice here. Every number is exact; every outcome is earned. If you fall short, your plan was short. Begin.",
		], func() -> void:
			game.advance_tutorial(2)
			timer.start())
	else:
		timer.start()


# --- unit cards -----------------------------------------------------------------

func _make_card(col: VBoxContainer, unit: BattleUnit) -> Dictionary:
	var affinity_color: Color = Enums.AFFINITY_COLORS[unit.data.affinity]

	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_BG
	style.set_border_width_all(2)
	style.border_color = affinity_color
	style.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", style)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(_on_card_input.bind(unit))
	card.resized.connect(func() -> void: card.pivot_offset = card.size / 2.0)
	col.add_child(card)

	var inner := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		inner.add_theme_constant_override("margin_" + side, 8)
	card.add_child(inner)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	inner.add_child(row)

	# Portrait, or affinity-tinted block with the unit's initial.
	var portrait_holder := PanelContainer.new()
	portrait_holder.custom_minimum_size = Vector2(64, 64)
	var pstyle := StyleBoxFlat.new()
	var tex: Texture2D = db.unit_art(String(unit.data.id), "portrait")
	if tex != null:
		pstyle.bg_color = Color.TRANSPARENT
		portrait_holder.add_theme_stylebox_override("panel", pstyle)
		var trect := TextureRect.new()
		trect.texture = tex
		trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		trect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait_holder.add_child(trect)
	else:
		pstyle.bg_color = affinity_color.darkened(0.35)
		pstyle.set_corner_radius_all(4)
		portrait_holder.add_theme_stylebox_override("panel", pstyle)
		var initial := Label.new()
		initial.text = unit.data.display_name.left(1)
		initial.add_theme_font_size_override("font_size", 30)
		initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		portrait_holder.add_child(initial)
	row.add_child(portrait_holder)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 3)
	row.add_child(v)

	var name_lbl := Label.new()
	name_lbl.text = unit.data.label()
	v.add_child(name_lbl)

	var hp_bar := _make_bar(v, Color(0.35, 0.78, 0.42), unit.max_hp)
	var fv_bar := _make_bar(v, Color(0.42, 0.56, 0.9), BattleUnit.FERVOR_MAX)

	var status_lbl := Label.new()
	status_lbl.add_theme_font_size_override("font_size", 11)
	status_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	v.add_child(status_lbl)

	return {
		"card": card, "style": style, "affinity_color": affinity_color,
		"hp_bar": hp_bar, "fv_bar": fv_bar,
		"name_lbl": name_lbl, "status_lbl": status_lbl,
	}


func _make_bar(parent: Control, color: Color, max_value: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(150, 12)
	bar.max_value = max_value
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	parent.add_child(bar)
	return bar


func _refresh_cards() -> void:
	for unit: BattleUnit in cards:
		var c: Dictionary = cards[unit]
		c["hp_bar"].value = unit.hp
		c["fv_bar"].value = unit.fervor
		var fill: StyleBoxFlat = c["fv_bar"].get_theme_stylebox("fill")
		fill.bg_color = ACCENT if unit.fervor >= BattleUnit.FERVOR_MAX else Color(0.42, 0.56, 0.9)
		var warn := not unit.is_player_side and unit.fervor >= 80.0 and unit.is_alive()
		c["status_lbl"].text = ("TRANCE IMMINENT!  " if warn else "") + unit.status_line()
		if unit in targeting_units:
			c["style"].border_color = Color.CYAN
			c["style"].set_border_width_all(3)
		elif unit == manager.current_actor and not manager.ended:
			# Accent gold, not white — Mevlevi's affinity color is pearl white.
			c["style"].border_color = ACCENT
			c["style"].set_border_width_all(4)
		elif warn:
			c["style"].border_color = Color(1.0, 0.35, 0.3)
			c["style"].set_border_width_all(3)
		else:
			c["style"].border_color = c["affinity_color"]
			c["style"].set_border_width_all(2)


# --- presentation (signal-driven) -------------------------------------------------

func _float_text(unit: BattleUnit, text: String, color: Color, big: bool = false) -> void:
	if not cards.has(unit):
		return
	var card: PanelContainer = cards[unit]["card"]
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 30 if big else 20)
	lbl.add_theme_color_override("font_color", color)
	overlay.add_child(lbl)
	lbl.global_position = card.global_position + Vector2(
		card.size.x * randf_range(0.35, 0.6), card.size.y * 0.25)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "global_position:y", lbl.global_position.y - 44.0, 0.8)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.8).set_delay(0.25)
	tw.chain().tween_callback(lbl.queue_free)


func _pulse(unit: BattleUnit, color: Color, scale_to: float = 1.0) -> void:
	if not cards.has(unit):
		return
	var card: PanelContainer = cards[unit]["card"]
	var tw := create_tween()
	card.modulate = color
	tw.tween_property(card, "modulate", Color.WHITE, 0.35)
	if scale_to != 1.0:
		var tw2 := create_tween()
		tw2.tween_property(card, "scale", Vector2.ONE * scale_to, 0.1)
		tw2.tween_property(card, "scale", Vector2.ONE, 0.15)


func _on_action_started(actor: BattleUnit, skill: SkillData, _primary: BattleUnit) -> void:
	_pulse(actor, Color(1.3, 1.3, 1.3), 1.07)
	if skill.slot == Enums.Slot.TRANCE:
		sfx("trance")
		banner.text = "%s — %s" % [actor.data.display_name, skill.full_name()]
		banner.add_theme_color_override("font_color",
			Enums.AFFINITY_COLORS[actor.data.affinity].lightened(0.3))
		var tw := create_tween()
		banner.modulate.a = 0.0
		banner.scale = Vector2.ONE * 0.8
		tw.set_parallel(true)
		tw.tween_property(banner, "modulate:a", 1.0, 0.15)
		tw.tween_property(banner, "scale", Vector2.ONE, 0.2)
		tw.chain().tween_interval(0.9)
		tw.chain().tween_property(banner, "modulate:a", 0.0, 0.3)


func _on_damage_dealt(target: BattleUnit, amount: int, crit: bool) -> void:
	sfx("hit_crit" if crit else "hit")
	_pulse(target, Color(1.6, 0.5, 0.5), 0.94)
	_float_text(target, ("-%d!" if crit else "-%d") % amount,
		Color(1.0, 0.85, 0.3) if crit else Color(1, 1, 1), crit)


func _on_unit_healed(target: BattleUnit, amount: int) -> void:
	sfx("heal")
	_pulse(target, Color(0.6, 1.5, 0.6))
	_float_text(target, "+%d" % amount, Color(0.55, 0.95, 0.55))


func _on_unit_evaded(target: BattleUnit, label: String) -> void:
	sfx("evade")
	_float_text(target, label, Color(0.7, 0.9, 1.0))


func _on_unit_died(unit: BattleUnit) -> void:
	sfx("fall")
	if unit.is_player_side:
		player_deaths += 1
	if not cards.has(unit):
		return
	var card: PanelContainer = cards[unit]["card"]
	var tw := create_tween()
	tw.tween_property(card, "modulate", Color(0.45, 0.4, 0.45, 0.4), 0.5)


# --- flow / input ------------------------------------------------------------------

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
	targeting_units = candidates
	prompt_label.text = "Choose a target for %s:" % skill.full_name()
	_refresh_cards()


func _on_card_input(event: InputEvent, unit: BattleUnit) -> void:
	if pending_skill == null or unit not in targeting_units:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_submit(pending_skill, unit)


func _submit(skill: SkillData, target: BattleUnit) -> void:
	pending_skill = null
	targeting_units = []
	prompt_label.text = ""
	_clear_skill_buttons()
	manager.submit_player_action(skill, target)


func _clear_skill_buttons() -> void:
	for b in skill_buttons:
		b.queue_free()
	skill_buttons.clear()


func _on_auto_toggled(on: bool) -> void:
	manager.auto_mode = on
	if on and manager.awaiting_player:
		pending_skill = null
		targeting_units = []
		prompt_label.text = ""
		_clear_skill_buttons()
		manager.force_auto_current()


func _on_log(text: String) -> void:
	log_label.append_text(text + "\n")


func _on_battle_ended(victory: bool) -> void:
	timer.stop()
	sfx("victory" if victory else "defeat")
	var summary: Dictionary
	if minaret_floor > 0:
		summary = game.finish_minaret(minaret_floor, victory)
	elif is_sanctum:
		summary = game.finish_sanctum(victory)
	else:
		summary = game.finish_stage(stage, victory,
			{"deaths": player_deaths, "turns": manager.turns_taken})
	prompt_label.text = "VICTORY — the darkness recedes" if victory else "DEFEAT — try a different approach"
	var cont := Button.new()
	cont.text = "Continue"
	cont.pressed.connect(func() -> void: screens.goto("results", summary))
	skill_bar.add_child(cont)
	skill_buttons.append(cont)
