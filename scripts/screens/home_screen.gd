extends ScreenBase
## Home: title + navigation. The lodge, eventually.


func _build() -> void:
	var root := make_root()
	add_header(root, "")
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	center.add_child(v)

	var title := Label.new()
	title.text = "SEVEN  SPRINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	v.add_child(title)
	var sub := Label.new()
	sub.text = "Valley of the Quest — prototype"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	v.add_child(HSeparator.new())

	_nav_button(v, "Journey", "stages")
	_nav_button(v, "The Company", "roster")
	_nav_button(v, "The Calling", "calling")


func _nav_button(parent: Control, text: String, screen_name: String) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(340, 52)
	b.pressed.connect(func() -> void: screens.goto(screen_name))
	parent.add_child(b)
