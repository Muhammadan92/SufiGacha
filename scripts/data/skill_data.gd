class_name SkillData
extends Resource
## A character ability: Litany (basic), Remembrance (skill), or Trance (ultimate).
## Trances cost a full Fervor gauge instead of having a cooldown.

@export var id: StringName
@export var display_name: String = ""
## English subtitle for the rare Arabic-seasoned Trance names (GDD §1.1),
## e.g. display_name "Khalwa", subtitle "Seclusion". Usually empty.
@export var subtitle: String = ""
@export var slot: Enums.Slot = Enums.Slot.LITANY
@export var cooldown: int = 0
@export var target_type: Enums.TargetType = Enums.TargetType.ENEMY_SINGLE
@export var fervor_gain: int = 20
@export var effects: Array = []  # Array of EffectBlock


func full_name() -> String:
	return "%s — %s" % [display_name, subtitle] if subtitle != "" else display_name
