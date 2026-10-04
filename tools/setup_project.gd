extends SceneTree
## Tool (roadmap 1.3, extended in 1.6b): writes project settings and the boot scene.
## Run: godot --headless --path . --script res://tools/setup_project.gd


func _init() -> void:
	_apply_settings()
	_add_inputs()
	_add_autoloads()
	_add_shader_globals()
	var err: Error = ProjectSettings.save()
	print("[setup] project settings saved: ", error_string(err))
	_build_main_scene()
	quit()


func _apply_settings() -> void:
	ProjectSettings.set_setting("application/config/name", "KIOSK '81")
	ProjectSettings.set_setting("application/config/description", "First-person narrative kiosk simulation, Warsaw 1981-1989.")
	ProjectSettings.set_setting("application/config/features", PackedStringArray(["4.7", "Forward Plus"]))
	ProjectSettings.set_setting("application/run/main_scene", "res://scenes/main/main.tscn")
	ProjectSettings.set_setting("display/window/size/viewport_width", 1920)
	ProjectSettings.set_setting("display/window/size/viewport_height", 1080)
	ProjectSettings.set_setting("display/window/stretch/mode", "canvas_items")
	ProjectSettings.set_setting("display/window/stretch/aspect", "expand")
	ProjectSettings.set_setting("rendering/renderer/rendering_method", "forward_plus")
	# Typed GDScript: untyped declarations are errors (2 = error).
	ProjectSettings.set_setting("debug/gdscript/warnings/untyped_declaration", 2)
	var layers: PackedStringArray = ["World", "Interactable", "Customer", "Slot", "PlayerBody"]
	for i: int in layers.size():
		ProjectSettings.set_setting("layer_names/3d_physics/layer_%d" % (i + 1), layers[i])


func _key(code: Key) -> InputEventKey:
	var ev: InputEventKey = InputEventKey.new()
	ev.physical_keycode = code
	ev.device = -1  # all devices
	return ev


func _mouse(button: MouseButton) -> InputEventMouseButton:
	var ev: InputEventMouseButton = InputEventMouseButton.new()
	ev.button_index = button
	ev.device = -1  # all devices
	return ev


func _add_inputs() -> void:
	var actions: Dictionary[String, InputEvent] = {
		"interact": _mouse(MOUSE_BUTTON_LEFT),
		"inspect": _mouse(MOUSE_BUTTON_RIGHT),
		"cancel": _key(KEY_ESCAPE),
		"stand_toggle": _key(KEY_SPACE),
		"move_forward": _key(KEY_W),
		"move_back": _key(KEY_S),
		"move_left": _key(KEY_A),
		"move_right": _key(KEY_D),
		"look_watch": _key(KEY_Q),
		"debug_panel": _key(KEY_F3),
	}
	for action: String in actions:
		ProjectSettings.set_setting("input/" + action, {"deadzone": 0.2, "events": [actions[action]]})


func _add_autoloads() -> void:
	# Order matters: later autoloads may use earlier ones.
	ProjectSettings.set_setting("autoload/Settings", "*res://game/core/settings.gd")
	ProjectSettings.set_setting("autoload/ContentDB", "*res://game/content/content_db.gd")
	ProjectSettings.set_setting("autoload/Game", "*res://game/core/game.gd")
	ProjectSettings.set_setting("autoload/SaveManager", "*res://game/save/save_manager.gd")
	ProjectSettings.set_setting("autoload/Audio", "*res://game/core/audio_manager.gd")


func _add_shader_globals() -> void:
	# Lo-fi look (Gorsel Hedef, section 9); LoFiView changes them at runtime.
	# Start values match the default retro level (Hafif).
	ProjectSettings.set_setting("shader_globals/lofi_affine", {"type": "float", "value": 0.2})
	ProjectSettings.set_setting("shader_globals/lofi_snap_grid", {"type": "vec2", "value": Vector2(960, 540)})


func _build_main_scene() -> void:
	if FileAccess.file_exists("res://scenes/main/main.tscn"):
		print("[setup] main scene exists, left unchanged")
		return
	var root: Node3D = Node3D.new()
	root.name = "Main"
	root.set_script(load("res://scenes/main/main.gd"))

	var env_node: WorldEnvironment = WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#1f1a20")  # Gorsel Hedef: dis gece golgesi
	env_node.environment = env
	root.add_child(env_node)

	var cam: Camera3D = Camera3D.new()
	cam.name = "Camera3D"
	cam.fov = 65.0  # Yol Plani, gri kutu olculeri
	cam.position = Vector3(0.0, 1.25, 0.0)
	root.add_child(cam)

	var ui: CanvasLayer = CanvasLayer.new()
	ui.name = "UI"
	root.add_child(ui)
	var label: Label = Label.new()
	label.name = "Status"
	label.text = "KIOSK '81 - project skeleton ready (step 1.3)"
	label.position = Vector2(48.0, 48.0)
	label.add_theme_color_override("font_color", Color("#d4dad8"))
	label.add_theme_font_size_override("font_size", 28)
	ui.add_child(label)

	for child: Node in [env_node, cam, ui, label]:
		child.owner = root

	var packed: PackedScene = PackedScene.new()
	var err: Error = packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, "res://scenes/main/main.tscn")
	print("[setup] main scene saved: ", error_string(err))
	root.free()
