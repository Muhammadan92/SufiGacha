extends Control
## Entry point: hands off to the screen manager immediately.


func _ready() -> void:
	get_node("/root/Screens").goto("home")
