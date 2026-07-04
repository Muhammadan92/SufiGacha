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
	# bare clear = 1 star (default stats fail the other objectives):
	# marks = 200 start + 20 stage + 20 star; seals = 1 first-clear + 1 star
	assert(summary["stars"] == 1 and summary["new_stars"] == 1)
	assert(game.seals == 2 and game.marks == 200 + 20 + 20)
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

	# --- mastery (Teaching Scrolls spend) ---
	assert(game.mastery_of("bram") == 0 and is_equal_approx(game.skill_mult_of("bram"), 1.0))
	game.scrolls = 3
	assert(game.upgrade_mastery("bram") and game.mastery_of("bram") == 1 and game.scrolls == 2)
	assert(game.upgrade_mastery("bram") and game.scrolls == 0, "level 2 costs 2 scrolls")
	assert(not game.upgrade_mastery("bram"), "no scrolls -> no upgrade")
	assert(is_equal_approx(game.skill_mult_of("bram"), 1.12))
	print("mastery ok")

	# --- star objectives ---
	var s2: StageData = db.stages["v1_s02"]
	var flawless: Dictionary = game.finish_stage(s2, true, {"deaths": 0, "turns": 10})
	assert(flawless["stars"] == 3 and flawless["new_stars"] == 3, "flawless should be 3 stars")
	assert(flawless["star_seals"] == 3, "3 new stars -> 3 seals")
	var repeat: Dictionary = game.finish_stage(s2, true, {"deaths": 2, "turns": 999})
	assert(repeat["stars"] == 1 and repeat["new_stars"] == 0, "worse repeat must not re-reward")
	assert(int(game.stars["v1_s02"]) == 3, "best stars persist")
	print("stars ok")

	# --- The Minaret ---
	assert(not game.minaret_unlocked(), "minaret should be locked pre-1-6")
	game.cleared[game.MINARET_UNLOCK_STAGE] = true
	assert(game.minaret_unlocked())
	var f1: StageData = game.make_minaret_stage(1)
	assert(f1.breath_cost == 0 and f1.enemy_scale > 0.6)
	var f10: StageData = game.make_minaret_stage(10)
	assert(f10.enemy_ids == ["kibr"], "every 10th floor is a Vice floor")
	var before_sigils: int = game.sigils
	var climb: Dictionary = game.finish_minaret(1, true)
	assert(game.minaret_floor == 1 and climb["marks"] == 35)
	var skip: Dictionary = game.finish_minaret(5, true)
	assert(skip["marks"] == 0 and game.minaret_floor == 1, "cannot skip floors")
	for f in range(2, 11):
		game.finish_minaret(f, true)
	assert(game.minaret_floor == 10 and game.sigils == before_sigils + 1, "floor 10 pays a Sigil")
	print("minaret ok")

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
