class_name UnitData
extends Resource
## Static definition of a character or enemy. All content lives in
## data/units/*.tres files — never hardcode units in scripts.

@export var id: StringName
@export var display_name: String = ""
@export var epithet: String = ""       # "Voice of Thunder" — empty for most
@export var order_name: String = ""    # "Qadiri" etc.; empty for demons
## Appearance description for the AI art pipeline — tools/export_art_tasks.gd
## composes generation prompts from this + the order's style block. Keeping it
## here means character data and art briefs can never drift apart.
@export var art_notes: String = ""
@export var affinity: Enums.Affinity = Enums.Affinity.THUNDER
@export var rarity: int = 3            # 3 Novice / 4 Wayfarer / 5 Luminary
@export var is_enemy: bool = false

@export_group("Stats")
@export var max_hp: int = 1000
@export var atk: int = 100
@export var def: int = 60
@export var spd: int = 100
@export var crit_rate: float = 0.15
@export var crit_damage: float = 1.5
@export var effectiveness: float = 0.0
@export var resilience: float = 0.0

@export_group("Skills")
@export var skills: Array = []  # Array of SkillData


func label() -> String:
	return "%s, %s" % [display_name, epithet] if epithet != "" else display_name
