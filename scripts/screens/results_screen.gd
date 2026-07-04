extends ScreenBase
## Post-battle rewards summary. Payload: the dict from Game.finish_stage().


func _build() -> void:
	var summary: Dictionary = screens.payload if screens.payload is Dictionary else {}
	var root := make_root()
	add_header(root, "")
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	center.add_child(v)

	var title := Label.new()
	title.add_theme_font_size_override("font_size", 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "VICTORY" if summary.get("victory", false) else "DEFEAT"
	v.add_child(title)

	var body := Label.new()
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var lines: Array = [summary.get("stage_name", "")]
	if summary.get("victory", false):
		lines.append("")
		if summary.get("stars", 0) > 0:
			lines.append("★".repeat(summary["stars"]) + "☆".repeat(3 - summary["stars"]))
			if summary.get("new_stars", 0) > 0:
				lines.append("New stars: +%d  (+%d Marks, +%d Seals)" % [
					summary["new_stars"], summary.get("star_marks", 0), summary.get("star_seals", 0)])
		lines.append("XP gained: %d per companion" % summary.get("xp_each", 0))
		lines.append("Silver Marks: +%d" % summary.get("marks", 0))
		if summary.get("scrolls", 0) > 0:
			lines.append("Teaching Scrolls: +%d" % summary["scrolls"])
		if summary.get("first_clear_seals", 0) > 0:
			lines.append("First clear: +%d Violet Seal(s)!" % summary["first_clear_seals"])
		if summary.get("first_clear_sigils", 0) > 0:
			lines.append("First clear: +%d Emerald Sigil(s)!" % summary["first_clear_sigils"])
		for msg in summary.get("level_ups", []):
			lines.append(str(msg))
	else:
		lines.append("")
		lines.append("The darkness holds this ground... for now.")
	body.text = "\n".join(lines)
	v.add_child(body)

	var cont := Button.new()
	cont.text = "Continue"
	cont.custom_minimum_size = Vector2(280, 48)
	cont.pressed.connect(func() -> void: screens.goto("stages"))
	v.add_child(cont)

	if game.tutorial_at(3) and summary.get("victory", false):
		show_tutorial([
			"Your first victory. XP raises your companions' levels; Marks and Seals fill your purse.",
			"Spend them in THE CALLING: every companion of every order has a fixed, visible price. No chance, no gambling — you choose exactly who walks beside you, and the Journey provides the means.",
		], func() -> void: game.advance_tutorial(3))
