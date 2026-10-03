extends Control
## Open tests/run_tests.tscn in the editor and press F6 to run every test.

@onready var _output: RichTextLabel = $Output


func _ready() -> void:
	var result: Dictionary = TestRunner.run_all()
	var ok: bool = int(result["failed"]) == 0
	_output.add_theme_color_override("default_color", Color("#9fd49f") if ok else Color("#e07a6f"))
	_output.text = "\n".join(result["lines"])
	for line: String in result["lines"]:
		print(line)
