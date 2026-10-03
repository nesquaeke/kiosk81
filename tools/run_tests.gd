extends SceneTree
## Command line test run (roadmap step 1.4):
##   godot --headless --path . --script res://tools/run_tests.gd
## Exit code 0 when every test passes, 1 otherwise.


func _init() -> void:
	var result: Dictionary = TestRunner.run_all()
	for line: String in result["lines"]:
		print(line)
	quit(0 if int(result["failed"]) == 0 else 1)
