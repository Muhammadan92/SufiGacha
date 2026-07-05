extends SceneTree
## Proves the BACKEND.md §0.2 claim IN THE REPO: with deterministic combat,
## a battle's action log fully reproduces it. Runs an auto-battle recording
## the log, then re-runs the same battle in MANUAL mode, submitting player
## actions purely from the log — and asserts identical outcome, turn count,
## and final log. This is the exact mechanism server-side replay
## verification will use.
## Run:  godot --headless --path . -s res://tests/replay_test.gd

const TEAM := ["bram", "echo", "brand", "aria"]
const ENEMIES := ["whisperling", "kibr", "whisperling"]
const LEVEL_MULT := 1.32  # ~level 9 (auto-clears the boss stage)
const SCALE := 1.3


func _initialize() -> void:
	var db: Node = root.get_node_or_null("Db")
	if db == null:
		db = preload("res://scripts/systems/database.gd").new()
		db.name = "Db"
		root.add_child(db)
	db.reload()

	# --- pass 1: auto-battle, record everything ---
	var first := _run(db, true, [])
	print("original: victory=%s turns=%d actions=%d" % [
		first["victory"], first["turns"], first["log"].size()])

	# --- pass 2: replay — player actions fed from the log ---
	var second := _run(db, false, first["log"])
	print("replay:   victory=%s turns=%d actions=%d" % [
		second["victory"], second["turns"], second["log"].size()])

	assert(second["victory"] == first["victory"], "replay outcome diverged")
	assert(second["turns"] == first["turns"], "replay turn count diverged")
	assert(second["log"] == first["log"], "replay action log diverged")
	print("REPLAY VERIFICATION PASSED — the action log exactly reproduces the battle")
	quit(0)


func _run(db: Node, auto: bool, script_log: Array) -> Dictionary:
	var team_data: Array = []
	for id in TEAM:
		team_data.append(db.units[id])
	var enemy_data: Array = []
	for eid in ENEMIES:
		enemy_data.append(db.units[eid])

	var mgr := BattleManager.new()
	mgr.auto_mode = auto
	var out := {}
	mgr.battle_ended.connect(func(v: bool) -> void: out["v"] = v)
	var cursor := [0]  # replay position (player actions only, in order)
	if not auto:
		mgr.awaiting_input.connect(func(actor: BattleUnit) -> void:
			# find this actor's next scripted action
			while cursor[0] < script_log.size():
				var entry: Dictionary = script_log[cursor[0]]
				cursor[0] += 1
				if entry["actor"] != String(actor.data.id):
					continue  # enemy actions replay themselves via AI
				var skill: SkillData = null
				for s: SkillData in actor.data.skills:
					if String(s.id) == entry["skill"]:
						skill = s
						break
				var target: BattleUnit = null
				for u: BattleUnit in mgr.players + mgr.enemies:
					if String(u.data.id) == entry["target"] and u.is_alive():
						target = u
						break
				mgr.submit_player_action(skill, target)
				return
			assert(false, "replay log exhausted while battle still running"))

	var mults := [LEVEL_MULT, LEVEL_MULT, LEVEL_MULT, LEVEL_MULT]
	mgr.setup(team_data, enemy_data, mults, SCALE)
	var steps := 0
	while not mgr.ended and steps < 3000:
		mgr.step()
		steps += 1
	var result := {
		"victory": out.get("v", false),
		"turns": mgr.turns_taken,
		"log": mgr.action_log.duplicate(true),
	}
	mgr.free()
	return result
