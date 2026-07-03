class_name BattleUnit
extends RefCounted
## Runtime state of one combatant. Pure state + stat math — all combat
## resolution and event emission happens in BattleManager.

var data: UnitData
var is_player_side: bool

var hp: int
var fervor: float = 0.0
var turn_meter: float = 0.0
var statuses: Array = []      # Array of StatusEffect
var cooldowns: Dictionary = {}  # skill id (StringName) -> turns remaining

const FERVOR_MAX := 100.0
const FERVOR_ON_HIT := 10.0


func _init(p_data: UnitData, p_player_side: bool) -> void:
	data = p_data
	is_player_side = p_player_side
	hp = data.max_hp


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
	return data.atk * _stat_mod(Enums.StatusId.ATK_UP, Enums.StatusId.ATK_DOWN)


func def() -> float:
	return data.def * _stat_mod(Enums.StatusId.DEF_UP, Enums.StatusId.DEF_DOWN)


func spd() -> float:
	return data.spd * _stat_mod(Enums.StatusId.SPD_UP, Enums.StatusId.SPD_DOWN)


func has_status(id: int) -> bool:
	for s: StatusEffect in statuses:
		if s.id == id:
			return true
	return false


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
