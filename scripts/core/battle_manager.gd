class_name BattleManager
extends Node
## Turn-meter battle state machine (GDD §4, §13.1). Emits signals for
## everything that happens; never touches UI. The UI drives pacing by
## calling step() and submits player choices via submit_player_action().

signal log_message(text: String)
signal state_refreshed
signal awaiting_input(actor: BattleUnit)
signal battle_ended(victory: bool)

const METER_MAX := 100.0

var players: Array = []  # Array of BattleUnit
var enemies: Array = []
var current_actor: BattleUnit = null
var awaiting_player := false
var ended := false
var auto_mode := false


func setup(player_data: Array, enemy_data: Array) -> void:
	players.clear()
	enemies.clear()
	ended = false
	awaiting_player = false
	current_actor = null
	for d: UnitData in player_data:
		players.append(BattleUnit.new(d, true))
	for d: UnitData in enemy_data:
		enemies.append(BattleUnit.new(d, false))
	log_message.emit("The battle begins.")
	state_refreshed.emit()


func all_units() -> Array:
	return players + enemies


func _alive(units: Array) -> Array:
	return units.filter(func(u: BattleUnit) -> bool: return u.is_alive())


## Advance the fight by one unit-turn. No-op while waiting on the player.
func step() -> void:
	if ended or awaiting_player:
		return
	var actor := _advance_turn_meter()
	if actor == null:
		return
	current_actor = actor
	actor.turn_meter = 0.0
	_start_of_turn(actor)
	if ended:
		return
	if not actor.is_alive():  # burn can kill at turn start
		state_refreshed.emit()
		return
	if actor.has_status(Enums.StatusId.WHISPERS) and randf() < StatusEffect.WHISPERS_SKIP_CHANCE:
		log_message.emit("%s is lost in the Whispers and loses their turn!" % actor.data.display_name)
		state_refreshed.emit()
		return
	if actor.is_player_side and not auto_mode:
		awaiting_player = true
		awaiting_input.emit(actor)
		state_refreshed.emit()
		return
	_ai_act(actor)


func submit_player_action(skill: SkillData, target: BattleUnit) -> void:
	if not awaiting_player or ended:
		return
	awaiting_player = false
	_resolve_skill(current_actor, skill, target)


## Called when auto mode is switched on while waiting for input.
func force_auto_current() -> void:
	if not awaiting_player or ended:
		return
	awaiting_player = false
	_ai_act(current_actor)


func valid_targets(actor: BattleUnit, skill: SkillData) -> Array:
	match skill.target_type:
		Enums.TargetType.ENEMY_SINGLE:
			var foes := _alive(enemies if actor.is_player_side else players)
			var taunters: Array = foes.filter(func(u: BattleUnit) -> bool: return u.has_status(Enums.StatusId.TAUNT))
			return taunters if not taunters.is_empty() else foes
		Enums.TargetType.ALLY_SINGLE:
			return _alive(players if actor.is_player_side else enemies)
		_:
			return []  # no manual selection needed


func _advance_turn_meter() -> BattleUnit:
	var living := _alive(all_units())
	if living.is_empty():
		return null
	var min_time := INF
	for u: BattleUnit in living:
		var t: float = (METER_MAX - u.turn_meter) / maxf(u.spd(), 1.0)
		min_time = minf(min_time, t)
	var next: BattleUnit = null
	for u: BattleUnit in living:
		u.turn_meter += u.spd() * min_time
		if u.turn_meter >= METER_MAX - 0.001 and (next == null or u.turn_meter > next.turn_meter):
			next = u
	return next


func _start_of_turn(actor: BattleUnit) -> void:
	for key in actor.cooldowns:
		actor.cooldowns[key] = maxi(0, actor.cooldowns[key] - 1)
	for s: StatusEffect in actor.statuses.duplicate():
		if s.id == Enums.StatusId.BURN:
			var dmg := maxi(1, int(actor.data.max_hp * s.magnitude))
			actor.hp = maxi(0, actor.hp - dmg)
			log_message.emit("%s takes %d burn damage." % [actor.data.display_name, dmg])
		elif s.id == Enums.StatusId.REGEN:
			var heal := int(actor.data.max_hp * s.magnitude)
			actor.hp = mini(actor.data.max_hp, actor.hp + heal)
			log_message.emit("%s regenerates %d HP." % [actor.data.display_name, heal])
	# Durations tick down once per own turn, in one place only. A 2-turn
	# status therefore lives through two of this unit's turn starts.
	actor.expire_statuses()
	if not actor.is_alive():
		_on_death(actor)
		_check_end()


func _ai_act(actor: BattleUnit) -> void:
	var skill := _ai_pick_skill(actor)
	var target := _ai_pick_target(actor, skill)
	_resolve_skill(actor, skill, target)


func _ai_pick_skill(actor: BattleUnit) -> SkillData:
	# Prefer Trance, then Remembrance, then Litany — but don't waste heals.
	for slot in [Enums.Slot.TRANCE, Enums.Slot.REMEMBRANCE, Enums.Slot.LITANY]:
		for skill: SkillData in actor.data.skills:
			if skill.slot == slot and actor.skill_ready(skill):
				if skill.slot != Enums.Slot.LITANY and _is_wasted_heal(actor, skill):
					continue
				return skill
	return actor.data.skills[0]


## True for pure healing skills when no ally is meaningfully hurt.
func _is_wasted_heal(actor: BattleUnit, skill: SkillData) -> bool:
	var heals := false
	for eff: EffectBlock in skill.effects:
		if eff.kind == Enums.EffectKind.DAMAGE:
			return false
		if eff.kind == Enums.EffectKind.HEAL:
			heals = true
	if not heals:
		return false
	for u: BattleUnit in _alive(players if actor.is_player_side else enemies):
		if float(u.hp) / u.data.max_hp < 0.8:
			return false
	return true


func _is_offensive(skill: SkillData) -> bool:
	return skill.target_type in [Enums.TargetType.ENEMY_SINGLE, Enums.TargetType.ENEMY_ALL]


func _ai_pick_target(actor: BattleUnit, skill: SkillData) -> BattleUnit:
	var choices := valid_targets(actor, skill)
	if choices.is_empty():
		return actor
	if _is_offensive(skill):
		choices.sort_custom(func(a: BattleUnit, b: BattleUnit) -> bool: return a.hp < b.hp)
	else:
		choices.sort_custom(func(a: BattleUnit, b: BattleUnit) -> bool:
			return float(a.hp) / a.data.max_hp < float(b.hp) / b.data.max_hp)
	return choices[0]


func _targets_for(actor: BattleUnit, target_type: int, primary: BattleUnit) -> Array:
	var foes := _alive(enemies if actor.is_player_side else players)
	var friends := _alive(players if actor.is_player_side else enemies)
	match target_type:
		Enums.TargetType.ENEMY_SINGLE:
			if primary != null and primary.is_alive() and primary in foes:
				return [primary]
			return [] if foes.is_empty() else [foes[0]]
		Enums.TargetType.ENEMY_ALL:
			return foes
		Enums.TargetType.ALLY_SINGLE:
			if primary != null and primary.is_alive() and primary in friends:
				return [primary]
			return [actor]
		Enums.TargetType.ALLY_ALL:
			return friends
		_:
			return [actor]


func _resolve_skill(actor: BattleUnit, skill: SkillData, primary: BattleUnit) -> void:
	var target_desc := ""
	if skill.target_type == Enums.TargetType.ENEMY_SINGLE or skill.target_type == Enums.TargetType.ALLY_SINGLE:
		var t := _targets_for(actor, skill.target_type, primary)
		if not t.is_empty():
			target_desc = " on %s" % t[0].data.display_name
	log_message.emit("%s uses [%s] %s%s." % [
		actor.data.display_name, Enums.SLOT_NAMES[skill.slot], skill.full_name(), target_desc])

	if skill.slot == Enums.Slot.TRANCE:
		actor.fervor = 0.0
	else:
		actor.gain_fervor(skill.fervor_gain)
	if skill.cooldown > 0:
		actor.cooldowns[skill.id] = skill.cooldown

	for eff: EffectBlock in skill.effects:
		var tt: int = skill.target_type if eff.target_override < 0 else eff.target_override
		for target: BattleUnit in _targets_for(actor, tt, primary):
			_apply_effect(actor, eff, target)

	for u: BattleUnit in all_units():
		if not u.is_alive() and not u.statuses.is_empty():
			_on_death(u)
	state_refreshed.emit()
	_check_end()


func _apply_effect(actor: BattleUnit, eff: EffectBlock, target: BattleUnit) -> void:
	if not target.is_alive():
		return
	match eff.kind:
		Enums.EffectKind.DAMAGE:
			_deal_damage(actor, target, eff.power)
		Enums.EffectKind.HEAL:
			var amount := int(actor.atk() * eff.power)
			target.hp = mini(target.data.max_hp, target.hp + amount)
			log_message.emit("  %s recovers %d HP." % [target.data.display_name, amount])
		Enums.EffectKind.APPLY_STATUS:
			var is_debuff := eff.status_id not in Enums.BUFF_IDS
			var land_chance := eff.chance
			if is_debuff:
				land_chance *= 1.0 + actor.data.effectiveness - target.data.resilience
			if randf() < land_chance:
				target.add_status(eff.status_id, eff.duration, eff.amount, eff.stack_cap)
				log_message.emit("  %s gains %s." % [target.data.display_name, Enums.STATUS_NAMES[eff.status_id]])
			elif is_debuff:
				log_message.emit("  %s resists %s." % [target.data.display_name, Enums.STATUS_NAMES[eff.status_id]])
		Enums.EffectKind.GAIN_FERVOR:
			target.gain_fervor(eff.amount)
			log_message.emit("  %s gains %d Fervor." % [target.data.display_name, int(eff.amount)])
		Enums.EffectKind.MODIFY_TURN_METER:
			target.turn_meter = clampf(target.turn_meter + eff.amount, 0.0, METER_MAX)
			log_message.emit("  %s's turn meter shifts %d%%." % [target.data.display_name, int(eff.amount)])


func _deal_damage(actor: BattleUnit, target: BattleUnit, power: float) -> void:
	if target.has_status(Enums.StatusId.IMMUNITY):
		log_message.emit("  %s is immune!" % target.data.display_name)
		return
	var mult := Affinity.damage_multiplier(actor.data.affinity, target.data.affinity)
	var base := actor.atk() * power * mult
	var mitigation := 300.0 / (300.0 + target.def())
	var crit := randf() < actor.data.crit_rate
	var crit_mult := actor.data.crit_damage if crit else 1.0
	var dmg := maxi(1, int(base * mitigation * crit_mult * randf_range(0.95, 1.05)))
	target.hp = maxi(0, target.hp - dmg)
	target.gain_fervor(BattleUnit.FERVOR_ON_HIT)
	var notes: Array = []
	if crit:
		notes.append("CRIT")
	if mult > 1.0:
		notes.append("advantage")
	elif mult < 1.0:
		notes.append("resisted")
	var suffix := "" if notes.is_empty() else " (%s)" % ", ".join(notes)
	log_message.emit("  %s takes %d damage%s." % [target.data.display_name, dmg, suffix])
	if not target.is_alive():
		_on_death(target)


func _on_death(unit: BattleUnit) -> void:
	unit.statuses.clear()
	unit.turn_meter = 0.0
	log_message.emit("%s falls!" % unit.data.display_name)


func _check_end() -> void:
	if ended:
		return
	if _alive(enemies).is_empty():
		ended = true
		log_message.emit("Victory! The darkness recedes.")
		battle_ended.emit(true)
	elif _alive(players).is_empty():
		ended = true
		log_message.emit("Defeat... the company falls.")
		battle_ended.emit(false)
