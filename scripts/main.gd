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
		return
	get_node("/root/Screens").goto("home")
