class_name StageData
extends Resource
## One campaign stage. Content lives in data/stages/*.tres.

@export var id: StringName
@export var display_name: String = ""
@export var valley: int = 1
@export var index: int = 1            # order within the valley; gates unlocking
@export var breath_cost: int = 6
@export var enemy_ids: Array = []     # unit ids, e.g. ["whisperling", "kibr"]
@export var enemy_scale: float = 1.0  # stat multiplier applied to all enemies
@export var xp_reward: int = 30       # per deployed character, on victory
@export var pearls_reward: int = 2
@export var first_clear_pearls: int = 10
