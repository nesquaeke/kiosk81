extends Node
## SaveManager (autoload, roadmap 1.9). The campaign is saved only at day
## boundaries (game rule, enforced by the day flow), as versioned JSON:
##   {"format": "kiosk81-save", "version": 1, "saved_at": <unix>, "checksum": <sha256>, "data": {...}}
## Writing is crash-safe: write <slot>.tmp, rotate backups (.bak1 newest .. .bak3),
## then rename .tmp to the real file. Loading falls back to the newest good backup.
## Old versions are upgraded step by step through `migrations`.

const FORMAT: String = "kiosk81-save"
const BACKUPS: int = 3

## Where slots live; tests point this somewhere else.
var save_dir: String = "user://saves"
## The version this build writes.
var current_version: int = 1
## from_version -> Callable(data: Dictionary) -> Dictionary returning version + 1 data.
var migrations: Dictionary[int, Callable] = {}


class LoadResult:
	extends RefCounted
	var ok: bool = false
	var state: CampaignState = null
	## "slot_1.json", "slot_1.json.bak2", ... the file that was actually used.
	var used_file: String = ""
	## Problems met on the way (a broken main file before a good backup, for example).
	var problems: PackedStringArray = []
	var migrated_from: int = 0


func slot_path(slot: int) -> String:
	return save_dir.path_join("slot_%d.json" % slot)


func has_save(slot: int) -> bool:
	for path: String in _candidates(slot):
		if FileAccess.file_exists(path):
			return true
	return false


func save_campaign(state: CampaignState, slot: int = 1) -> Error:
	DirAccess.make_dir_recursive_absolute(save_dir)
	var data: Dictionary = state.to_dict()
	var envelope: Dictionary = {
		"format": FORMAT,
		"version": current_version,
		"saved_at": int(Time.get_unix_time_from_system()),
		"checksum": checksum(data),
		"data": data,
	}
	var path: String = slot_path(slot)
	var tmp: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(envelope, "\t", true))
	file.close()
	# Rotate: bak2 -> bak3, bak1 -> bak2, main -> bak1.
	for i: int in range(BACKUPS - 1, 0, -1):
		var older: String = "%s.bak%d" % [path, i]
		if FileAccess.file_exists(older):
			DirAccess.rename_absolute(older, "%s.bak%d" % [path, i + 1])
	if FileAccess.file_exists(path):
		DirAccess.rename_absolute(path, path + ".bak1")
	return DirAccess.rename_absolute(tmp, path)


func load_campaign(slot: int = 1) -> LoadResult:
	var result: LoadResult = LoadResult.new()
	for path: String in _candidates(slot):
		if not FileAccess.file_exists(path):
			continue
		var problem: String = _try_load(path, result)
		if problem == "":
			result.ok = true
			result.used_file = path.get_file()
			return result
		result.problems.append("%s: %s" % [path.get_file(), problem])
	if result.problems.is_empty():
		result.problems.append("no save in slot %d" % slot)
	return result


## Stable checksum over the data with sorted keys.
static func checksum(data: Dictionary) -> String:
	return JSON.stringify(data, "", true).sha256_text()


## Ids in the state that the loaded content does not know (a removed item, a
## renamed character). The game keeps them and reports them; it never crashes.
static func find_unknown_ids(state: CampaignState, content: Node) -> PackedStringArray:
	var unknown: PackedStringArray = []
	for character_id: String in state.characters:
		if character_id.begins_with("chr_") and not content.call("has_id", character_id):
			unknown.append(character_id)
	for location: String in state.stock:
		for item_id: Variant in state.stock[location]:
			if not content.call("has_id", str(item_id)) and not str(item_id) in unknown:
				unknown.append(str(item_id))
	return unknown


func _candidates(slot: int) -> PackedStringArray:
	var path: String = slot_path(slot)
	var list: PackedStringArray = [path]
	for i: int in range(1, BACKUPS + 1):
		list.append("%s.bak%d" % [path, i])
	return list


func _try_load(path: String, result: LoadResult) -> String:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		return "empty or unreadable file"
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return "damaged JSON at line %d (%s)" % [json.get_error_line() + 1, json.get_error_message()]
	if typeof(json.data) != TYPE_DICTIONARY:
		return "not a save file"
	var envelope: Dictionary = CampaignState.normalize_numbers(json.data)
	if envelope.get("format") != FORMAT:
		return "not a KIOSK '81 save"
	if typeof(envelope.get("data")) != TYPE_DICTIONARY or typeof(envelope.get("version")) != TYPE_INT:
		return "missing data or version"
	var data: Dictionary = envelope["data"]
	if checksum(data) != str(envelope.get("checksum", "")):
		return "checksum does not match (file changed or damaged)"
	var version: int = envelope["version"]
	if version > current_version:
		return "made by a newer version of the game (save v%d, game v%d)" % [version, current_version]
	if version < current_version:
		result.migrated_from = version
	while version < current_version:
		if not migrations.has(version):
			return "no upgrade path from save v%d" % version
		data = migrations[version].call(data)
		version += 1
	result.state = CampaignState.from_dict(data)
	return ""
