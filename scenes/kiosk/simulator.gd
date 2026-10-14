extends Node3D
## Physical kiosk slice; models/views follow Game, commands belong to KioskTrading.

const PRODUCT_DIR: String = "res://assets/models/kiosk_products/"
const SLOT_SIZE: Vector3 = Vector3(0.34, 0.10, 0.30)

var trading: KioskTrading
var camera: Camera3D
var hand_view: Node3D
var slot_nodes: Array[Interactable] = []
var storage_nodes: Dictionary[String, Interactable] = {}
var tray: Interactable
var hovered: Interactable
var request_label: Label
var totals_label: Label
var hand_label: Label
var status_label: Label
var sell_button: Button
var hover_label: Label
var _selftest: bool = false
var _capture_dir: String = ""


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--selftest":
			_selftest = true
		elif arg.begins_with("--capture="):
			_capture_dir = arg.trim_prefix("--capture=")
	trading = KioskTrading.new(ContentDB.all_of("item"))
	_build_world()
	_build_ui()
	Game.state_changed.connect(_refresh)
	_restart()
	if _selftest:
		_run_selftest()


func _restart() -> void:
	Game.new_campaign(1982, trading.opening())
	status_label.text = "Bir ürüne tıkla, satış tablasına bırak ve satışı tamamla."


func _build_world() -> void:
	var environment: WorldEnvironment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("293d3b")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("fff1d4")
	environment.environment.ambient_light_energy = 0.65
	add_child(environment)
	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-65, -25, 0)
	light.light_energy = 1.1
	add_child(light)
	_box(self, Vector3(3.1, 0.12, 1.8), Vector3(0, 0.90, 0), Color("71533d"))
	_box(self, Vector3(3.15, 0.85, 0.06), Vector3(0, 0.44, 0.87), Color("45645b"))
	_box(self, Vector3(3.2, 2.3, 0.07), Vector3(0, 1.15, -1.3), Color("53685f"))
	for row: int in 2:
		_box(self, Vector3(2.3, 0.04, 0.3), Vector3(-0.35, 1.12 + row * 0.35, -1.02), Color("71533d"))
	camera = Camera3D.new()
	add_child(camera)
	camera.position = Vector3(0, 2.65, 3.35)
	camera.look_at(Vector3(0, 1.15, -0.15))
	camera.fov = 52
	camera.current = true
	hand_view = Node3D.new()
	hand_view.position = Vector3(0.27, -0.21, -0.65)
	hand_view.rotation_degrees = Vector3(25, -15, 0)
	camera.add_child(hand_view)
	for i: int in KioskTrading.SLOT_COUNT:
		var slot: Interactable = _target("slot", str(i), Vector3(-1.08 + (i % 4) * 0.38, 0.97, -0.55 + (i / 4) * 0.36), SLOT_SIZE, Color("947e5a"))
		slot.set_meta("index", i)
		slot_nodes.append(slot)
		var label: Label3D = _label(slot, "", Vector3(0, 0.10, 0.10), 0.0011)
		label.name = "Caption"
	for i: int in KioskCatalog.PRODUCTS.size():
		var item_id: String = KioskCatalog.PRODUCTS[i]["id"]
		var box: Interactable = _target("storage", item_id, Vector3(-1.25 + (i % 6) * 0.39, 1.15 + (i / 6) * 0.35, -1.02), Vector3(0.35, 0.20, 0.24), Color("b5996f"))
		var label: Label3D = _label(box, "", Vector3(0, 0.105, 0.15), 0.0011)
		label.name = "Caption"
		storage_nodes[item_id] = box
	tray = _target("tray", "", Vector3(0.88, 0.98, 0.02), Vector3(0.58, 0.07, 0.54), Color("7c9d8d"))
	_label(tray, "SATIŞ TABLASI", Vector3(0, 0.08, 0.19), 0.001)
	_label(self, "RUCH  •  1982", Vector3(0.95, 1.91, -1.1), 0.002)


func _target(action: String, item_id: String, at: Vector3, size: Vector3, color: Color) -> Interactable:
	var target: Interactable = Interactable.new()
	target.action = action
	target.item_id = item_id
	target.position = at
	target.collision_layer = 2
	target.collision_mask = 0
	add_child(target)
	var mesh_at: Vector3 = Vector3(0, size.y / 2, 0) if action == "storage" else Vector3.ZERO
	var mesh: MeshInstance3D = _box(target, Vector3(size.x, 0.018, size.z) if action == "slot" else size, mesh_at, color)
	mesh.name = "Surface"
	target.highlight_meshes = [NodePath("Surface")]
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position.y = size.y / 2
	target.add_child(collision)
	return target


func _box(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	instance.mesh = box
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance


func _label(parent: Node3D, text: String, at: Vector3, pixel_size: float) -> Label3D:
	var label: Label3D = Label3D.new()
	label.text = text
	label.position = at
	label.font_size = 32
	label.width = 310
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.pixel_size = pixel_size
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("fff5dc")
	label.outline_modulate = Color("302b24")
	label.outline_size = 6
	parent.add_child(label)
	return label


func _build_ui() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)
	var top: PanelContainer = PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 20
	top.offset_right = -20
	top.offset_top = 12
	canvas.add_child(top)
	var margin: MarginContainer = _margin(top)
	var rows: VBoxContainer = VBoxContainer.new()
	margin.add_child(rows)
	var title: Label = _ui_label(rows, "KIOSK '81  /  Kiosk Simulator", 24)
	title.modulate = Color("ecd5a4")
	request_label = _ui_label(rows, "", 22)
	totals_label = _ui_label(rows, "", 17)
	var bottom: PanelContainer = PanelContainer.new()
	canvas.add_child(bottom)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 20
	bottom.offset_right = -20
	bottom.offset_top = -205
	bottom.offset_bottom = -12
	var bottom_rows: VBoxContainer = VBoxContainer.new()
	_margin(bottom).add_child(bottom_rows)
	hover_label = _ui_label(bottom_rows, "", 19)
	hand_label = _ui_label(bottom_rows, "", 19)
	status_label = _ui_label(bottom_rows, "", 17)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var buttons: HBoxContainer = HBoxContainer.new()
	bottom_rows.add_child(buttons)
	sell_button = _button(buttons, "Satışı tamamla", func() -> void: _execute(trading.sell(Game.state), "Satış kaydedildi."))
	_button(buttons, "Eldekini geri bırak", func() -> void: _execute(trading.cancel_hand(Game.state), "Ürün geldiği yere bırakıldı."))
	_button(buttons, "Yeni deneme günü", _restart)
	_button(buttons, "Karne masası", func() -> void: get_tree().change_scene_to_file("res://scenes/kiosk/ration_desk.tscn"))
	_button(buttons, "Anlatı prototipi", func() -> void: get_tree().change_scene_to_file("res://scenes/kiosk/prototype.tscn"))
	_ui_label(bottom_rows, "Sol tık: al / boş yere bırak / satış tablasına koy  ·  Sağ tık veya Esc: eldeki ürünü geri bırak", 16)


func _margin(parent: Control) -> MarginContainer:
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	parent.add_child(margin)
	return margin


func _ui_label(parent: Control, text: String, size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _button(parent: Control, text: String, pressed: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(pressed)
	parent.add_child(button)
	return button


func _refresh(state: CampaignState) -> void:
	var layout: Array = KioskTrading.slots(state)
	for i: int in slot_nodes.size():
		var item_id: String = str(layout[i]) if i < layout.size() else ""
		_set_model(slot_nodes[i], item_id)
		(slot_nodes[i].get_node("Caption") as Label3D).text = KioskCatalog.title(item_id) if item_id != "" else "BOŞ YER"
	for item_id: String in storage_nodes:
		var box: Interactable = storage_nodes[item_id]
		(box.get_node("Caption") as Label3D).text = "%s\nDepo: %d" % [KioskCatalog.title(item_id), state.stock_count("backroom", item_id)]
		_set_model(box, item_id, 0.205)
	_set_model(tray, KioskTrading.located(state, "counter"), 0.05)
	_set_model(hand_view, KioskTrading.located(state, "hand"), 0.0)
	var want: String = trading.requested(state)
	var index: int = int(state.flags.get(KioskTrading.ORDER_KEY, 0))
	request_label.text = "Müşteri %d / %d: Bir adet %s istiyorum." % [index + 1, trading.order.size(), KioskCatalog.title(want)] if want != "" else "Gün tamamlandı! %d ürün satıldı. Ciro: %s" % [state.register.size(), Money.format(int(state.money["till"]) - 2000)]
	totals_label.text = "15 Şubat 1982  ·  Kasa: %s  ·  Satış: %d  ·  Fiyatlar geçici" % [Money.format(state.money["till"]), state.register.size()]
	var held: String = KioskTrading.located(state, "hand")
	var staged: String = KioskTrading.located(state, "counter")
	hand_label.text = "Elde: %s  |  Satış tablası: %s" % [KioskCatalog.title(held) if held != "" else "boş", KioskCatalog.title(staged) if staged != "" else "boş"]
	sell_button.disabled = want == "" or staged != want
	_update_hover()


func _set_model(parent: Node3D, item_id: String, height: float = 0.015) -> void:
	if parent.get_meta("shown", "?") == item_id:
		return
	parent.set_meta("shown", item_id)
	var old: Node = parent.get_node_or_null("Product")
	if old != null:
		parent.remove_child(old)
		old.queue_free()
	if item_id == "":
		return
	var path: String = PRODUCT_DIR + item_id + ".tscn"
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		push_error("Missing kiosk product model: " + path)
		return
	var model: Node3D = packed.instantiate() as Node3D
	model.name = "Product"
	model.position.y = height
	parent.add_child(model)


func _process(_delta: float) -> void:
	_update_hover()


func _update_hover() -> void:
	var next: Interactable = null
	if get_viewport().gui_get_hovered_control() == null:
		next = _pick(get_viewport().get_mouse_position())
	if next != hovered:
		if is_instance_valid(hovered):
			hovered.set_hovered(false)
		hovered = next
		if hovered != null:
			hovered.set_hovered(true)
	if hover_label != null:
		hover_label.text = _hover_text(hovered)


func _hover_text(target: Interactable) -> String:
	if target == null:
		return "Tezgâhtaki ürüne veya depodaki kutuya tıkla."
	if target.action == "storage":
		return "Depo: %s  ·  Tıkla: al / aynı ürünü geri bırak" % KioskCatalog.title(target.item_id)
	if target.action == "tray":
		return "Satış tablası  ·  Tıkla: ürünü koy / geri al"
	var item_id: String = str(KioskTrading.slots(Game.state)[int(target.get_meta("index"))])
	return "Boş tezgâh yeri  ·  Tıkla: elindeki ürünü bırak" if item_id == "" else "%s  ·  %s  ·  Tıkla: al" % [KioskCatalog.title(item_id), Money.format(int(ContentDB.get_record("item", item_id)["price"]))]


func _pick(at: Vector2) -> Interactable:
	var from: Vector3 = camera.project_ray_origin(at)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, from + camera.project_ray_normal(at) * 6, 2)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return hit.get("collider") as Interactable


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var button: int = (event as InputEventMouseButton).button_index
		if button == MOUSE_BUTTON_LEFT:
			var target: Interactable = _pick((event as InputEventMouseButton).position)
			if target != null:
				_use(target)
				get_viewport().set_input_as_handled()
		elif button == MOUSE_BUTTON_RIGHT:
			_execute(trading.cancel_hand(Game.state), "Ürün geldiği yere bırakıldı.")
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		_execute(trading.cancel_hand(Game.state), "Ürün geldiği yere bırakıldı.")


func _use(target: Interactable) -> void:
	var result: Dictionary
	match target.action:
		"slot":
			result = trading.use_slot(Game.state, int(target.get_meta("index")))
		"storage":
			result = trading.take_storage(Game.state, target.item_id) if KioskTrading.located(Game.state, "hand") == "" else trading.return_storage(Game.state, target.item_id)
		"tray":
			result = trading.use_tray(Game.state)
		_:
			return
	_execute(result, "Ürün taşındı.")


func _execute(command: Dictionary, message: String) -> bool:
	if not command["ok"]:
		status_label.text = command["error"]
		return false
	var effects: Array[Dictionary] = []
	effects.assign(command["effects"])
	if not Game.apply_effects(effects):
		status_label.text = "İşlem uygulanamadı; durum değiştirilmedi."
		return false
	status_label.text = message
	return true


func _run_selftest() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var failures: PackedStringArray = []
	for target: Interactable in slot_nodes + storage_nodes.values() + [tray]:
		var screen: Vector2 = camera.unproject_position(target.global_position + Vector3(0, 0.04, 0))
		if _pick(screen) != target:
			failures.append("ray pick failed: %s/%s" % [target.action, target.item_id])
	# Exercise real mouse dispatch, not only command calls.
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = get_viewport().get_final_transform() * camera.unproject_position(slot_nodes[0].global_position + Vector3(0, 0.04, 0))
	click.global_position = click.position
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = click.position
	motion.global_position = click.position
	Input.parse_input_event(motion)
	Input.parse_input_event(click)
	Input.flush_buffered_events()
	await get_tree().process_frame
	var release: InputEventMouseButton = click.duplicate() as InputEventMouseButton
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	if KioskTrading.located(Game.state, "hand") != trading.order[0]:
		failures.append("mouse input did not pick up the first product")
	var cancel: InputEventKey = InputEventKey.new()
	cancel.physical_keycode = KEY_ESCAPE
	cancel.pressed = true
	Input.parse_input_event(cancel)
	Input.flush_buffered_events()
	await get_tree().process_frame
	if KioskTrading.located(Game.state, "hand") != "":
		failures.append("Esc input did not return the product")
	for item_id: String in trading.order:
		var index: int = KioskTrading.slots(Game.state).find(item_id)
		_use(slot_nodes[index])
		if KioskTrading.located(Game.state, "hand") != item_id or hand_view.get_node_or_null("Product") == null:
			failures.append("pickup/model failed: " + item_id)
		_use(slot_nodes[index])
		_use(slot_nodes[index])
		_use(tray)
		_use(tray)
		_use(tray)
		var sales_before: int = Game.state.register.size()
		sell_button.pressed.emit()
		if Game.state.register.size() != sales_before + 1:
			failures.append("sale failed: " + item_id)
		_use(storage_nodes[item_id])
		_use(slot_nodes[index])
	if Game.state.register.size() != trading.order.size() or trading.requested(Game.state) != "":
		failures.append("customer sequence did not finish")
	if _capture_dir != "" and DisplayServer.get_name() != "headless":
		_restart()
		await _capture("01_counter")
		_use(slot_nodes[0])
		await _capture("02_pickup")
		_use(tray)
		await _capture("03_sale_tray")
	print("[kiosk selftest] %s" % ("PASS: 12 models, 25 ray targets, pickup/return/stage/sell/restock" if failures.is_empty() else "FAIL: " + "; ".join(failures)))
	get_tree().quit(0 if failures.is_empty() else 1)


func _capture(name: String) -> void:
	DirAccess.make_dir_recursive_absolute(_capture_dir)
	for i: int in 4:
		await get_tree().process_frame
	var picture: Image = get_viewport().get_texture().get_image()
	var err: Error = picture.save_png(_capture_dir.path_join(name + ".png"))
	if err != OK:
		push_error("Capture failed: " + error_string(err))
