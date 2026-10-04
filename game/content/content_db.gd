extends Node
## ContentDB (autoload, roadmap 1.8): loads every content JSON file once at start,
## validates it and answers lookups. Game code never reads content files directly.
## File format and field rules: game/content/content_schema.gd.
## Errors name the file, the JSON path and (when it can be found) the line:
##   res://content/items/items.json:14 records[2].price: must be a whole number, 0 or more

signal loaded(error_count: int)

const DEFAULT_ROOTS: PackedStringArray = ["res://content", "res://dialogue"]

## type -> {id -> record}
var records: Dictionary[String, Dictionary] = {}
## id -> file it came from
var sources: Dictionary[String, String] = {}
var errors: PackedStringArray = []
var file_count: int = 0


func _ready() -> void:
	load_roots(DEFAULT_ROOTS)
	if not errors.is_empty():
		for problem: String in errors:
			push_error("[content] " + problem)
	print("[content] %d files, %d records, %d errors" % [file_count, record_count(), errors.size()])


## Loads (or reloads) everything under the given folders. Returns true when clean.
func load_roots(roots: PackedStringArray) -> bool:
	records.clear()
	sources.clear()
	errors.clear()
	file_count = 0
	for type_name: String in ContentSchema.TYPES:
		records[type_name] = {}
	var refs: Array = []
	var texts: Dictionary = {}
	for root: String in roots:
		for path: String in _json_files(root):
			_load_file(path, refs, texts)
	_check_refs(refs, texts)
	loaded.emit(errors.size())
	return errors.is_empty()


func get_record(type_name: String, id: String) -> Dictionary:
	return (records.get(type_name, {}) as Dictionary).get(id, {})


func has_id(id: String) -> bool:
	return sources.has(id)


func all_of(type_name: String) -> Array:
	return (records.get(type_name, {}) as Dictionary).values()


func record_count() -> int:
	return sources.size()


# ---------------------------------------------------------------- loading

func _json_files(root: String) -> PackedStringArray:
	var found: PackedStringArray = []
	var dir: DirAccess = DirAccess.open(root)
	if dir == null:
		return found
	for file_name: String in dir.get_files():
		if file_name.ends_with(".json"):
			found.append(root.path_join(file_name))
	for sub: String in dir.get_directories():
		if not sub.begins_with("."):
			found.append_array(_json_files(root.path_join(sub)))
	found.sort()
	return found


func _load_file(path: String, refs: Array, texts: Dictionary) -> void:
	file_count += 1
	var text: String = FileAccess.get_file_as_string(path)
	texts[path] = text
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		errors.append("%s:%d JSON error: %s" % [path, json.get_error_line() + 1, json.get_error_message()])  # Godot counts lines from 0
		return
	var data: Variant = CampaignState.normalize_numbers(json.data)
	if typeof(data) != TYPE_DICTIONARY:
		errors.append("%s: the file must hold an object with 'type' and 'records'" % path)
		return
	var file_data: Dictionary = data
	var type_name: String = str(file_data.get("type", ""))
	if not ContentSchema.TYPES.has(type_name):
		errors.append("%s: unknown type '%s' (known: %s)" % [path, type_name, ", ".join(PackedStringArray(ContentSchema.TYPES.keys()))])
		return
	if typeof(file_data.get("records")) != TYPE_ARRAY:
		errors.append("%s: 'records' must be a list" % path)
		return
	for key: Variant in file_data:
		if not str(key) in ["type", "records"]:
			errors.append("%s: unknown top-level field '%s'" % [path, str(key)])
	var list: Array = file_data["records"]
	for i: int in list.size():
		var record: Variant = list[i]
		var record_path: String = "records[%d]" % i
		var file_refs: Array = []
		for problem: String in ContentSchema.check_record(type_name, record, record_path, file_refs):
			errors.append(_locate(path, text, record, problem))
		for ref: Array in file_refs:
			refs.append([ref[0], ref[1], ref[2], path, record])
		if typeof(record) != TYPE_DICTIONARY or typeof((record as Dictionary).get("id")) != TYPE_STRING:
			continue
		var id: String = record["id"]
		if sources.has(id):
			errors.append(_locate(path, text, record, "%s.id: duplicate id '%s' (first in %s)" % [record_path, id, sources[id]]))
			continue
		sources[id] = path
		(records[type_name] as Dictionary)[id] = record


func _check_refs(refs: Array, texts: Dictionary) -> void:
	for ref: Array in refs:
		var wanted_type: String = ref[0]
		var id: String = ref[1]
		if not (records.get(wanted_type, {}) as Dictionary).has(id):
			var file_path: String = ref[3]
			errors.append(_locate(file_path, texts.get(file_path, ""), ref[4],
					"%s: unknown %s '%s'" % [ref[2], wanted_type, id]))


## Prefixes a problem with "file:line" using the line where the record's id appears.
func _locate(path: String, text: String, record: Variant, problem: String) -> String:
	var line: int = 0
	if typeof(record) == TYPE_DICTIONARY and typeof((record as Dictionary).get("id")) == TYPE_STRING:
		var at: int = text.find("\"%s\"" % record["id"])
		if at >= 0:
			line = text.substr(0, at).count("\n") + 1
	return "%s:%d %s" % [path, line, problem] if line > 0 else "%s %s" % [path, problem]
