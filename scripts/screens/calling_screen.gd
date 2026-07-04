extends ScreenBase
## The Calling — GAMBLING-FREE (GDD §9.1): the player CHOOSES a companion and
## pays their fixed tier-token price. No rates, no pity, no rolls. The
## door-of-light ceremony plays on every successful Call.

var notice: Label
var list: VBoxContainer
var reveal_overlay: Control
var door: PanelContainer
var door_style: StyleBoxFlat
var door_portrait: TextureRect
var door_name: Label
var door_rarity: Label
var door_note: Label
var flash: ColorRect
var busy := false

const CURRENCY_NAMES := {
	"marks": "Silver Marks", "seals": "Violet Seals", "sigils": "Emerald Sigils",
}
const RARITY_SFX := { 3: "reveal_novice", 4: "reveal_wayfarer", 5: "reveal_luminary" }


func _build() -> void:
	var root := make_root()
	add_header(root, "The Calling", "home")

	var blurb := Label.new()
	blurb.text = "Every Call is a choice — fixed prices, no chance, no gambling."
	blurb.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	root.add_child(blurb)

	notice = Label.new()
	notice.add_theme_color_override("font_color", ACCENT)
	root.add_child(notice)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	_build_reveal_overlay()
	_refresh_list()


func _refresh_list() -> void:
	refresh_resources()
	for child in list.get_children():
		child.queue_free()

	# Teaching Scrolls first — the other fixed-price purchase.
	var scroll_row := HBoxContainer.new()
	scroll_row.add_theme_constant_override("separation", 10)
	list.add_child(scroll_row)
	var scroll_lbl := Label.new()
	scroll_lbl.text = "Teaching Scroll (skill-ups)  —  %d Silver Marks" % game.SCROLL_COST_MARKS
	scroll_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_row.add_child(scroll_lbl)
	var scroll_btn := Button.new()
	scroll_btn.text = "Buy"
	scroll_btn.disabled = game.marks < game.SCROLL_COST_MARKS
	scroll_btn.pressed.connect(_on_buy_scroll)
	scroll_row.add_child(scroll_btn)
	list.add_child(HSeparator.new())

	# Units grouped by rarity, strongest first.
	var ids: Array = []
	for id in db.units:
		if not db.units[id].is_enemy:
			ids.append(id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ua: UnitData = db.units[a]
		var ub: UnitData = db.units[b]
		return ua.display_name < ub.display_name if ua.rarity == ub.rarity else ua.rarity > ub.rarity)
	for id in ids:
		list.add_child(_unit_row(id))


func _unit_row(id: String) -> HBoxContainer:
	var u: UnitData = db.units[id]
	var cost: Dictionary = game.unit_cost(u.rarity)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	icon.texture = db.unit_art(id, "icon")
	row.add_child(icon)

	var info := Label.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.text = "%s  [%s %s]" % [u.label(), Enums.RARITY_NAMES[u.rarity],
		u.order_name if u.order_name != "" else "—"]
	info.add_theme_color_override("font_color", Enums.RARITY_COLORS[u.rarity])
	row.add_child(info)

	var price := Label.new()
	price.text = "%d %s" % [cost["amount"], CURRENCY_NAMES[cost["currency"]]]
	price.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	row.add_child(price)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(90, 36)
	if game.owns(id):
		btn.text = "In Company"
		btn.disabled = true
	else:
		btn.text = "Call"
		btn.disabled = not game.can_afford_unit(u)
		btn.pressed.connect(_on_call.bind(id))
	row.add_child(btn)
	return row


func _on_buy_scroll() -> void:
	if game.buy_scroll(1):
		sfx("ui_tap")
		notice.text = "A Teaching Scroll joins your satchel."
	_refresh_list()


func _on_call(id: String) -> void:
	var result: String = game.buy_unit(id)
	match result:
		"ok":
			_play_ceremony(db.units[id])
		"poor":
			notice.text = "Not enough tokens — the Journey provides. Clear stages and trials."
		"owned":
			notice.text = "They already walk beside you."
	_refresh_list()


# --- the door-of-light ceremony ------------------------------------------------

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

	flash = ColorRect.new()
	flash.color = Color(0.3, 0.9, 0.5, 0.0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_overlay.add_child(flash)


func _play_ceremony(u: UnitData) -> void:
	busy = true
	var color: Color = Enums.RARITY_COLORS[u.rarity]
	door_style.border_color = color
	door_portrait.texture = db.unit_art(String(u.id), "portrait")
	door_name.text = u.label()
	door_name.add_theme_color_override("font_color", color)
	door_rarity.text = "%s — %s" % [Enums.RARITY_NAMES[u.rarity],
		u.order_name if u.order_name != "" else "of the Springs"]
	door_note.text = "answers the Call!"
	notice.text = ""
	reveal_overlay.visible = true
	sfx(RARITY_SFX[u.rarity])

	door.scale = Vector2.ONE * 0.7
	door.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(door, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(door, "modulate:a", 1.0, 0.25)
	if u.rarity == 5:
		flash.color.a = 0.55
		tw.tween_property(flash, "color:a", 0.0, 0.7)
	tw.chain().tween_callback(func() -> void: busy = false)


func _on_overlay_input(event: InputEvent) -> void:
	if busy:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		reveal_overlay.visible = false
		_refresh_list()
