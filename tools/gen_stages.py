#!/usr/bin/env python3
"""Regenerates data/stages/ for valleys 2-7 from the calibrated curve.

Valley 1 is hand-authored and NEVER touched. Balance tuning that deviates
from the formulas lives in OVERRIDES — edit curves or overrides here, run,
then re-validate with tests/min_clear_levels.gd.

    python3 tools/gen_stages.py        (from the repo root)

Acceptance check after any edit: `git diff --stat data/stages/` should show
only the changes you intended.
"""
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent

BOSS_TARGETS = [8, 15, 22, 29, 36, 42, 48]
XP_VALLEY_BONUS = 0.5

# Balance tuning knobs that override the formulas (with the reasons):
OVERRIDES = {
    # Kasal & Zeenah's kits lose the proportional-scaling ratio war to
    # sustain comps at ANY level — their walls need a ratio jump.
    "v5_s12": {"scale": 2.62},
    "v6_s12": {"scale": 3.35, "enemies": ["hollow_brute", "zeenah", "hollow_brute"]},
}


def level_mult(l):
    return 1.0 + 0.04 * (l - 1)


def expected(v, i):
    prev = 1.0 if v == 1 else BOSS_TARGETS[v - 2]
    return round(prev + (BOSS_TARGETS[v - 1] - prev) * (i / 11.0))


# (valley: name, poolA, poolB, poolC, vice, escorts, stage names)
VALLEYS = {
 2: ("Valley of Love", ["whisperling", "smoke_serpent"], ["smoke_serpent", "shadow_vermin"],
     ["whisperling", "smoke_serpent", "shadow_vermin"], "hasad", ["smoke_serpent", "smoke_serpent"],
     ["The Murmuring Orchard", "Petals in the Dark", "The Longing Road", "A Song Half-Heard",
      "The Jealous Garden", "Sweetness Soured", "The Coveted Spring", "Green-Eyed Hollow",
      "What Others Have", "The Grasping Vines", "Love's Impostor", "Hasad, Devourer of Blessings"]),
 3: ("Valley of Knowledge", ["mirror_shade", "whisperling"], ["mirror_shade", "smoke_serpent"],
     ["mirror_shade", "mirror_shade", "whisperling"], "ghadab", ["mirror_shade", "mirror_shade"],
     ["The Hall of Echoes", "False Reflections", "The Half-Truth", "A Familiar Face",
      "The Library of Smoke", "Certainty's Edge", "The Burning Question", "Sparks of Argument",
      "The Furious Scholar", "Blaze of Conviction", "The Answer Withheld", "Ghadab, the Blazing"]),
 4: ("Valley of Detachment", ["hollow_brute", "shadow_vermin"], ["hollow_brute", "ash_ghoul"],
     ["hollow_brute", "hollow_brute", "smoke_serpent"], "hirs", ["hollow_brute", "hollow_brute"],
     ["The Weighted Path", "What the Hands Hold", "The Heavy Gate", "Stones of Habit",
      "The Grasping Dark", "Possession's Price", "The Hoarded Way", "Never Enough",
      "The Hollow Feast", "Appetite Unbound", "The Open Maw", "Hirs, the Hollow Maw"]),
 5: ("Valley of Unity", ["hollow_brute", "mirror_shade"], ["ash_ghoul", "smoke_serpent", "shadow_vermin"],
     ["mirror_shade", "hollow_brute", "whisperling"], "kasal", ["hollow_brute", "hollow_brute"],
     ["The Single Road", "Many Made One", "The Still Water", "One Breath",
      "The Unmoved Stone", "Weight of Rest", "The Slow Descent", "Moss on the Gate",
      "The Sleeper's Court", "Roots of Torpor", "The Great Repose", "Kasal, the Unmoving"]),
 6: ("Valley of Wonder", ["smoke_serpent", "mirror_shade"], ["mirror_shade", "ash_ghoul", "whisperling"],
     ["smoke_serpent", "smoke_serpent", "mirror_shade"], "zeenah", ["mirror_shade", "mirror_shade"],
     ["The Turning Sky", "Stars Below", "The Gilded Mirage", "Glitter and Dust",
      "The Ornamented Gate", "A Feast of Illusions", "The Golden Cage", "Bought and Sold",
      "The Price of Shine", "Treasures of Smoke", "The Last Bazaar", "Zeenah, the Gilded"]),
 7: ("Valley of the Passing-Away", ["mirror_shade", "hollow_brute", "smoke_serpent"],
     ["ash_ghoul", "ash_ghoul", "mirror_shade"], ["hollow_brute", "smoke_serpent", "mirror_shade", "whisperling"],
     "yas", ["mirror_shade", "hollow_brute"],
     ["The Thinning Road", "Letting Go", "The Quiet Threshold", "Names Forgotten",
      "The Last Doubt", "A Whisper of Ending", "The Empty Mirror", "What Remains",
      "The Final Veil", "Silence Gathers", "The Edge of Nothing", "Ya's, the Last Whisper"]),
}

TPL = '''[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/stage_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"{sid}"
display_name = "{name}"
valley = {v}
index = {idx}
breath_cost = {breath}
enemy_ids = [{enemies}]
enemy_scale = {scale}
turn_target = {tt}
xp_reward = {xp}
marks_reward = {marks}
first_clear_seals = {seals}
first_clear_sigils = {sigils}
'''


def fmt_scale(x):
    """Match Godot's serialization of the original generator's round(x, 3)."""
    return repr(round(x, 3))


def main():
    count = 0
    for v, (vname, pool_a, pool_b, pool_c, vice, escorts, names) in VALLEYS.items():
        for i in range(12):
            idx = i + 1
            sid = "v%d_s%02d" % (v, idx)
            boss = idx == 12
            pressure = 1.0 if boss else 0.72 + 0.28 * (i / 11.0)
            scale = round(level_mult(expected(v, i)) * pressure, 3)
            enemies = [escorts[0], vice, escorts[1]] if boss else [pool_a, pool_b, pool_c][i % 3]
            over = OVERRIDES.get(sid, {})
            scale = over.get("scale", scale)
            enemies = over.get("enemies", enemies)
            stage = TPL.format(
                sid=sid, name=names[i], v=v, idx=idx,
                breath=10 if boss else (6 if i < 6 else 8),
                enemies=", ".join('"%s"' % e for e in enemies),
                scale=fmt_scale(scale),
                tt=(150 if boss else 30 + 4 * i) + 6 * v,
                xp=int((26 + 6 * i) * (1.0 + XP_VALLEY_BONUS * (v - 1))),
                marks=50 if boss else (20 if i < 6 else 30),
                seals=3 if boss else (2 if i == 10 else 1),
                sigils=2 if boss else 0)
            (ROOT / "data" / "stages" / (sid + ".tres")).write_text(stage)
            count += 1
    print("regenerated %d stages (valleys 2-7); valley 1 untouched" % count)


if __name__ == "__main__":
    main()
