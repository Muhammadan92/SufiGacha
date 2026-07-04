extends SceneTree
## ECONOMY & ENGAGEMENT SIMULATOR — the canonical tuning tool (ECONOMY_TUNING.md).
## Models 90-day player careers against the FULL current game plus the GDD
## §9.3 revenue roadmap: token packs, monthly pass, season pass, cosmetics
## catalog, and content cadence (new heroes). Ends with a BLENDED projection
## per 1,000 installs under a documented population-mix assumption.
##
## Deterministic combat (GDD §4.4) => battle outcomes cached as a pure
## function of (stage, level, mastery). Team fixed to starters (conservative
## power floor; purchases count for collection/revenue, not combat).
## Run:  godot --headless --path . -s res://tests/simulate_economy.gd

const DAYS := 90
## GDD §6.1 staggered release: valleys 1-4 at launch, 5/6/7 monthly.
const VALLEY_RELEASE_DAY := { 1: 0, 2: 0, 3: 0, 4: 0, 5: 30, 6: 60, 7: 90 }
const TEAM := ["bram", "echo", "brand", "aria"]
const LEVEL_CAP := 60
const STEP_CAP := 900
const BOSS_TARGET_LEVELS := [8, 15, 22, 29, 36, 42, 48]
const XP_VALLEY_BONUS := 0.5

# --- engagement assumptions (ECONOMY_TUNING.md §2) ---
const SECONDS_PER_TURN := 0.9
const MENU_SECONDS_PER_RUN := 25.0
const DAILY_OVERHEAD_MINUTES := 3.0
const MAX_MINARET_CLIMBS_PER_DAY := 6  # session-limit model, not a game rule

# --- economy constants (mirror game_state.gd / GDD §9) ---
const UNIT_PRICES := { 3: ["marks", 300], 4: ["seals", 10], 5: ["sigils", 6] }
const SCROLL_COST := 60
const STAR_MARKS := 20
const STAR_SEALS := 1
const MARKS_RESERVE := 500

# --- revenue roadmap (GDD §9.3) ---
const PACKS := {
	"sigils": [[6, 66.0], [3, 33.0], [1, 12.0]],
	"seals": [[10, 18.0]],
	"marks": [[1000, 5.0]],
}
const PASS_PRICE_MONTHLY := 4.99
const PASS_DAILY := { "marks": 15, "seals": 1 }
const PASS_SIGIL_EVERY_DAYS := 10
const SEASON_PASS_PRICE := 9.99
const SEASON_GRANTS := { "marks": 300, "seals": 2, "sigils": 1, "scrolls": 5 }
const COSMETIC_AVG_PRICE := 6.0
const COSMETICS_PER_MONTH := 3     # content cadence (GDD §9.3.1)
const NEW_HERO_EVERY_DAYS := 15    # 2 heroes/month, Luminary-priced

## Profiles. budget = $/30d on TOKEN PACKS (passes/cosmetics are separate,
## deliberate purchases). cosmetics: items bought per month (-1 = all).
const PROFILES := {
	"f2p casual":    { "breath": 80,  "budget": 0.0,     "pass": false, "season": false, "cosmetics": 0 },
	"f2p hardcore":  { "breath": 200, "budget": 0.0,     "pass": false, "season": false, "cosmetics": 0 },
	"pass holder":   { "breath": 110, "budget": 0.0,     "pass": true,  "season": false, "cosmetics": 0 },
	"light spender": { "breath": 110, "budget": 15.0,    "pass": true,  "season": true,  "cosmetics": 1 },
	"completionist": { "breath": 200, "budget": 99999.0, "pass": true,  "season": true,  "cosmetics": -1 },
}

## Population mix per 1,000 installs — PLACEHOLDER conversion assumptions
## (~4.5% payers, genre-plausible); replace with real analytics at soft
## launch (ECONOMY_TUNING.md §7).
const MIX := {
	"f2p casual": 800, "f2p hardcore": 155,
	"pass holder": 20, "light spender": 20, "completionist": 5,
}

const DESIRES := [
	"sage", "vale", "gale", "isla", "lucia",
	"seren", "rowan", "ansel",
	"flint", "dylan", "sol",
]

var db: Node
var battle_cache := {}


func _initialize() -> void:
	db = root.get_node_or_null("Db")
	if db == null:
		db = preload("res://scripts/systems/database.gd").new()
		db.name = "Db"
		root.add_child(db)
	db.reload()
	var stages := _build_campaign()
	print("ECONOMY SIM w/ REVENUE ROADMAP — %d days | cadence: hero/%dd, %d cosmetics/mo, season pass $%.2f" % [
		DAYS, NEW_HERO_EVERY_DAYS, COSMETICS_PER_MONTH, SEASON_PASS_PRICE])
	var results := {}
	for profile_name in PROFILES:
		results[profile_name] = _run_career(profile_name, PROFILES[profile_name], stages)
	_print_blended(results)
	quit(0)


# --- campaign construction ---------------------------------------------------------

func _level_mult(l: int) -> float:
	return 1.0 + 0.04 * (l - 1)


func _expected_level(v: int, i: int) -> int:
	var prev: float = 1.0 if v == 1 else float(BOSS_TARGET_LEVELS[v - 2])
	return int(round(lerpf(prev, float(BOSS_TARGET_LEVELS[v - 1]), float(i) / 11.0)))


func _build_campaign() -> Array:
	var out: Array = []
	for s: StageData in db.stage_order:
		out.append({
			"key": String(s.id), "boss": s.index == 12, "valley": s.valley,
			"enemy_ids": s.enemy_ids, "scale": s.enemy_scale, "breath": s.breath_cost,
			"xp": s.xp_reward, "marks": s.marks_reward, "turn_target": s.turn_target,
			"fc_seals": s.first_clear_seals, "fc_sigils": s.first_clear_sigils,
		})
	var sets := [["whisperling", "shadow_vermin"], ["shadow_vermin", "ash_ghoul"],
		["whisperling", "whisperling", "ash_ghoul"], ["ash_ghoul", "ash_ghoul", "shadow_vermin"],
		["whisperling", "ash_ghoul", "shadow_vermin"], ["whisperling", "whisperling", "whisperling"]]
	for v in range(2, 8):
		for i in 12:
			var is_boss := i == 11
			var pressure := 1.0 if is_boss else 0.72 + 0.28 * float(i) / 11.0
			out.append({
				"key": "v%d_s%02d" % [v, i + 1], "boss": is_boss, "valley": v,
				"enemy_ids": ["whisperling", "kibr", "whisperling"] if is_boss else sets[i % sets.size()],
				"scale": _level_mult(_expected_level(v, i)) * pressure,
				"breath": 10 if is_boss else (6 if i < 6 else 8),
				"xp": int((26 + 6 * i) * (1.0 + XP_VALLEY_BONUS * (v - 1))),
				"marks": 50 if is_boss else (20 if i < 6 else 30),
				"turn_target": (150 if is_boss else 30 + 4 * i) + 6 * v,
				"fc_seals": 3 if is_boss else (2 if i == 10 else 1),
				"fc_sigils": 2 if is_boss else 0,
			})
	return out


# --- deterministic battle with cache -------------------------------------------------

func _battle(stage_key: String, enemy_ids: Array, scale: float, level: int, mastery: int) -> Dictionary:
	var cache_key := "%s|%d|%d" % [stage_key, level, mastery]
	if battle_cache.has(cache_key):
		return battle_cache[cache_key]
	var mult := _level_mult(level)
	var smult := 1.0 + 0.06 * mastery
	var team_data: Array = []
	for id in TEAM:
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
	mgr.setup(team_data, enemy_data, [mult, mult, mult, mult], scale, [smult, smult, smult, smult])
	var steps := 0
	while not mgr.ended and steps < STEP_CAP:
		mgr.step()
		steps += 1
	mgr.free()
	var result := { "win": out.get("v", false), "turns": steps, "deaths": deaths }
	battle_cache[cache_key] = result
	return result


# --- career -----------------------------------------------------------------------------

func _run_career(profile_name: String, profile: Dictionary, stages: Array) -> Dictionary:
	var level := 1
	var xp := 0
	var mastery := 0
	var scrolls := 0
	var marks := 200
	var seals := 0
	var sigils := 0
	var next_idx := 0
	var stage_stars := {}
	var diff_frontier := {}  # "hard"/"nm" -> stages cleared in that chain
	var minaret := 0
	var owned_desires := 0
	var total_desires := DESIRES.size()
	var rev := { "packs": 0.0, "pass": 0.0, "season": 0.0, "cosmetics": 0.0 }
	var budget_left: float = profile["budget"]
	var minutes_total := 0.0
	var campaign_day := -1
	var snapshots := {}

	for day in range(1, DAYS + 1):
		# --- monthly beats ---
		if day % 30 == 1:
			budget_left = profile["budget"]
			if profile["pass"]:
				rev["pass"] += PASS_PRICE_MONTHLY
			if profile["season"]:
				rev["season"] += SEASON_PASS_PRICE
				marks += SEASON_GRANTS["marks"]
				seals += SEASON_GRANTS["seals"]
				sigils += SEASON_GRANTS["sigils"]
				scrolls += SEASON_GRANTS["scrolls"]
			var n_cosmetics: int = COSMETICS_PER_MONTH if profile["cosmetics"] < 0 else mini(profile["cosmetics"], COSMETICS_PER_MONTH)
			rev["cosmetics"] += n_cosmetics * COSMETIC_AVG_PRICE
		if profile["pass"]:
			marks += PASS_DAILY["marks"]
			seals += PASS_DAILY["seals"]
			if day % PASS_SIGIL_EVERY_DAYS == 0:
				sigils += 1
		if day % NEW_HERO_EVERY_DAYS == 0:
			total_desires += 1  # content cadence: a new Luminary ships

		var minutes_today := DAILY_OVERHEAD_MINUTES
		var breath: int = profile["breath"]
		var fail_streak := 0

		# 0) Daily loop income (policy-modeled, mirrors game_state):
		# Deeds: 3 dailies (+20 Marks each), 3 weeklies (+1 Seal each);
		# free season track per ~30d: +100 Marks, 1 Seal, 2 Scrolls.
		marks += 60
		if day % 7 == 0:
			seals += 3
		if day % 30 == 15:
			marks += 100
			seals += 1
			scrolls += 2
		# Sanctum: 2 runs/day once unlocked (stage 1-4): 20 Breath ->
		# 2 Scrolls + 80 Marks + 40 team XP, ~2.5 min.
		if next_idx >= 4 and breath >= 20:
			breath -= 20
			scrolls += 2
			marks += 80
			var sres := _grant_xp(level, xp, 40)
			level = sres[0]
			xp = sres[1]
			minutes_today += 2.5

		# 1) Campaign push (frontier gated by the release calendar)
		while next_idx < stages.size():
			var target: Dictionary = stages[next_idx]
			if day < int(VALLEY_RELEASE_DAY.get(int(target["valley"]), 0)):
				break
			var farm_mode := fail_streak >= 2
			var stage: Dictionary = stages[maxi(0, next_idx - 1)] if farm_mode and next_idx > 0 else target
			if breath < int(stage["breath"]):
				break
			breath -= int(stage["breath"])
			var r := _battle(stage["key"], stage["enemy_ids"], stage["scale"], level, mastery)
			minutes_today += (r["turns"] * SECONDS_PER_TURN + MENU_SECONDS_PER_RUN) / 60.0
			if r["win"]:
				marks += int(stage["marks"])
				var res := _grant_xp(level, xp, int(stage["xp"]))
				if res[0] > level:
					fail_streak = 0
				level = res[0]
				xp = res[1]
				if not farm_mode:
					var earned := 1
					if r["deaths"] == 0:
						earned += 1
					if r["turns"] <= int(stage["turn_target"]):
						earned += 1
					var prev: int = int(stage_stars.get(next_idx, 0))
					if earned > prev:
						stage_stars[next_idx] = earned
						marks += STAR_MARKS * (earned - prev)
						seals += STAR_SEALS * (earned - prev)
					seals += int(stage["fc_seals"])
					sigils += int(stage["fc_sigils"])
					next_idx += 1
					fail_streak = 0
					if next_idx >= stages.size():
						campaign_day = day
			elif not farm_mode:
				fail_streak += 1

		# 1b) Leftover Breath: farm best cleared stage
		if next_idx > 0:
			var farm: Dictionary = stages[next_idx - 1]
			while breath >= int(farm["breath"]):
				breath -= int(farm["breath"])
				var fr := _battle(farm["key"], farm["enemy_ids"], farm["scale"], level, mastery)
				minutes_today += (fr["turns"] * SECONDS_PER_TURN + MENU_SECONDS_PER_RUN) / 60.0
				if fr["win"]:
					marks += int(farm["marks"])
					var fres := _grant_xp(level, xp, int(farm["xp"]))
					level = fres[0]
					xp = fres[1]

		# 1c) Difficulty re-clears (GDD §6.1): once the normal campaign is
		# done, push the hard chain, then nightmare (scale x2.2 / x3.2;
		# marks x2/x3; +1 Sigil per boss first-clear per tier).
		if next_idx >= stages.size():
			for dtier in [["hard", 2.2, 2], ["nm", 3.2, 3]]:
				var dkey: String = dtier[0]
				var dfrontier: int = int(diff_frontier.get(dkey, 0))
				if dkey == "nm" and int(diff_frontier.get("hard", 0)) < stages.size():
					break
				var dfails := 0
				while dfrontier < stages.size() and dfails < 2:
					var dstage: Dictionary = stages[dfrontier]
					if day < int(VALLEY_RELEASE_DAY.get(int(dstage["valley"]), 0)):
						break
					if breath < int(dstage["breath"]):
						break
					breath -= int(dstage["breath"])
					var dr := _battle("%s_%s" % [dkey, dstage["key"]], dstage["enemy_ids"],
						float(dstage["scale"]) * float(dtier[1]), level, mastery)
					minutes_today += (dr["turns"] * SECONDS_PER_TURN + MENU_SECONDS_PER_RUN) / 60.0
					if dr["win"]:
						marks += int(dstage["marks"]) * int(dtier[2])
						seals += int(dstage["fc_seals"]) * int(dtier[2])
						if dstage["boss"]:
							sigils += 1
						var dres := _grant_xp(level, xp, int(dstage["xp"]))
						level = dres[0]
						xp = dres[1]
						dfrontier += 1
					else:
						dfails += 1
				diff_frontier[dkey] = dfrontier

		# 2b) Weekly Vice Trial: attempt tiers 1..5 once per week, stop at
		# first loss (rewards: marks/seals/scrolls, no Sigils).
		if day % 7 == 1 and next_idx >= 12:
			var trial_rewards := [[40, 0, 0], [60, 1, 0], [0, 2, 1], [0, 3, 2], [100, 4, 3]]
			for tier in 5:
				var tr := _battle("trial_t%d" % (tier + 1), ["ash_ghoul", "kibr", "ash_ghoul"],
					[2.0, 2.6, 3.2, 3.8, 4.5][tier], level, mastery)
				minutes_today += (tr["turns"] * SECONDS_PER_TURN + MENU_SECONDS_PER_RUN) / 60.0
				if not tr["win"]:
					break
				marks += trial_rewards[tier][0]
				seals += trial_rewards[tier][1]
				scrolls += trial_rewards[tier][2]

		# 2) The Minaret
		if next_idx > 5:
			for climb in MAX_MINARET_CLIMBS_PER_DAY:
				var floor: int = minaret + 1
				var m_ids: Array = ["kibr"] if floor % 10 == 0 else \
					[["whisperling", "shadow_vermin"], ["shadow_vermin", "ash_ghoul"],
					["whisperling", "whisperling", "ash_ghoul"],
					["ash_ghoul", "ash_ghoul", "shadow_vermin"],
					["whisperling", "ash_ghoul", "shadow_vermin", "whisperling"]][(floor - 1) % 5]
				var mr := _battle("minaret_f%d" % floor, m_ids, 0.6 + 0.07 * floor, level, mastery)
				minutes_today += (mr["turns"] * SECONDS_PER_TURN + MENU_SECONDS_PER_RUN) / 60.0
				if not mr["win"]:
					break
				minaret = floor
				marks += 30 + 5 * floor
				if floor % 5 == 0:
					seals += 2
				if floor % 10 == 0:
					sigils += 1
				var res2 := _grant_xp(level, xp, 10 + 2 * floor)
				level = res2[0]
				xp = res2[1]

		# 3) Spend tokens on desires; buy at most one pack/day if blocked
		while owned_desires < total_desires:
			var price: Array
			if owned_desires < DESIRES.size():
				price = UNIT_PRICES[db.units[DESIRES[owned_desires]].rarity]
			else:
				price = UNIT_PRICES[5]  # cadence heroes are Luminaries
			var have: int = marks if price[0] == "marks" else (seals if price[0] == "seals" else sigils)
			if have >= int(price[1]):
				match price[0]:
					"marks": marks -= int(price[1])
					"seals": seals -= int(price[1])
					"sigils": sigils -= int(price[1])
				owned_desires += 1
				continue
			var bought := false
			if budget_left > 0.0:
				for pack in PACKS[price[0]]:
					if pack[1] <= budget_left:
						budget_left -= pack[1]
						rev["packs"] += pack[1]
						match price[0]:
							"marks": marks += int(pack[0])
							"seals": seals += int(pack[0])
							"sigils": sigils += int(pack[0])
						bought = true
						break
			if not bought:
				break

		# 4) Mastery from surplus Marks
		while marks - MARKS_RESERVE >= SCROLL_COST:
			marks -= SCROLL_COST
			scrolls += 1
		while mastery < 5 and scrolls >= (mastery + 1) * 4:
			scrolls -= (mastery + 1) * 4
			mastery += 1

		minutes_total += minutes_today
		if day == 30 or day == 60 or day == 90:
			snapshots[day] = {
				"level": level, "campaign": next_idx, "minaret": minaret,
				"desires": owned_desires, "total_desires": total_desires,
				"revenue": rev["packs"] + rev["pass"] + rev["season"] + rev["cosmetics"],
				"min_per_day": minutes_total / day,
			}

	print("\n=== %s (%d Breath/day%s%s%s) ===" % [
		profile_name, profile["breath"],
		", pass" if profile["pass"] else "",
		", season" if profile["season"] else "",
		", $%.0f/mo packs" % profile["budget"] if profile["budget"] > 0.0 and profile["budget"] < 9999.0 else ""])
	print("  campaign clear: %s" % ("day %d" % campaign_day if campaign_day > 0 else "in progress at day %d (staggered)" % DAYS))
	for d in [30, 60, 90]:
		var s: Dictionary = snapshots[d]
		print("  day %-3d Lv%-3d camp %2d/84 minaret %-3d heroes %2d/%-2d  %5.1f min/day  revenue $%7.2f" % [
			d, s["level"], s["campaign"], s["minaret"], s["desires"], s["total_desires"],
			s["min_per_day"], s["revenue"]])
	print("  lines: packs $%.2f | monthly pass $%.2f | season pass $%.2f | cosmetics $%.2f" % [
		rev["packs"], rev["pass"], rev["season"], rev["cosmetics"]])
	return snapshots


func _print_blended(results: Dictionary) -> void:
	print("\n=== BLENDED PROJECTION per 1,000 installs (mix is a placeholder — replace with soft-launch analytics) ===")
	print("  mix: %s" % str(MIX))
	for d in [30, 60, 90]:
		var total := 0.0
		for profile_name in MIX:
			total += results[profile_name][d]["revenue"] * MIX[profile_name]
		print("  day %-3d  revenue/1k installs: $%8.2f   (ARPU $%.3f/player, $%.3f/player/month)" % [
			d, total, total / 1000.0, total / 1000.0 / (d / 30.0)])
	print("  NOTE: no churn modeled — treat as revenue per 1k RETAINED players; real blended revenue = this x retention curve.")


func _grant_xp(level: int, xp: int, amount: int) -> Array:
	xp += amount
	while level < LEVEL_CAP and xp >= 25 * level:
		xp -= 25 * level
		level += 1
	return [level, xp]
