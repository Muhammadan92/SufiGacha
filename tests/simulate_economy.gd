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
## Game constants read straight from the source (never copy them here —
## a hand-copied table hid the tier-30 bug the rf review found).
const GS := preload("res://scripts/systems/game_state.gd")
const SCROLL_COST := GS.SCROLL_COST_MARKS
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
# Season pass rewards come from GS.PASS_FREE / GS.PASS_PAID via simulated
# tier progression — no more lump-sum grants (they hid tier-reachability bugs).
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

## Retention scenarios (fraction of installs still active on day D) —
## genre-benchmark PLACEHOLDERS until soft-launch analytics. Survival is
## log-linearly interpolated between anchors. Payers churn less than f2p in
## reality; applying one curve to all profiles is conservative for revenue.
const RETENTION := {
	"pessimistic": { 1: 0.30, 7: 0.08, 30: 0.025, 90: 0.010 },
	"baseline":    { 1: 0.40, 7: 0.14, 30: 0.060, 90: 0.030 },
	"optimistic":  { 1: 0.50, 7: 0.20, 30: 0.100, 90: 0.055 },
}


static func _survival(day: int, curve: Dictionary) -> float:
	if day <= 0:
		return 1.0
	var anchors := [0, 1, 7, 30, 90]
	var values := [1.0, curve[1], curve[7], curve[30], curve[90]]
	for i in range(1, anchors.size()):
		if day <= anchors[i]:
			var t := (log(float(day) + 0.0001) - log(float(anchors[i - 1]) + 0.0001)) \
				/ (log(float(anchors[i]) + 0.0001) - log(float(anchors[i - 1]) + 0.0001))
			return lerpf(values[i - 1], values[i], clampf(t, 0.0, 1.0))
	return curve[90]

const DESIRES := [
	"sage", "vale", "gale", "isla", "lucia",
	"seren", "rowan", "ansel", "wren", "torrin", "ember_r", "lark", "marin", "hale", "rae",
	"flint", "dylan", "sol", "peal", "cole", "reed", "brooke", "june", "dawn",
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


## All 7 valleys are AUTHORED as of Phase 3 — the sim reads real stage data.
## (The old synthetic v2-7 generator seeded their authored curves and is gone.)
func _build_campaign() -> Array:
	var out: Array = []
	for s: StageData in db.stage_order:
		out.append({
			"key": String(s.id), "boss": s.index == 12, "valley": s.valley,
			"enemy_ids": s.enemy_ids, "scale": s.enemy_scale, "breath": s.breath_cost,
			"xp": s.xp_reward, "marks": s.marks_reward, "turn_target": s.turn_target,
			"fc_seals": s.first_clear_seals, "fc_sigils": s.first_clear_sigils,
		})
	assert(out.size() == 84, "expected the full authored campaign")
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
	var waymarks_done := {}
	var season_xp := 0
	var season_tier := 0
	var minaret := 0
	var owned_desires := 0
	var total_desires := DESIRES.size()
	var rev := { "packs": 0.0, "pass": 0.0, "season": 0.0, "cosmetics": 0.0 }
	var budget_left: float = profile["budget"]
	var minutes_total := 0.0
	var campaign_day := -1
	var snapshots := {}
	var daily_rev: Array = []       # revenue delta per day (retention weighting)
	var dry_days_progress := 0      # days with NO progression event (churn risk)
	var first_dry_day := -1

	for day in range(1, DAYS + 1):
		var rev_before: float = rev["packs"] + rev["pass"] + rev["season"] + rev["cosmetics"]
		var owned_before := owned_desires
		var minaret_before := minaret
		var frontier_before := next_idx
		var mastery_before := mastery
		var diff_before: int = int(diff_frontier.get("hard", 0)) + int(diff_frontier.get("nm", 0))
		# --- monthly beats ---
		if day % 30 == 1:
			budget_left = profile["budget"]
			if profile["pass"]:
				rev["pass"] += PASS_PRICE_MONTHLY
			if profile["season"]:
				rev["season"] += SEASON_PASS_PRICE
			season_xp = 0
			season_tier = 0
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

		# 0) Daily loop income, driven by the game's own constants.
		# Deeds (assumes full completion — optimistic-consistent):
		marks += 3 * GS.DEED_MARKS_DAILY
		season_xp += 3 * GS.DEED_XP_DAILY
		if day % 7 == 0:
			seals += 3 * GS.DEED_SEALS_WEEKLY
			season_xp += 3 * GS.DEED_XP_WEEKLY
		# Season tier progression: the REAL XP thresholds and reward tables.
		while season_tier < GS.SEASON_TIERS and season_xp >= GS.TIER_XP * (season_tier + 1):
			season_tier += 1
			for tbl in ([GS.PASS_FREE, GS.PASS_PAID] if profile["season"] else [GS.PASS_FREE]):
				var g: Dictionary = tbl.get(season_tier, {})
				marks += g.get("marks", 0)
				seals += g.get("seals", 0)
				sigils += g.get("sigils", 0)
				scrolls += g.get("scrolls", 0)
		if day == 30 and season_tier < GS.SEASON_TIERS:
			print("  !! season tier only %d/%d by day 30 — pass top unreachable" % [season_tier, GS.SEASON_TIERS])
		# Sanctum: runs/day once unlocked (stage 1-4).
		var sanctum_cost: int = GS.SANCTUM_RUNS_PER_DAY * GS.SANCTUM_BREATH_COST
		if next_idx >= 4 and breath >= sanctum_cost:
			breath -= sanctum_cost
			scrolls += GS.SANCTUM_RUNS_PER_DAY * GS.SANCTUM_REWARD_SCROLLS
			marks += GS.SANCTUM_RUNS_PER_DAY * GS.SANCTUM_REWARD_MARKS
			var sres := _grant_xp(level, xp, GS.SANCTUM_RUNS_PER_DAY * GS.SANCTUM_REWARD_XP)
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
						marks += GS.STAR_REWARD_MARKS * (earned - prev)
						seals += GS.STAR_REWARD_SEALS * (earned - prev)
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
				var mr := _battle("minaret_f%d" % floor, m_ids,
					GS.MINARET_SCALE_BASE + GS.MINARET_SCALE_PER_FLOOR * floor, level, mastery)
				minutes_today += (mr["turns"] * SECONDS_PER_TURN + MENU_SECONDS_PER_RUN) / 60.0
				if not mr["win"]:
					break
				minaret = floor
				marks += GS.MINARET_MARKS_BASE + GS.MINARET_MARKS_PER_FLOOR * floor
				if floor % GS.MINARET_SEALS_EVERY == 0:
					seals += 2
				if floor % GS.MINARET_SIGIL_EVERY == 0:
					sigils += 1
				var res2 := _grant_xp(level, xp, GS.MINARET_XP_BASE + GS.MINARET_XP_PER_FLOOR * floor)
				level = res2[0]
				xp = res2[1]

		# 3) Spend tokens on desires; buy at most one pack/day if blocked
		while owned_desires < total_desires:
			var price: Array
			if owned_desires < DESIRES.size():
				var rar: int = db.units[DESIRES[owned_desires]].rarity
				price = [GS.UNIT_COSTS[rar]["currency"], GS.UNIT_COSTS[rar]["amount"]]
			else:
				price = [GS.UNIT_COSTS[5]["currency"], GS.UNIT_COSTS[5]["amount"]]  # cadence heroes are Luminaries
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

		# 5) Waymarks (mirrors game_state.WAYMARKS — keep in sync)
		var star_total := 0
		for v_ in stage_stars.values():
			star_total += int(v_)
		var wm_metrics := {
			"stars": star_total, "cleared": next_idx, "minaret": minaret,
			"mastery": mastery * 4, "roster": 4 + owned_desires,
		}
		for wm: Dictionary in GS.WAYMARKS:
			if waymarks_done.has(wm["id"]):
				continue
			if int(wm_metrics[wm["metric"]]) >= int(wm["at"]):
				waymarks_done[wm["id"]] = true
				marks += int(wm.get("marks", 0))
				seals += int(wm.get("seals", 0))
				sigils += int(wm.get("sigils", 0))

		minutes_total += minutes_today
		daily_rev.append(rev["packs"] + rev["pass"] + rev["season"] + rev["cosmetics"] - rev_before)
		var progressed := next_idx > frontier_before or minaret > minaret_before \
			or owned_desires > owned_before or mastery > mastery_before \
			or (int(diff_frontier.get("hard", 0)) + int(diff_frontier.get("nm", 0))) > diff_before
		if not progressed:
			dry_days_progress += 1
			if first_dry_day < 0:
				first_dry_day = day
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
	print("  churn-risk: %d days without a progression event (first: day %s)" % [
		dry_days_progress, str(first_dry_day) if first_dry_day > 0 else "none"])
	var result := snapshots.duplicate()
	result["daily_rev"] = daily_rev
	return result


func _print_blended(results: Dictionary) -> void:
	print("\n=== BLENDED PROJECTION per 1,000 RETAINED players (mix is a placeholder) ===")
	print("  mix: %s" % str(MIX))
	for d in [30, 60, 90]:
		var total := 0.0
		for profile_name in MIX:
			total += results[profile_name][d]["revenue"] * MIX[profile_name]
		print("  day %-3d  revenue/1k retained: $%8.2f   (ARPU $%.3f/player/month)" % [
			d, total, total / 1000.0 / (d / 30.0)])

	# Retention-weighted: expected revenue per INSTALL = sum over days of
	# survival(day) x that day's revenue delta, under each scenario curve.
	print("\n=== RETENTION-WEIGHTED per 1,000 INSTALLS (scenario curves — ECONOMY_TUNING.md §6c) ===")
	for scenario in RETENTION:
		var curve: Dictionary = RETENTION[scenario]
		var total := 0.0
		for profile_name in MIX:
			var daily: Array = results[profile_name]["daily_rev"]
			var expected := 0.0
			for i in daily.size():
				expected += _survival(i + 1, curve) * float(daily[i])
			total += expected * MIX[profile_name]
		print("  %-12s D1/D7/D30/D90 = %d/%d/%.1f/%.1f%%   90d revenue/1k installs: $%8.2f   (LTV $%.3f/install, ~$%.3f net of store fee)" % [
			scenario, curve[1] * 100, curve[7] * 100, curve[30] * 100, curve[90] * 100,
			total, total / 1000.0, total / 1000.0 * 0.85])


func _grant_xp(level: int, xp: int, amount: int) -> Array:
	xp += amount
	while level < LEVEL_CAP and xp >= 25 * level:
		xp -= 25 * level
		level += 1
	return [level, xp]
