extends SceneTree
## Comp-comparison for DETERMINISTIC combat (GDD §4.4): for each team comp,
## the win pattern by level against the actual authored boss stage (v1_s12,
## at its real enemy_scale). Replaces the old win-% sim.
##
## Reading the output: earlier first-contiguous-win level = stronger comp.
## Balance targets: balanced comp clears earliest; missing-role comps lag by
## 2+ levels; turtle either lags far behind or wins only via very long fights
## (turn count printed — the anti-stall enrage should punish it).
## Run:  godot --headless --path . -s res://tests/simulate.gd

const LEVELS := 16

const COMPS := {
	"balanced (nuk/brk/tank/heal)": ["bram", "echo", "brand", "aria"],
	"no healer": ["bram", "echo", "brand", "echo"],
	"no tank": ["bram", "echo", "aria", "echo"],
	"all offense": ["bram", "bram", "echo", "echo"],
	"turtle (2 tank / 2 heal)": ["brand", "brand", "aria", "aria"],
	"guardian comp (Sage)": ["bram", "echo", "sage", "aria"],
}


func _initialize() -> void:
	var db: Node = root.get_node_or_null("Db")
	if db == null:
		db = preload("res://scripts/systems/database.gd").new()
		db.name = "Db"
		root.add_child(db)
	db.reload()

	var boss: StageData = db.stages["v1_s12"]
	var enemy_data: Array = []
	for eid in boss.enemy_ids:
		enemy_data.append(db.units[eid])

	print("boss stage %s (scale %.2f) | win pattern by level 1..%d | turns at first win" % [
		boss.display_name, boss.enemy_scale, LEVELS])
	for comp_name in COMPS:
		var team_data: Array = []
		for id in COMPS[comp_name]:
			team_data.append(db.units[id])
		var pattern := ""
		var first_win_turns := -1
		for level in range(1, LEVELS + 1):
			var mult := 1.0 + 0.04 * (level - 1)
			var mgr := BattleManager.new()
			mgr.auto_mode = true
			var out := {}
			mgr.battle_ended.connect(func(v: bool) -> void: out["v"] = v)
			mgr.setup(team_data, enemy_data, [mult, mult, mult, mult], boss.enemy_scale)
			var steps := 0
			while not mgr.ended and steps < 2000:
				mgr.step()
				steps += 1
			mgr.free()
			var won: bool = out.get("v", false)
			pattern += "W" if won else "."
			if won and first_win_turns < 0:
				first_win_turns = steps
		print("  %-30s %s   %s" % [comp_name, pattern,
			("first win: %d turns" % first_win_turns) if first_win_turns > 0 else "no win <= L%d" % LEVELS])
	quit(0)
