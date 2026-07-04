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


func unit_title(id: String) -> String:
	var u: UnitData = db.units[id]
	return "%s  [%s %s]  Lv %d" % [
		u.label(), Enums.RARITY_NAMES[u.rarity], u.order_name, game.level_of(id)]
