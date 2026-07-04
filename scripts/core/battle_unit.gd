class_name BattleUnit
extends RefCounted
## Runtime state of one combatant. Pure state + stat math — all combat
## resolution and event emission happens in BattleManager.
## `stat_mult` scales base stats for character level / stage difficulty.

var data: UnitData
var is_player_side: bool
var stat_mult: float
## Mastery bonus from Teaching Scrolls (GDD §8): multiplies DAMAGE and HEAL
## effect output. 1.0 = untrained.
var skill_mult: float

var max_hp: int
var hp: int
var fervor: float = 0.0
var turn_meter: float = 0.0
var statuses: Array = []        # Array of StatusEffect
var cooldowns: Dictionary = {}  # skill id (StringName) -> turns remaining

const FERVOR_MAX := 100.0
const FERVOR_ON_HIT := 10.0


func _init(p_data: UnitData, p_player_side: bool, p_stat_mult: float = 1.0, p_skill_mult: float = 1.0) -> void:
	data = p_data
	is_player_side = p_player_side
	stat_mult = p_stat_mult
	skill_mult = p_skill_mult
	max_hp = maxi(1, int(data.max_hp * stat_mult))
	hp = max_hp


func is_alive() -> bool:
	return hp > 0


func _stat_mod(up_id: int, down_id: int) -> float:
	var mod := 1.0
	for s: StatusEffect in statuses:
		if s.id == up_id:
			mod += s.magnitude
		elif s.id == down_id:
			mod -= s.magnitude
	return maxf(mod, 0.1)


func atk() -> float:
	return data.atk * stat_mult * _stat_mod(Enums.StatusId.ATK_UP, Enums.StatusId.ATK_DOWN)


func def() -> float:
	return data.def * stat_mult * _stat_mod(Enums.StatusId.DEF_UP, Enums.StatusId.DEF_DOWN)


func spd() -> float:
	return data.spd * _stat_mod(Enums.StatusId.SPD_UP, Enums.StatusId.SPD_DOWN)


func has_status(id: int) -> bool:
	for s: StatusEffect in statuses:
		if s.id == id:
			return true
	return false


func status_magnitude(id: int) -> float:
	var best := 0.0
	for s: StatusEffect in statuses:
		if s.id == id:
			best = maxf(best, s.magnitude)
	return best


func add_status(id: int, turns: int, magnitude: float, stack_cap: float = 3.0) -> void:
	for s: StatusEffect in statuses:
		if s.id == id:
			s.turns_left = maxi(s.turns_left, turns)
			# Reapplication stacks magnitude up to stack_cap applications —
			# lets breakers stack DEF Down, and powers boss enrages
			# (Kibr's Swell of Pride ramps unbounded to punish stalling).
			s.magnitude = minf(s.magnitude + magnitude, magnitude * stack_cap)
			return
	statuses.append(StatusEffect.new(id, turns, magnitude))


## Consumes barrier absorb pools; returns the damage that gets through.
func absorb_with_barrier(amount: float) -> float:
	for s: StatusEffect in statuses:
		if s.id == Enums.StatusId.BARRIER and s.magnitude > 0.0 and amount > 0.0:
			var absorbed := minf(s.magnitude, amount)
			s.magnitude -= absorbed
			amount -= absorbed
	statuses = statuses.filter(func(s: StatusEffect) -> bool:
		return s.id != Enums.StatusId.BARRIER or s.magnitude > 0.0)
	return amount


## Removes all debuffs; returns how many were removed.
func remove_debuffs() -> int:
	var before := statuses.size()
	statuses = statuses.filter(func(s: StatusEffect) -> bool: return s.is_buff())
	return before - statuses.size()


## Removes all buffs (DISPEL — Envy steals blessings); returns count removed.
func remove_buffs() -> int:
	var before := statuses.size()
	statuses = statuses.filter(func(s: StatusEffect) -> bool: return not s.is_buff())
	return before - statuses.size()


func expire_statuses() -> void:
	for s: StatusEffect in statuses:
		s.turns_left -= 1
	statuses = statuses.filter(func(s: StatusEffect) -> bool: return s.turns_left > 0)


func gain_fervor(amount: float) -> void:
	fervor = clampf(fervor + amount, 0.0, FERVOR_MAX)


func skill_ready(skill: SkillData) -> bool:
	if not is_alive():
		return false
	match skill.slot:
		Enums.Slot.TRANCE:
			return fervor >= FERVOR_MAX
		Enums.Slot.REMEMBRANCE:
			return cooldowns.get(skill.id, 0) <= 0 and not has_status(Enums.StatusId.SILENCE)
		_:
			return true


func status_line() -> String:
	if statuses.is_empty():
		return "-"
	var parts: Array = []
	for s: StatusEffect in statuses:
		parts.append(s.display())
	return " ".join(parts)
