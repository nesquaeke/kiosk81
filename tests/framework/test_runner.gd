class_name TestRunner
extends RefCounted
## Finds every tests/<group>/test_*.gd file, runs its test_ methods and
## reports the results. Used by the command line and by run_tests.tscn.

const TEST_DIRS: PackedStringArray = ["res://tests/unit", "res://tests/save", "res://tests/content"]


static func run_all() -> Dictionary:
	var lines: PackedStringArray = []
	var passed: int = 0
	var failed: int = 0
	for path: String in _find_test_files():
		var script: GDScript = load(path) as GDScript
		if script == null:
			lines.append("FAIL %s: could not load script" % path)
			failed += 1
			continue
		for method: Dictionary in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			var case: TestCase = script.new() as TestCase
			if case == null:
				lines.append("FAIL %s: not a TestCase" % path)
				failed += 1
				break
			case.current_test = "%s::%s" % [path.get_file(), method_name]
			case.before_each()
			case.call(method_name)
			case.after_each()
			if case.failures.is_empty():
				passed += 1
				lines.append("PASS %s" % case.current_test)
			else:
				failed += 1
				for failure: String in case.failures:
					lines.append("FAIL " + failure)
	lines.append("---- %d passed, %d failed ----" % [passed, failed])
	return {"passed": passed, "failed": failed, "lines": lines}


static func _find_test_files() -> PackedStringArray:
	var found: PackedStringArray = []
	for dir_path: String in TEST_DIRS:
		var dir: DirAccess = DirAccess.open(dir_path)
		if dir == null:
			continue
		for file_name: String in dir.get_files():
			if file_name.begins_with("test_") and file_name.ends_with(".gd"):
				found.append(dir_path.path_join(file_name))
	found.sort()
	return found
