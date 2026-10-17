extends SceneTree
## Reproducible graphical capture through the normal viewport cursor. No selftest
## cursor override, forced inspection state or forged campaign data is used.
var desk: Node3D
var recording: bool = false
var frame_number: int = 0
var saved: int = 0
var output: String = "/tmp/kiosk81-desk-native"

func _initialize() -> void:
	call_deferred("run")

func _process(_delta: float) -> bool:
	if recording:
		frame_number += 1
		if frame_number % 2 == 0:
			root.get_texture().get_image().save_png(output.path_join("frames/%04d.png" % saved))
			saved += 1
	return false

func frames(count: int) -> void:
	for frame: int in count: await process_frame

func point(world: Vector3) -> void:
	if desk._desk_inspecting:
		root.warp_mouse(desk.player.camera.unproject_position(world))
	else:
		desk.player.camera.look_at(world, Vector3.UP)
	await frames(4)

func button(which: int, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = which
	event.pressed = pressed
	event.position = root.get_mouse_position()
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func motion(delta: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.relative = delta
	event.screen_relative = delta
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func shot(name: String) -> void:
	await frames(3)
	root.get_texture().get_image().save_png(output.path_join(name + ".png"))

func check(condition: bool, reason: String = "Normal viewport interaction failed") -> bool:
	if condition: return true
	push_error(reason)
	quit(1)
	return false

func run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): output = arg.trim_prefix("--capture=")
	DirAccess.make_dir_recursive_absolute(output.path_join("frames"))
	desk = load("res://scenes/kiosk/ration_desk_focus.tscn").instantiate()
	root.add_child(desk)
	await frames(70)
	await point(desk.card.global_position)
	recording = true
	button(MOUSE_BUTTON_LEFT, true)
	button(MOUSE_BUTTON_LEFT, false)
	await frames(14)
	if not check(desk.card_held, "normal one-click handoff must take the same card into the hand"): return
	await point(desk.workmat.global_position)
	desk._key(KEY_G)
	await frames(40)
	if not check(desk._desk_inspecting, "placing the held card must enter overhead"): return
	if not check((-desk.player.camera.global_basis.z).dot(Vector3.DOWN) > .995): return
	if not check(not desk._selftest and not desk._desk_cursor_override.is_finite()): return
	await shot("01_automatic_overhead")
	var origin: Vector3 = desk.card.global_position
	await point(origin)
	button(MOUSE_BUTTON_LEFT, true)
	await point(origin + Vector3(.065, 0, .025))
	await frames(12)
	button(MOUSE_BUTTON_RIGHT, true)
	motion(Vector2(45, 0))
	await frames(4)
	button(MOUSE_BUTTON_RIGHT, false)
	if not check(desk._paper_dragging and desk.card.position.y > 1.01): return
	await shot("02_lifted_paper")
	button(MOUSE_BUTTON_LEFT, false)
	await frames(12)
	await point(desk.props["scissors"].global_position + Vector3.UP * .012)
	if not check(desk._ray().get("collider") == desk.props["scissors"], "real viewport mouse must reach the tool"): return
	button(MOUSE_BUTTON_LEFT, true)
	button(MOUSE_BUTTON_LEFT, false)
	await frames(14)
	if not check(desk.held_tool == desk.props["scissors"]): return
	await point(desk.card.pixel_to_world(Vector2(30, 285)))
	button(MOUSE_BUTTON_LEFT, true)
	await point(desk.card.pixel_to_world(Vector2(170, 285)))
	await shot("03_scissors_open")
	await frames(6)
	await shot("04_scissors_closed")
	await frames(60)
	button(MOUSE_BUTTON_LEFT, false)
	await frames(12)
	if not check(desk._cut_length_m > .02 and not RationDeskRules.desk(root.get_node("Game").state).get("incisions", []).is_empty()): return
	await shot("05_persistent_incision")
	await point(desk.card.global_position)
	desk._key(KEY_R)
	await frames(16)
	desk._key(KEY_F)
	await frames(10)
	button(MOUSE_BUTTON_LEFT, true)
	motion(Vector2(65, -40))
	button(MOUSE_BUTTON_LEFT, false)
	await frames(12)
	await shot("06_physical_card")
	await frames(25)
	recording = false
	print("[normal viewport capture] PASS: single-click pickup, placement overhead, lifted/rotated paper, real-pointer scissors and persistent incision; %d frames" % saved)
	quit()
