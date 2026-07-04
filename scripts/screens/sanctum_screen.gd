extends ScreenBase
## Daily Sanctum (GDD §7): one order's sanctum per day, Teaching Scrolls as
## the material reward, limited runs — the Breath's daily destination.

var notice: Label


func _build() -> void:
	game.tick_time()
	var root := make_root()
	add_header(root, "The Sanctum", "home")

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	center.add_child(v)

	if not game.sanctum_unlocked():
		var locked := Label.new()
		locked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked.text = "The sanctums have not opened to you yet.\nClear stage 1-4 of the Journey first."
		v.add_child(locked)
		return

	var order: String = game.sanctum_order_today()
	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.text = "Sanctum of the %s" % order
	var order_color := Color.WHITE
	for u in db.units.values():
		if u.order_name == order:
			order_color = Enums.AFFINITY_COLORS[u.affinity]
			break
	title.add_theme_color_override("font_color", order_color)
	v.add_child(title)

	var info := Label.new()
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.text = "A different order keeps the sanctum each day.\nReward per visit: 1 Teaching Scroll + 40 Marks.\nVisits left today: %d / %d   ·   Cost: %d Breath\nThe keepers match your strength — this is training, not a stroll." % [
		game.sanctum_runs_left(), game.SANCTUM_RUNS_PER_DAY, game.SANCTUM_BREATH_COST]
	v.add_child(info)

	notice = Label.new()
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.add_theme_color_override("font_color", ACCENT)
	v.add_child(notice)

	var enter := Button.new()
	enter.text = "Enter the Sanctum"
	enter.custom_minimum_size = Vector2(340, 52)
	enter.disabled = game.sanctum_runs_left() <= 0
	if enter.disabled:
		enter.text = "The sanctum rests until tomorrow"
	enter.pressed.connect(_on_enter)
	v.add_child(enter)


func _on_enter() -> void:
	if game.sanctum_runs_left() <= 0:
		return
	if not game.spend_breath(game.SANCTUM_BREATH_COST):
		notice.text = "Not enough Breath — it returns with time."
		return
	screens.goto("battle", {"sanctum": true})
