class_name BattlerRig
extends Node2D
## The 3-part paper-doll battler: head / torso / skirt cut programmatically
## from a single chibi texture (no hand-rigging). Rig-friendly chibis
## (A-pose, transparent bg — the art pipeline produces these) animate
## cleanly; any other texture still works, just with visible band seams.
##
## All motion is cosmetic presentation (GDD §4.4 untouched). Animations are
## tween-driven: idle (loop), attack, hit, cast, death.

var head_pivot: Node2D
var torso_pivot: Node2D
var skirt: Sprite2D
var facing := 1.0  # -1 for enemies (mirror lunges toward the player side)

var _idle_tween: Tween
const HEAD_FRAC := 0.46   # chibi proportions: big head
const HIP_FRAC := 0.76
const SEAM := 4           # px of overlap so joints don't show gaps


func setup(tex: Texture2D, height_px: float, face := 1.0) -> void:
	facing = face
	var size := tex.get_size()
	var s := height_px / size.y
	scale = Vector2(s, s)
	var h1 := size.y * HEAD_FRAC
	var h2 := size.y * HIP_FRAC

	# skirt/legs: bottom band, feet planted at local y=0
	skirt = _band(tex, Rect2(0, h2 - SEAM, size.x, size.y - h2 + SEAM))
	skirt.position = Vector2(0, -(size.y - h2 + SEAM))
	add_child(skirt)

	# torso: pivots at the hip line
	torso_pivot = Node2D.new()
	torso_pivot.position = Vector2(0, -(size.y - h2))
	add_child(torso_pivot)
	var torso := _band(tex, Rect2(0, h1 - SEAM, size.x, h2 - h1 + SEAM))
	torso.position = Vector2(0, -(h2 - h1 + SEAM))
	torso_pivot.add_child(torso)

	# head: pivots at the neck, rides on the torso
	head_pivot = Node2D.new()
	head_pivot.position = Vector2(0, -(h2 - h1))
	torso_pivot.add_child(head_pivot)
	var head := _band(tex, Rect2(0, 0, size.x, h1))
	head.position = Vector2(0, -h1)
	head_pivot.add_child(head)


func _band(tex: Texture2D, region: Rect2) -> Sprite2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = region
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.centered = false
	sprite.offset = Vector2(-region.size.x / 2.0, 0)
	return sprite


# --- animations -------------------------------------------------------------

func play_idle(phase := 0) -> void:
	if _idle_tween != null:
		_idle_tween.kill()
	var dur := 1.2 + 0.11 * float(phase % 5)
	_idle_tween = create_tween().set_loops()
	_idle_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(torso_pivot, "rotation", 0.035, dur)
	_idle_tween.parallel().tween_property(head_pivot, "rotation", -0.025, dur)
	_idle_tween.parallel().tween_property(self, "position:y", position.y - 2.0, dur)
	_idle_tween.chain().tween_property(torso_pivot, "rotation", -0.035, dur)
	_idle_tween.parallel().tween_property(head_pivot, "rotation", 0.025, dur)
	_idle_tween.parallel().tween_property(self, "position:y", position.y, dur)


func play_attack() -> void:
	var tw := create_tween()
	tw.tween_property(self, "position:x", position.x + 16.0 * facing, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(torso_pivot, "rotation", -0.3 * facing, 0.12)
	tw.tween_property(self, "position:x", position.x, 0.22)
	tw.parallel().tween_property(torso_pivot, "rotation", 0.0, 0.22)


func play_hit() -> void:
	var tw := create_tween()
	modulate = Color(1.6, 0.7, 0.7)
	tw.tween_property(self, "modulate", Color.WHITE, 0.3)
	tw.parallel().tween_property(head_pivot, "rotation", 0.18 * facing, 0.08)
	tw.chain().tween_property(head_pivot, "rotation", 0.0, 0.18)


func play_cast() -> void:
	var tw := create_tween()
	tw.tween_property(torso_pivot, "rotation", 0.14 * facing, 0.18)
	tw.parallel().tween_property(self, "modulate", Color(1.25, 1.25, 1.05), 0.18)
	tw.tween_property(torso_pivot, "rotation", 0.0, 0.25)
	tw.parallel().tween_property(self, "modulate", Color.WHITE, 0.25)


func play_death() -> void:
	if _idle_tween != null:
		_idle_tween.kill()
	var tw := create_tween()
	tw.tween_property(torso_pivot, "rotation", 0.5 * facing, 0.4)
	tw.parallel().tween_property(self, "position:y", position.y + 5.0, 0.4)
	tw.parallel().tween_property(self, "modulate:a", 0.3, 0.4)
