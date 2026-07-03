class_name Enums
## Shared enums. The integer values are serialized in data/*.tres files —
## append new entries at the end, never reorder.

enum Affinity {
	HEART,       # Naqshbandi — outside the triangle
	THUNDER,     # Qadiri
	EMBER,       # Rifai
	WIND,        # Mevlevi
	SEA,         # Shadhili
	HARMONY,     # Chishti
	LIGHT,       # Suhrawardi
	CORRUPTION,  # bosses/elites
}

enum AffinityGroup { NONE, POWER, FLOW, SPIRIT, CORRUPT }

enum Slot { LITANY, REMEMBRANCE, TRANCE }

enum TargetType { ENEMY_SINGLE, ENEMY_ALL, ALLY_SINGLE, ALLY_ALL, SELF }

enum EffectKind { DAMAGE, HEAL, APPLY_STATUS, GAIN_FERVOR, MODIFY_TURN_METER }

enum StatusId {
	ATK_UP, ATK_DOWN,
	DEF_UP, DEF_DOWN,
	SPD_UP, SPD_DOWN,
	BURN, REGEN,
	BARRIER, IMMUNITY, EVASION,
	SILENCE, WHISPERS, TAUNT,
}

const SLOT_NAMES := {
	Slot.LITANY: "Litany",
	Slot.REMEMBRANCE: "Remembrance",
	Slot.TRANCE: "Trance",
}

const AFFINITY_NAMES := {
	Affinity.HEART: "Heart",
	Affinity.THUNDER: "Thunder",
	Affinity.EMBER: "Ember",
	Affinity.WIND: "Wind",
	Affinity.SEA: "Sea",
	Affinity.HARMONY: "Harmony",
	Affinity.LIGHT: "Light",
	Affinity.CORRUPTION: "Corruption",
}

const STATUS_NAMES := {
	StatusId.ATK_UP: "ATK Up", StatusId.ATK_DOWN: "ATK Down",
	StatusId.DEF_UP: "DEF Up", StatusId.DEF_DOWN: "DEF Down",
	StatusId.SPD_UP: "SPD Up", StatusId.SPD_DOWN: "SPD Down",
	StatusId.BURN: "Burn", StatusId.REGEN: "Regen",
	StatusId.BARRIER: "Barrier", StatusId.IMMUNITY: "Immunity",
	StatusId.EVASION: "Evasion", StatusId.SILENCE: "Silence",
	StatusId.WHISPERS: "Whispers", StatusId.TAUNT: "Taunt",
}

const BUFF_IDS := [
	StatusId.ATK_UP, StatusId.DEF_UP, StatusId.SPD_UP,
	StatusId.REGEN, StatusId.BARRIER, StatusId.IMMUNITY,
	StatusId.EVASION, StatusId.TAUNT,
]
