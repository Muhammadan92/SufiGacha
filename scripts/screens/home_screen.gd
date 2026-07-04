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
	_nav_button(v, "The Minaret", "minaret")
	_nav_button(v, "The Company", "roster")
	_nav_button(v, "The Calling", "calling")
	_nav_button(v, "The Traveler's Notebook", "codex")

	v.add_child(HSeparator.new())
	_build_settings(v)


func _build_settings(parent: Control) -> void:
	if audio == null:
		return
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	parent.add_child(grid)

	var music_lbl := Label.new()
	music_lbl.text = "Music"
	grid.add_child(music_lbl)
	var music_slider := HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.05
	music_slider.value = audio.music_volume
	music_slider.custom_minimum_size = Vector2(220, 20)
	music_slider.value_changed.connect(audio.set_music_volume)
	grid.add_child(music_slider)

	var sfx_lbl := Label.new()
	sfx_lbl.text = "Sound"
	grid.add_child(sfx_lbl)
	var sfx_slider := HSlider.new()
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05
	sfx_slider.value = audio.sfx_volume
	sfx_slider.custom_minimum_size = Vector2(220, 20)
	sfx_slider.value_changed.connect(func(v_: float) -> void:
		audio.set_sfx_volume(v_)
		sfx("ui_tap"))
	grid.add_child(sfx_slider)

	var perc := CheckBox.new()
	perc.text = "Percussion & voice only (no melodic instruments)"
	perc.button_pressed = audio.percussion_only
	perc.toggled.connect(audio.set_percussion_only)
	parent.add_child(perc)


func _nav_button(parent: Control, text: String, screen_name: String) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(340, 52)
	b.pressed.connect(func() -> void: screens.goto(screen_name))
	parent.add_child(b)
