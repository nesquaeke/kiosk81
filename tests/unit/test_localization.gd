extends TestCase
## Localisation tables and fallbacks (roadmap 1.11).

var _locale_before: String = ""


func before_each() -> void:
	_locale_before = TranslationServer.get_locale()
	Loc.load_tables()


func after_each() -> void:
	TranslationServer.set_locale(_locale_before)


func test_text_changes_with_language() -> void:
	TranslationServer.set_locale("en")
	assert_eq(Loc.text("itm_matches.name", "Matches"), "Matches")
	assert_eq(Loc.ui("ui.dialogue.continue"), "Continue")
	TranslationServer.set_locale("tr")
	assert_eq(Loc.text("itm_matches.name", "Matches"), "Kibrit")
	assert_eq(Loc.ui("ui.dialogue.continue"), "Devam")


func test_missing_translation_falls_back_to_english_source() -> void:
	TranslationServer.set_locale("tr")
	assert_eq(Loc.text("no.such.key", "Source text"), "Source text")


func test_missing_ui_key_shows_the_key() -> void:
	assert_eq(Loc.ui("ui.not_written_yet"), "ui.not_written_yet")


func test_reloading_does_not_duplicate_tables() -> void:
	var first: int = Loc.load_tables()
	var second: int = Loc.load_tables()
	assert_eq(first, second)
	assert_true(first > 0)


func test_every_content_text_has_turkish() -> void:
	var file: FileAccess = FileAccess.open("res://localization/content.csv", FileAccess.READ)
	var header: PackedStringArray = file.get_csv_line()
	var tr_col: int = header.find("tr")
	assert_true(tr_col > 0)
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() > tr_col:
			assert_ne(row[tr_col], "", "missing Turkish for %s" % row[0])


func test_key_helpers() -> void:
	assert_eq(Loc.line_key("dlg_a", "start", 2), "dlg_a.start.l2")
	assert_eq(Loc.choice_key("dlg_a", "start", 0), "dlg_a.start.c0")
	assert_eq(Loc.record_key("itm_x", "name"), "itm_x.name")
