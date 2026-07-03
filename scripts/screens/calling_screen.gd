extends ScreenBase
## The Calling: summoning with published rates and a visible pity counter
## (GDD §9.1, §9.3 — transparency as a brand value).

var results_label: RichTextLabel
var pity_label: Label

const RARITY_COLORS := { 3: "gray", 4: "violet", 5: "gold" }


func _build() -> void:
	var root := make_root()
	add_header(root, "The Calling", "home")

	var rates := Label.new()
	rates.text = "Rates: Luminary 3%% — Wayfarer 20%% — Novice 77%%.  Guaranteed Luminary within %d calls." % game.PITY_LIMIT
	root.add_child(rates)
	pity_label = Label.new()
	root.add_child(pity_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	root.add_child(buttons)
	var one := Button.new()
	one.text = "Call x1  (%d Pearls)" % game.PULL_COST
	one.custom_minimum_size = Vector2(0, 48)
	one.pressed.connect(_pull.bind(1))
	buttons.add_child(one)
	var ten := Button.new()
	ten.text = "Call x10  (%d Pearls — one Wayfarer+ guaranteed)" % (game.PULL_COST * 10)
	ten.custom_minimum_size = Vector2(0, 48)
	ten.pressed.connect(_pull.bind(10))
	buttons.add_child(ten)

	results_label = RichTextLabel.new()
	results_label.bbcode_enabled = true
	results_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(results_label)
	_refresh()


func _refresh() -> void:
	refresh_resources()
	pity_label.text = "Calls since last Luminary: %d / %d" % [game.pity, game.PITY_LIMIT]


func _pull(count: int) -> void:
	var results: Array = game.pull(count)
	if results.is_empty():
		results_label.text = "Not enough Pearls. The Journey provides — clear stages to earn more."
		return
	var lines: Array = []
	for r: Dictionary in results:
		var u: UnitData = r["unit"]
		var tag := "[color=%s]%s[/color]" % [RARITY_COLORS[r["rarity"]], Enums.RARITY_NAMES[r["rarity"]]]
		var note := "  — NEW!" if r["is_new"] else "  (duplicate -> +1 Teaching Scroll)"
		lines.append("%s  %s%s" % [tag, u.label(), note])
	results_label.text = "\n".join(lines)
	_refresh()
