extends ScreenBase
## The Calling: summoning with published rates, a visible pity counter
## (GDD §9.1, §9.3), and a sequential reveal — each answered call steps out
## of a doorway of light colored by rarity. Tap to advance, Skip to resolve.

var results_label: RichTextLabel
var pity_label: Label
var reveal_overlay: Control
var door: PanelContainer
var door_style: StyleBoxFlat
var door_portrait: TextureRect
var door_name: Label
var door_rarity: Label
var door_note: Label
var flash: ColorRect

var queue: Array = []
var revealed: Array = []
var busy := false

const RARITY_BB := { 3: "gray", 4: "violet", 5: "green" }
const RARITY_SFX := { 3: "reveal_novice", 4: "reveal_wayfarer", 5: "reveal_luminary" }


func _build() -> void:
	var root := make_root()
	add_header(root, "The Calling", "home")

	var rates := Label.new()
	rates.text = "Rates: Luminary 3%% — Wayfarer 20%% — Novice 77%%.  Guaranteed Luminary within %d calls." % game.PITY_LIMIT
	rates.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	root.add_child(rates)
	pity_label = Label.new()
	root.add_child(pity_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	root.add_child(buttons)
	var one := Button.new()
	one.text = "Call x1  (%d Pearls)" % game.PULL_COST
	one.custom_minimum_size = Vector2(0, 48)
	one.pressed.connect(_pull.bind(1))
	buttons.add_child(one)
	var ten := Button.new()
	ten.text = "Call x10  (%d Pearls — one Wayfarer+ guaranteed)" % (game.PULL_COST * 10)
	ten.custom_minimum_size = Vector2(0, 48)
	ten.pressed.connect(_pull.bind(10))
	buttons.add_child(ten)

	results_label = RichTextLabel.new()
	results_label.bbcode_enabled = true
	results_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(results_label)

	_build_reveal_overlay()
	_refresh()


func _build_reveal_overlay() -> void:
	reveal_overlay = ColorRect.new()
	reveal_overlay.color = Color(0.01, 0.02, 0.05, 0.92)
	reveal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reveal_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	reveal_overlay.visible = false
	reveal_overlay.gui_input.connect(_on_overlay_input)
	add_child(reveal_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_overlay.add_child(center)

	door = PanelContainer.new()
	door.custom_minimum_size = Vector2(320, 420)
	door_style = StyleBoxFlat.new()
	door_style.bg_color = Color(0.07, 0.09, 0.15)
	door_style.set_border_width_all(3)
	door_style.set_corner_radius_all(10)
	door.add_theme_stylebox_override("panel", door_style)
	door.resized.connect(func() -> void: door.pivot_offset = door.size / 2.0)
	door.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(door)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	door.add_child(v)

	door_portrait = TextureRect.new()
	door_portrait.custom_minimum_size = Vector2(220, 220)
	door_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	door_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	door_portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(door_portrait)

	door_name = Label.new()
	door_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	door_name.add_theme_font_size_override("font_size", 24)
	v.add_child(door_name)

	door_rarity = Label.new()
	door_rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(door_rarity)

	door_note = Label.new()
	door_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	door_note.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	v.add_child(door_note)

	var hint := Label.new()
	hint.text = "tap to continue"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	v.add_child(hint)

	var skip := Button.new()
	skip.text = "Skip"
	skip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	skip.position += Vector2(-90, -60)
	skip.pressed.connect(_skip_all)
	reveal_overlay.add_child(skip)

	# Full-screen flash for Luminary reveals — emerald, the strongest color.
	flash = ColorRect.new()
	flash.color = Color(0.3, 0.9, 0.5, 0.0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_overlay.add_child(flash)


func _refresh() -> void:
	refresh_resources()
	pity_label.text = "Calls since last Luminary: %d / %d" % [game.pity, game.PITY_LIMIT]


func _pull(count: int) -> void:
	var results: Array = game.pull(count)
	if results.is_empty():
		results_label.text = "Not enough Pearls. The Journey provides — clear stages to earn more."
		return
	sfx("ui_tap")
	_refresh()
	queue = results
	revealed = []
	results_label.text = ""
	reveal_overlay.visible = true
	_show_next()


func _show_next() -> void:
	if queue.is_empty():
		reveal_overlay.visible = false
		_show_summary()
		return
	busy = true
	var r: Dictionary = queue.pop_front()
	revealed.append(r)
	var u: UnitData = r["unit"]
	var color: Color = Enums.RARITY_COLORS[r["rarity"]]

	door_style.border_color = color
	door_portrait.texture = db.unit_art(String(u.id), "portrait")
	door_name.text = u.label()
	door_name.add_theme_color_override("font_color", color)
	door_rarity.text = "%s — %s Order" % [Enums.RARITY_NAMES[r["rarity"]], u.order_name]
	door_note.text = "answers the Call!" if r["is_new"] else "walks the Path already  (+1 Teaching Scroll)"
	sfx(RARITY_SFX[r["rarity"]])

	door.scale = Vector2.ONE * 0.7
	door.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(door, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(door, "modulate:a", 1.0, 0.25)
	if r["rarity"] == 5:
		flash.color.a = 0.55
		tw.tween_property(flash, "color:a", 0.0, 0.7)
	tw.chain().tween_callback(func() -> void: busy = false)


func _on_overlay_input(event: InputEvent) -> void:
	if busy:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_next()


func _skip_all() -> void:
	revealed.append_array(queue)
	queue = []
	reveal_overlay.visible = false
	_show_summary()


func _show_summary() -> void:
	var lines: Array = []
	for r: Dictionary in revealed:
		var u: UnitData = r["unit"]
		var tag := "[color=%s]%s[/color]" % [RARITY_BB[r["rarity"]], Enums.RARITY_NAMES[r["rarity"]]]
		var note := "  — NEW!" if r["is_new"] else "  (duplicate -> +1 Teaching Scroll)"
		lines.append("%s  %s%s" % [tag, u.label(), note])
	results_label.text = "\n".join(lines)
	_refresh()
