class_name BattleSim
## The one shared deterministic battle runner for every test/tool harness
## (rq review: five hand-rolled copies of this loop had already drifted on
## which stats they collected). Deterministic combat means identical inputs
## always give identical results.


## Runs one auto-battle. Returns:
##   win (bool) · turns (manager turn count) · steps (loop iterations,
##   the legacy minutes proxy) · deaths (player-side falls)
static func run(db: Node, team_ids: Array, enemy_ids: Array, level_mult: float,
		enemy_scale: float, skill_mult := 1.0, step_cap := 1500) -> Dictionary:
	var team_data: Array = []
	for id in team_ids:
		team_data.append(db.units[id])
	var enemy_data: Array = []
	for eid in enemy_ids:
		enemy_data.append(db.units[eid])
	var mgr := BattleManager.new()
	mgr.auto_mode = true
	var out := {}
	mgr.battle_ended.connect(func(v: bool) -> void: out["v"] = v)
	var deaths := 0
	mgr.unit_died.connect(func(u: BattleUnit) -> void:
		if u.is_player_side:
			deaths += 1)
	var mults := [level_mult, level_mult, level_mult, level_mult]
	var smults := [skill_mult, skill_mult, skill_mult, skill_mult]
	mgr.setup(team_data, enemy_data, mults, enemy_scale, smults)
	var steps := 0
	while not mgr.ended and steps < step_cap:
		mgr.step()
		steps += 1
	var result := {
		"win": out.get("v", false), "turns": mgr.turns_taken,
		"steps": steps, "deaths": deaths,
	}
	mgr.free()
	return result
