extends ScreenBase
## The Company: owned characters with a detail pane.

var detail: RichTextLabel


func _build() -> void:
	var root := make_root()
	add_header(root, "The Company", "home")

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
	detail.size_flags_stretch_ratio = 1.4
	detail.bbcode_enabled = true
	split.add_child(detail)

	var ids: Array = game.roster.keys()
	ids.sort()
	for id in ids:
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 40)
		b.text = unit_title(id)
		b.pressed.connect(_show_detail.bind(id))
		list.add_child(b)
	if not ids.is_empty():
		_show_detail(ids[0])


func _show_detail(id: String) -> void:
	var u: UnitData = db.units[id]
	var level: int = game.level_of(id)
	var mult: float = game.level_mult(level)
	var entry: Dictionary = game.roster[id]
	var lines: Array = []
	lines.append("[b]%s[/b]" % u.label())
	lines.append("%s of the %s Order — %s affinity" % [
		Enums.RARITY_NAMES[u.rarity], u.order_name, Enums.AFFINITY_NAMES[u.affinity]])
	lines.append("Level %d   (%d/%d XP)   Dupes: %d" % [
		level, entry["xp"], game.xp_to_next(level), entry["dupes"]])
	lines.append("")
	lines.append("HP %d   ATK %d   DEF %d   SPD %d" % [
		int(u.max_hp * mult), int(u.atk * mult), int(u.def * mult), u.spd])
	lines.append("Crit %d%% (x%.1f)   Eff %d%%   Res %d%%" % [
		int(u.crit_rate * 100), u.crit_damage,
		int(u.effectiveness * 100), int(u.resilience * 100)])
	lines.append("")
	for skill: SkillData in u.skills:
		lines.append("[b][%s][/b] %s%s" % [
			Enums.SLOT_NAMES[skill.slot], skill.full_name(),
			"  (cooldown %d)" % skill.cooldown if skill.cooldown > 0 else ""])
	detail.text = "\n".join(lines)
