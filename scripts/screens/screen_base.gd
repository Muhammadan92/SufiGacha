class_name ScreenBase
extends Control
## Base for all grey-box screens: autoload access, full-rect layout, and a
## standard header (back button + title + resource readout).

@onready var game: Node = get_node("/root/Game")
@onready var db: Node = get_node("/root/Db")
@onready var screens: Node = get_node("/root/Screens")
@onready var audio: Node = get_node_or_null("/root/Audio")

var resources_label: Label = null


const BG_COLOR := Color(0.05, 0.07, 0.12)
const ACCENT := Color(0.87, 0.75, 0.42)  # deep gold — GDD §11 palette


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build()
	if audio != null:
		audio.play_music(music_key())


## Override in each screen.
func _build() -> void:
	pass


## Music track key for this screen ("" = leave current music playing).
func music_key() -> String:
	return "title"


func sfx(key: String) -> void:
	if audio != null:
		audio.play_sfx(key)


## Standard vertical root with margins.
func make_root() -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	margin.add_child(v)
	return v


func add_header(root: VBoxContainer, title: String, back_screen: String = "") -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	root.add_child(h)
	if back_screen != "":
		var back := Button.new()
		back.text = "< Back"
		back.pressed.connect(func() -> void: screens.goto(back_screen))
		h.add_child(back)
	var t := Label.new()
	t.text = title
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	resources_label = Label.new()
	h.add_child(resources_label)
	refresh_resources()


func refresh_resources() -> void:
	if resources_label == null:
		return
	game.regen_breath()
	resources_label.text = "Marks %d   Seals %d   Sigils %d   Scrolls %d   Breath %d/%d" % [
		game.marks, game.seals, game.sigils, game.scrolls, game.breath, game.BREATH_MAX]


## Sequential tutorial panels: dims the screen, shows messages one tap at a
## time, then calls on_done. Used by the first-session flow (GDD §14 tutorial).
func show_tutorial(messages: Array, on_done: Callable = Callable()) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.72)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.17)
	style.set_border_width_all(2)
	style.border_color = ACCENT
	style.set_corner_radius_all(8)
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	var text := Label.new()
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(592, 0)
	v.add_child(text)
	var hint := Label.new()
	hint.text = "tap to continue"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	v.add_child(hint)

	var queue: Array = messages.duplicate()
	text.text = str(queue.pop_front())
	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			sfx("ui_tap")
			if queue.is_empty():
				overlay.queue_free()
				if on_done.is_valid():
					on_done.call()
			else:
				text.text = str(queue.pop_front()))


func unit_title(id: String) -> String:
	var u: UnitData = db.units[id]
	return "%s  [%s %s]  Lv %d" % [
		u.label(), Enums.RARITY_NAMES[u.rarity], u.order_name, game.level_of(id)]
