#!/usr/bin/env python3
"""Scaffolds a new playable hero .tres in the house format.

    python3 tools/new_hero.py <id> "<Display Name>" <Order> <affinity 0-6> <rarity 3-5>

Example:
    python3 tools/new_hero.py sable "Sable" Naqshbandi 0 4

Writes data/units/<id>.tres with a three-skill skeleton (litany / remembrance
/ trance) using the affinity's baseline stats — then hand-tune the kit, add
art_notes, and validate with tests/min_clear_levels.gd + the economy sim.
Enum cheat sheet: EffectKind DAMAGE0 HEAL1 APPLY_STATUS2 GAIN_FERVOR3
MODIFY_TURN_METER4 CLEANSE5 DISPEL6 | Target ES0 EA1 AS2 AA3 SELF4.
"""
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

TPL = '''[gd_resource type="Resource" load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/data/unit_data.gd" id="1"]
[ext_resource type="Script" path="res://scripts/data/skill_data.gd" id="2"]
[ext_resource type="Script" path="res://scripts/data/effect_block.gd" id="3"]

[sub_resource type="Resource" id="e1"]
script = ExtResource("3")
kind = 0
power = 1.0

[sub_resource type="Resource" id="e2"]
script = ExtResource("3")
kind = 0
power = 1.4

[sub_resource type="Resource" id="e3"]
script = ExtResource("3")
kind = 0
power = 2.2

[sub_resource type="Resource" id="s1"]
script = ExtResource("2")
id = &"{uid}_lit"
display_name = "TODO Litany"
slot = 0
cooldown = 0
target_type = 0
fervor_gain = 20
effects = [SubResource("e1")]

[sub_resource type="Resource" id="s2"]
script = ExtResource("2")
id = &"{uid}_rem"
display_name = "TODO Remembrance"
slot = 1
cooldown = 3
target_type = 0
fervor_gain = 15
effects = [SubResource("e2")]

[sub_resource type="Resource" id="s3"]
script = ExtResource("2")
id = &"{uid}_trance"
display_name = "TODO Trance"
slot = 2
cooldown = 0
target_type = 0
fervor_gain = 0
effects = [SubResource("e3")]

[resource]
script = ExtResource("1")
id = &"{uid}"
display_name = "{name}"
epithet = ""
art_notes = "TODO — follow the order's palette (GDD SS2)"
order_name = "{order}"
affinity = {aff}
rarity = {rar}
is_enemy = false
max_hp = {hp}
atk = {atk}
def = {df}
spd = {spd}
crit_rate = 0.15
crit_damage = 1.5
effectiveness = 0.0
resilience = 0.0
skills = [SubResource("s1"), SubResource("s2"), SubResource("s3")]
'''

# Baseline stat blocks per rarity (tune per kit afterward)
BASELINES = {3: (800, 85, 60, 100), 4: (950, 95, 70, 104), 5: (1100, 105, 80, 108)}


def main():
    if len(sys.argv) != 6:
        sys.exit(__doc__)
    uid, name, order, aff, rar = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]), int(sys.argv[5])
    path = ROOT / "data" / "units" / (uid + ".tres")
    if path.exists():
        sys.exit("refusing to overwrite existing unit: %s" % path)
    hp, atk, df, spd = BASELINES[rar]
    path.write_text(TPL.format(uid=uid, name=name, order=order, aff=aff, rar=rar,
                               hp=hp, atk=atk, df=df, spd=spd))
    print("wrote %s — now: tune the kit, write art_notes, run gen_placeholders + export_art_tasks" % path)


if __name__ == "__main__":
    main()
