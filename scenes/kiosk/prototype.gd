extends Node
## Playable prototype: one working day at the window (roadmap Faz 2, first slice).
## Not canon: invented customers, a simplified ration card, placeholder prices.
## Every change to the campaign goes through Game.apply_effects; this script only
## plays the visits, shows the panels and turns clicks into effects. The unseen
## half of the day (deliveries, everyday sales, the till to Ruch, family costs)
## is DaySimulator's, the same rules tools/simulate.gd measures.
## Controls: mouse to the screen edges = look · click cartons = refill shelves ·
## right click = inspect the document · hold Q = watch · F2 = language · F3 = dev panel.
## Cloud check: godot --path . res://scenes/kiosk/prototype.tscn -- --autoplay --fast --capture=<dir>

const SCENARIO_ID: String = "scn_prototype"
const RESTOCK_QTY: int = 5
const RESTOCK_MINUTES: int = 3
const YAW_MAX: float = 100.0
const PITCH_DOWN: float = -42.0
const PITCH_UP: float = 14.0
const REST_PITCH: float = -6.0
const EDGE_X: float = 0.72   # |x| past this (screen -1..1) turns the head
const EDGE_DOWN: float = 0.93
const EDGE_UP: float = -0.86

@onready var view: LoFiView = $LoFiView
@onready var sub_viewport: SubViewport = $LoFiView/SubViewport
@onready var world: Node3D = $LoFiView/SubViewport/World
@onready var seat: Node3D = $LoFiView/SubViewport/World/Seat
@onready var camera: Camera3D = $LoFiView/SubViewport/World/Seat/Camera3D
@onready var customer: CustomerPlaceholder = $LoFiView/SubViewport/Customer
@onready var tray_document: Node3D = $LoFiView/SubViewport/World/Kiosk/TrayDocument
@onready var dialogue: DialoguePanel = $UI/Dialogue
@onready var document_view: DocumentView = $UI/Document
@onready var decree: DecreeNote = $UI/Decree
@onready var day_end: DayEndPanel = $UI/DayEnd
@onready var hints: Label = $UI/Hints

var scenario: Dictionary = {}
var plan: ShiftPlan
var background: DaySimulator
var morning_report: Dictionary = {}
var suspicion_at_opening: int = 0
var runner: DialogueRunner
var visit: Dictionary = {}
var visit_index: int = -1
var step: DialogueRunner.Step
var hovered: Interactable
var yaw: float = 0.0
var pitch: float = REST_PITCH

var _applying: bool = false
var _look_locked: bool = false
var _autoplay: bool = false
var _speed: float = 1.0
var _capture_dir: String = ""
var _selftest: bool = false
var _captured: Dictionary = {}


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--autoplay":
			_autoplay = true
		elif arg == "--fast":
			_speed = 0.15
		elif arg == "--selftest":
			_selftest = true
		elif arg.begins_with("--capture="):
			_capture_dir = arg.trim_prefix("--capture=")
			DirAccess.make_dir_recursive_absolute(_capture_dir)
	scenario = ContentDB.get_record("scenario", SCENARIO_ID)
	if scenario.is_empty():
		push_error("[prototype] scenario %s missing; content errors: %s" % [SCENARIO_ID, ContentDB.errors])
		return
	customer.time_scale = _speed
	customer.visible = false
	tray_document.visible = false
	Game.effects_rejected.connect(func(reason: String) -> void: push_error("[prototype] effects rejected: " + reason))
	Game.state_changed.connect(_on_state_changed)
	Settings.language_changed.connect(_on_language_changed)
	dialogue.choice_made.connect(_on_choice)
	dialogue.close_requested.connect(_end_visit)
	day_end.save_requested.connect(_on_save)
	day_end.restart_requested.connect(func() -> void: get_tree().reload_current_scene())
	day_end.quit_requested.connect(func() -> void: get_tree().quit())
	Game.new_campaign(1981, scenario["start"])
	plan = ShiftPlan.new(scenario)
	var balance_record: Dictionary = ContentDB.get_record("balance", Balance.RECORD_ID)
	if balance_record.is_empty():
		push_error("[prototype] balance %s missing; content errors: %s" % [Balance.RECORD_ID, ContentDB.errors])
		return
	background = DaySimulator.new(Game.state, Balance.from_record(balance_record), ContentDB.all_of("item"))
	suspicion_at_opening = int(Game.state.meters.get("suspicion", 0))
	morning_report = _background(func() -> Dictionary: return background.morning())
	_apply(plan.opening_effects(Game.state))
	decree.refresh(Game.state.calendar_date)
	hints.text = Loc.ui("ui.hint.controls")
	get_tree().create_timer(30.0 * _speed).timeout.connect(func() -> void: create_tween().tween_property(hints, "modulate:a", 0.0, 2.0))
	_refresh_displays()
	_capture("00_opening")
	get_tree().create_timer(1.2 * _speed).timeout.connect(_next_visit)


# ---------------------------------------------------------------- visits

func _next_visit() -> void:
	visit = plan.next_visit(Game.state)
	if visit.is_empty():
		_close_day()
		return
	visit_index = plan.current_index()
	_apply(plan.arrival_effects(visit, Game.state))
	tray_document.visible = visit.has("document")
	customer.setup(visit.get("look", {}))
	customer.arrive()
	await customer.arrived
	runner = DialogueRunner.new(ContentDB.get_record("dialogue", visit["dialogue"]))
	_show(runner.start(Game.state))
	if _selftest and visit_index == 0:
		_run_selftest()


func _show(next_step: DialogueRunner.Step) -> void:
	if next_step == null:
		_end_visit()
		return
	step = next_step
	_applying = true
	_apply(step.effects)
	_applying = false
	dialogue.show_step(step, _speaker_names())
	if _autoplay:
		_autoplay_step()


func _on_choice(index: int) -> void:
	if runner == null:
		return
	_applying = true
	var effects: Array[Dictionary] = runner.choose(index)
	if runner.error == "":
		_apply(effects)
	_applying = false
	if runner.error != "":
		return
	_show(runner.next(Game.state))


func _end_visit() -> void:
	if visit.is_empty():
		return
	var leaving: Dictionary = visit
	visit = {}
	runner = null
	dialogue.visible = false
	document_view.close()
	tray_document.visible = false
	_apply(plan.departure_effects(leaving))
	customer.leave()
	await customer.left
	get_tree().create_timer(0.7 * _speed).timeout.connect(_next_visit)


func _speaker_names() -> Dictionary:
	var names: Dictionary = {
		"customer": Loc.text(plan.customer_key(visit_index), str(visit.get("customer", ""))),
		"player": Loc.text("chr_tadeusz.name", "Tadeusz Wolski").get_slice(" ", 0),
		"narrator": "",
	}
	for character: Dictionary in ContentDB.all_of("character"):
		names[character["id"]] = Loc.text(Loc.record_key(character["id"], "name"), character["name"]).get_slice(" ", 0)
	return names


# ---------------------------------------------------------------- day end

func _close_day() -> void:
	_apply(plan.closing_effects(Game.state))
	var window: Dictionary = ShiftPlan.ledger(Game.state)
	var report: Dictionary = _background(func() -> Dictionary: return background.evening(background.close(morning_report.duplicate())))
	var summary: Dictionary = DaySimulator.day_summary(report, Game.state, suspicion_at_opening)
	var today: PackedStringArray = []
	for entry: Dictionary in Game.state.decision_log:
		if int(entry.get("day", 0)) == Game.state.day:
			today.append(str(entry.get("id", "")))
	day_end.show_ledger(window, summary, today, Game.state.calendar_date)
	print("[prototype] day closed: %s" % summary)
	_capture("90_day_end", 2)
	if _autoplay:
		get_tree().create_timer(0.5).timeout.connect(_on_save)


func _on_save() -> void:
	_background(func() -> Dictionary: return background.night({}))
	var err: Error = SaveManager.save_campaign(Game.state)
	var message: String = Loc.ui("ui.ledger.saved") % DecreeNote.format_date(Game.state.calendar_date) if err == OK else "%s (%s)" % [Loc.ui("ui.ledger.save_failed"), error_string(err)]
	day_end.show_saved(message)
	print("[prototype] day saved: %s" % error_string(err))
	_capture("95_saved", 2)
	if _autoplay:
		get_tree().create_timer(1.0).timeout.connect(func() -> void: get_tree().quit())


# ---------------------------------------------------------------- the kiosk itself

func _process(delta: float) -> void:
	_update_look(delta)
	_update_hover()


func _update_look(delta: float) -> void:
	if document_view.visible or day_end.visible or _look_locked:
		return
	var screen: Vector2 = get_viewport().get_visible_rect().size
	var m: Vector2 = get_viewport().get_mouse_position() / screen * 2.0 - Vector2.ONE
	var target_yaw: float = -signf(m.x) * smoothstep(EDGE_X, 1.0, absf(m.x)) * YAW_MAX
	var target_pitch: float = REST_PITCH
	if m.y > EDGE_DOWN:
		target_pitch = PITCH_DOWN
	elif m.y < EDGE_UP:
		target_pitch = PITCH_UP
	yaw = lerpf(yaw, target_yaw, clampf(delta * 2.5, 0.0, 1.0))
	pitch = lerpf(pitch, target_pitch, clampf(delta * 2.5, 0.0, 1.0))
	seat.rotation_degrees.y = yaw
	camera.rotation_degrees.x = pitch


func _update_hover() -> void:
	var target: Interactable = null
	if get_viewport().gui_get_hovered_control() == null and not day_end.visible:
		target = _pick(get_viewport().get_mouse_position())
	if target != hovered:
		if hovered != null and is_instance_valid(hovered):
			hovered.set_hovered(false)
		hovered = target
		if hovered != null:
			hovered.set_hovered(true)


func _pick(mouse: Vector2) -> Interactable:
	var scale_to_sub: Vector2 = Vector2(sub_viewport.size) / view.size
	var at: Vector2 = mouse * scale_to_sub
	var from: Vector3 = camera.project_ray_origin(at)
	var to: Vector3 = from + camera.project_ray_normal(at) * 3.0
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to, 2)
	var hit: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	var node: Interactable = hit["collider"] as Interactable
	if node == null or not node.is_visible_in_tree():
		return null
	return node


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if hovered != null:
			_use(hovered)
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inspect"):
		_toggle_document()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).physical_keycode == KEY_F2:
		Settings.set_language("tr" if Settings.language == "en" else "en")


func _use(target: Interactable) -> void:
	match target.action:
		"restock":
			var qty: int = mini(RESTOCK_QTY, Game.state.stock_count("backroom", target.item_id))
			if qty <= 0:
				target.nudge()
				return
			_apply([
				{"op": "stock_move", "from": "backroom", "to": "shelf", "item": target.item_id, "qty": qty},
				{"op": "clock_advance", "minutes": RESTOCK_MINUTES},
			])
		"document":
			_toggle_document()


func _toggle_document() -> void:
	if document_view.visible:
		document_view.close()
	elif visit.has("document"):
		document_view.show_document(visit["document"])


## Shelf stacks follow the stock (roadmap 2.6: the shelf view is fed by the state).
func _refresh_displays() -> void:
	for display: Node3D in get_tree().get_nodes_in_group("stock_display"):
		var item_id: String = display.get_meta("item_id", "")
		var count: int = mini(Game.state.stock_count("shelf", item_id), int(display.get_meta("max_units", 8)))
		for child: Node in display.get_children():
			child.queue_free()
		var unit: Vector3 = display.get_meta("unit_size", Vector3(0.1, 0.02, 0.1))
		var step_by: Vector3 = display.get_meta("unit_step", Vector3(0, 0.02, 0))
		var color: Color = display.get_meta("color", Color.GRAY)
		for i: int in count:
			var mesh: BoxMesh = BoxMesh.new()
			mesh.size = unit
			var mat: ShaderMaterial = ShaderMaterial.new()
			mat.shader = preload("res://assets/shaders/lofi_world.gdshader")
			mat.set_shader_parameter("albedo", color.lightened(0.04 * float(i % 2)))
			mat.set_shader_parameter("grime", 0.3)
			mesh.material = mat
			var mi: MeshInstance3D = MeshInstance3D.new()
			mi.mesh = mesh
			mi.position = step_by * float(i) + Vector3(0, unit.y * 0.5, 0)
			display.add_child(mi)


func _on_state_changed(_state: CampaignState) -> void:
	_refresh_displays()
	if _applying or runner == null or step == null or step.finished or not dialogue.visible:
		return
	# Something changed while the customer waits (shelf refilled): offer the choices again.
	step = runner.refresh(Game.state)
	dialogue.show_choices(step)


func _on_language_changed(_language: String) -> void:
	decree.refresh(Game.state.calendar_date)
	hints.text = Loc.ui("ui.hint.controls")
	if runner != null and step != null and dialogue.visible and not step.finished:
		step = runner.refresh(Game.state)
		dialogue.show_step(step, _speaker_names())


## Runs one step of the unseen day on the current state and hands the result back
## to Game (one state, one owner). Errors are reported, never hidden.
func _background(job: Callable) -> Dictionary:
	background.state = Game.state
	var report: Dictionary = job.call()
	for error: String in background.errors:
		push_error("[prototype] background day: " + error)
	background.errors.clear()
	Game.load_state(background.state)
	return report


func _apply(effects: Array[Dictionary]) -> bool:
	if effects.is_empty():
		return true
	return Game.apply_effects(effects)


# ---------------------------------------------------------------- cloud checks

func _autoplay_step() -> void:
	await get_tree().create_timer(0.35).timeout
	if runner == null or step == null:
		return
	if visit_index == 1 and not _captured.has("20_document"):
		dialogue.visible = true
		_toggle_document()
		_capture("20_document", 2)
		await get_tree().create_timer(0.3).timeout
		document_view.close()
	if visit_index == 3 and not _captured.has("30_bribe"):
		_capture("30_bribe", 2)
	if visit_index == 0 and not _captured.has("10_first_customer"):
		_capture("10_first_customer", 2)
	if visit_index == 2 and not _captured.has("25_shelf_left") and _capture_dir != "":
		_look_locked = true
		for shot: Array in [["25_shelf_left", 72.0, -14.0], ["26_shelf_right", -72.0, -14.0], ["27_under_counter", 0.0, -42.0]]:
			seat.rotation_degrees.y = shot[1]
			camera.rotation_degrees.x = shot[2]
			await _capture(shot[0], 4)
		seat.rotation_degrees.y = yaw
		camera.rotation_degrees.x = pitch
		_look_locked = false
	if step.finished:
		_end_visit()
	elif not step.choices.is_empty():
		dialogue.choice_made.emit(step.choices[0]["index"])


## Checks the parts autoplay does not touch: pointing, refilling, language, watch.
func _run_selftest() -> void:
	var failures: PackedStringArray = []
	await get_tree().physics_frame
	await get_tree().physics_frame
	# 1. Pointing at a carton finds it (screen position from the 3D position).
	_look_locked = true
	camera.rotation_degrees.x = -42.0
	await get_tree().physics_frame
	var carton: Interactable = world.get_node("Kiosk/Cartons/Restock_itm_trybuna_ludu") as Interactable
	var on_sub: Vector2 = camera.unproject_position(carton.global_position)
	var on_screen: Vector2 = on_sub * view.size / Vector2(sub_viewport.size)
	var picked: Interactable = _pick(on_screen)
	if picked != carton:
		failures.append("pick: expected the Trybuna carton, got %s" % [picked])
	# 2. Using it moves five from the back room to the shelf and costs three minutes.
	var shelf_before: int = Game.state.stock_count("shelf", "itm_trybuna_ludu")
	var minute_before: int = Game.state.minute_of_day
	_use(carton)
	if Game.state.stock_count("shelf", "itm_trybuna_ludu") != shelf_before + RESTOCK_QTY:
		failures.append("restock: shelf did not grow by %d" % RESTOCK_QTY)
	if Game.state.minute_of_day != minute_before + RESTOCK_MINUTES:
		failures.append("restock: clock did not move %d minutes" % RESTOCK_MINUTES)
	var display: Node3D = world.get_node("Kiosk/Displays/Display_itm_trybuna_ludu")
	await get_tree().process_frame
	if display.get_child_count() != mini(shelf_before + RESTOCK_QTY, 12):
		failures.append("display: %d boxes for %d on the shelf" % [display.get_child_count(), shelf_before + RESTOCK_QTY])
	# 3. Language switch changes the dialogue on screen.
	var before: String = step.lines[0]["text"]
	Settings.set_language("tr" if Settings.language == "en" else "en")
	if step.lines[0]["text"] == before:
		failures.append("language: line did not change (%s)" % before)
	Settings.set_language("en")
	# 4. The watch shows the clock.
	var watch: WatchOverlay = $UI/Watch
	watch.show_state(Game.state)
	var expected: String = "%02d:%02d" % [Game.state.minute_of_day / 60, Game.state.minute_of_day % 60]
	if watch.get_child(0).get_child(0).text != expected:
		failures.append("watch: shows %s, expected %s" % [watch.get_child(0).get_child(0).text, expected])
	# 5. The developer panel describes the same state.
	if not DevPanel.describe(Game.state).contains(expected):
		failures.append("dev panel: time missing")
	_look_locked = false
	print("[selftest] %s" % ("PASS" if failures.is_empty() else "FAIL\n  " + "\n  ".join(failures)))
	get_tree().quit(0 if failures.is_empty() else 1)


func _capture(shot: String, wait_frames: int = 6) -> void:
	if _capture_dir == "" or _captured.has(shot):
		return
	_captured[shot] = true
	for i: int in wait_frames:
		await get_tree().process_frame
	var image: Image = get_viewport().get_texture().get_image()
	var path: String = _capture_dir.path_join(shot + ".png")
	print("[capture] %s -> %s" % [path, error_string(image.save_png(path))])
