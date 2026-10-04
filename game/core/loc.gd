class_name Loc
extends RefCounted
## Localisation (roadmap 1.11). English is the source language: content files hold
## English text, and every player-facing text also has a stable key.
## Tables are CSV files in res://localization with a header like "key,en,tr".
## Columns whose name starts with "_" (for example "_status") are notes, not languages.
## The CSV files are kept as plain files (".import" = keep), so Godot does not
## turn them into .translation files; this class loads them at start.
##   Loc.text("dlg_x.ask.l0", "Trybuna Ludu, please.")  -> current language, else the English source
##   Loc.ui("ui.dialogue.continue")                       -> UI text from ui.csv

const TABLE_DIR: String = "res://localization"
const SOURCE_LANGUAGE: String = "en"
const LANGUAGES: PackedStringArray = ["en", "tr"]

static var _loaded: Array[Translation] = []


## Loads every table; returns the number of keys read. Safe to call again.
static func load_tables(dir: String = TABLE_DIR) -> int:
	for old: Translation in _loaded:
		TranslationServer.remove_translation(old)
	_loaded.clear()
	var by_locale: Dictionary[String, Translation] = {}
	var keys: int = 0
	for file_name: String in DirAccess.get_files_at(dir):
		if file_name.ends_with(".csv"):
			keys += _load_csv(dir.path_join(file_name), by_locale)
	for locale: String in by_locale:
		TranslationServer.add_translation(by_locale[locale])
		_loaded.append(by_locale[locale])
	return keys


static func _load_csv(path: String, by_locale: Dictionary[String, Translation]) -> int:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[loc] cannot open %s" % path)
		return 0
	var header: PackedStringArray = file.get_csv_line()
	if header.is_empty() or header[0] != "key":
		push_error("[loc] %s: first column must be 'key'" % path)
		return 0
	var count: int = 0
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() < 2 or row[0].strip_edges() == "" or row[0].begins_with("#"):
			continue
		count += 1
		for col: int in range(1, mini(row.size(), header.size())):
			var locale: String = header[col]
			if locale.begins_with("_") or row[col] == "":
				continue
			if not by_locale.has(locale):
				var t: Translation = Translation.new()
				t.locale = locale
				by_locale[locale] = t
			by_locale[locale].add_message(row[0], row[col].c_unescape())
	return count


## Player-facing content text: the translation for `key`, or the English source.
static func text(key: String, source: String) -> String:
	var translated: String = String(TranslationServer.translate(key))
	return source if translated == key or translated == "" else translated


## UI text from ui.csv; shows the key itself when it is missing (easy to spot).
static func ui(key: String) -> String:
	return String(TranslationServer.translate(key))


static func language() -> String:
	return TranslationServer.get_locale().substr(0, 2)


## Key helpers so every system builds keys the same way.
static func record_key(record_id: String, field: String) -> String:
	return "%s.%s" % [record_id, field]


static func line_key(dialogue_id: String, node_id: String, index: int) -> String:
	return "%s.%s.l%d" % [dialogue_id, node_id, index]


static func choice_key(dialogue_id: String, node_id: String, index: int) -> String:
	return "%s.%s.c%d" % [dialogue_id, node_id, index]
