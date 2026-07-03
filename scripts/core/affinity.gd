class_name Affinity
## Affinity math per GDD §2.1: Power > Flow > Spirit > Power (x1.3 advantaged,
## x0.85 disadvantaged). Heart sits outside the triangle: neutral both ways,
## +20% vs Corruption. Corruption is strong vs the triangle, weak only to Heart.

const GROUP_OF := {
	Enums.Affinity.HEART: Enums.AffinityGroup.NONE,
	Enums.Affinity.THUNDER: Enums.AffinityGroup.POWER,
	Enums.Affinity.EMBER: Enums.AffinityGroup.POWER,
	Enums.Affinity.WIND: Enums.AffinityGroup.FLOW,
	Enums.Affinity.SEA: Enums.AffinityGroup.FLOW,
	Enums.Affinity.HARMONY: Enums.AffinityGroup.SPIRIT,
	Enums.Affinity.LIGHT: Enums.AffinityGroup.SPIRIT,
	Enums.Affinity.CORRUPTION: Enums.AffinityGroup.CORRUPT,
}

const BEATS := {
	Enums.AffinityGroup.POWER: Enums.AffinityGroup.FLOW,
	Enums.AffinityGroup.FLOW: Enums.AffinityGroup.SPIRIT,
	Enums.AffinityGroup.SPIRIT: Enums.AffinityGroup.POWER,
}

static func damage_multiplier(attacker: Enums.Affinity, defender: Enums.Affinity) -> float:
	var ag: Enums.AffinityGroup = GROUP_OF[attacker]
	var dg: Enums.AffinityGroup = GROUP_OF[defender]
	if ag == Enums.AffinityGroup.NONE:
		return 1.2 if dg == Enums.AffinityGroup.CORRUPT else 1.0
	if ag == Enums.AffinityGroup.CORRUPT:
		return 1.15 if dg in [Enums.AffinityGroup.POWER, Enums.AffinityGroup.FLOW, Enums.AffinityGroup.SPIRIT] else 1.0
	if BEATS.get(ag) == dg:
		return 1.3
	if BEATS.get(dg) == ag:
		return 0.85
	return 1.0
