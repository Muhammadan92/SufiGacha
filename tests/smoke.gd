extends SceneTree
## Headless smoke test: loads every unit resource and simulates a full
## auto-battle against the Pride boss.
## Run:  godot --headless --path . -s res://tests/smoke.gd

func _initialize() -> void:
	var unit_ids := ["bram", "echo", "brand", "aria", "whisperling", "shadow_vermin", "ash_ghoul", "kibr"]
	var units := {}
	for id in unit_ids:
		var res: UnitData = load("res://data/units/%s.tres" % id)
		assert(res != null, "failed to load " + id)
		assert(res.skills.size() >= 2, id + " has too few skills")
		for skill: SkillData in res.skills:
			assert(skill.effects.size() >= 1, "%s skill %s has no effects" % [id, skill.display_name])
		units[id] = res
		print("loaded %-14s %-24s %d skills" % [id, res.label(), res.skills.size()])

	var mgr := BattleManager.new()
	mgr.auto_mode = true
	mgr.log_message.connect(func(t: String) -> void: print("  | " + t))
	var outcome := {}
	mgr.battle_ended.connect(func(v: bool) -> void: outcome["victory"] = v)
	mgr.setup(
		[units["bram"], units["echo"], units["brand"], units["aria"]],
		[units["whisperling"], units["kibr"], units["whisperling"]])

	var steps := 0
	while not mgr.ended and steps < 1000:
		mgr.step()
		steps += 1

	assert(mgr.ended, "battle did not finish within 1000 steps")
	print("RESULT: finished in %d unit-turns, victory=%s" % [steps, str(outcome.get("victory"))])
	mgr.free()
	quit(0)
