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
	assert(db.units.size() == 41, "expected 41 units, got %d" % db.units.size())
	assert(db.stages.size() == 84, "expected 84 stages, got %d" % db.stages.size())
	assert(String(db.stage_order[0].id) == "v1_s01", "stage order broken")
	assert(db.playable_pool(5).size() == 8, "Luminary pool should be 8 (incl. Sage)")
	assert(db.playable_pool(4).size() == 11, "Wayfarer pool should be 11")
	assert(db.playable_pool(3).size() == 9, "Novice pool should be 9")
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

	# --- lunar calendar (tabular; known date check) ---
	var probe: int = int(Time.get_unix_time_from_datetime_string("2026-07-04T12:00:00"))
	var h: Dictionary = SeasonCalendar.from_unix(probe)
	assert(h["year"] == 1448 and h["month"] == 1, "2026-07-04 should be month 1, 1448 (got %s)" % str(h))
	assert(SeasonCalendar.season_name(probe) == "The Door")
	assert(SeasonCalendar.SEASON_NAMES.size() == 12)
	print("calendar ok: 2026-07-04 -> %s day %d, %d" % [SeasonCalendar.season_name(probe), h["day"], h["year"]])

	# --- deeds + season pass ---
	game.reset_profile()
	game.tick_time()
	assert(game.deeds["daily"].size() == 3 and game.deeds["weekly"].size() == 3)
	var marks_before: int = game.marks
	game.deed_event("win")
	game.deed_event("win")
	game.deed_event("win")  # completes win3 if in today's rotation
	var any_done := false
	for d in game.deeds["daily"] + game.deeds["weekly"]:
		if d["done"]:
			any_done = true
	# 3 wins always progress the weekly win12 (3/12) — completion depends on
	# the daily rotation, so just assert progress happened:
	var weekly_win: Dictionary = game.deeds["weekly"][0]
	assert(weekly_win["progress"] == 3, "weekly win deed should track progress")
	game.deed_event("refine")
	assert(game.deeds["weekly"][1]["done"], "refine weekly should complete")
	assert(game.seals > 0 or game.marks > marks_before or any_done, "deed rewards should flow")
	assert(int(game.season.get("tier_xp", 0)) >= game.DEED_XP_WEEKLY, "season xp should accrue")

	# tier + retroactive pass
	game.season["tier_xp"] = 0
	game.season["tier"] = 0
	game.season["paid"] = false
	var sigils_before: int = game.sigils
	game._grant_season_xp(game.TIER_XP * 30)  # blast to tier 30
	assert(int(game.season["tier"]) == 30, "should reach tier 30")
	var seals_after_free: int = game.seals
	game.unlock_season_pass()  # retroactive: all paid tiers grant now
	assert(game.sigils == sigils_before + 1, "paid tier 30 grants the Sigil retroactively")
	assert(game.seals == seals_after_free + 2, "paid track grants 2 Seals")
	print("deeds + season pass ok")

	# --- difficulty re-clears ---
	assert(not game.diff_unlocked("hard"), "hard locked before valley clear")
	game.cleared["v1_s12"] = true
	assert(game.diff_unlocked("hard") and not game.diff_unlocked("nm"))
	var hard_boss: StageData = game.make_diff_stage(db.stages["v1_s12"], "hard")
	assert(is_equal_approx(hard_boss.enemy_scale, 1.3 * 2.2), "hard scale = base x2.2")
	assert(game.is_unlocked(db.stages["v1_s01"], "hard"), "hard 1-1 open once unlocked")
	assert(not game.is_unlocked(db.stages["v1_s02"], "hard"), "hard chain gates")
	var m0: int = game.marks
	var hsum: Dictionary = game.finish_stage(db.stages["v1_s01"], true, {}, "hard")
	assert(hsum["marks"] == db.stages["v1_s01"].marks_reward * 2, "hard pays x2 marks")
	assert(hsum["stars"] == 0, "stars are normal-difficulty only")
	assert(game.cleared.has("hard:v1_s01"))
	var hboss: Dictionary = game.finish_stage(db.stages["v1_s12"], true, {}, "hard")
	assert(hboss["first_clear_sigils"] == 1, "hard boss first clear pays +1 Sigil")
	assert(game.diff_unlocked("nm"), "nightmare unlocks after hard boss")
	print("difficulty re-clears ok")

	# --- weekly Vice Trial ---
	assert(game.trial_unlocked())
	assert(not game.trial_cleared_this_week(3))
	var t3: StageData = game.make_trial_stage(3)
	assert(is_equal_approx(t3.enemy_scale, 3.2) and t3.enemy_ids.has("kibr"))
	var seals0: int = game.seals
	var tsum: Dictionary = game.finish_trial(3, true)
	assert(tsum["first_clear_seals"] == 2 and game.seals == seals0 + 2)
	var trepeat: Dictionary = game.finish_trial(3, true)
	assert(trepeat["first_clear_seals"] == 0, "trial reward once per week")
	assert(game.trial_cleared_this_week(3))
	print("weekly trial ok")

	# --- waymarks ---
	game.reset_profile()
	assert(game.waymark_metric("roster") == 4)
	var sig0: int = game.sigils
	game.stars = {"a": 3, "b": 3, "c": 3, "d": 3, "e": 3}  # 15 stars
	var wms: Array = game.check_waymarks()
	assert(game.waymarks_claimed.has("stars_15"), "15-star waymark should claim")
	assert(game.sigils == sig0 + 1, "15-star waymark pays the week-2 Sigil")
	assert(game.check_waymarks().is_empty(), "waymarks claim once")
	print("waymarks ok (%d claimed on blast)" % wms.size())

	# --- tutorial flow ---
	assert(game.tutorial_step == 0, "fresh profile starts the tutorial")
	game.advance_tutorial(0)
	game.advance_tutorial(0)  # double-advance must be a no-op
	assert(game.tutorial_step == 1)
	for s in range(1, 5):
		game.advance_tutorial(s)
	assert(game.tutorial_step == game.TUTORIAL_DONE)
	print("tutorial ok")

	# --- sanctum ---
	assert(not game.sanctum_unlocked())
	game.cleared[game.SANCTUM_UNLOCK_STAGE] = true
	assert(game.sanctum_unlocked() and game.sanctum_runs_left() == 2)
	var sstage: StageData = game.make_sanctum_stage()
	assert(sstage.enemy_scale > 0.5 and sstage.enemy_ids.size() >= 2)
	var scrolls_before: int = game.scrolls
	var ssum: Dictionary = game.finish_sanctum(true)
	assert(ssum["scrolls"] == 1 and game.scrolls == scrolls_before + 1)
	game.finish_sanctum(true)
	assert(game.sanctum_runs_left() == 0)
	var blocked: Dictionary = game.finish_sanctum(true)
	assert(blocked["scrolls"] == 0, "third run must grant nothing")
	print("sanctum ok")

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
