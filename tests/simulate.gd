extends SceneTree
## Batch battle simulator for tuning (GDD §14 exit criteria: balanced comps
## should win the boss fight, bad comps should mostly lose).
## Run:  godot --headless --path . -s res://tests/simulate.gd

const RUNS := 300
const STEP_CAP := 2000  # unit-turns before a battle counts as a stalemate loss

const UNIT_IDS := ["bram", "echo", "brand", "aria", "whisperling", "shadow_vermin", "ash_ghoul", "kibr"]

const COMPS := {
	"balanced (nuk/brk/tank/heal)": ["bram", "echo", "brand", "aria"],
	"no healer": ["bram", "echo", "brand", "echo"],
	"no tank": ["bram", "echo", "aria", "echo"],
	"all offense": ["bram", "bram", "echo", "echo"],
	"turtle (2 tank / 2 heal)": ["brand", "brand", "aria", "aria"],
}

const ENCOUNTERS := {
	"patrol": ["whisperling", "shadow_vermin", "ash_ghoul"],
	"boss":   ["whisperling", "kibr", "whisperling"],
}

var units := {}


func _initialize() -> void:
	for id in UNIT_IDS:
		units[id] = load("res://data/units/%s.tres" % id)

	print("%d runs per cell | comp -> win%% / avg turns / avg surviving team HP%% (wins only)" % RUNS)
	for encounter_name in ENCOUNTERS:
		print("\n=== ENCOUNTER: %s ===" % encounter_name)
		for comp_name in COMPS:
			var wins := 0
			var stalemates := 0
			var turn_sum := 0
			var hp_sum := 0.0
			for i in RUNS:
				var r := _run_battle(COMPS[comp_name], ENCOUNTERS[encounter_name])
				if r.victory:
					wins += 1
					hp_sum += r.team_hp
				if r.stalemate:
					stalemates += 1
				turn_sum += r.turns
			var win_pct := 100.0 * wins / RUNS
			var avg_hp := (100.0 * hp_sum / wins) if wins > 0 else 0.0
			var stale_note := "  [%d stalemates]" % stalemates if stalemates > 0 else ""
			print("  %-30s win %5.1f%%  turns %5.1f  hp %5.1f%%%s" % [
				comp_name, win_pct, float(turn_sum) / RUNS, avg_hp, stale_note])
	quit(0)


func _run_battle(comp_ids: Array, enemy_ids: Array) -> Dictionary:
	var mgr := BattleManager.new()
	mgr.auto_mode = true
	var out := {"victory": false, "turns": 0, "team_hp": 0.0, "stalemate": false}
	mgr.battle_ended.connect(func(v: bool) -> void: out["victory"] = v)
	var player_data: Array = []
	for id in comp_ids:
		player_data.append(units[id])
	var enemy_data: Array = []
	for id in enemy_ids:
		enemy_data.append(units[id])
	mgr.setup(player_data, enemy_data)
	var steps := 0
	while not mgr.ended and steps < STEP_CAP:
		mgr.step()
		steps += 1
	out["turns"] = steps
	out["stalemate"] = not mgr.ended
	var frac := 0.0
	for u: BattleUnit in mgr.players:
		frac += float(u.hp) / u.max_hp
	out["team_hp"] = frac / mgr.players.size()
	mgr.free()
	return out
