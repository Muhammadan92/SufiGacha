extends ScreenBase
## The current Moon: season progress, Deeds (dailies/weeklies), and the
## Season Pass tracks (GDD §9.3.1). The Moon's Codex entry is one tap away.


func _build() -> void:
	game.tick_time()
	var root := make_root()
	var unix: int = game.now_unix()
	add_header(root, SeasonCalendar.season_name(unix), "home")

	var sub := Label.new()
	sub.text = "Day %d of the season  ·  The Twelve Moons" % SeasonCalendar.season_day(unix)
	sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	root.add_child(sub)

	var lore := Button.new()
	lore.text = "Read this season's page in the Traveler's Notebook"
	lore.pressed.connect(func() -> void: screens.goto("codex"))
	root.add_child(lore)
	root.add_child(HSeparator.new())

	# --- season pass progress ---
	var tier: int = int(game.season.get("tier", 0))
	var xp: int = int(game.season.get("tier_xp", 0))
	var tier_lbl := Label.new()
	tier_lbl.text = "Season tier %d / %d    (%d / %d season XP)%s" % [
		tier, game.SEASON_TIERS, xp, game.TIER_XP * (tier + 1),
		"    PASS ACTIVE" if game.season.get("paid", false) else ""]
	tier_lbl.add_theme_color_override("font_color", ACCENT)
	root.add_child(tier_lbl)

	if not game.season.get("paid", false):
		var buy := Button.new()
		buy.text = "Season Pass — $9.99 (prototype: tap to unlock free)"
		buy.pressed.connect(func() -> void:
			game.unlock_season_pass()
			sfx("reveal_wayfarer")
			screens.goto("season"))
		root.add_child(buy)

	var upcoming := Label.new()
	upcoming.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	upcoming.text = _upcoming_rewards_text(tier)
	root.add_child(upcoming)
	root.add_child(HSeparator.new())

	# --- deeds ---
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	_deed_section(list, "Today's Deeds  (+%d Marks, +%d season XP each)" % [
		game.DEED_MARKS_DAILY, game.DEED_XP_DAILY], game.deeds.get("daily", []))
	_deed_section(list, "This Week's Deeds  (+%d Seal, +%d season XP each)" % [
		game.DEED_SEALS_WEEKLY, game.DEED_XP_WEEKLY], game.deeds.get("weekly", []))

	# --- Waymarks: lifetime milestones (Sigil income + goals) ---
	var wm_header := Label.new()
	wm_header.text = "Waymarks of the Road"
	wm_header.add_theme_color_override("font_color", ACCENT)
	list.add_child(wm_header)
	for def in game.WAYMARKS:
		var row := Label.new()
		var have: int = game.waymark_metric(def["metric"])
		var bits: Array = []
		for k in ["marks", "seals", "sigils"]:
			if def.get(k, 0) > 0:
				bits.append("+%d %s" % [def[k], k])
		if game.waymarks_claimed.has(def["id"]):
			row.text = "   %s  —  [reached]" % def["desc"]
			row.add_theme_color_override("font_color", Enums.RARITY_COLORS[5])
		else:
			row.text = "   %s  —  %d/%d  (%s)" % [def["desc"], mini(have, int(def["at"])), int(def["at"]), ", ".join(bits)]
		list.add_child(row)


func _deed_section(list: VBoxContainer, title: String, deed_list: Array) -> void:
	var header := Label.new()
	header.text = title
	header.add_theme_color_override("font_color", ACCENT)
	list.add_child(header)
	for d in deed_list:
		var row := Label.new()
		var mark := "[done]" if d["done"] else "%d/%d" % [d["progress"], d["goal"]]
		row.text = "   %s  —  %s" % [d["desc"], mark]
		if d["done"]:
			row.add_theme_color_override("font_color", Enums.RARITY_COLORS[5])
		list.add_child(row)


func _upcoming_rewards_text(tier: int) -> String:
	var parts: Array = []
	for t in range(tier + 1, mini(tier + 6, game.SEASON_TIERS + 1)):
		var bits: Array = []
		if game.PASS_FREE.has(t):
			bits.append("free: %s" % _fmt(game.PASS_FREE[t]))
		if game.PASS_PAID.has(t):
			bits.append("pass: %s" % _fmt(game.PASS_PAID[t]))
		if not bits.is_empty():
			parts.append("t%d %s" % [t, " | ".join(bits)])
	return "Coming up:  " + ("  ·  ".join(parts) if not parts.is_empty() else "—")


func _fmt(reward: Dictionary) -> String:
	var bits: Array = []
	for k in reward:
		bits.append("%d %s" % [reward[k], k])
	return ", ".join(bits)
