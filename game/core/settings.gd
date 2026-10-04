extends Node
## Settings (autoload): player-facing options such as accessibility,
## display and audio levels. Stored separately from the campaign save.
## So far: retro intensity (visual sketch, roadmap 1.6b) and language (1.11).
## Saving the settings to disk comes with the settings menu (roadmap 2.12).

signal retro_level_changed(level: int)
signal language_changed(language: String)

var retro_level: int = LoFiProfile.DEFAULT_LEVEL
var language: String = Loc.SOURCE_LANGUAGE


func _ready() -> void:
	Loc.load_tables()
	# First start: follow the system language when we have it (Turkish players get Turkish).
	var system: String = OS.get_locale_language()
	set_language(system if system in Loc.LANGUAGES else Loc.SOURCE_LANGUAGE)


func set_retro_level(level: int) -> void:
	var clamped: int = clampi(level, LoFiProfile.Level.OFF, LoFiProfile.Level.STRONG)
	if clamped == retro_level:
		return
	retro_level = clamped
	retro_level_changed.emit(retro_level)


func set_language(code: String) -> void:
	if not code in Loc.LANGUAGES:
		push_warning("[settings] unknown language '%s'" % code)
		return
	language = code
	TranslationServer.set_locale(code)
	language_changed.emit(code)
