class_name StatusEffect
extends RefCounted
## A live buff/debuff on a BattleUnit. `magnitude` meaning depends on the id:
## fraction for stat mods (0.3 = +30% ATK), fraction of max HP per turn for
## BURN/REGEN, unused for IMMUNITY/TAUNT/WHISPERS/SILENCE.

var id: int
var turns_left: int
var magnitude: float

## Chance for WHISPERS to steal the afflicted unit's turn (GDD §4.2).
const WHISPERS_SKIP_CHANCE := 0.3


func _init(p_id: int, p_turns: int, p_magnitude: float = 0.0) -> void:
	id = p_id
	turns_left = p_turns
	magnitude = p_magnitude


func is_buff() -> bool:
	return id in Enums.BUFF_IDS


func display() -> String:
	return "%s(%d)" % [Enums.STATUS_NAMES[id], turns_left]
