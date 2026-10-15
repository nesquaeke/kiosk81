extends Node3D
## Physical first-person workflow. The document UI is ink on a 3D object only.

const REACH: float = 2.5
var player: KioskFPSPlayer
var card: RationCard3D
var customer: CustomerPlaceholder
var customer_target: Interactable
var workmat: Interactable
var drawer: Interactable
var coupon_bin: Node3D
var bell: Interactable
var parcel: RationParcel3D
var props: Dictionary[String, Interactable] = {}
var shelves: Dictionary[String, Interactable] = {}
var homes: Dictionary[Node3D, Transform3D] = {}
var shelf_labels: Dictionary[String, Label3D] = {}
var pages: Dictionary[String, RichTextLabel] = {}
var page_viewports: Dictionary[String, SubViewport] = {}
var left_hand: Node3D
var right_hand: Node3D
var held_tool: Interactable
var card_held: bool = false
var rules: RationDeskRules
var foley: RationFoley
var hint: Label
var subtitle: Label
var message: Label
var pause: PanelContainer
var _index: int = -1
var _epoch: int = 0
var _window_ready: bool = false
var _busy: bool = false
var _card_busy: bool = false
var _inspecting: bool = false
var _desk_inspecting: bool = false
var _lean_tween: Tween
var _eye_rest: Transform3D
var _subtitle_until: int = 0
var _inspect_angles: Vector2 = Vector2.ZERO
var _held_distance: float = 0.48
var _cut_index: int = -1
var _progress: float = 0.0
var _snips: int = 0
var _stamp_charging: bool = false
var _stamp_time: float = 0.0
var _stamp_pixel: Vector2
var _stamp_kind: String = ""
var _stamp_tween: Tween
var _stamp_animating: bool = false
var _stamp_contacted: bool = false
var _tool_generation: int = 0
var _feedback_until: int = 0
var _tweens: Array[Tween] = []
var _tokens: Array[Node3D] = []
var _selftest: bool = false
var _capture_dir: String = ""


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--selftest": _selftest = true
		elif arg.begins_with("--capture="): _capture_dir = arg.trim_prefix("--capture=")
	rules = RationDeskRules.new(ContentDB.all_of("ration_case"))
	foley = RationFoley.new()
	add_child(foley)
	_build_room()
	_build_station()
	_build_hud()
	Game.state_changed.connect(_refresh)
	_restart()
	if _selftest: _run_selftest()


func _build_room() -> void:
	var environment: WorldEnvironment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("a4b7b9")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("e8e3ce")
	environment.environment.ambient_light_energy = 0.35
	add_child(environment)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 0.65
	sun.shadow_enabled = true
	add_child(sun)
	_solid(Vector3(14, 0.1, 16), Vector3(0, -0.05, -2), Color("a0a79f"), "floor")
	_solid(Vector3(6, 0.02, 6), Vector3(0, 0.005, 0), Color("6d6a56"), "floor")
	for x: float in [-3.0, 3.0]:
		_solid(Vector3(0.12, 2.7, 6), Vector3(x, 1.35, 0), Color("788b7b"))
	for x: float in [-1.925, 1.925]:
		_solid(Vector3(2.15, 2.7, 0.14), Vector3(x, 1.35, -3), Color("7c8d7b"))
	_solid(Vector3(1.7, 1.02, 0.14), Vector3(0, 0.51, -3), Color("607667"))
	_solid(Vector3(1.7, 0.55, 0.14), Vector3(0, 2.425, -3), Color("7c8d7b"))
	_solid(Vector3(3.5, 2.7, 0.12), Vector3(-1.25, 1.35, 3), Color("788b7b"))
	_solid(Vector3(1.1, 2.7, 0.12), Vector3(2.45, 1.35, 3), Color("788b7b"))
	_solid(Vector3(1.4, 0.55, 0.12), Vector3(1.2, 2.425, 3), Color("788b7b"))
	_solid(Vector3(1.85, 0.06, 0.38), Vector3(0, 1.04, -2.94), Color("b29a70"), "table")
	_solid(Vector3(2.5, 0.12, 1.1), Vector3(0, 0.90, -2.15), Color("7f6249"), "table")
	for x: float in [-1.05, 1.05]:
		_solid(Vector3(0.1, 0.88, 0.1), Vector3(x, 0.44, -2.15), Color("4c5145"))
	_label(self, "RUCH  ·  1982", Vector3(0, 2.27, -2.88), 0.0025)
	for x: float in [-5.0, 5.0]:
		_solid(Vector3(2, 4, 7), Vector3(x, 2, -6), Color("848d89"))
	_solid(Vector3(0.47, 0.43, 0.018), Vector3(-1.62, 1.78, -2.91), Color("e0d5b8"))
	var calendar: Label3D = _label(self, "15\nLUTY · ŞUBAT\n1982", Vector3(-1.62, 1.81, -2.897), 0.0012)
	calendar.font_size = 42
	calendar.modulate = Color("463d32")
	calendar.outline_size = 0
	var task_light: OmniLight3D = OmniLight3D.new()
	task_light.position = Vector3(-0.6, 2.15, -1.85)
	task_light.light_color = Color("ffe5b9")
	task_light.light_energy = 0.18
	task_light.omni_range = 2.5
	add_child(task_light)
	player = KioskFPSPlayer.new()
	add_child(player)
	left_hand = _hand()
	right_hand = _hand()
	player.camera.add_child(left_hand)
	player.camera.add_child(right_hand)
	left_hand.visible = false
	right_hand.visible = false
	customer = CustomerPlaceholder.new()
	customer.position = Vector3(0, 0, -3.65)
	add_child(customer)
	customer.visible = false
	customer_target = _prop("customer", Vector3(0, 1.05, 0), Vector3(0.5, 0.7, 0.35), false)
	customer_target.reparent(customer, false)
	customer_target.collision_layer = 3
	_segment(customer, Vector3(0.22, 1.38, 0), Vector3(0.22, 1.22, 0.78), 0.055, Color("4a5746"))
	_box(customer, Vector3(0.09, 0.045, 0.12), Vector3(0.22, 1.22, 0.78), Color("ad8768"))


func _build_station() -> void:
	workmat = _prop("workmat", Vector3(-0.20, 0.963, -2.13), Vector3(0.67, 0.014, 0.43), true, Color("405b50"))
	drawer = _prop("drawer", Vector3(0.93, 0.96, -2.44), Vector3(0.34, 0.075, 0.32), true, Color("514c42"))
	var drawer_tag: Label3D = _label(drawer, "ALIKONULAN BELGELER", Vector3(0, 0.077, 0), 0.00065)
	drawer_tag.rotation.x = -PI / 2
	coupon_bin = Node3D.new()
	coupon_bin.position = Vector3(0.35, 0.96, -2.5)
	add_child(coupon_bin)
	_box(coupon_bin, Vector3(0.20, 0.01, 0.16), Vector3.ZERO, Color("967950"))
	for x: float in [-0.1, 0.1]: _box(coupon_bin, Vector3(0.01, 0.055, 0.16), Vector3(x, 0.025, 0), Color("967950"))
	for z: float in [-0.08, 0.08]: _box(coupon_bin, Vector3(0.20, 0.055, 0.01), Vector3(0, 0.025, z), Color("967950"))
	for i: int in 3:
		var kind: String = ["approve", "reject", "seize"][i]
		var stamp: Interactable = _prop("stamp_" + kind, Vector3(0.45 + i * 0.25, 0.968, -1.85), Vector3(0.105, 0.20, 0.07))
		_box(stamp, Vector3(0.09, 0.017, 0.055), Vector3(0, 0.01, 0), Color("45423b"))
		_cylinder(stamp, 0.012, 0.10, Vector3(0, 0.07, 0), Color("8e6b42"))
		_cylinder(stamp, 0.03, 0.025, Vector3(0, 0.135, 0), Color("8e6b42"))
		var tag: Label3D = _label(stamp, ["SATIŞ", "RET", "ALIKOY"][i], Vector3(0, 0.149, 0), 0.00065)
		tag.rotation.x = -PI / 2
		props["stamp_" + kind] = stamp
		_remember(stamp)
	var scissors: Interactable = _prop("scissors", Vector3(-0.76, 0.968, -1.83), Vector3(0.24, 0.035, 0.10))
	for i: int in 2:
		var blade: Node3D = Node3D.new()
		blade.name = "Blade%d" % i
		blade.rotation.y = -0.15 if i == 0 else 0.15
		scissors.add_child(blade)
		_box(blade, Vector3(0.14, 0.004, 0.01), Vector3(0.055, 0.012, 0), Color("b3b8b7"))
		var ring: TorusMesh = TorusMesh.new()
		ring.inner_radius = 0.019
		ring.outer_radius = 0.026
		_mesh(blade, ring, Vector3(-0.065, 0.012, 0), Color("443c31"))
	props["scissors"] = scissors
	_remember(scissors)
	var book: Interactable = _prop("book", Vector3(-0.92, 0.97, -2.27), Vector3(0.42, 0.02, 0.34))
	_make_page(book, "reference", Vector2(0.40, 0.32), "[b]SATIŞ TALİMATI · ŞUBAT 1982[/b]\n\nİŞÇİ: 750 g et · kurum F14\nÖĞRETMEN: 500 g et · kurum S03\nEMEKLİ: 250 g et · kurum E02\n\nHer sınıf: 1000 g şeker, 1 sabun.\nArka yüzde kurum onayı gerekli.\n\nEski ay, bitmiş kupon, eksik onay: RET.\nYanlış kurum veya değişmiş hak: ALIKOY.\nYıpranma tek başına sahtecilik değildir.\n\nStok yoksa kuponu kesme.\nÜrünü ve kalan kartı müşteriye teslim et.")
	props["book"] = book
	_remember(book)
	_solid(Vector3(0.55, 0.07, 0.65), Vector3(-2.2, 0.92, -1.65), Color("7f6249"), "table")
	var order: Interactable = _prop("order", Vector3(0.53, 0.97, -2.24), Vector3(0.29, 0.009, 0.17))
	_make_page(order, "order", Vector2(0.28, 0.16), "TALEP FİŞİ")
	props["order"] = order
	_remember(order)
	var ledger: Interactable = _prop("ledger", Vector3(-2.2, 0.97, -1.65), Vector3(0.37, 0.02, 0.47))
	_make_page(ledger, "ledger", Vector2(0.36, 0.46), "[b]GÜN SONU DEFTERİ[/b]\n\nMüşteri sırası bitince kararlar ve hesap buraya yazılır.")
	props["ledger"] = ledger
	_remember(ledger)
	bell = _prop("bell", Vector3(1.10, 0.97, -2.12), Vector3(0.11, 0.07, 0.11))
	_cylinder(bell, 0.05, 0.04, Vector3(0, 0.025, 0), Color("b8a46f"))
	for i: int in 3:
		var item: String = RationDeskRules.PRODUCT_ORDER[i]
		var shelf: Interactable = _prop("storage", Vector3(2.52, 1.0, 0.45 - i * 0.65), Vector3(0.45, 0.30, 0.43), false)
		_crate(shelf, item, Color("a58a60"))
		shelf.set_meta("source", "official")
		shelf.collision_layer = 3
		shelf.set_meta("item", item)
		shelves[item] = shelf
		shelf_labels[item] = _label(shelf, "", Vector3(-0.231, 0.17, 0), 0.0012)
		shelf_labels[item].rotation.y = -PI / 2
		shelf_labels[item].outline_size = 0
		shelf_labels[item].modulate = Color("382e24")
		_solid(Vector3(0.55, 0.06, 0.48), Vector3(2.52, 0.98, 0.45 - i * 0.65), Color("675746"))
	var hidden: Interactable = _prop("storage", Vector3(2.50, 0.15, -0.20), Vector3(0.42, 0.25, 0.40), false)
	_crate(hidden, "meat", Color("514735"))
	hidden.set_meta("source", "hidden")
	hidden.collision_layer = 3
	hidden.set_meta("item", "meat")
	shelves["hidden"] = hidden
	shelf_labels["hidden"] = _label(hidden, "", Vector3(-0.231, 0.16, 0), 0.0010)
	shelf_labels["hidden"].rotation.y = -PI / 2
	shelf_labels["hidden"].outline_size = 0
	shelf_labels["hidden"].modulate = Color("ead9b5")
	parcel = RationParcel3D.new()
	add_child(parcel)
	parcel.visible = false
	parcel.collision_layer = 0
	card = RationCard3D.new()
	add_child(card)
	card.visible = false


func _crate(container: Interactable, item: String, wood: Color) -> void:
	_box(container, Vector3(0.44, 0.025, 0.42), Vector3(0, 0.0125, 0), wood)
	for x: float in [-0.21, 0.21]:
		for z: float in [-0.195, 0.195]:
			_box(container, Vector3(0.027, 0.29, 0.027), Vector3(x, 0.145, z), wood.darkened(0.15))
	for y: float in [0.075, 0.175, 0.27]:
		for z: float in [-0.20, 0.20]:
			_box(container, Vector3(0.44, 0.065, 0.018), Vector3(0, y, z), wood)
		for x: float in [-0.22, 0.22]:
			_box(container, Vector3(0.018, 0.065, 0.42), Vector3(x, y, 0), wood)
	var sample: RationParcel3D = RationParcel3D.new()
	container.add_child(sample)
	sample.configure(item, 1000 if item == "sugar" else (1 if item == "soap" else 750), "official")
	sample.action = "display"
	sample.collision_layer = 0
	sample.position = Vector3(0, 0.028, 0)
	sample.rotation.y = 0.16


func _build_hud() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)
	var crosshair: Label = Label.new()
	crosshair.text = "·"
	crosshair.add_theme_font_size_override("font_size", 30)
	canvas.add_child(crosshair)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -6
	crosshair.offset_top = -20
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint = _hud_label(canvas, 21, Control.PRESET_CENTER_BOTTOM, -104)
	subtitle = _hud_label(canvas, 23, Control.PRESET_CENTER_TOP, 26)
	message = _hud_label(canvas, 18, Control.PRESET_CENTER_BOTTOM, -62)
	pause = PanelContainer.new()
	canvas.add_child(pause)
	pause.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pause.offset_left = -230
	pause.offset_top = -200
	pause.offset_right = 230
	pause.offset_bottom = 200
	var rows: VBoxContainer = VBoxContainer.new()
	pause.add_child(rows)
	var controls: Label = Label.new()
	controls.text = "FPS / KARNE\nWASD: yürü · Shift: hızlı yürü\nE: al / teslim et · G: yüzeye bırak\nE: masaya eğil · R: karneyi eline al\nQ / WASD: incelemeden ayrıl\nSağ tuş basılı: elde incele\nF: kartı çevir · Tekerlek: yaklaştır\nSol tuş: damga / çizgi boyunca kes\n\nSes"
	controls.add_theme_font_size_override("font_size", 20)
	rows.add_child(controls)
	var volume: HSlider = HSlider.new()
	volume.max_value = 1
	volume.step = 0.01
	volume.value = 0.56
	volume.value_changed.connect(foley.set_level)
	rows.add_child(volume)
	for entry: Array in [["Devam", _toggle_pause], ["Yeni deneme günü", _restart]]:
		var button: Button = Button.new()
		button.text = entry[0]
		button.pressed.connect(entry[1])
		rows.add_child(button)
	pause.visible = false


func _restart() -> void:
	_exit_desk_inspection(true)
	_epoch += 1
	for tween: Tween in _tweens:
		if tween.is_valid(): tween.kill()
	_tweens.clear()
	for token: Node3D in _tokens:
		if is_instance_valid(token): token.queue_free()
	_tokens.clear()
	_cut_index = -1
	_stamp_charging = false
	_busy = false
	_card_busy = false
	_inspecting = false
	card_held = false
	if held_tool != null: _return_tool_home()
	for prop: Node3D in homes:
		prop.global_transform = homes[prop]
		if prop is CollisionObject3D: prop.collision_layer = 2
	left_hand.visible = false
	left_hand.reparent(player.camera)
	right_hand.visible = false
	right_hand.reparent(player.camera)
	card.reparent(self)
	card.scale = Vector3.ONE
	card.front_showing = true
	player.position = Vector3(0, 0.03, 1.1)
	player.rotation = Vector3.ZERO
	player.head.rotation = Vector3.ZERO
	player.camera.transform = Transform3D.IDENTITY
	player.camera.rotation = Vector3.ZERO
	player.look_locked = false
	_index = -1
	_window_ready = false
	customer.cancel_motion()
	customer.visible = false
	pause.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Game.new_campaign(1982, rules.opening())
	_message("Cama yaklaş. Müşterinin uzattığı karta bakıp E ile al.")


func _refresh(state: CampaignState) -> void:
	var work: Dictionary = RationDeskRules.desk(state)
	var encounter: Dictionary = rules.current(state)
	var index: int = int(work.get("index", 0))
	if encounter.is_empty():
		if index != _index:
			_index = index
			_window_ready = false
			customer.leave()
		card.visible = false
		subtitle.text = "Gün tamamlandı. Masadaki gün sonu defterini eline alıp inceleyebilirsin."
		_write_ledger(work)
	elif index != _index:
		_index = index
		_window_ready = false
		card_held = false
		left_hand.visible = false
		card.reparent(self)
		card.scale = Vector3.ONE
		card.rotation = Vector3.ZERO
		card.front_showing = true
		card.collision_layer = 0
		card.visible = false
		card.refresh(encounter["card"], work)
		_offer_card(index, _epoch)
	else:
		card.refresh(encounter["card"], work)
	pages["order"].text = "[b]TALEP FİŞİ[/b]\n" + ("Gün tamamlandı." if encounter.is_empty() else "%s\n%s · %s\n\nKarneyi kontrol et → damga / kupon → raflardan erzak → tezgâhta teslim." % [encounter["customer"], RationDeskRules.GOODS[encounter["request"]["item"]], RationDeskRules.amount_text(encounter["request"]["item"], int(encounter["request"]["amount"]))])
	page_viewports["order"].render_target_update_mode = SubViewport.UPDATE_ONCE
	for item: String in RationDeskRules.PRODUCT_ORDER:
		shelf_labels[item].text = "%s\n%s" % [RationDeskRules.GOODS[item], RationDeskRules.amount_text(item, int(work.get("official", {}).get(item, 0)))]
	shelf_labels["hidden"].text = "ÖZEL STOK\nEt: %d g" % int(work.get("hidden", {}).get("meat", 0))
	var package: Dictionary = work.get("parcel", {})
	if package.is_empty() or package.get("delivered", false):
		parcel.visible = false
		parcel.collision_layer = 0
		if package.is_empty() and held_tool == parcel:
			right_hand.reparent(player.camera)
			right_hand.visible = false
			parcel.reparent(self)
			held_tool = null
	else:
		parcel.configure(package["item"], int(package["amount"]), package["source"])


func _offer_card(index: int, generation: int) -> void:
	if customer.visible:
		customer.time_scale = 0.04 if _selftest else 0.7
		customer.leave()
		await customer.left
	if generation != _epoch or index != _index: return
	var encounter: Dictionary = rules.current(Game.state)
	if encounter.is_empty(): return
	var spec: Dictionary = RationDeskRules.CLASSES.get(encounter["card"]["class"], {})
	customer.setup({"coat": str(spec.get("color", Color.GRAY).to_html()), "height_cm": 172, "hat": index % 2 == 0})
	customer.time_scale = 0.04 if _selftest else 0.7
	customer.arrive()
	await customer.arrived
	if generation != _epoch or index != _index: return
	_window_ready = true
	card.position = Vector3(0.22, 1.25, -2.86)
	card.rotation = Vector3.ZERO
	card.visible = true
	card.collision_layer = 2
	_subtitle_until = Time.get_ticks_msec() + 8000
	subtitle.text = "%s: %s (%s)" % [encounter["customer"], encounter["line"], RationDeskRules.amount_text(encounter["request"]["item"], int(encounter["request"]["amount"]))]


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).physical_keycode:
			KEY_ESCAPE: _toggle_pause(); get_viewport().set_input_as_handled(); return
			KEY_E:
				if not pause.visible: _interact()
			KEY_Q:
				if not pause.visible:
					_exit_desk_inspection()
					_subtitle_until = 0
			KEY_R:
				if not pause.visible and not _busy and not _card_busy and _ray().get("collider") == card and RationDeskRules.desk(Game.state).get("placement") == "table":
					_exit_desk_inspection(true)
					if _execute(rules.move_card(Game.state, "hand")): _hold_card()
			KEY_G:
				if not pause.visible: _drop_held()
			KEY_F:
				if not pause.visible: _flip_card()
	if pause.visible: return
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_RIGHT:
			_inspecting = mouse.pressed and (card_held or _is_book(held_tool))
			player.look_locked = _inspecting
		elif mouse.pressed and mouse.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			_held_distance = clampf(_held_distance + (-0.035 if mouse.button_index == MOUSE_BUTTON_WHEEL_UP else 0.035), 0.30, 0.65)
			if card_held and not _card_busy: card.position = _card_hold_position()
			elif _is_book(held_tool): held_tool.position = _book_hold_position()
		elif mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed: _begin_tool()
			else: _end_tool()
	elif event is InputEventMouseMotion and _inspecting:
		var mouse: InputEventMouseMotion = event as InputEventMouseMotion
		_inspect_angles.x = clampf(_inspect_angles.x - mouse.relative.y * 0.004, -0.65, 0.65)
		_inspect_angles.y = clampf(_inspect_angles.y + mouse.relative.x * 0.004, -0.8, 0.8)
		if card_held and not _card_busy:
			card.rotation = Vector3(_inspect_angles.x, _inspect_angles.y + (0 if card.front_showing else PI), 0)
		elif _is_book(held_tool):
			held_tool.rotation = Vector3(PI / 2 + _inspect_angles.x, _inspect_angles.y, 0)
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not pause.visible and (_desk_inspecting or _stamp_charging or _stamp_animating or _cut_index >= 0) and Input.get_vector("move_left", "move_right", "move_forward", "move_back") != Vector2.ZERO:
		_exit_desk_inspection()
	player.can_move = not pause.visible and not _desk_inspecting and not _busy and _cut_index < 0 and not _stamp_charging
	player.sensitivity = 0.0008 if _cut_index >= 0 or _stamp_charging else 0.002
	if pause.visible: return
	subtitle.visible = _window_ready and Time.get_ticks_msec() < _subtitle_until and player.global_position.distance_to(customer_target.global_position) < 3.0 and -player.camera.global_basis.z.dot((customer_target.global_position - player.camera.global_position).normalized()) > 0.55
	message.visible = Time.get_ticks_msec() < _feedback_until
	if _stamp_charging:
		_stamp_time += delta
		if held_tool != null:
			var above: Vector3 = card.pixel_to_world(_stamp_pixel) + Vector3(0, 0.10, 0)
			held_tool.global_position = held_tool.global_position.lerp(above, minf(delta * 20, 1))
			held_tool.quaternion = held_tool.quaternion.slerp(Quaternion.IDENTITY, minf(delta * 20, 1))
	if _cut_index >= 0: _update_cut()
	var hit: Dictionary = _ray()
	var target: Node = hit.get("collider") as Node
	hint.text = _hint(target)


func _enter_desk_inspection() -> void:
	if _desk_inspecting or card_held or not card.visible or RationDeskRules.desk(Game.state).get("placement") != "table": return
	if player.camera.global_position.distance_to(card.global_position) > 1.5:
		_message("İncelemek için masaya biraz daha yaklaş."); return
	if _lean_tween != null and _lean_tween.is_valid(): return
	_desk_inspecting = true
	_eye_rest = player.camera.transform
	var offset: Vector3 = Vector3(0, -0.28, -0.22)
	var eye: Vector3 = player.head.to_global(offset)
	var clearance: Dictionary = get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(player.head.global_position, eye, 1))
	if not clearance.is_empty():
		_desk_inspecting = false
		_message("Buradan masaya güvenle eğilemiyorsun; önüne yaklaş."); return
	var facing: Basis = player.head.global_basis.inverse() * Basis.looking_at(card.global_position - eye, Vector3.UP)
	_lean_tween = create_tween().set_parallel(true)
	_lean_tween.tween_property(player.camera, "position", offset, 0.24).set_trans(Tween.TRANS_SINE)
	_lean_tween.tween_property(player.camera, "rotation", facing.get_euler(), 0.24).set_trans(Tween.TRANS_SINE)
	_message("Karne masada. F: çevir · R: eline al · Q veya WASD: masadan ayrıl.")


func _cancel_gesture() -> void:
	if _stamp_animating:
		if _stamp_tween != null and _stamp_tween.is_valid(): _stamp_tween.kill()
		_tool_generation += 1
		if _stamp_contacted: foley.play_sound("stamp_lift")
		_stamp_animating = false
		_stamp_contacted = false
		_busy = false
		_restore_tool_to_hand()
	elif _stamp_charging:
		_restore_tool_to_hand()
	if _cut_index >= 0:
		_cut_index = -1
		card.cut_progress(-1, 0)
		_restore_tool_to_hand()
	_stamp_charging = false
	_inspecting = false
	player.look_locked = false


func _exit_desk_inspection(immediate: bool = false) -> void:
	_cancel_gesture()
	if not _desk_inspecting:
		if immediate and _lean_tween != null and _lean_tween.is_valid():
			_lean_tween.kill()
			player.camera.transform = _eye_rest
		return
	_desk_inspecting = false
	if _lean_tween != null and _lean_tween.is_valid(): _lean_tween.kill()
	if immediate:
		player.camera.transform = _eye_rest
	else:
		_lean_tween = create_tween().set_parallel(true)
		_lean_tween.tween_property(player.camera, "position", _eye_rest.origin, 0.20).set_trans(Tween.TRANS_SINE)
		_lean_tween.tween_property(player.camera, "rotation", _eye_rest.basis.get_euler(), 0.20).set_trans(Tween.TRANS_SINE)


func _ray() -> Dictionary:
	var origin: Vector3 = player.camera.global_position
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, origin - player.camera.global_basis.z * REACH, 3)
	return get_world_3d().direct_space_state.intersect_ray(query)


func _interact() -> void:
	if _busy or _card_busy or _cut_index >= 0 or _stamp_charging: return
	var hit: Dictionary = _ray()
	var target: Interactable = hit.get("collider") as Interactable
	if target == null: return
	var kind: String = target.action
	if target == card:
		if card_held: return
		if RationDeskRules.desk(Game.state).get("location") == "intake":
			if not _window_ready or not _execute(rules.take(Game.state)): return
			_receive_card()
		else:
			_enter_desk_inspection()
	elif kind == "workmat" and card_held:
		_place_card(hit["position"])
	elif kind == "workmat" and RationDeskRules.desk(Game.state).get("placement") == "table":
		_enter_desk_inspection()
	elif kind == "customer":
		if held_tool == parcel: _deliver_parcel()
		elif card_held: _finish_card("return")
		else: _subtitle_until = Time.get_ticks_msec() + 8000
	elif kind == "drawer" and card_held:
		_finish_card("seize")
	elif kind == "bell":
		if _execute(rules.next(Game.state)): _message("Sonraki müşteri cama geliyor.")
	elif kind == "storage":
		_prepare_from(target)
	elif kind == "parcel":
		if held_tool != null: _message("Sağ elindeki nesneyi G ile bırak."); return
		if _execute(rules.move_parcel(Game.state, "hand")): _equip(parcel)
	elif kind.begins_with("stamp_") or kind in ["scissors", "book", "ledger", "order"]:
		if held_tool != null: _message("Sağ elindeki nesneyi G ile bir yüzeye bırak."); return
		_equip(target)


func _receive_card() -> void:
	card_held = false
	card.collision_layer = 0
	card.reparent(self)
	_card_busy = true
	left_hand.reparent(card)
	left_hand.position = Vector3(-0.208, -0.04, 0.015)
	left_hand.scale.x = -1
	left_hand.rotation = Vector3.ZERO
	left_hand.visible = true
	foley.play_sound("paper_pick")
	# The transfer takes place in world space even if the player immediately walks away.
	if not _execute(rules.move_card(Game.state, "table")): return
	var generation: int = _epoch
	var transfer: Tween = create_tween().set_parallel(true)
	_tweens.append(transfer)
	transfer.tween_property(card, "position", Vector3(-0.20, 0.978, -2.13), 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	transfer.tween_property(card, "quaternion", RationCard3D.table_orientation(true), 0.36).set_trans(Tween.TRANS_SINE)
	transfer.chain().tween_callback(func() -> void:
		if generation == _epoch:
			left_hand.reparent(player.camera)
			left_hand.visible = false
			card.collision_layer = 2
			_card_busy = false
			foley.play_sound("paper_place"))
	_message("Karneyi masaya alıyorsun. E: eğilip incele · R: eline al. İstediğin zaman uzaklaşabilirsin.")


func _hold_card() -> void:
	card_held = true
	if _is_book(held_tool): held_tool.position = _book_hold_position()
	card.collision_layer = 0
	card.reparent(player.camera)
	_card_busy = true
	var generation: int = _epoch
	var pickup: Tween = create_tween().set_parallel(true)
	_tweens.append(pickup)
	pickup.tween_property(card, "position", _card_hold_position(), 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	pickup.tween_property(card, "rotation", Vector3(0, 0 if card.front_showing else PI, 0), 0.24)
	pickup.chain().tween_callback(func() -> void:
		if generation == _epoch:
			_card_busy = false)
	_inspect_angles = Vector2.ZERO
	left_hand.reparent(card)
	_align_card_grip()
	left_hand.visible = true
	foley.play_sound("paper_pick")
	_message("Kart elinde. Sağ tuşa basılı tutup fareyle eğ; F ile çevir. Masaya bakıp G ile bırak.")


func _align_card_grip() -> void:
	# Keep the left forearm on the player's left when the sheet is turned over.
	var side: float = 1.0 if card.front_showing else -1.0
	left_hand.position = Vector3(-0.208 * side, -0.04, 0.015 * side)
	left_hand.scale.x = -1
	left_hand.rotation = Vector3(0, 0 if card.front_showing else PI, 0)


func _card_hold_position() -> Vector3:
	return Vector3(-0.20 if _is_book(held_tool) else -0.03, -0.14 * _held_distance / 0.48, -_held_distance)


func _book_hold_position() -> Vector3:
	return Vector3(0.22 if card_held else 0.02, -0.10, -_held_distance)


func _place_card(at: Vector3) -> void:
	if not _execute(rules.move_card(Game.state, "table")): return
	left_hand.visible = false
	left_hand.reparent(player.camera)
	card_held = false
	if _is_book(held_tool): held_tool.position = _book_hold_position()
	card.reparent(self)
	_card_busy = true
	var generation: int = _epoch
	var placing: Tween = create_tween().set_parallel(true)
	_tweens.append(placing)
	placing.tween_property(card, "position", Vector3(clampf(at.x, -0.43, 0.01), 0.978, clampf(at.z, -2.32, -1.95)), 0.24).set_trans(Tween.TRANS_SINE)
	placing.tween_property(card, "quaternion", RationCard3D.table_orientation(card.front_showing), 0.24)
	placing.chain().tween_callback(func() -> void:
		if generation == _epoch:
			card.collision_layer = 2
			_card_busy = false
			foley.play_sound("paper_place"))
	_inspecting = false
	player.look_locked = false
	_message("Kart masada. Makası veya bir karar damgasını fiziksel olarak al.")


func _drop_held() -> void:
	if _busy or _card_busy or _cut_index >= 0 or _stamp_charging: return
	var hit: Dictionary = _ray()
	if hit.is_empty(): _message("Nesneyi bırakmak için yakındaki bir yüzeye bak."); return
	var target: Node = hit["collider"]
	if card_held and (target == customer_target or target == drawer):
		_finish_card("seize" if target == drawer else "return")
		return
	var on_table: bool = target == workmat or target.get_meta("surface", "") == "table"
	if held_tool != null:
		if not on_table and target.get_meta("surface", "") != "floor":
			_message("Nesneyi masaya veya zemine bırak."); return
		var tool: Interactable = held_tool
		if tool == parcel and not _execute(rules.move_parcel(Game.state, "table")): return
		held_tool = null
		if card_held: card.position = _card_hold_position()
		tool.reparent(self)
		tool.collision_layer = 0
		_busy = true
		var generation: int = _epoch
		var placing: Tween = create_tween().set_parallel(true)
		_tweens.append(placing)
		placing.tween_property(tool, "rotation", homes[tool].basis.get_euler() if homes.has(tool) else Vector3.ZERO, 0.16)
		placing.tween_property(tool, "position", hit["position"] + Vector3(0, _support_height(tool), 0), 0.16).set_trans(Tween.TRANS_SINE)
		placing.chain().tween_callback(func() -> void:
			if generation == _epoch:
				right_hand.visible = false
				right_hand.reparent(player.camera)
				tool.collision_layer = 2
				_busy = false
				if tool == parcel: foley.play_package("place", parcel.item_id)
				else: foley.play_sound("paper_place"))
		_inspecting = false
		player.look_locked = false
	elif card_held:
		if on_table: _place_card(hit["position"])
		else: _message("Karneyi çalışma masasının üzerine bırak.")


func _support_height(tool: Interactable) -> float:
	if tool.action == "scissors": return -0.0082
	if tool.action.begins_with("stamp_"): return -0.0012
	return 0.0005


func _equip(tool: Interactable) -> void:
	held_tool = tool
	tool.collision_layer = 0
	tool.reparent(player.camera)
	var from: Transform3D = tool.transform
	_pose_tool()
	var to: Transform3D = tool.transform
	tool.transform = from
	_busy = true
	var generation: int = _epoch
	var pickup: Tween = create_tween().set_parallel(true)
	_tweens.append(pickup)
	pickup.tween_property(tool, "position", to.origin, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	pickup.tween_property(tool, "rotation", to.basis.get_euler(), 0.16)
	if card_held: pickup.tween_property(card, "position", _card_hold_position(), 0.16)
	pickup.chain().tween_callback(func() -> void:
		if generation == _epoch:
			_busy = false
			if tool == parcel: foley.play_package("pick", parcel.item_id)
			else: foley.play_sound("paper_pick"))
	right_hand.reparent(tool)
	right_hand.position = Vector3(-0.04, 0.08, 0.05)
	if _is_book(tool): right_hand.position = Vector3(0.208, 0.026, 0.11)
	elif tool == parcel: right_hand.position = parcel.grip_position
	right_hand.rotation = Vector3.ZERO
	right_hand.visible = true
	_message("Nesne sağ elinde. G ile bir yüzeye bırakabilirsin.")


func _pose_tool() -> void:
	if held_tool == null: return
	held_tool.position = Vector3(0.19, -0.27, -0.46)
	held_tool.rotation = Vector3(0.20, 0, -0.2)
	if _is_book(held_tool):
		held_tool.position = _book_hold_position()
		held_tool.rotation = Vector3(PI / 2, 0, 0)
	elif held_tool == parcel:
		held_tool.position = parcel.carry_position()
		held_tool.rotation = parcel.carry_rotation()
	elif held_tool.action == "scissors":
		held_tool.rotation = Vector3(0.7, 0, -0.2)
		for i: int in 2:
			(held_tool.get_node("Blade%d" % i) as Node3D).rotation.y = -0.15 if i == 0 else 0.15


func _return_tool_home() -> void:
	if held_tool == null: return
	var tool: Interactable = held_tool
	right_hand.reparent(player.camera)
	right_hand.visible = false
	tool.reparent(self)
	if homes.has(tool): tool.global_transform = homes[tool]
	tool.collision_layer = 2
	held_tool = null


func _prepare_from(shelf: Interactable) -> void:
	if held_tool != null: _message("Ürün almak için sağ elindeki nesneyi G ile bırak."); return
	var source: String = shelf.get_meta("source", "official")
	var item: String = shelf.get_meta("item", "")
	if not _execute(rules.prepare(Game.state, source, item, true)): return
	parcel.visible = true
	parcel.position = shelf.global_position + Vector3(-0.30, 0.32, 0)
	if _execute(rules.move_parcel(Game.state, "hand")): _equip(parcel)
	_message("Ürün elinde. Tezgâha taşı; G ile yüzeye bırak veya müşteriye E ile uzat.")


func _deliver_parcel() -> void:
	if not _execute(rules.deliver_parcel(Game.state)): return
	parcel.reparent(self)
	parcel.visible = true
	parcel.collision_layer = 0
	_busy = true
	var generation: int = _epoch
	var handover: Tween = create_tween().set_parallel(true)
	_tweens.append(handover)
	handover.tween_property(parcel, "position", Vector3(0.22, 1.21, -2.91), 0.30).set_trans(Tween.TRANS_CUBIC)
	handover.tween_property(parcel, "rotation", Vector3.ZERO, 0.30)
	handover.chain().tween_callback(func() -> void:
		if generation == _epoch:
			right_hand.reparent(player.camera)
			right_hand.visible = false
			parcel.visible = false
			held_tool = null
			_busy = false
			foley.play_package("place", parcel.item_id))
	_message("Ürünü müşteriye uzatıyorsun. Kalan karneyi R ile alıp E ile iade et.")


func _finish_card(destination: String) -> void:
	if not card_held or not _execute(rules.finish(Game.state, destination, true)): return
	card_held = false
	left_hand.reparent(player.camera)
	left_hand.visible = false
	card.reparent(self)
	card.collision_layer = 0
	_busy = true
	var generation: int = _epoch
	var target: Vector3 = drawer.global_position + Vector3(0, 0.12, 0) if destination == "seize" else Vector3(0.22, 1.25, -2.86)
	var tween: Tween = create_tween()
	_tweens.append(tween)
	tween.tween_property(card, "position", target, 0.30)
	tween.tween_callback(func() -> void:
		if generation == _epoch:
			card.visible = false
			_busy = false
			foley.play_sound("drawer" if destination == "seize" else "paper_place"))
	_message("İşlem tamamlandı. Masadaki zile basarak sonraki müşteriyi çağır.")


func _flip_card() -> void:
	if _card_busy or _busy or _cut_index >= 0 or _stamp_charging or not card.visible: return
	if not card_held and _ray().get("collider") != card: return
	if RationDeskRules.desk(Game.state).get("location") != "desk": return
	_card_busy = true
	card.front_showing = not card.front_showing
	_inspect_angles = Vector2.ZERO
	var target: Quaternion = Quaternion(Vector3.UP, 0 if card.front_showing else PI) if card_held else RationCard3D.table_orientation(card.front_showing)
	var generation: int = _epoch
	var tween: Tween = create_tween()
	_tweens.append(tween)
	var resting: Vector3 = card.position
	if not card_held:
		tween.tween_property(card, "position", resting + Vector3(0, RationCard3D.WIDTH / 2 + 0.025, 0), 0.10)
	tween.tween_property(card, "quaternion", target, 0.25).set_trans(Tween.TRANS_SINE)
	if not card_held:
		tween.tween_property(card, "position", resting, 0.10)
	tween.tween_callback(func() -> void:
		if generation == _epoch:
			_card_busy = false
			if card_held: _align_card_grip())
	foley.play_sound("paper_flip")


func _begin_tool() -> void:
	if _busy or _card_busy or held_tool == null or card_held: return
	if _ray().get("collider") != card or not card.front_showing:
		_message("Kartın ön yüzü masada olmalı; aracı kartın üstüne yönelt."); return
	var pixel: Vector2 = card.ray_pixel(player.camera.global_position, -player.camera.global_basis.z)
	if held_tool.action.begins_with("stamp_"):
		if not RationCardView.DECISION_RECT.has_point(pixel): _message("Damgayı kartın KARAR alanına yönelt."); return
		_stamp_charging = true
		_stamp_time = 0
		_stamp_pixel = pixel
		_stamp_kind = held_tool.action.trim_prefix("stamp_")
		held_tool.reparent(self)
	elif held_tool.action == "scissors":
		var work: Dictionary = RationDeskRules.desk(Game.state)
		for i: int in 3:
			var rect: Rect2 = RationCardView.coupon_rect(i)
			if Rect2(rect.position - Vector2(12, 24), Vector2(46, 48)).has_point(pixel):
				var item: String = RationDeskRules.PRODUCT_ORDER[i]
				if rules.current(Game.state)["request"]["item"] != item or work.get("stamp") != "approve" or item in work.get("cuts", []) or not item in rules.current(Game.state)["card"]["available"]:
					_message("Önce satış damgası gerekli; müşterinin istediği ürünün kuponunu kes."); return
				_cut_index = i
				_progress = 0
				_snips = 0
				_start_tool_on_table(card.pixel_to_world(rect.position) - Vector3(0.08, -0.008, 0))
				return
		_message("Kuponun sol üst kesik çizgisinden başla. Sol tuş basılıyken sağa doğru bak.")


func _end_tool() -> void:
	if _stamp_charging:
		_stamp_charging = false
		if _stamp_time >= 0.08: _stamp_contact()
		else:
			_restore_tool_to_hand()
			_message("Damgayı kısa süre basılı tutup bırak.")
	if _cut_index >= 0:
		_update_cut()
		if _cut_index < 0: return
		var index: int = _cut_index
		var item: String = RationDeskRules.PRODUCT_ORDER[index]
		_cut_index = -1
		card.cut_progress(-1, 0)
		if _progress >= 0.92 and _execute(rules.cut(Game.state, item, true)):
			_detach_coupon(index, item)
			_message("Kupon ayrıldı. Makası bırak, erzak rafından ürünü al ve tezgâha getir.")
		else: _message("Kesim kısa kaldı; kupon tüketilmedi.")
		_restore_tool_to_hand()


func _stamp_contact() -> void:
	if held_tool == null: return
	if _ray().get("collider") != card or not card.front_showing:
		_restore_tool_to_hand(); return
	var current: Vector2 = card.ray_pixel(player.camera.global_position, -player.camera.global_basis.z)
	if current.distance_to(_stamp_pixel) > 28:
		_restore_tool_to_hand(); _message("Damga alanından uzaklaştın; yeniden dene."); return
	_busy = true
	_stamp_animating = true
	_stamp_contacted = false
	_tool_generation += 1
	var gesture: int = _tool_generation
	var kind: String = _stamp_kind
	var pixel: Vector2 = _stamp_pixel
	var tool: Interactable = held_tool
	var generation: int = _epoch
	var contact: Vector3 = card.pixel_to_world(_stamp_pixel)
	_start_tool_on_table(contact + Vector3(0, 0.12, 0))
	var tween: Tween = create_tween()
	_stamp_tween = tween
	_tweens.append(tween)
	tween.tween_property(tool, "position", contact + Vector3(0, -0.0019, 0), 0.12).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func() -> void:
		if generation == _epoch and gesture == _tool_generation and _execute(rules.stamp(Game.state, kind, pixel, true)):
			_stamp_contacted = true
			foley.play_sound("stamp_down"))
	tween.tween_interval(0.07)
	tween.tween_property(tool, "position", contact + Vector3(0, 0.10, 0), 0.12)
	tween.tween_callback(func() -> void:
		if generation == _epoch and gesture == _tool_generation:
			if _stamp_contacted: foley.play_sound("stamp_lift")
			_restore_tool_to_hand()
			_stamp_animating = false
			_stamp_contacted = false
			_busy = false)


func _start_tool_on_table(at: Vector3) -> void:
	if held_tool == null: return
	held_tool.reparent(self)
	held_tool.global_position = at
	held_tool.rotation = Vector3.ZERO


func _restore_tool_to_hand() -> void:
	if held_tool == null: return
	held_tool.reparent(player.camera)
	_pose_tool()


func _update_cut() -> void:
	if _cut_index < 0: return
	var pixel: Vector2 = card.ray_pixel(player.camera.global_position, -player.camera.global_basis.z)
	var rect: Rect2 = RationCardView.coupon_rect(_cut_index)
	if _ray().get("collider") != card or absf(pixel.y - rect.position.y) > 27 or pixel.x < rect.position.x - 18:
		_cut_index = -1
		card.cut_progress(-1, 0)
		_restore_tool_to_hand()
		_message("Çizgiden çıktın. Kupon tüketilmedi.")
		return
	_progress = maxf(_progress, clampf((pixel.x - rect.position.x) / rect.size.x, 0, 1))
	var at: Vector2 = rect.position + Vector2(rect.size.x * _progress, 0)
	held_tool.global_position = card.pixel_to_world(at) - Vector3(0.08, -0.008, 0)
	for i: int in 2:
		(held_tool.get_node("Blade%d" % i) as Node3D).rotation.y = (1 if i == 0 else -1) * (0.05 + absf(sin(_progress * 30)) * 0.22)
	var steps: int = int(_progress * 5)
	if steps > _snips: foley.play_sound("snip"); _snips = steps
	card.cut_progress(_cut_index, _progress)


func _detach_coupon(index: int, _item: String) -> void:
	var token: Node3D = card.create_coupon(index)
	add_child(token)
	token.position = card.pixel_to_world(RationCardView.coupon_rect(index).get_center()) + Vector3(0, 0.02, 0)
	token.global_rotation = card.global_rotation
	_tokens.append(token)
	var generation: int = _epoch
	var tween: Tween = create_tween()
	_tweens.append(tween)
	tween.tween_property(token, "position", coupon_bin.global_position + Vector3(0, 0.14, 0), 0.23)
	tween.tween_property(token, "position", coupon_bin.global_position + Vector3(randf_range(-0.025, 0.025), 0.016 + _tokens.size() * 0.002, randf_range(-0.025, 0.025)), 0.18)
	tween.tween_callback(func() -> void:
		if generation == _epoch: foley.play_sound("coupon_drop"))


func _hint(target: Node) -> String:
	if target == null: return "WASD · Yürü    E · Al / ver    G · Yüzeye bırak    Esc · Menü"
	if target == card:
		if RationDeskRules.desk(Game.state).get("location") == "intake": return "E · Uzatılan karneyi masaya al"
		var inspect: String = "Q / WASD · Ayrıl" if _desk_inspecting else "E · Eğilip incele"
		return inspect + "    R · Eline al    F · Çevir" + ("    Sol tuş · Aracı kullan" if held_tool != null else "")
	var kind: String = str(target.get("action")) if target is Interactable else ""
	match kind:
		"workmat": return "E / G · Karneyi masaya bırak" if card_held else "E · Masadaki karneyi incelemek için eğil    Q · Ayrıl"
		"customer": return "E · Ürünü müşteriye uzat" if held_tool == parcel else ("E · Karneyi iade et" if card_held else "E · Müşterinin isteğini tekrar dinle")
		"drawer": return "E · Elindeki karneyi alıkoyma bölmesine koy"
		"storage": return "E · Bu koliden istenen ürünü hazırla ve al"
		"parcel": return "E · Hazırlanmış ürünü al"
		"bell": return "E · Sonraki müşteriyi çağır"
		"book": return "E · Kural defterini al ve elde incele"
		"order": return "E · Masadaki talep fişini al ve oku"
		"ledger": return "E · Gün sonu defterini al"
		"scissors": return "E · Makası al"
	if kind.begins_with("stamp_"): return "E · %s damgasını al" % {"stamp_approve": "SATIŞ", "stamp_reject": "RET", "stamp_seize": "ALIKOY"}.get(kind, "")
	return "G · Elindeki nesneyi bu yüzeye bırak"


func _toggle_pause() -> void:
	_exit_desk_inspection(true)
	pause.visible = not pause.visible
	_inspecting = false
	player.look_locked = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if pause.visible else Input.MOUSE_MODE_CAPTURED


func _execute(command: Dictionary) -> bool:
	if not command["ok"]: _message(command["error"]); return false
	var effects: Array[Dictionary] = []
	effects.assign(command["effects"])
	if not Game.apply_effects(effects): _message("İşlem uygulanamadı; durum değiştirilmedi."); return false
	return true


func _message(text: String) -> void:
	message.text = text
	_feedback_until = Time.get_ticks_msec() + 5500
	message.visible = true


func _write_ledger(work: Dictionary) -> void:
	var lines: PackedStringArray = ["[b]GÜN SONU DEFTERİ[/b]", "Kasa: %s · Cep: %s" % [Money.format(Game.state.money["till"]), Money.format(Game.state.money["pocket"])]]
	lines.append("Denetim riski: %d" % Game.state.meters["suspicion"])
	for result: Dictionary in work.get("results", []):
		lines.append("\n[b]%s[/b] · %s" % [result["customer"], "DOĞRU" if result["correct"] else "YANLIŞ"])
		lines.append("%s%s" % ["; ".join(result["issues"]) if not result["issues"].is_empty() else "Geçerli belge", " · kayıt dışı satış" if result["source"] == "hidden" else ""])
	pages["ledger"].text = "\n".join(lines)
	page_viewports["ledger"].render_target_update_mode = SubViewport.UPDATE_ONCE


func _make_page(prop: Node3D, key: String, dimensions: Vector2, text: String) -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1100, 1400 if key == "ledger" else 900)
	viewport.disable_3d = true
	viewport.gui_disable_input = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	prop.add_child(viewport)
	var background: ColorRect = ColorRect.new()
	background.color = Color("e3d8bb")
	background.size = Vector2(viewport.size)
	viewport.add_child(background)
	var text_view: RichTextLabel = RichTextLabel.new()
	text_view.position = Vector2(35, 25)
	text_view.size = Vector2(viewport.size) - Vector2(70, 50)
	text_view.bbcode_enabled = true
	text_view.scroll_active = false
	text_view.add_theme_color_override("default_color", Color("383b31"))
	text_view.add_theme_font_size_override("normal_font_size", 36)
	text_view.add_theme_font_size_override("bold_font_size", 36)
	text_view.text = text
	viewport.add_child(text_view)
	pages[key] = text_view
	page_viewports[key] = viewport
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = dimensions
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_texture = viewport.get_texture()
	material.roughness = 1
	var thickness: float = 0.001 if key == "order" else 0.019
	_box(prop, Vector3(dimensions.x + 0.004, thickness, dimensions.y + 0.004), Vector3(0, thickness / 2, 0), Color("b5a782"))
	var surface: MeshInstance3D = MeshInstance3D.new()
	surface.mesh = plane
	surface.material_override = material
	surface.position.y = thickness + 0.002
	prop.add_child(surface)


func _is_book(tool: Interactable) -> bool:
	return tool != null and tool.action in ["book", "ledger", "order"]


func _remember(prop: Node3D) -> void:
	homes[prop] = prop.global_transform


func _prop(kind: String, at: Vector3, size: Vector3, solid_mesh: bool = false, color: Color = Color.GRAY) -> Interactable:
	var prop: Interactable = Interactable.new()
	prop.action = kind
	prop.position = at
	prop.collision_layer = 2
	prop.collision_mask = 0
	add_child(prop)
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = size.y / 2
	prop.add_child(collision)
	if solid_mesh: _box(prop, size, Vector3(0, size.y / 2, 0), color)
	return prop


func _solid(size: Vector3, at: Vector3, color: Color, kind: String = "wall") -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.position = at
	body.set_meta("surface", kind)
	add_child(body)
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	_box(body, size, Vector3.ZERO, color)
	return body


func _box(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	return _mesh(parent, mesh, at, color)


func _mesh(parent: Node3D, mesh: Mesh, at: Vector3, color: Color) -> MeshInstance3D:
	var node: MeshInstance3D = MeshInstance3D.new()
	node.mesh = mesh
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	node.material_override = material
	node.position = at
	parent.add_child(node)
	return node


func _cylinder(parent: Node3D, radius: float, height: float, at: Vector3, color: Color) -> void:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	_mesh(parent, mesh, at, color)


func _segment(parent: Node3D, from: Vector3, to: Vector3, radius: float, color: Color) -> void:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = from.distance_to(to)
	var node: MeshInstance3D = _mesh(parent, mesh, (from + to) / 2, color)
	node.quaternion = Quaternion(Vector3.UP, (to - from).normalized())


func _hand() -> Node3D:
	var root: Node3D = Node3D.new()
	_box(root, Vector3(0.07, 0.025, 0.09), Vector3.ZERO, Color("b29274"))
	for i: int in 4: _box(root, Vector3(0.014, 0.019, 0.05), Vector3(-0.025 + i * 0.017, 0, -0.045), Color("b29274"))
	_box(root, Vector3(0.018, 0.022, 0.047), Vector3(-0.038, -0.006, 0), Color("b29274"))
	_segment(root, Vector3(0, -0.003, 0.035), Vector3(0, -0.035, 0.28), 0.045, Color("4a5c50"))
	return root


func _label(parent: Node3D, text: String, at: Vector3, pixel_size: float) -> Label3D:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font_size = 24
	label.pixel_size = pixel_size
	label.position = at
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.outline_size = 4
	parent.add_child(label)
	return label


func _hud_label(parent: CanvasLayer, font_size: int, preset: int, y: float) -> Label:
	var label: Label = Label.new()
	parent.add_child(label)
	label.set_anchors_and_offsets_preset(preset)
	label.offset_left = -760
	label.offset_right = 760
	label.offset_top = y
	label.offset_bottom = y + 40
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _run_selftest() -> void:
	var failures: PackedStringArray = await preload("res://tests/fps_ration_regressions.gd").new().run(self)
	await _wait_customer()
	_aim(card.global_position)
	_key(KEY_E)
	await _wait_hands()
	if card_held: failures.append("out-of-reach pickup was allowed")
	player.camera.rotation = Vector3.ZERO
	var start: Vector3 = player.position
	_key_down(KEY_W, true)
	await get_tree().create_timer(1.25).timeout
	_key_down(KEY_W, false)
	await get_tree().create_timer(0.15).timeout
	if start.distance_to(player.position) < 1.5: failures.append("WASD input did not move the character")
	if player.position.z < -1.5: failures.append("character walked through the counter")
	await _capture("01_window")
	for i: int in rules.cases.size():
		await _wait_customer()
		var encounter: Dictionary = rules.current(Game.state)
		player.position = Vector3(0, 0.025, -1.25)
		await get_tree().physics_frame
		_aim(card.global_position)
		_key(KEY_E)
		await _wait_hands()
		await _wait_hands()
		await get_tree().physics_frame
		if card_held or card.get_parent() != self or RationDeskRules.desk(Game.state).get("placement") != "table":
			failures.append("customer card did not settle on world table: " + encounter["id"])
			break
		if i == 0:
			var resting_card: Transform3D = card.global_transform
			var eye_before: Transform3D = player.camera.transform
			_aim(card.global_position)
			_key(KEY_E)
			await _wait_hands()
			await get_tree().create_timer(0.28).timeout
			if not _desk_inspecting or player.camera.position.length() < 0.1: failures.append("world desk inspection did not lean the eye camera")
			await _capture("06_lean_inspection")
			_key(KEY_F)
			await _wait_hands()
			if card.global_basis.z.dot(Vector3.DOWN) < 0.99: failures.append("table flip did not expose physical back face")
			await _capture("12_table_back")
			_key(KEY_F)
			await _wait_hands()
			_key_down(KEY_S, true)
			await get_tree().create_timer(0.25).timeout
			_key_down(KEY_S, false)
			await get_tree().create_timer(0.22).timeout
			if _desk_inspecting or not player.can_move or player.look_locked: failures.append("walking did not release desk inspection")
			if not player.camera.position.is_equal_approx(eye_before.origin) or not card.global_transform.is_equal_approx(resting_card): failures.append("leaving the desk moved the card or failed to restore eye offset")
			if subtitle.visible: failures.append("customer subtitles followed the player away from the window")
			player.position = Vector3(0, 0.025, -1.25)
			await get_tree().physics_frame
		_aim(card.global_position)
		_key(KEY_R)
		await _wait_hands()
		if not card_held: failures.append("explicit world card pickup failed")
		var camera_before: Basis = player.camera.global_basis
		if i == 0:
			var distance_before: float = card.position.z
			_mouse(MOUSE_BUTTON_WHEEL_UP, true)
			if card.position.z <= distance_before: failures.append("held paper did not zoom toward the eye")
			_mouse(MOUSE_BUTTON_WHEEL_DOWN, true)
		_mouse(MOUSE_BUTTON_RIGHT, true)
		var motion: InputEventMouseMotion = InputEventMouseMotion.new()
		motion.relative = Vector2(30, -20)
		Input.parse_input_event(motion)
		Input.flush_buffered_events()
		_key(KEY_Q)
		if player.look_locked or _inspecting: failures.append("Q did not release held-object inspection")
		_mouse(MOUSE_BUTTON_RIGHT, false)
		if not player.camera.global_basis.is_equal_approx(camera_before) or card.rotation.x == 0:
			failures.append("inspection rotated the eye camera instead of the held card")
		_key(KEY_F)
		await get_tree().create_timer(0.34).timeout
		await _wait_hands()
		if card.front_showing: failures.append("physical back-face flip failed")
		if i == 0: await _capture("03_held_back")
		elif i == 5: await _capture("08_tampered_back")
		_key(KEY_F)
		await get_tree().create_timer(0.34).timeout
		await _wait_hands()
		if i == 0: await _capture("02_held_front")
		elif i == 5: await _capture("07_tampered_front")
		_aim(workmat.global_position)
		_key(KEY_G)
		await _wait_hands()
		await get_tree().create_timer(0.27).timeout
		await _wait_hands()
		await get_tree().physics_frame
		await get_tree().physics_frame
		if card_held or RationDeskRules.desk(Game.state).get("placement") != "table":
			failures.append("physical table placement failed")
		var kind: String = "approve" if RationDeskRules.issues(encounter).is_empty() else ("seize" if RationDeskRules.is_forged(encounter) else "reject")
		var stamp: Interactable = props["stamp_" + kind]
		_aim(stamp.global_position + Vector3(0, 0.08, 0))
		_key(KEY_E)
		await _wait_hands()
		if held_tool != stamp: failures.append("physical stamp pickup failed: " + encounter["id"])
		await get_tree().physics_frame
		_aim(card.pixel_to_world(Vector2(540, 190)))
		_mouse(MOUSE_BUTTON_LEFT, true)
		await get_tree().create_timer(0.12).timeout
		_mouse(MOUSE_BUTTON_LEFT, false)
		await get_tree().create_timer(0.36).timeout
		await _wait_hands()
		if RationDeskRules.desk(Game.state).get("stamp") != kind: failures.append("3D stamp contact failed: " + encounter["id"])
		_aim(homes[stamp].origin)
		_key(KEY_G)
		await _wait_hands()
		if held_tool != null: failures.append("physical stamp put-down failed")
		await get_tree().physics_frame
		if kind == "approve":
			var item: String = encounter["request"]["item"]
			_aim(props["scissors"].global_position + Vector3(0, 0.016, 0))
			_key(KEY_E)
			await _wait_hands()
			if held_tool != props["scissors"]: failures.append("physical scissors pickup failed")
			await get_tree().physics_frame
			var rect: Rect2 = RationCardView.coupon_rect(RationDeskRules.PRODUCT_ORDER.find(item))
			if i == 0:
				_aim(card.pixel_to_world(rect.position + Vector2(3, 0)))
				_mouse(MOUSE_BUTTON_LEFT, true)
				_aim(card.pixel_to_world(rect.position + Vector2(55, 0)))
				await get_tree().physics_frame
				_mouse(MOUSE_BUTTON_LEFT, false)
				if not (RationDeskRules.desk(Game.state).get("cuts", []) as Array).is_empty(): failures.append("short 3D cut spent a coupon")
			_aim(card.pixel_to_world(rect.position + Vector2(3, 0)))
			_mouse(MOUSE_BUTTON_LEFT, true)
			for step: int in range(1, 9):
				_aim(card.pixel_to_world(rect.position + Vector2(rect.size.x * step / 8, 0)))
				await get_tree().physics_frame
			_mouse(MOUSE_BUTTON_LEFT, false)
			if not item in RationDeskRules.desk(Game.state).get("cuts", []): failures.append("physical coupon cut failed: " + encounter["id"])
			if i == 0: await _capture("04_table_cut")
			_aim(Vector3(0.25, 0.966, -1.66))
			_key(KEY_G)
			await _wait_hands()
			await get_tree().physics_frame
			if not (RationDeskRules.desk(Game.state).get("parcel", {}) as Dictionary).is_empty(): failures.append("paperwork required goods before completion")
			# Actual walking/lean release is tested above; fixture positions isolate shelf handling.
			player.position = Vector3(1.60, 0.025, 0.15)
			await get_tree().physics_frame
			var shelf: Interactable = shelves["hidden" if i == 7 else item]
			_aim(shelf.global_position + Vector3(0, 0.14, 0))
			_key(KEY_E)
			await _wait_hands()
			if held_tool != parcel: failures.append("shelf package pickup after paperwork failed: " + encounter["id"])
			if i == 0: await _capture("09_goods_hand")
			elif i == 1: await _capture("11_sugar_hand")
			await get_tree().physics_frame
			player.position = Vector3(0, 0.025, -1.25)
			await get_tree().physics_frame
			_aim(Vector3(-0.85, 0.966, -1.66))
			_key(KEY_G)
			await _wait_hands()
			await get_tree().physics_frame
			if i == 0:
				_aim(parcel.global_position + Vector3(0, 0.05, 0))
				await _capture("10_goods_counter")
			_aim(parcel.global_position + Vector3(0, 0.05, 0))
			_key(KEY_E)
			await _wait_hands()
			await get_tree().physics_frame
			_aim(customer_target.global_position + Vector3(0, 0.45, 0))
			_key(KEY_E)
			await _wait_hands()
			if not RationDeskRules.desk(Game.state).get("parcel", {}).get("delivered", false): failures.append("package was not handed to customer")
			await _wait_hands()
		_aim(card.global_position)
		_key(KEY_R)
		await get_tree().create_timer(0.27).timeout
		await _wait_hands()
		await get_tree().physics_frame
		_aim((drawer.global_position + Vector3(0, 0.045, 0)) if kind == "seize" else (customer_target.global_position + Vector3(0, 0.45, 0)))
		_key(KEY_E)
		await _wait_hands()
		await get_tree().create_timer(0.34).timeout
		await _wait_hands()
		if not RationDeskRules.desk(Game.state).get("done", false):
			failures.append("physical card delivery failed: " + encounter["id"] + " / " + message.text)
			break
		_aim(bell.global_position + Vector3(0, 0.03, 0))
		_key(KEY_E)
		await _wait_hands()
	var results: Array = RationDeskRules.desk(Game.state).get("results", [])
	if results.size() != 8: failures.append("only %d of 8 cases completed" % results.size())
	for result: Dictionary in results:
		if not result["correct"]: failures.append("unexpected audit error: " + result["case"])
	for name: String in ["paper_pick", "paper_flip", "stamp_down", "stamp_lift", "snip", "coupon_drop", "drawer"]:
		if not name in foley.events: failures.append("missing physical sound contact: " + name)
	if rules.current(Game.state).is_empty():
		_aim(props["ledger"].global_position)
		_key(KEY_E)
		await _wait_hands()
		await _capture("05_ledger")
	# Interrupted hand/NPC animations must not alter the new day's document.
	_restart()
	await _wait_customer()
	player.position = Vector3(0, 0.025, -1.25)
	await get_tree().physics_frame
	_aim(card.global_position)
	_key(KEY_E)
	await _wait_hands()
	await _wait_hands()
	_aim(card.global_position)
	_key(KEY_F)
	await get_tree().physics_frame
	_restart()
	await _wait_customer()
	await get_tree().create_timer(0.35).timeout
	if not card.front_showing or card_held or _card_busy or not customer.visible or not _window_ready:
		failures.append("restart left an old card/NPC animation active")
	foley.stop_all()
	await get_tree().create_timer(0.15).timeout
	print("[fps selftest] %s" % ("PASS: movement/collision/reach, table handoff, lean/leave, held inspection exit, paperwork before goods, 3D tools, 8 customers" if failures.is_empty() else "FAIL: " + "; ".join(failures)))
	get_tree().quit(0 if failures.is_empty() else 1)


func _wait_hands() -> void:
	var deadline: int = Time.get_ticks_msec() + 5000
	while (_busy or _card_busy) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


func _wait_customer() -> void:
	var attempts: int = 0
	while not _window_ready and not rules.current(Game.state).is_empty() and attempts < 100:
		await get_tree().create_timer(0.02).timeout
		attempts += 1
	await get_tree().physics_frame
	await get_tree().physics_frame


func _aim(at: Vector3) -> void:
	player.camera.look_at(at)


func _key(key: int) -> void:
	_key_down(key, true)
	_key_down(key, false)


func _key_down(key: int, pressed: bool) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _mouse(button: int, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _capture(name: String) -> void:
	if _capture_dir == "" or DisplayServer.get_name() == "headless": return
	DirAccess.make_dir_recursive_absolute(_capture_dir)
	for i: int in 4: await get_tree().process_frame
	var err: Error = get_viewport().get_texture().get_image().save_png(_capture_dir.path_join(name + ".png"))
	if err != OK: push_error("FPS screenshot failed: " + error_string(err))


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and not _selftest and not pause.visible:
		_toggle_pause()


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
