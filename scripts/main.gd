extends Control
## Entry point: hands off to the screen manager immediately.


func _ready() -> void:
	# Debug/CI hook: SS_SCREEN=battle SS_STAGE=v1_s01 godot --headless ...
	# jumps straight to a screen so headless runs can exercise UI code.
	var debug_screen := OS.get_environment("SS_SCREEN")
	if debug_screen != "":
		var payload = null
		if debug_screen == "battle":
			payload = {"stage_id": OS.get_environment("SS_STAGE")}
		get_node("/root/Screens").goto(debug_screen, payload)
		if OS.get_environment("SS_DUMP") != "":
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				_dump(get_tree().root, 0))
		return
	get_node("/root/Screens").goto("home")


func _dump(n: Node, depth: int) -> void:
	if n is Window:
		print("%s%s(Window) size=%s" % ["  ".repeat(depth), n.name, n.size])
	elif n is Control:
		print("%s%s(%s) size=%s pos=%s anchors=(%s,%s,%s,%s)" % [
			"  ".repeat(depth), n.name, n.get_class(), n.size, n.position,
			n.anchor_left, n.anchor_top, n.anchor_right, n.anchor_bottom])
	for c in n.get_children():
		_dump(c, depth + 1)
	if depth > 3:
		return
