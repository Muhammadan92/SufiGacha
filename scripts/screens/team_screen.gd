extends ScreenBase
## Company editor: pick exactly 4 owned characters.

var selected: Array = []
var confirm: Button
var count_label: Label
var buttons := {}  # id -> Button


func _build() -> void:
	selected = game.team.duplicate()
	var root := make_root()
	add_header(root, "Edit Company", "stages")

	count_label = Label.new()
	root.add_child(count_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	var ids: Array = game.roster.keys()
	ids.sort()
	for id in ids:
		var b := Button.new()
		b.toggle_mode = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 40)
		b.text = unit_title(id)
		b.button_pressed = id in selected
		b.toggled.connect(_on_toggled.bind(id))
		buttons[id] = b
		list.add_child(b)

	confirm = Button.new()
	confirm.text = "Confirm Company"
	confirm.custom_minimum_size = Vector2(0, 48)
	confirm.pressed.connect(_on_confirm)
	root.add_child(confirm)
	_refresh()


func _on_toggled(on: bool, id: String) -> void:
	if on and id not in selected:
		selected.append(id)
	elif not on:
		selected.erase(id)
	_refresh()


func _refresh() -> void:
	count_label.text = "Selected %d / 4" % selected.size()
	confirm.disabled = selected.size() != 4


func _on_confirm() -> void:
	game.team = selected.duplicate()
	game.save()
	screens.goto("stages")
