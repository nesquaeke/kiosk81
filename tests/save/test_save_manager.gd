extends TestCase
## SaveManager: versioned, checksummed, crash-safe saves with backups and migrations (roadmap 1.9).

const SaveScript: GDScript = preload("res://game/save/save_manager.gd")
const ContentDBScript: GDScript = preload("res://game/content/content_db.gd")
const DIR: String = "user://test_saves"

var saves: Node


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	for old: String in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(old))
	saves = SaveScript.new()
	saves.save_dir = DIR


func after_each() -> void:
	saves.free()


func _state(day: int) -> CampaignState:
	var s: CampaignState = CampaignState.new()
	s.day = day
	s.money["pocket"] = 1234 + day
	s.stock["shelf"]["itm_trybuna_ludu"] = 7
	s.flags["note"] = "dzień %d" % day
	s.ensure_character("chr_marek")["relations"]["trust"] = -2
	return s


func _write(path: String, text: String) -> void:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func test_round_trip_keeps_everything() -> void:
	var s: CampaignState = _state(4)
	assert_eq(saves.save_campaign(s), OK)
	var r: Variant = saves.load_campaign()
	assert_true(r.ok, "%s" % [r.problems])
	assert_eq(r.used_file, "slot_1.json")
	assert_eq(r.state.to_dict(), s.to_dict())
	assert_false(FileAccess.file_exists(saves.slot_path(1) + ".tmp"), "temp file is renamed away")


func test_keeps_three_backups() -> void:
	for day: int in range(1, 6):
		saves.save_campaign(_state(day))
	var path: String = saves.slot_path(1)
	assert_true(FileAccess.file_exists(path + ".bak3"))
	assert_false(FileAccess.file_exists(path + ".bak4"))
	var newest: Variant = saves.load_campaign()
	assert_eq(newest.state.day, 5)
	var bak1: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path + ".bak1"))
	assert_eq(int(bak1["data"]["day"]), 4, "bak1 is the previous save")


func test_truncated_file_falls_back_to_backup() -> void:
	saves.save_campaign(_state(1))
	saves.save_campaign(_state(2))
	var path: String = saves.slot_path(1)
	var text: String = FileAccess.get_file_as_string(path)
	_write(path, text.substr(0, text.length() / 2))  # power cut in the middle of a write
	var r: Variant = saves.load_campaign()
	assert_true(r.ok)
	assert_eq(r.used_file, "slot_1.json.bak1")
	assert_eq(r.state.day, 1)
	assert_true(r.problems[0].contains("damaged JSON"), "%s" % [r.problems])


func test_edited_file_fails_the_checksum() -> void:
	saves.save_campaign(_state(1))
	var path: String = saves.slot_path(1)
	_write(path, FileAccess.get_file_as_string(path).replace("\"pocket\": 1235", "\"pocket\": 999999"))
	var r: Variant = saves.load_campaign()
	assert_false(r.ok, "no backup to fall back to")
	assert_true(r.problems[0].contains("checksum"), "%s" % [r.problems])


func test_newer_save_is_refused() -> void:
	saves.current_version = 5
	saves.save_campaign(_state(1))
	saves.current_version = 1
	var r: Variant = saves.load_campaign()
	assert_false(r.ok)
	assert_true(r.problems[0].contains("newer version"), "%s" % [r.problems])


func test_migration_chain_runs_in_order() -> void:
	saves.save_campaign(_state(3))  # written as v1
	saves.current_version = 3
	saves.migrations[1] = func(data: Dictionary) -> Dictionary:
		data["flags"]["steps"] = "1>2"
		return data
	saves.migrations[2] = func(data: Dictionary) -> Dictionary:
		data["flags"]["steps"] += ">3"
		return data
	var r: Variant = saves.load_campaign()
	assert_true(r.ok, "%s" % [r.problems])
	assert_eq(r.migrated_from, 1)
	assert_eq(r.state.flags["steps"], "1>2>3")
	assert_eq(r.state.day, 3)


func test_missing_migration_is_reported() -> void:
	saves.save_campaign(_state(1))
	saves.current_version = 2
	var r: Variant = saves.load_campaign()
	assert_false(r.ok)
	assert_true(r.problems[0].contains("no upgrade path from save v1"), "%s" % [r.problems])


func test_unknown_ids_are_reported_not_fatal() -> void:
	var content: Node = ContentDBScript.new()
	content.load_roots(ContentDBScript.DEFAULT_ROOTS)
	var s: CampaignState = _state(1)
	s.stock["hidden"]["itm_removed_in_patch"] = 1
	s.ensure_character("chr_ghost")
	var unknown: PackedStringArray = SaveScript.find_unknown_ids(s, content)
	assert_true("itm_removed_in_patch" in unknown)
	assert_true("chr_ghost" in unknown)
	assert_false("itm_trybuna_ludu" in unknown)
	assert_false("chr_marek" in unknown)
	content.free()


func test_empty_slot() -> void:
	var r: Variant = saves.load_campaign(7)
	assert_false(r.ok)
	assert_false(saves.has_save(7))
	assert_true(r.problems[0].contains("no save"))
