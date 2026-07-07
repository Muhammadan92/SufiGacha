extends ScreenBase
## The Company: owned characters with a detail pane.

var detail: RichTextLabel
var detail_portrait: TextureRect
var mastery_btn: Button
var shown_id := ""


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

	var detail_pane := VBoxContainer.new()
	detail_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_pane.size_flags_stretch_ratio = 1.4
	detail_pane.add_theme_constant_override("separation", 10)
	split.add_child(detail_pane)
	detail_portrait = TextureRect.new()
	detail_portrait.custom_minimum_size = Vector2(140, 140)
	start_idle.call_deferred(detail_portrait, 1, 3.0)
	detail_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_pane.add_child(detail_portrait)
	detail = RichTextLabel.new()
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.bbcode_enabled = true
	detail_pane.add_child(detail)

	mastery_btn = Button.new()
	mastery_btn.custom_minimum_size = Vector2(0, 44)
	mastery_btn.pressed.connect(_on_mastery_pressed)
	detail_pane.add_child(mastery_btn)

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
	shown_id = id
	detail_portrait.texture = chibi_texture(id)
	var u: UnitData = db.units[id]
	var level: int = game.level_of(id)
	var mult: float = game.level_mult(level)
	var entry: Dictionary = game.roster[id]
	var mastery: int = game.mastery_of(id)
	var lines: Array = []
	lines.append("[b]%s[/b]" % u.label())
	lines.append("%s of the %s Order — %s affinity" % [
		Enums.RARITY_NAMES[u.rarity], u.order_name, Enums.AFFINITY_NAMES[u.affinity]])
	lines.append("Level %d   (%d/%d XP)" % [level, entry["xp"], game.xp_to_next(level)])
	lines.append("Mastery %d/%d  (+%d%% damage & healing)" % [
		mastery, game.MASTERY_CAP, int(game.MASTERY_BONUS_PER_LEVEL * mastery * 100)])
	lines.append("")
	lines.append("HP %d   ATK %d   DEF %d   SPD %d" % [
		int(u.max_hp * mult), int(u.atk * mult), int(u.def * mult), u.spd])
	# Deterministic stats (GDD §4.4): Precision is a flat damage bonus;
	# Potency strengthens debuffs inflicted, Ward shrinks debuffs received.
	lines.append("Precision +%d%% dmg   Potency +%d%%   Ward -%d%%" % [
		int(u.crit_rate * (u.crit_damage - 1.0) * 100),
		int(u.effectiveness * 100), int(u.resilience * 100)])
	lines.append("")
	for skill: SkillData in u.skills:
		lines.append("[b][%s][/b] %s%s" % [
			Enums.SLOT_NAMES[skill.slot], skill.full_name(),
			"  (cooldown %d)" % skill.cooldown if skill.cooldown > 0 else ""])
	detail.text = "\n".join(lines)
	_refresh_mastery_button()


func _refresh_mastery_button() -> void:
	var mastery: int = game.mastery_of(shown_id)
	if mastery >= game.MASTERY_CAP:
		mastery_btn.text = "Mastery complete"
		mastery_btn.disabled = true
		return
	var cost: int = game.mastery_cost(mastery)
	mastery_btn.text = "Refine technique  (+%d%% dmg & heal)  —  %d Teaching Scroll%s (have %d)" % [
		int(game.MASTERY_BONUS_PER_LEVEL * 100), cost, "s" if cost > 1 else "", game.scrolls]
	mastery_btn.disabled = game.scrolls < cost


func _on_mastery_pressed() -> void:
	if game.upgrade_mastery(shown_id):
		sfx("reveal_novice")
		refresh_resources()
		_show_detail(shown_id)
