extends SceneTree
## ECONOMY & ENGAGEMENT SIMULATOR — the canonical tuning tool (ECONOMY_TUNING.md).
## Supersedes simulate_progression.gd: models 90-day player careers against the
## FULL current game — campaign (v1 authored, v2-7 synthesized), star
## objectives, the Minaret, mastery spending — plus spender profiles with
## purchase policies, producing time-spent and revenue per profile.
##
## Deterministic combat (GDD §4.4) => battle outcome is a pure function of
## (stage, team level, mastery); outcomes are cached, so careers run fast.
## Team is fixed to the starters (conservative floor — bought heroes count
## for collection/spend modeling, not power).
## Run:  godot --headless --path . -s res://tests/simulate_economy.gd

const DAYS := 90
## GDD §6.1 staggered release: valleys 1-4 at launch, 5/6/7 monthly.
const VALLEY_RELEASE_DAY := { 1: 0, 2: 0, 3: 0, 4: 0, 5: 30, 6: 60, 7: 90 }
const TEAM := ["bram", "echo", "brand", "aria"]
const LEVEL_CAP := 60
const STEP_CAP := 900
const BOSS_TARGET_LEVELS := [8, 15, 22, 29, 36, 42, 48]
const XP_VALLEY_BONUS := 0.5

# --- engagement assumptions (documented in ECONOMY_TUNING.md §2) ---
const SECONDS_PER_TURN := 0.9        # manual-ish pacing incl. thinking
const MENU_SECONDS_PER_RUN := 25.0
const DAILY_OVERHEAD_MINUTES := 3.0
const MAX_MINARET_CLIMBS_PER_DAY := 6  # session-limit model, not a game rule

# --- economy constants (mirror game_state.gd / GDD §9) ---
const UNIT_PRICES := { 3: ["marks", 300], 4: ["seals", 10], 5: ["sigils", 6] }
const SCROLL_COST := 60
const STAR_MARKS := 20
const STAR_SEALS := 1
const MARKS_RESERVE := 500  # keep this much before buying scrolls

# --- real-money packs (GDD §9.3) ---
const PACKS := {
	"sigils": [[6, 66.0], [3, 33.0], [1, 12.0]],
	"seals": [[10, 18.0]],
	"marks": [[1000, 5.0]],
}
const PASS_PRICE_MONTHLY := 5.0
const PASS_DAILY := { "marks": 15, "seals": 1 }
const PASS_SIGIL_EVERY_DAYS := 10

## Who we model. budget = max real-money $/30 days on packs (pass separate).
const PROFILES := {
	"f2p casual":    { "breath": 80,  "budget": 0.0,     "pass": false },
	"f2p hardcore":  { "breath": 200, "budget": 0.0,     "pass": false },
	"pass holder":   { "breath": 110, "budget": 0.0,     "pass": true },
	"light spender": { "breath": 110, "budget": 15.0,    "pass": true },
	"completionist": { "breath": 200, "budget": 99999.0, "pass": true },
}

## Acquisition desire order (Luminaries, then Wayfarers, then Novices).
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
	print("ECONOMY & ENGAGEMENT SIM — %d days | %d campaign stages + Minaret | prices: L=6 sigils W=10 seals N=300 marks" % [
		DAYS, stages.size()])
	for profile_name in PROFILES:
		_run_career(profile_name, PROFILES[profile_name], stages)
	quit(0)


# --- campaign construction (authored v1 + synthesized v2-7) ---------------------

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


# --- deterministic battle with cache ---------------------------------------------

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


# --- career ------------------------------------------------------------------------

func _run_career(profile_name: String, profile: Dictionary, stages: Array) -> void:
	var level := 1
	var xp := 0
	var mastery := 0            # uniform team mastery tier (0..5)
	var scrolls := 0
	var marks := 200
	var seals := 0
	var sigils := 0
	var next_idx := 0           # campaign frontier
	var stage_stars := {}       # idx -> best stars
	var minaret := 0
	var owned_desires := 0      # units acquired from DESIRES, in order
	var spent := 0.0
	var pass_spent := 0.0
	var budget_left: float = profile["budget"]
	var minutes_total := 0.0
	var dry_days := 0
	var campaign_day := -1
	var snapshots := {}

	for day in range(1, DAYS + 1):
		if day % 30 == 1:
			budget_left = profile["budget"]  # monthly budget refresh
			if profile["pass"]:
				pass_spent += PASS_PRICE_MONTHLY
		if profile["pass"]:
			marks += PASS_DAILY["marks"]
			seals += PASS_DAILY["seals"]
			if day % PASS_SIGIL_EVERY_DAYS == 0:
				sigils += 1

		var minutes_today := DAILY_OVERHEAD_MINUTES
		var progressed := false
		var breath: int = profile["breath"]
		var fail_streak := 0

		# 1) Campaign push / farm (frontier gated by the release calendar)
		while next_idx < stages.size():
			var target: Dictionary = stages[next_idx]
			if day < int(VALLEY_RELEASE_DAY.get(int(target["valley"]), 0)):
				break  # next valley hasn't shipped yet
			var farm_mode := fail_streak >= 2
			var stage: Dictionary = stages[maxi(0, next_idx - 1)] if farm_mode and next_idx > 0 else target
			if breath < int(stage["breath"]):
				break
			breath -= int(stage["breath"])
			var r := _battle(stage["key"], stage["enemy_ids"], stage["scale"], level, mastery)
			minutes_today += (r["turns"] * SECONDS_PER_TURN + MENU_SECONDS_PER_RUN) / 60.0
			if r["win"]:
				marks += int(stage["marks"])
				var gained_xp: int = int(stage["xp"])
				var res := _grant_xp(level, xp, gained_xp)
				if res[0] > level:
					fail_streak = 0
				level = res[0]
				xp = res[1]
				if not farm_mode:
					# stars (deterministic — computed exactly)
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
					progressed = true
					fail_streak = 0
					if next_idx >= stages.size():
						campaign_day = day
			else:
				if not farm_mode:
					fail_streak += 1

		# 1b) Leftover Breath: farm the best cleared stage (marks + xp)
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

		# 2) The Minaret (free, unlocked after 1-6): climb until first loss
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
				progressed = true

		# 3) Spend tokens on desires (all profiles), then real money (spenders)
		while owned_desires < DESIRES.size():
			var want: UnitData = db.units[DESIRES[owned_desires]]
			var price: Array = UNIT_PRICES[want.rarity]
			var have: int = marks if price[0] == "marks" else (seals if price[0] == "seals" else sigils)
			if have >= int(price[1]):
				match price[0]:
					"marks": marks -= int(price[1])
					"seals": seals -= int(price[1])
					"sigils": sigils -= int(price[1])
				owned_desires += 1
				progressed = true
				continue
			# short — consider buying ONE pack today if budget allows
			var bought := false
			if budget_left > 0.0:
				for pack in PACKS[price[0]]:
					if pack[1] <= budget_left:
						budget_left -= pack[1]
						spent += pack[1]
						match price[0]:
							"marks": marks += int(pack[0])
							"seals": seals += int(pack[0])
							"sigils": sigils += int(pack[0])
						bought = true
						break
			if not bought:
				break

		# 4) Mastery: convert excess marks to scrolls, scrolls to team mastery
		while marks - MARKS_RESERVE >= SCROLL_COST:
			marks -= SCROLL_COST
			scrolls += 1
		while mastery < 5 and scrolls >= (mastery + 1) * 4:  # whole team per tier
			scrolls -= (mastery + 1) * 4
			mastery += 1
			progressed = true

		minutes_total += minutes_today
		if not progressed:
			dry_days += 1
		if day == 30 or day == 60 or day == 90:
			snapshots[day] = {
				"level": level, "campaign": next_idx, "minaret": minaret,
				"mastery": mastery, "desires": owned_desires,
				"spent": spent + pass_spent, "min_per_day": minutes_total / day,
				"sigils": sigils,
			}

	print("\n=== %s (%d Breath/day, budget $%.0f/mo%s) ===" % [
		profile_name, profile["breath"], profile["budget"], ", pass" if profile["pass"] else ""])
	print("  campaign clear: %s | dry days (no progression): %d/%d" % [
		"day %d" % campaign_day if campaign_day > 0 else "NOT in %d days" % DAYS, dry_days, DAYS])
	for d in [30, 60, 90]:
		var s: Dictionary = snapshots[d]
		print("  day %-3d Lv%-3d camp %d/84  minaret %-3d mastery %d  heroes bought %d/%d  %5.1f min/day  revenue $%.2f" % [
			d, s["level"], s["campaign"], s["minaret"], s["mastery"],
			s["desires"], DESIRES.size(), s["min_per_day"], s["spent"]])


func _grant_xp(level: int, xp: int, amount: int) -> Array:
	xp += amount
	while level < LEVEL_CAP and xp >= 25 * level:
		xp -= 25 * level
		level += 1
	return [level, xp]
