extends Node
## Visual sketch (roadmap 1.6b): a look-only scene to judge the lo-fi style early.
## No gameplay. Built by tools/build_visual_sketch.gd; edit the builder, not the .tscn.
## Keys (sketch only, not the final input map):
##   mouse = look (click to capture, Esc to release) · 1-4 = retro level
##   L = desk lamp · E = test document (always crisp, never distorted)
## Cloud check: godot --path . res://scenes/sketch/visual_sketch.tscn -- --capture=<dir>

const MOUSE_SENSITIVITY: float = 0.12  # degrees per pixel
const YAW_LIMIT: float = 100.0  # Yol Plani: seated look limits
const PITCH_DOWN: float = -60.0
const PITCH_UP: float = 35.0

# name, retro level, yaw, pitch, document open
const CAPTURE_SHOTS: Array[Array] = [
	["k1_orta", 2, 0.0, -4.0, false],
	["k1_kapali", 0, 0.0, -4.0, false],
	["k1_hafif", 1, 0.0, -4.0, false],
	["k1_guclu", 3, 0.0, -4.0, false],
	["raf_sol_orta", 2, 72.0, -6.0, false],
	["raf_sag_orta", 2, -72.0, -6.0, false],
	["tezgah_orta", 2, 0.0, -40.0, false],
	["belge_orta", 2, 0.0, -4.0, true],
]

@onready var lofi_view: LoFiView = $LoFiView
@onready var seat: Node3D = $LoFiView/SubViewport/World/Seat
@onready var camera: Camera3D = $LoFiView/SubViewport/World/Seat/Camera3D
@onready var desk_lamp: SpotLight3D = $LoFiView/SubViewport/World/Kiosk/DeskLamp/Light
@onready var lamp_bulb: MeshInstance3D = $LoFiView/SubViewport/World/Kiosk/DeskLamp/Bulb
@onready var hint: Label = $UI/Hint
@onready var document: Control = $UI/Document

var _yaw: float = 0.0
var _pitch: float = -4.0


func _ready() -> void:
	Settings.retro_level_changed.connect(_on_retro_changed)
	_apply_look()
	_refresh_hint()
	var capture_dir: String = _capture_dir()
	if not capture_dir.is_empty():
		_run_capture(capture_dir)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: InputEventMouseMotion = event
		_yaw -= motion.relative.x * MOUSE_SENSITIVITY
		_pitch -= motion.relative.y * MOUSE_SENSITIVITY
		_apply_look()
	elif event is InputEventKey and event.pressed and not event.echo:
		var key: InputEventKey = event
		match key.physical_keycode:
			KEY_1, KEY_2, KEY_3, KEY_4:
				Settings.set_retro_level(key.physical_keycode - KEY_1)
			KEY_L:
				_toggle_lamp()
			KEY_E:
				document.visible = not document.visible
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _apply_look() -> void:
	_yaw = clampf(_yaw, -YAW_LIMIT, YAW_LIMIT)
	_pitch = clampf(_pitch, PITCH_DOWN, PITCH_UP)
	seat.rotation_degrees.y = _yaw
	camera.rotation_degrees.x = _pitch


func _toggle_lamp() -> void:
	desk_lamp.visible = not desk_lamp.visible
	lamp_bulb.visible = desk_lamp.visible


func _on_retro_changed(_level: int) -> void:
	_refresh_hint()


func _refresh_hint() -> void:
	var size: Vector2i = lofi_view.internal_size()
	hint.text = "Retro: %s (3B: %d×%d)   |   1-4 retro · L lamba · E belge · tıkla: fareyle bak · Esc: fareyi bırak" % [
		lofi_view.profile.display_name(), size.x, size.y]


func _capture_dir() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			return arg.trim_prefix("--capture=")
	return ""


func _run_capture(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	for shot: Array in CAPTURE_SHOTS:
		Settings.set_retro_level(shot[1])
		_yaw = shot[2]
		_pitch = shot[3]
		_apply_look()
		document.visible = shot[4]
		for i: int in 8:
			await get_tree().process_frame
		var image: Image = get_viewport().get_texture().get_image()
		var path: String = dir.path_join("%s.png" % shot[0])
		print("[capture] %s -> %s" % [path, error_string(image.save_png(path))])
	get_tree().quit()
