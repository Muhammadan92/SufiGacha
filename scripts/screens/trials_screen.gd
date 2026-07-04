extends ScreenBase
## The weekly Vice Trial (GDD §6.1): five ascending duels with Pride, each
## tier's reward claimable once per week. Free to attempt, free to retry —
## the Trial is a test of the company you've built, not of your Breath.

func music_key() -> String:
	return "boss"


func _build() -> void:
	game.tick_time()
	var root := make_root()
	add_header(root, "The Trial of Pride", "home")

	if not game.trial_unlocked():
		var center := CenterContainer.new()
		center.size_flags_vertical = Control.SIZE_EXPAND_FILL
		root.add_child(center)
		var locked := Label.new()
		locked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked.text = "The Trial waits beyond the first valley.\nDefeat Kibr at stage 1-12 to earn the right."
		center.add_child(locked)
		return

	var blurb := Label.new()
	blurb.text = "Pride returns each week, swollen anew. Five tiers; each reward claimed once per week. Retries are free."
	blurb.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	root.add_child(blurb)

	var listbox := VBoxContainer.new()
	listbox.add_theme_constant_override("separation", 8)
	listbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(listbox)

	for tier in range(1, 6):
		listbox.add_child(_tier_row(tier))


func _tier_row(tier: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var info := Label.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var reward: Dictionary = game.TRIAL_REWARDS[tier - 1]
	var bits: Array = []
	for k in reward:
		bits.append("%d %s" % [reward[k], k])
	info.text = "Trial %s   (foe strength x%.1f)   —   %s" % [
		["I", "II", "III", "IV", "V"][tier - 1], game.TRIAL_SCALES[tier - 1], ", ".join(bits)]
	row.add_child(info)

	var b := Button.new()
	b.custom_minimum_size = Vector2(160, 40)
	if game.trial_cleared_this_week(tier):
		b.text = "Claimed this week"
		b.disabled = true
	else:
		b.text = "Face the Trial"
		b.pressed.connect(func() -> void:
			screens.goto("battle", {"trial_tier": tier}))
	row.add_child(b)
	return row
