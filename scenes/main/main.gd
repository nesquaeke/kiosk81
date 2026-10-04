extends Node3D
## Boot scene. For now it only proves that the project starts
## and that every autoload is present.

const AUTOLOADS: PackedStringArray = ["Settings", "ContentDB", "Game", "SaveManager", "Audio", "DevPanel"]


func _ready() -> void:
	for autoload_name: String in AUTOLOADS:
		var present: bool = get_tree().root.has_node(autoload_name)
		print("[boot] autoload %s: %s" % [autoload_name, "ok" if present else "MISSING"])
	print("[boot] KIOSK '81 skeleton ready on Godot %s" % Engine.get_version_info().string)
