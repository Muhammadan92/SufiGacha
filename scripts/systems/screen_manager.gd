extends Node
## Autoload "Screens": swaps top-level screens (GDD §13.1 "screens as scenes").
## Screens are code-built Controls; goto(name, payload) replaces the current
## one. The payload is read by the incoming screen via Screens.payload.

const SCREEN_SCRIPTS := {
	"home": preload("res://scripts/screens/home_screen.gd"),
	"stages": preload("res://scripts/screens/stage_select_screen.gd"),
	"roster": preload("res://scripts/screens/roster_screen.gd"),
	"team": preload("res://scripts/screens/team_screen.gd"),
	"calling": preload("res://scripts/screens/calling_screen.gd"),
	"battle": preload("res://scripts/screens/battle_screen.gd"),
	"results": preload("res://scripts/screens/results_screen.gd"),
	"codex": preload("res://scripts/screens/codex_screen.gd"),
	"minaret": preload("res://scripts/screens/minaret_screen.gd"),
}

var current: Control = null
var payload = null


func goto(screen_name: String, p_payload = null) -> void:
	assert(SCREEN_SCRIPTS.has(screen_name), "unknown screen: " + screen_name)
	payload = p_payload
	if current != null:
		current.queue_free()
	current = SCREEN_SCRIPTS[screen_name].new()
	current.name = screen_name.capitalize() + "Screen"
	# Parent to the main scene's root Control, NOT the Window — full-rect
	# anchors only resolve against a Control ancestor. Adding screens to the
	# Window collapses them to minimum content size (invisible stage lists).
	get_tree().current_scene.add_child.call_deferred(current)
