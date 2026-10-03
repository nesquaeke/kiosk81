extends Node
## Settings (autoload): player-facing options such as accessibility,
## display and audio levels. Stored separately from the campaign save.
## So far only the retro intensity exists (visual sketch, roadmap 1.6b);
## saving to disk comes with the settings menu (roadmap 2.12).

signal retro_level_changed(level: int)

var retro_level: int = LoFiProfile.DEFAULT_LEVEL


func set_retro_level(level: int) -> void:
	var clamped: int = clampi(level, LoFiProfile.Level.OFF, LoFiProfile.Level.STRONG)
	if clamped == retro_level:
		return
	retro_level = clamped
	retro_level_changed.emit(retro_level)
