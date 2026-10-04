extends SceneTree
## Replaced (roadmap 1.12): some code now uses autoloads (Game, Settings), and
## Godot does not load autoloads in --script mode, so tests run as a scene:
##   godot --headless --path . res://tests/run_tests.tscn -- --ci


func _init() -> void:
	printerr("Tests now run as a scene: godot --headless --path . res://tests/run_tests.tscn -- --ci")
	quit(2)
