extends SceneTree
## Headless test of the meta-game systems: database, profile, XP, Breath,
## stage progression, and The Calling (deterministic fixed-price shop).
## Backs up and restores the real save file so manual playtests are safe.
## Run:  godot --headless --path . -s res://tests/systems_test.gd

const SAVE_PATH := "user://save.json"


func _initialize() -> void:
	var backup := ""
	if FileAccess.file_exists(SAVE_PATH):
		backup = FileAccess.open(SAVE_PATH, FileAccess.READ).get_as_text()

	# In script mode (-s) autoload nodes exist but their _ready never fires —
	# reuse them (creating doubles would shadow the ones game code resolves)
	# and trigger their loading explicitly.
	var db: Node = root.get_node_or_null("Db")
	if db == null:
		db = preload("res://scripts/systems/database.gd").new()
		db.name = "Db"
		root.add_child(db)
	db.reload()
	var game: Node = root.get_node_or_null("Game")
	if game == null:
		game = preload("res://scripts/systems/game_state.gd").new()
		game.name = "Game"
		root.add_child(game)
	game.load_save()

	# --- database ---
	assert(db.units.size() == 19, "expected 19 units, got %d" % db.units.size())
	assert(db.stages.size() == 12, "expected 12 stages, got %d" % db.stages.size())
	assert(String(db.stage_order[0].id) == "v1_s01", "stage order broken")
	assert(db.playable_pool(5).size() == 8, "Luminary pool should be 8 (incl. Sage)")
	assert(db.playable_pool(4).size() == 4, "Wayfarer pool should be 4")
	assert(db.playable_pool(3).size() == 3, "Novice pool should be 3")
	print("db ok: %d units, %d stages" % [db.units.size(), db.stages.size()])

	# --- fresh profile ---
	game.reset_profile()
	assert(game.roster.size() == 4 and game.marks == 200)

	# --- XP / levels ---
	assert(game.add_xp("bram", 25) == 1 and game.level_of("bram") == 2)
	assert(is_equal_approx(game.level_mult(1), 1.0))
	print("xp ok")

	# --- Breath ---
	assert(game.spend_breath(6) and game.breath == game.BREATH_MAX - 6)
	assert(not game.spend_breath(1000))
	print("breath ok")

	# --- stage flow ---
	var s1: StageData = db.stages["v1_s01"]
	assert(game.is_unlocked(s1))
	assert(not game.is_unlocked(db.stages["v1_s02"]))
	var summary: Dictionary = game.finish_stage(s1, true)
	assert(summary["victory"] and summary["first_clear_seals"] == 1)
	assert(game.seals == 1 and game.marks == 200 + 20)
	assert(game.is_unlocked(db.stages["v1_s02"]))
	assert(not game.is_unlocked(db.stages["v1_s12"]))
	print("stage flow ok")

	# --- The Calling (deterministic shop — GDD 9.1: no rolls, ever) ---
	assert(game.buy_unit("vale") == "poor", "should not afford Vale with 0 sigils")
	game.sigils = 6
	assert(game.buy_unit("vale") == "ok")
	assert(game.owns("vale") and game.sigils == 0, "sigil purchase broken")
	assert(game.buy_unit("vale") == "owned", "double-purchase must be blocked")
	game.seals = 10
	assert(game.buy_unit("rowan") == "ok" and game.seals == 0)
	game.marks = 300
	assert(game.buy_unit("sol") == "ok" and game.marks == 0)
	game.marks = game.SCROLL_COST_MARKS
	assert(game.buy_scroll(1) and game.scrolls == 1 and game.marks == 0)
	assert(not game.buy_scroll(1), "scroll purchase with 0 marks must fail")
	# audit: no randomness in acquisition — buying is exact and repeatable
	print("calling ok: deterministic purchases, no rolls")

	# --- save roundtrip ---
	game.sigils = 4242
	game.save()
	var game2: Node = preload("res://scripts/systems/game_state.gd").new()
	game2.name = "Game2"
	root.add_child(game2)
	game2.load_save()
	assert(game2.sigils == 4242, "save roundtrip failed")
	print("save ok")

	# restore the player's real save
	if backup != "":
		FileAccess.open(SAVE_PATH, FileAccess.WRITE).store_string(backup)
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	print("ALL SYSTEMS TESTS PASSED")
	quit(0)
