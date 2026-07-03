class_name EffectBlock
extends Resource
## One composable effect (GDD §13.1). Skills are arrays of these.
## Field meaning depends on `kind`:
##   DAMAGE / HEAL       — `power` = multiplier of the actor's ATK
##   APPLY_STATUS        — `status_id` + `chance` + `duration` + `amount` (magnitude,
##                         e.g. 0.3 = ±30% for stat mods, fraction of max HP for BURN/REGEN)
##   GAIN_FERVOR         — `amount` = flat Fervor granted to targets
##   MODIFY_TURN_METER   — `amount` = turn meter percentage points (+/-)

@export var kind: Enums.EffectKind = Enums.EffectKind.DAMAGE
@export var power: float = 1.0
@export var status_id: int = -1
@export var chance: float = 1.0
@export var duration: int = 2
@export var amount: float = 0.0
## -1 = use the skill's target set; otherwise an Enums.TargetType overriding it
## (e.g. a damage skill whose second effect buffs SELF).
@export var target_override: int = -1
## For APPLY_STATUS: reapplication stacks magnitude up to `amount * stack_cap`.
## Set very high (99) for unbounded ramps like boss enrages.
@export var stack_cap: float = 3.0
