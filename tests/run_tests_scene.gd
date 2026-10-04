extends Control
## Runs every test with the autoloads loaded (Game, Settings, ContentDB ...).
##   Editor: open tests/run_tests.tscn and press F6 (green = all passed).
##   Command line: godot --headless --path . res://tests/run_tests.tscn -- --ci
##   (prints the results and exits with 0 when every test passes, 1 otherwise).

@onready var _output: RichTextLabel = $Output


func _ready() -> void:
	var result: Dictionary = TestRunner.run_all()
	var ok: bool = int(result["failed"]) == 0
	_output.add_theme_color_override("default_color", Color("#9fd49f") if ok else Color("#e07a6f"))
	_output.text = "\n".join(result["lines"])
	for line: String in result["lines"]:
		print(line)
	if "--ci" in OS.get_cmdline_user_args():
		get_tree().quit(0 if ok else 1)
