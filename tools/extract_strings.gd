extends SceneTree
## Collects every player-facing content text into localization/content.csv
## (roadmap 1.11). Keeps existing translations; marks rows that need work:
##   _status = new      key appeared for the first time
##   _status = changed  English source changed since the translation was written
##   _status = todo     no Turkish yet
## Run: godot --headless --path . --script res://tools/extract_strings.gd

const ContentDBScript: GDScript = preload("res://game/content/content_db.gd")
const OUT: String = "res://localization/content.csv"
const TRANSLATED: PackedStringArray = ["tr"]


func _init() -> void:
	var db: Node = ContentDBScript.new()
	if not db.load_roots(ContentDBScript.DEFAULT_ROOTS):
		for problem: String in db.errors:
			printerr(problem)
		db.free()
		quit(1)
		return
	var rows: Array[PackedStringArray] = []
	for record: Dictionary in db.all_of("item"):
		rows.append(PackedStringArray([Loc.record_key(record["id"], "name"), record["name"]]))
	for record: Dictionary in db.all_of("character"):
		rows.append(PackedStringArray([Loc.record_key(record["id"], "name"), record["name"]]))
	for record: Dictionary in db.all_of("scenario"):
		rows.append(PackedStringArray([Loc.record_key(record["id"], "name"), record["name"]]))
		var visits: Array = record["visits"]
		for i: int in visits.size():
			rows.append(PackedStringArray(["%s.v%d.customer" % [record["id"], i], visits[i]["customer"]]))
	for record: Dictionary in db.all_of("dialogue"):
		var nodes: Dictionary = record["nodes"]
		for node_id: String in nodes:
			var node: Dictionary = nodes[node_id]
			var lines: Array = node.get("lines", [])
			for i: int in lines.size():
				rows.append(PackedStringArray([Loc.line_key(record["id"], node_id, i), lines[i]["text"]]))
			var choices: Array = node.get("choices", [])
			for i: int in choices.size():
				rows.append(PackedStringArray([Loc.choice_key(record["id"], node_id, i), choices[i]["text"]]))
	db.free()
	rows.sort_custom(func(a: PackedStringArray, b: PackedStringArray) -> bool: return a[0] < b[0])
	var old: Dictionary = _read_existing()
	var file: FileAccess = FileAccess.open(OUT, FileAccess.WRITE)
	var header: PackedStringArray = ["key", "en"]
	header.append_array(TRANSLATED)
	header.append("_status")
	file.store_csv_line(header)
	var todo: int = 0
	for row: PackedStringArray in rows:
		var key: String = row[0]
		var en: String = row[1]
		var before: Dictionary = old.get(key, {})
		var out: PackedStringArray = [key, en]
		var status: String = ""
		for lang: String in TRANSLATED:
			var translated: String = before.get(lang, "")
			out.append(translated)
			if translated == "":
				status = "todo"
		if before.is_empty():
			status = "new"
		elif before.get("en", "") != en:
			status = "changed"
		if status != "":
			todo += 1
		out.append(status)
		file.store_csv_line(out)
	file.close()
	for key: String in old:
		if not rows.any(func(r: PackedStringArray) -> bool: return r[0] == key):
			print("[extract] dropped key no longer in content: %s" % key)
	print("[extract] %d keys written to %s, %d need translation work" % [rows.size(), OUT, todo])
	quit(0)


func _read_existing() -> Dictionary:
	var out: Dictionary = {}
	var file: FileAccess = FileAccess.open(OUT, FileAccess.READ)
	if file == null:
		return out
	var header: PackedStringArray = file.get_csv_line()
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() < 2:
			continue
		var entry: Dictionary = {}
		for col: int in range(1, mini(row.size(), header.size())):
			entry[header[col]] = row[col]
		out[row[0]] = entry
	return out
