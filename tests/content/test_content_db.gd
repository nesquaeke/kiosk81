extends TestCase
## ContentDB: real content loads clean; broken files are caught with file and line (roadmap 1.8).

const ContentDBScript: GDScript = preload("res://game/content/content_db.gd")
const TMP_ROOT: String = "user://test_content"

var db: Node


func before_each() -> void:
	db = ContentDBScript.new()


func after_each() -> void:
	if db != null:
		db.free()
		db = null


func _write_case(case_name: String, files: Dictionary) -> String:
	var dir: String = TMP_ROOT.path_join(case_name)
	DirAccess.make_dir_recursive_absolute(dir)
	for old: String in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(old))
	for file_name: String in files:
		var f: FileAccess = FileAccess.open(dir.path_join(file_name), FileAccess.WRITE)
		f.store_string(files[file_name])
		f.close()
	return dir


func _load_case(case_name: String, files: Dictionary) -> PackedStringArray:
	var dir: String = _write_case(case_name, files)
	db.load_roots([dir])
	return db.errors


func _expect_error(case_name: String, files: Dictionary, file_name: String, text: String) -> void:
	var errors: PackedStringArray = _load_case(case_name, files)
	for problem: String in errors:
		if problem.contains(file_name) and problem.contains(text):
			return
	fail("%s: no error mentioning '%s' in %s; got %s" % [case_name, text, file_name, errors])


const CHARS: String = '{"type": "character", "records": [{"id": "chr_a", "name": "A", "role": "test"}]}'


func _dialogue(choice_extra: String) -> String:
	return '{"type": "dialogue", "records": [{"id": "dlg_x", "speakers": ["customer", "chr_a"], "start": "n1", "nodes": {"n1": {"lines": [{"speaker": "chr_a", "text": "Hi."}], "choices": [{"text": "Bye."%s}]}, "n2": {"end": true}}}]}' % choice_extra


func test_real_content_loads_clean() -> void:
	assert_true(db.load_roots(ContentDBScript.DEFAULT_ROOTS), "errors: %s" % [db.errors])
	assert_true(db.has_id("itm_trybuna_ludu"))
	assert_true(db.has_id("chr_marek"))
	assert_eq(db.get_record("item", "itm_matches")["price"], 50, "JSON numbers become ints")
	assert_true(db.all_of("dialogue").size() >= 1)


func test_valid_case_has_no_errors() -> void:
	var errors: PackedStringArray = _load_case("valid", {"chars.json": CHARS, "dlg.json": _dialogue(', "goto": "n2"')})
	assert_eq(errors.size(), 0, "%s" % [errors])


func test_broken_json_syntax_reports_line() -> void:
	_expect_error("syntax", {"bad.json": '{\n "type": "item",\n "records": [\n  {"id": "itm_x",,}\n ]\n}'}, "bad.json:4", "JSON error")


func test_missing_required_field() -> void:
	_expect_error("missing", {"items.json": '{"type": "item", "records": [{"id": "itm_x", "name": "X", "category": "other", "legal": true}]}'},
			"items.json", "missing field 'price'")


func test_wrong_type() -> void:
	_expect_error("wrong_type", {"items.json": '{"type": "item", "records": [{"id": "itm_x", "name": "X", "category": "other", "price": "1.00", "legal": true}]}'},
			"items.json:1", "price: must be a whole number")


func test_duplicate_id_across_files() -> void:
	_expect_error("duplicate", {"a.json": CHARS, "b.json": CHARS}, "b.json", "duplicate id 'chr_a'")


func test_unknown_reference() -> void:
	var dlg: String = _dialogue(', "goto": "n2"').replace('["customer", "chr_a"]', '["customer", "chr_a", "chr_nobody"]')
	_expect_error("unknown_ref", {"chars.json": CHARS, "dlg.json": dlg}, "dlg.json", "unknown character 'chr_nobody'")


func test_bad_condition_inside_dialogue() -> void:
	_expect_error("bad_condition", {"chars.json": CHARS, "dlg.json": _dialogue(', "goto": "n2", "if": {"if": "relation", "character": "chr_a", "dimension": "love", "cmp": ">", "value": 1}')},
			"dlg.json", "unknown relation 'love'")


func test_bad_effect_inside_dialogue() -> void:
	_expect_error("bad_effect", {"chars.json": CHARS, "dlg.json": _dialogue(', "goto": "n2", "effects": [{"op": "money_add", "account": "wallet", "amount": 5}]')},
			"dlg.json", "unknown account 'wallet'")


func test_goto_to_missing_node() -> void:
	_expect_error("bad_goto", {"chars.json": CHARS, "dlg.json": _dialogue(', "goto": "n9"')}, "dlg.json", "node 'n9' does not exist")


func test_wrong_id_prefix_and_unknown_type() -> void:
	_expect_error("prefix", {"items.json": '{"type": "item", "records": [{"id": "trybuna", "name": "X", "category": "other", "price": 1, "legal": true}]}'},
			"items.json", "must start with 'itm_'")
	_expect_error("type", {"x.json": '{"type": "weapon", "records": []}'}, "x.json", "unknown type 'weapon'")


func test_unknown_field_is_reported() -> void:
	_expect_error("unknown_field", {"items.json": '{"type": "item", "records": [{"id": "itm_x", "name": "X", "category": "other", "price": 1, "legal": true, "prise": 2}]}'},
			"items.json", "unknown field 'prise'")


func test_every_broken_case_counts_as_failed_load() -> void:
	# The roadmap asks for five deliberately broken files; each must make load_roots() return false.
	var broken: Array[Dictionary] = [
		{"a.json": "{ not json"},
		{"a.json": '{"type": "item", "records": [{"id": "itm_x"}]}'},
		{"a.json": CHARS, "b.json": CHARS},
		{"d.json": _dialogue(', "goto": "n2"')},
		{"c.json": CHARS, "d.json": _dialogue(', "end": true, "goto": "n2"')},
	]
	for i: int in broken.size():
		var dir: String = _write_case("broken_%d" % i, broken[i])
		assert_false(db.load_roots([dir]), "broken case %d must fail" % i)
