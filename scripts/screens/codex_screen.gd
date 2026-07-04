extends ScreenBase
## The Traveler's Notebook — the dawah layer (GDD §1.1). Entries carry
## "Learn more" hyperlinks to the recorded lore source pages.

var detail: RichTextLabel


func _build() -> void:
	var root := make_root()
	add_header(root, "The Traveler's Notebook", "home")

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 20)
	root.add_child(split)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	detail = RichTextLabel.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.size_flags_stretch_ratio = 1.7
	detail.bbcode_enabled = true
	detail.selection_enabled = true
	detail.meta_clicked.connect(func(meta) -> void: OS.shell_open(str(meta)))
	split.add_child(detail)

	for entry: CodexEntry in db.codex:
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 40)
		b.text = entry.title
		b.pressed.connect(_show_entry.bind(entry))
		list.add_child(b)
	if not db.codex.is_empty():
		_show_entry(db.codex[0])


func _show_entry(entry: CodexEntry) -> void:
	sfx("ui_tap")
	game.deed_event("codex")
	var text := "[b]%s[/b]\n\n%s" % [entry.title, entry.body]
	# STRICT lore caveat (GDD §1.1): every page carries the fantasy framing,
	# and sources are always "Inspired by" — this game teaches nothing;
	# it points.
	text += "\n\n[i][color=#8a8fa3]The Notebook is a work of fantasy, inspired by living teachings. Where a name, number, or image was found rather than invented, the thread is linked — follow it to the source; do not mistake this game for one.[/color][/i]"
	if not entry.links.is_empty():
		text += "\n\n[color=#dec06b]Inspired by:[/color]"
		for link in entry.links:
			var parts: PackedStringArray = str(link).split("|")
			if parts.size() == 2:
				text += "\n[url=%s]%s[/url]" % [parts[1].strip_edges(), parts[0].strip_edges()]
	detail.text = text
