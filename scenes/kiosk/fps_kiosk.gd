extends Node3D
## Physical first-person workflow. The document UI is ink on a 3D object only.

@export var document_focus: bool = false
@export var review_day_only: bool = false

const REACH: float = 2.5
var player: KioskFPSPlayer
var card: RationCard3D
var identity_document: IdentityDocument3D
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
var crosshair: Label
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
var _desk_center: Vector3 = Vector3.ZERO
var _desk_distance: float = 0.82
var _desk_pan: bool = false
var _desk_cursor_override: Vector2 = Vector2(INF, INF)
var _eye_fov: float = 72.0
var _cut_tip: Vector2 = Vector2.ZERO
var _cut_points: PackedVector2Array = []
var _cut_length_m: float = 0.0
var _cut_direction: Vector2 = Vector2.RIGHT
var _scissor_stroke: ScissorStroke
var _last_snip_cycle: int = -1
var _paper_dragging: bool = false
var _paper_rotating: bool = false
var _paper_drag_offset: Vector3 = Vector3.ZERO
var _paper_rotation_anchor: Vector3 = Vector3.ZERO
var _table_yaw: float = 0.0
var _stamp_height: float = 0.10
var _stamp_target_height: float = 0.10
var _stamp_impact_speed: float = 0.0
var _stamp_approach_speed: float = 0.0
var _stamp_dwell: float = 0.0
var _stamp_pressure: float = 0.0
var _stamp_offset: Vector2 = Vector2.ZERO
var _stamp_serial: int = -1
var _stamp_update_time: float = 0.0
var _stamp_yaw: float = 0.0
var _stamp_cursor_before: Vector2 = Vector2.ZERO
var _stamp_lift_played: bool = false
var _tweens: Array[Tween] = []
var _tokens: Array[Node3D] = []
var _selftest: bool = false
var _capture_dir: String = ""
var _object_inspector: HeldObjectInspector
var _inspect_pending: bool = false
var _inspection_back: bool = false
var _inspection_left_visible: bool = false
var _inspection_right_visible: bool = false
var _inspection_card_visible: bool = false
var _comparison_views: Dictionary[int, Dictionary] = {}
var _placement_preview: PaperPlacementPreview
var _stamp_guide: StampPlacementGuide
var _stamp_assistance: bool = true


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--selftest": _selftest = true
		elif arg.begins_with("--capture="): _capture_dir = arg.trim_prefix("--capture=")
	_load_cases()
	foley = RationFoley.new()
	add_child(foley)
	_build_room()
	_build_station()
	_object_inspector = HeldObjectInspector.new()
	add_child(_object_inspector)
	_placement_preview = PaperPlacementPreview.new()
	add_child(_placement_preview)
	_stamp_guide = StampPlacementGuide.new()
	card.add_child(_stamp_guide)
	_build_hud()
	Game.state_changed.connect(_refresh)
	_restart()
	if _selftest:
		if document_focus: _run_document_selftest()
		else: _run_selftest()


func _load_cases() -> void:
	var cases: Array = [] if document_focus and review_day_only else ContentDB.all_of("ration_case")
	if document_focus: cases.append_array(ContentDB.all_of("ration_review_case"))
	rules = RationDeskRules.new(cases)


func _start_review_day() -> void:
	review_day_only = true
	_load_cases()
	_restart()


func _build_room() -> void:
	var environment: WorldEnvironment = WorldEnvironment.new()
	environment.environment = Environment.new()
	var sky: Sky = Sky.new()
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("8296a7")
	sky_material.sky_horizon_color = Color("c1c0b0")
	sky_material.ground_bottom_color = Color("42392f")
	sky_material.ground_horizon_color = Color("777566")
	sky.sky_material = sky_material
	environment.environment.sky = sky
	environment.environment.background_mode = Environment.BG_SKY
	environment.environment.background_color = Color("a4b7b9")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("e8e3ce")
	environment.environment.ambient_light_energy = 0.25
	add_child(environment)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 0.45
	sun.shadow_enabled = true
	sun.shadow_bias = 0.20
	sun.shadow_normal_bias = 1.5
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
	task_light.light_energy = 0.08
	task_light.omni_range = 2.5
	add_child(task_light)
	player = KioskFPSPlayer.new()
	add_child(player)
	left_hand = _hand()
	right_hand = WorkbenchArt.build_hand(true)
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
	var offered_hand: Node3D = _hand()
	customer.add_child(offered_hand)
	offered_hand.position = Vector3(0.22, 1.14, 0.78)
	offered_hand.rotation.y = PI


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
		# Leave enough space for a perspective ray to each empty base. A tight
		# row let the adjacent tall handle block G when returning a stamp.
		var stamp: Interactable = _prop("stamp_" + kind, Vector3(-0.04 + i * 0.19, 0.968, -1.89), Vector3(0.105, 0.20, 0.07))
		_adopt_visual(stamp, WorkbenchArt.build_stamp(kind))
		var stamp_name: Label3D = _label(stamp, ["ONAY", "RET", "ALIKOY"][i], Vector3(0, 0.023, 0.022), 0.00032)
		stamp_name.rotation.x = -PI / 2
		stamp_name.font = RationCardView.TYPEWRITER
		stamp_name.modulate = Color("d3c6a7")
		stamp_name.outline_size = 0
		props["stamp_" + kind] = stamp
		_remember(stamp)
	var scissors: Interactable = _prop("scissors", Vector3(0.31, 0.968, -2.40), Vector3(0.24, 0.035, 0.10))
	_adopt_visual(scissors, WorkbenchArt.build_scissors())
	props["scissors"] = scissors
	_remember(scissors)
	var book: Interactable = _prop("book", Vector3(-0.60, 0.97, -2.13), Vector3(0.244, 0.014, 0.229))
	book.add_child(preload("res://scenes/kiosk/desk_reference.gd").new())
	var loupe: InspectionLoupe = preload("res://scenes/kiosk/inspection_loupe.gd").new()
	add_child(loupe)
	loupe.position = Vector3(0.45, 0.969, -2.41)
	loupe.configure(get_world_3d())
	props["loupe"] = loupe
	_remember(loupe)
	props["book"] = book
	_remember(book)
	_solid(Vector3(0.55, 0.07, 0.65), Vector3(-2.2, 0.92, -1.65), Color("7f6249"), "table")
	var order: Interactable = _prop("order", Vector3(0.35, 0.97, -2.16), Vector3(0.29, 0.009, 0.17))
	_make_page(order, "order", Vector2(0.28, 0.16), "TALEP FİŞİ")
	props["order"] = order
	_remember(order)
	var ledger: Interactable = _prop("ledger", Vector3(-2.2, 0.97, -1.65), Vector3(0.37, 0.02, 0.47))
	_make_page(ledger, "ledger", Vector2(0.36, 0.46), "[b]GÜN SONU DEFTERİ[/b]\n\nMüşteri sırası bitince kararlar ve hesap buraya yazılır.")
	props["ledger"] = ledger
	_remember(ledger)
	bell = _prop("bell", Vector3(1.10, 0.97, -2.12), Vector3(0.11, 0.07, 0.11))
	_cylinder(bell, 0.05, 0.04, Vector3(0, 0.025, 0), Color("b8a46f"))
	if not document_focus:
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
	identity_document = IdentityDocument3D.new()
	add_child(identity_document)
	identity_document.position = Vector3(-0.22, 0.964, -2.42)
	identity_document.quaternion = RationCard3D.table_orientation(true)
	identity_document.visible = false
	props["identity"] = identity_document
	_remember(identity_document)


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


func _adopt_visual(parent: Node3D, model: Node3D) -> void:
	for child: Node in model.get_children():
		model.remove_child(child)
		parent.add_child(child)
	model.free()


func _build_hud() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)
	crosshair = Label.new()
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
	controls.text = "FPS / KARNE\nWASD: yürü · Shift: hızlan\nE: al / teslim et · G: yüzeye bırak\nMasada E: üstten bak · R: karneyi al\nElde F: yakından incele · F/Esc: geri\nİncelemede sol sürükle: döndür\nSağ tık: ters yüz · R: düzelt\nT: karneyi ışığa tut · Tekerlek: zoom\nİki belge eldeyken C: karşılaştır\nKitapçık incelemede Tab: rehber sayfası\nMasada F: çevir · Q/WASD: ayrıl\nSol tut + fare aşağı: damgayı indir\nSol tut + sürükle: makasla kes\n\nSes" if document_focus else "FPS / KARNE\nWASD: yürü · E: al / teslim et\nG: bırak · R: karneyi eline al\nSağ tut: elde incele · F: çevir\nQ / WASD: masadan ayrıl\n\nSes"
	controls.add_theme_font_size_override("font_size", 20)
	rows.add_child(controls)
	var volume: HSlider = HSlider.new()
	volume.max_value = 1
	volume.step = 0.01
	volume.value = 0.56
	volume.value_changed.connect(foley.set_level)
	rows.add_child(volume)
	var assistance: CheckBox = CheckBox.new()
	assistance.text = "İlk 2 müşteride damga hedefini vurgula"
	assistance.button_pressed = _stamp_assistance
	assistance.toggled.connect(func(enabled: bool) -> void: _stamp_assistance = enabled)
	rows.add_child(assistance)
	for entry: Array in [["Devam", _toggle_pause], ["Yeni deneme günü", _restart]]:
		var button: Button = Button.new()
		button.text = entry[0]
		button.pressed.connect(entry[1])
		rows.add_child(button)
	if document_focus:
		var review_button: Button = Button.new()
		review_button.text = "Belge karşılaştırma çalışma günü"
		review_button.pressed.connect(_start_review_day)
		rows.add_child(review_button)
	pause.visible = false


func _restart() -> void:
	_close_object_inspection()
	_inspect_pending = false
	_exit_desk_inspection(true)
	_epoch += 1
	for tween: Tween in _tweens:
		if tween.is_valid(): tween.kill()
	_tweens.clear()
	for token: Node3D in _tokens:
		if is_instance_valid(token): token.queue_free()
	_tokens.clear()
	_cut_index = -1
	_paper_dragging = false
	_table_yaw = 0.0
	_stamp_yaw = 0.0
	_held_distance = 0.48
	_stamp_charging = false
	_busy = false
	_card_busy = false
	_inspecting = false
	card_held = false
	if held_tool != null: _return_tool_home()
	for prop: Node3D in homes:
		prop.global_transform = homes[prop]
		if prop is CollisionObject3D: prop.collision_layer = 2
	_clear_identity()
	left_hand.visible = false
	left_hand.reparent(player.camera)
	right_hand.visible = false
	right_hand.reparent(player.camera)
	card.reparent(self)
	card.scale = Vector3.ONE
	card.front_showing = true
	card.set_held(false)
	player.position = Vector3(0, 0.03, -1.1) if document_focus and not _selftest else Vector3(0, 0.03, 1.1)
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
			_close_object_inspection()
			_clear_identity()
			_index = index
			_window_ready = false
			customer.leave()
		card.visible = false
		subtitle.text = "Gün tamamlandı. Masadaki gün sonu defterini eline alıp inceleyebilirsin."
		_write_ledger(work)
	elif index != _index:
		_close_object_inspection()
		_clear_identity()
		_inspect_pending = false
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
		identity_document.configure(encounter.get("identity", {}))
		_offer_card(index, _epoch)
	else:
		card.refresh(encounter["card"], work)
	pages["order"].text = "[b]ZAMÓWIENIE / TALEP[/b]\n\n" + ("Gün tamamlandı." if encounter.is_empty() else "%s\n\n%s\n[b]%s[/b]\n\n%s" % [encounter["customer"], RationDeskRules.GOODS[encounter["request"]["item"]], RationDeskRules.amount_text(encounter["request"]["item"], int(encounter["request"]["amount"])), "PUNKT NR 081  /  15.II.1982" if document_focus else "Karne → damga / kupon → erzak → teslim."])
	page_viewports["order"].render_target_update_mode = SubViewport.UPDATE_ONCE
	for item: String in shelves:
		if item == "hidden": continue
		shelf_labels[item].text = "%s\n%s" % [RationDeskRules.GOODS[item], RationDeskRules.amount_text(item, int(work.get("official", {}).get(item, 0)))]
	if shelf_labels.has("hidden"): shelf_labels["hidden"].text = "ÖZEL STOK\nEt: %d g" % int(work.get("hidden", {}).get("meat", 0))
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


func _clear_identity() -> void:
	if held_tool == identity_document: _return_tool_home()
	identity_document.reparent(self)
	identity_document.global_transform = homes[identity_document]
	identity_document.visible = false
	identity_document.collision_layer = 0


func _receive_identity() -> void:
	if identity_document.identity.is_empty(): return
	identity_document.visible = true
	identity_document.collision_layer = 0
	identity_document.global_position = Vector3(-0.10, 1.08, -2.79)
	var generation: int = _epoch
	var index: int = _index
	var transfer: Tween = create_tween()
	_tweens.append(transfer)
	transfer.tween_property(identity_document, "global_position", homes[identity_document].origin, 0.36).set_trans(Tween.TRANS_SINE)
	transfer.tween_callback(func() -> void:
		if generation == _epoch and index == _index:
			identity_document.collision_layer = 2
			foley.play_sound("paper_place"))


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


func _open_object_inspection(target_override: Node3D = null, continuing_comparison: bool = false) -> void:
	if _object_inspector.active or _busy or _card_busy or _paper_dragging or _stamp_charging or _cut_index >= 0: return
	var target: Node3D = target_override if target_override != null else (card if card_held else held_tool)
	if target == null: return
	if not continuing_comparison: _comparison_views.clear()
	_exit_desk_inspection(true)
	_inspecting = false
	_inspection_back = false
	_inspection_left_visible = left_hand.visible
	_inspection_right_visible = right_hand.visible
	_inspection_card_visible = card.visible
	left_hand.visible = false
	right_hand.visible = false
	if held_tool != null: held_tool.visible = held_tool == target
	if card_held: card.visible = target == card
	var readable: Quaternion = Quaternion.IDENTITY
	var dimensions: Vector3 = Vector3(RationCard3D.WIDTH, RationCard3D.HEIGHT, 0.01)
	var center: Vector3 = Vector3.ZERO
	if target == card:
		readable = Quaternion(Vector3.UP, 0.0 if card.front_showing else PI)
	elif target == identity_document:
		dimensions = Vector3(IdentityDocument3D.WIDTH, IdentityDocument3D.HEIGHT, IdentityDocument3D.THICKNESS)
	elif _is_book(held_tool):
		readable = Quaternion(Vector3.RIGHT, PI / 2)
		dimensions = Vector3(0.37, 0.025, 0.47) if held_tool.action == "ledger" else Vector3(0.28, 0.02, 0.23)
	elif held_tool.action.begins_with("stamp_"):
		dimensions = Vector3(0.105, 0.20, 0.07)
		center.y = 0.09
	elif held_tool.action == "scissors":
		readable = Quaternion(Vector3.RIGHT, PI / 2)
		dimensions = Vector3(0.24, 0.04, 0.11)
	else:
		readable = Quaternion(Vector3.RIGHT, PI / 2)
		dimensions = Vector3(0.16, 0.04, 0.24)
	_object_inspector.open(target, player.camera, readable, dimensions, center)
	if continuing_comparison and _comparison_views.has(target.get_instance_id()):
		var view: Dictionary = _comparison_views[target.get_instance_id()]
		_inspection_back = view.get("back", false)
		_object_inspector.restore_view(view)
	player.look_locked = true
	player.can_move = false
	_placement_preview.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_viewport().warp_mouse(get_viewport().get_visible_rect().size / 2)
	_feedback_until = 0


func _close_object_inspection() -> void:
	if _object_inspector == null or not _object_inspector.active: return
	_object_inspector.close()
	left_hand.visible = _inspection_left_visible
	right_hand.visible = _inspection_right_visible
	card.visible = _inspection_card_visible
	if held_tool != null: held_tool.visible = true
	player.look_locked = false
	player.can_move = not pause.visible
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _inspection_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).physical_keycode:
			KEY_F, KEY_ESCAPE, KEY_Q: _close_object_inspection()
			KEY_T: _object_inspector.toggle_backlight()
			KEY_C:
				if card_held and held_tool == identity_document:
					var view: Dictionary = _object_inspector.capture_view()
					view["back"] = _inspection_back
					_comparison_views[_object_inspector.object.get_instance_id()] = view
					var target: Node3D = identity_document if _object_inspector.object == card else card
					_close_object_inspection()
					_open_object_inspection(target, true)
			KEY_TAB:
				if _object_inspector.object == props["book"]:
					var reference: RationDeskReference = props["book"].get_node("ClassAndIssuerReference")
					reference.next_evidence_page()
					_inspection_back = true
					_object_inspector.readable_face(true)
					foley.play_sound("paper_flip")
			KEY_R:
				_inspection_back = false
				_object_inspector.reset_pose()
			KEY_W, KEY_A, KEY_S, KEY_D: _close_object_inspection()
	elif event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT: _object_inspector.dragging = mouse.pressed
		elif mouse.pressed:
			match mouse.button_index:
				MOUSE_BUTTON_RIGHT:
					_inspection_back = not _inspection_back
					_object_inspector.readable_face(_inspection_back)
					foley.play_sound("paper_flip")
				MOUSE_BUTTON_WHEEL_UP: _object_inspector.zoom(-1.0)
				MOUSE_BUTTON_WHEEL_DOWN: _object_inspector.zoom(1.0)
	elif event is InputEventMouseMotion:
		var mouse: InputEventMouseMotion = event as InputEventMouseMotion
		var movement: Vector2 = mouse.screen_relative
		if movement == Vector2.ZERO: movement = mouse.relative
		_object_inspector.rotate_object(movement)


func _card_placement(at: Vector3) -> Vector3:
	# This function is shared by the footprint and the actual placement tween.
	return Vector3(clampf(at.x, -0.43, 0.01), 0.978, clampf(at.z, -2.32, -1.95))


func _update_placement_preview() -> void:
	_placement_preview.visible = false
	if not document_focus or not card_held or _object_inspector.active or _card_busy or _busy: return
	var hit: Dictionary = _ray()
	var target: Node = hit.get("collider") as Node
	if target == null or not (target == workmat or target.get_meta("surface", "") == "table"): return
	_placement_preview.global_position = _card_placement(hit["position"]) + Vector3.UP * 0.001
	_placement_preview.rotation.y = _table_yaw
	_placement_preview.visible = true


func _input(event: InputEvent) -> void:
	if _object_inspector.active:
		_inspection_input(event)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).physical_keycode:
			KEY_ESCAPE: _toggle_pause(); get_viewport().set_input_as_handled(); return
			KEY_E:
				if not pause.visible: _interact()
			KEY_Q:
				if not pause.visible:
					_inspect_pending = false
					_exit_desk_inspection()
					_subtitle_until = 0
			KEY_R:
				if not pause.visible and not _busy and not _card_busy and _ray().get("collider") == card and RationDeskRules.desk(Game.state).get("placement") == "table":
					_exit_desk_inspection(true)
					if _execute(rules.move_card(Game.state, "hand")): _hold_card()
			KEY_G:
				if not pause.visible: _drop_held()
			KEY_F:
				if not pause.visible and not _paper_dragging:
					if document_focus and not _desk_inspecting and (card_held or held_tool != null):
						if _card_busy or _busy: _inspect_pending = true
						else: _open_object_inspection()
					else: _flip_card()
	if pause.visible: return
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if mouse.button_index == MOUSE_BUTTON_RIGHT:
			if _paper_dragging:
				if mouse.pressed: _paper_rotation_anchor = card.global_position
				else: _paper_drag_offset = card.global_position - _table_point()
				_paper_rotating = mouse.pressed
			elif _desk_inspecting:
				_desk_pan = mouse.pressed and not _stamp_charging and _cut_index < 0
			else:
				_inspecting = not document_focus and mouse.pressed and (card_held or _is_book(held_tool))
				player.look_locked = _inspecting
		elif mouse.pressed and mouse.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var step: float = -1.0 if mouse.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
			if _desk_inspecting and not _stamp_charging and _cut_index < 0:
				if mouse.shift_pressed and held_tool != null and held_tool.action.begins_with("stamp_"):
					_stamp_yaw += step * 0.10
				else:
					_desk_distance = clampf(_desk_distance * (1.0 + step * 0.12), 0.42, 2.05)
					_update_overhead_camera()
			else:
				_held_distance = clampf(_held_distance + step * 0.035, 0.30, 0.65)
				if card_held and not _card_busy: card.position = _card_hold_position()
				elif _is_book(held_tool): held_tool.position = _book_hold_position()
		elif mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				if held_tool == null and not _busy and not _card_busy:
					if _desk_inspecting and _ray().get("collider") == card: _begin_paper_drag()
					else: _interact()
				else: _begin_tool()
			else:
				if _paper_dragging: _end_paper_drag()
				else: _end_tool()
	elif event is InputEventMouseMotion:
		var mouse: InputEventMouseMotion = event
		var movement: Vector2 = mouse.screen_relative
		if movement == Vector2.ZERO: movement = mouse.relative * get_viewport().get_screen_transform().get_scale()
		if _paper_dragging:
			if _paper_rotating: _table_yaw += movement.x * 0.006
			if not _selftest: _desk_cursor_override = Vector2(INF, INF)
			get_viewport().set_input_as_handled()
		elif _stamp_charging:
			_stamp_target_height = clampf(_stamp_target_height - movement.y * 0.00065, -0.004, 0.14)
			_stamp_offset.x = clampf(_stamp_offset.x + movement.x * 0.00012, -0.009, 0.009)
			get_viewport().set_input_as_handled()
		elif _desk_inspecting:
			if not _selftest: _desk_cursor_override = Vector2(INF, INF)
			if _desk_pan:
				_desk_center.x -= movement.x * _desk_distance * 0.0014
				_desk_center.z -= movement.y * _desk_distance * 0.0014
				_update_overhead_camera()
			get_viewport().set_input_as_handled()
		elif _inspecting:
			_inspect_angles.x = clampf(_inspect_angles.x - movement.y * 0.004, -0.65, 0.65)
			_inspect_angles.y = clampf(_inspect_angles.y + movement.x * 0.004, -0.8, 0.8)
			if card_held and not _card_busy:
				card.rotation = Vector3(_inspect_angles.x, _inspect_angles.y + (0 if card.front_showing else PI), 0)
			elif _is_book(held_tool): held_tool.rotation = Vector3(PI / 2 + _inspect_angles.x, _inspect_angles.y, 0)
			get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if _inspect_pending and not pause.visible and not _busy and not _card_busy:
		_inspect_pending = false
		_open_object_inspection()
	if _object_inspector.active and Input.get_vector("move_left", "move_right", "move_forward", "move_back") != Vector2.ZERO:
		_close_object_inspection()
	if not pause.visible and (_desk_inspecting or _stamp_charging or _stamp_animating or _cut_index >= 0) and Input.get_vector("move_left", "move_right", "move_forward", "move_back") != Vector2.ZERO:
		_exit_desk_inspection()
	player.can_move = not pause.visible and not _desk_inspecting and not _object_inspector.active and not _busy and _cut_index < 0 and not _stamp_charging
	player.sensitivity = 0.002
	if pause.visible: return
	crosshair.visible = not _desk_inspecting and not _object_inspector.active
	subtitle.visible = not _desk_inspecting and not _object_inspector.active and _window_ready and Time.get_ticks_msec() < _subtitle_until and player.global_position.distance_to(customer_target.global_position) < 3.0 and -player.camera.global_basis.z.dot((customer_target.global_position - player.camera.global_position).normalized()) > 0.55
	message.visible = Time.get_ticks_msec() < _feedback_until
	_update_placement_preview()
	_update_stamp_guide()
	if _object_inspector.active:
		hint.text = "İNCELE · Sol sürükle: döndür · Tekerlek: yaklaş · Sağ tık: çevir · R: düzelt · F/Esc/Q: geri"
		if _object_inspector.object == card:
			hint.text += "\nT · Işığı kaldır" if _object_inspector.backlight_enabled else "\nT · Işığa tut — filigranı ve kâğıt liflerini incele"
		if card_held and held_tool == identity_document: hint.text += "\nC · Diğer belgeyi yakından karşılaştır"
		if _object_inspector.object == props["book"]: hint.text += "\nTab · Kâğıt ve belge karşılaştırma rehberleri"
		return
	if _paper_dragging: _update_paper_drag(delta)
	elif _stamp_charging: _update_stamp(delta)
	elif _cut_index >= 0: _update_cut(delta)
	elif _desk_inspecting and not _busy and not _card_busy and held_tool != null:
		_update_tool_hover()
	var hit: Dictionary = _ray()
	hint.text = _hint(hit.get("collider") as Node)

func _enter_desk_inspection() -> void:
	_close_object_inspection()
	if _desk_inspecting or card_held or not card.visible or RationDeskRules.desk(Game.state).get("placement") != "table": return
	if player.camera.global_position.distance_to(card.global_position) > 1.5:
		_message("Masaya yaklaş ve karneye E ile etkileş."); return
	if _lean_tween != null and _lean_tween.is_valid(): return
	_eye_rest = player.camera.transform
	_eye_fov = player.camera.fov
	_desk_inspecting = true
	_desk_center = Vector3(card.global_position.x, card.global_position.y, card.global_position.z)
	_desk_distance = maxf(0.90, 1.30 / (2.0 * tan(deg_to_rad(25.0)) * maxf(0.8, get_viewport().get_visible_rect().size.aspect())))
	_desk_center.x = -0.12
	_desk_cursor_override = Vector2(INF, INF)
	player.look_locked = true
	player.camera.reparent(self)
	_lean_tween = create_tween().set_parallel(true)
	_lean_tween.tween_property(player.camera, "global_position", _desk_center + Vector3.UP * _desk_distance, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_lean_tween.tween_property(player.camera, "quaternion", Quaternion(Vector3.RIGHT, -PI / 2), 0.42).set_trans(Tween.TRANS_SINE)
	_lean_tween.tween_property(player.camera, "fov", 50.0, 0.42)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_viewport().warp_mouse(get_viewport().get_visible_rect().size / 2)
	if held_tool != null:
		held_tool.reparent(self)
		_pose_tool()
	_message("Masa: fareyle aracı yönelt · Sağ tuş sürükle: masayı kaydır · Tekerlek: yaklaş · Q/WASD: ayrıl")


func _update_overhead_camera() -> void:
	_desk_center.x = clampf(_desk_center.x, -0.85, 0.80)
	_desk_center.z = clampf(_desk_center.z, -2.56, -1.68)
	if _lean_tween != null and _lean_tween.is_valid(): _lean_tween.kill()
	player.camera.global_position = _desk_center + Vector3.UP * _desk_distance
	player.camera.quaternion = Quaternion(Vector3.RIGHT, -PI / 2)
	player.camera.fov = 50.0


func _pointer_position() -> Vector2:
	if _stamp_charging: return _stamp_cursor_before
	if _selftest and _desk_cursor_override.is_finite(): return _desk_cursor_override
	return get_viewport().get_mouse_position()


func _paper_pixel() -> Vector2:
	var pixel: Vector2 = _pointer_position()
	return card.ray_pixel(player.camera.project_ray_origin(pixel), player.camera.project_ray_normal(pixel))


func _table_point() -> Vector3:
	var pixel: Vector2 = _pointer_position()
	var origin: Vector3 = player.camera.project_ray_origin(pixel)
	var direction: Vector3 = player.camera.project_ray_normal(pixel)
	if absf(direction.y) < 0.0001: return _desk_center
	return origin + direction * ((_desk_center.y - origin.y) / direction.y)

func _cancel_gesture() -> void:
	if _paper_dragging: _end_paper_drag(true)
	if _cut_index >= 0: _commit_incision()
	if _stamp_charging or _stamp_animating:
		if _stamp_contacted: _save_stamp_impression()
		if _stamp_tween != null and _stamp_tween.is_valid(): _stamp_tween.kill()
		_tool_generation += 1
		if _stamp_contacted and not _stamp_lift_played: foley.play_sound("stamp_lift")
		_stamp_animating = false
		_stamp_contacted = false
		_stamp_charging = false
		_busy = false
		_restore_tool_to_hand()
	_inspecting = false
	_desk_pan = false
	player.look_locked = _desk_inspecting
	if _desk_inspecting: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _exit_desk_inspection(immediate: bool = false) -> void:
	if held_tool is InspectionLoupe: held_tool.set_active(false)
	_cancel_gesture()
	if not _desk_inspecting:
		if immediate and _lean_tween != null and _lean_tween.is_valid():
			_lean_tween.kill()
			player.camera.transform = _eye_rest
			player.camera.fov = _eye_fov
		player.look_locked = false
		return
	_desk_inspecting = false
	_desk_cursor_override = Vector2(INF, INF)
	player.look_locked = false
	if _lean_tween != null and _lean_tween.is_valid(): _lean_tween.kill()
	player.camera.reparent(player.head)
	if immediate:
		player.camera.transform = _eye_rest
		player.camera.fov = _eye_fov
	else:
		_lean_tween = create_tween().set_parallel(true)
		_lean_tween.tween_property(player.camera, "position", _eye_rest.origin, 0.30).set_trans(Tween.TRANS_CUBIC)
		_lean_tween.tween_property(player.camera, "quaternion", _eye_rest.basis.get_rotation_quaternion(), 0.30)
		_lean_tween.tween_property(player.camera, "fov", _eye_fov, 0.30)
	if held_tool != null: _restore_tool_to_hand()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _ray() -> Dictionary:
	var origin: Vector3 = player.camera.global_position
	var direction: Vector3 = -player.camera.global_basis.z
	if _desk_inspecting:
		origin = player.camera.project_ray_origin(_pointer_position())
		direction = player.camera.project_ray_normal(_pointer_position())
	return get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin, origin + direction * REACH, 3))

func _interact() -> void:
	if _busy or _card_busy or _cut_index >= 0 or _stamp_charging: return
	var hit: Dictionary = _ray()
	var target: Interactable = hit.get("collider") as Interactable
	if target == null:
		var surface: Node = hit.get("collider") as Node
		if surface != null and surface.get_meta("surface", "") == "table":
			if card_held: _place_card(hit["position"])
			else: _enter_desk_inspection()
		return
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
	elif kind.begins_with("stamp_") or kind in ["scissors", "book", "ledger", "order", "loupe", "identity"]:
		if held_tool != null: _message("Sağ elindeki nesneyi G ile bir yüzeye bırak."); return
		_equip(target)


func _begin_paper_drag() -> void:
	if not _desk_inspecting or card_held or _busy or _card_busy or held_tool != null: return
	_paper_dragging = true
	_paper_rotating = false
	_paper_drag_offset = card.global_position - _table_point()
	card.set_held(true)
	foley.play_sound("paper_pick")


func _update_paper_drag(delta: float) -> void:
	var target: Vector3 = _paper_rotation_anchor if _paper_rotating else _table_point() + _paper_drag_offset
	target.x = clampf(target.x, -0.72, 0.58)
	target.z = clampf(target.z, -2.52, -1.80)
	target.y = 1.025
	card.global_position = card.global_position.lerp(target, 1.0 - exp(-delta * 22.0))
	card.quaternion = Quaternion(Vector3.UP, _table_yaw) * RationCard3D.table_orientation(card.front_showing)


func _paper_rest_height() -> float:
	var radius_x: float = absf(cos(_table_yaw)) * 0.18 + absf(sin(_table_yaw)) * 0.1125
	var radius_z: float = absf(sin(_table_yaw)) * 0.18 + absf(cos(_table_yaw)) * 0.1125
	var footprint: Rect2 = Rect2(Vector2(card.position.x - radius_x, card.position.z - radius_z), Vector2(radius_x, radius_z) * 2.0)
	return 0.978 if footprint.intersects(Rect2(-0.535, -2.345, 0.67, 0.43)) else 0.9608


func _end_paper_drag(immediate: bool = false) -> void:
	_paper_dragging = false
	_paper_rotating = false
	card.set_held(false)
	if immediate:
		card.position.y = _paper_rest_height()
		return
	_card_busy = true
	var generation: int = _epoch
	var settle: Tween = create_tween()
	_tweens.append(settle)
	settle.tween_property(card, "position:y", _paper_rest_height(), 0.16).set_trans(Tween.TRANS_SINE)
	settle.tween_callback(func() -> void:
		if generation == _epoch:
			_card_busy = false
			foley.play_sound("paper_place"))


func _receive_card() -> void:
	_receive_identity()
	if document_focus:
		_hold_card()
		return
	card_held = false
	card.set_held(false)
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
			foley.play_sound("paper_place")
			if document_focus and not pause.visible: _enter_desk_inspection())
	_message("Karneyi masaya alıyorsun. E: eğilip incele · R: eline al. İstediğin zaman uzaklaşabilirsin.")


func _hold_card() -> void:
	card_held = true
	card.set_held(true)
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
	_message("Kart elinde. F: yakından incele · Masaya bakıp E / G: bırak." if document_focus else "Kart elinde. Sağ tuşa basılı tutup fareyle eğ; F ile çevir. Masaya bakıp G ile bırak.")


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
	card.set_held(false)
	_placement_preview.visible = false
	left_hand.visible = false
	left_hand.reparent(player.camera)
	card_held = false
	if _is_book(held_tool): held_tool.position = _book_hold_position()
	card.reparent(self)
	_card_busy = true
	var generation: int = _epoch
	var placing: Tween = create_tween().set_parallel(true)
	_tweens.append(placing)
	placing.tween_property(card, "position", _card_placement(at), 0.24).set_trans(Tween.TRANS_SINE)
	placing.tween_property(card, "quaternion", Quaternion(Vector3.UP, _table_yaw) * RationCard3D.table_orientation(card.front_showing), 0.24)
	placing.chain().tween_callback(func() -> void:
		if generation == _epoch:
			card.collision_layer = 2
			_card_busy = false
			foley.play_sound("paper_place")
			if document_focus and not pause.visible: _enter_desk_inspection())
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
		if tool is InspectionLoupe: tool.set_active(false)
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
	if tool == identity_document: return IdentityDocument3D.THICKNESS * 0.5 + 0.0001
	if tool is InspectionLoupe: return 0.001
	if tool.action == "scissors": return -0.0082
	if tool.action.begins_with("stamp_"): return 0.0003
	return 0.0005


func _equip(tool: Interactable) -> void:
	held_tool = tool
	if _desk_inspecting and tool.action == "scissors":
		_desk_center = card.global_position
		_desk_distance = maxf(0.68, 0.75 / (2.0 * tan(deg_to_rad(25.0)) * maxf(0.8, get_viewport().get_visible_rect().size.aspect())))
		_update_overhead_camera()
		get_viewport().warp_mouse(player.camera.unproject_position(card.global_position))
		if _selftest: _desk_cursor_override = player.camera.unproject_position(card.global_position)
	tool.collision_layer = 0
	tool.reparent(player.camera)
	var from: Transform3D = tool.transform
	var from_global: Transform3D = tool.global_transform
	_pose_tool()
	var to: Transform3D = tool.transform
	# _pose_tool can reparent into world for overhead work; startfromsameparent.
	if _desk_inspecting: from = from_global
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
	if tool is InspectionLoupe: right_hand.position = Vector3(0.012, 0.062, 0.151)
	elif tool.action == "scissors": right_hand.position = Vector3(-0.065, 0.064, 0.025)
	elif tool.action.begins_with("stamp_"): right_hand.position = Vector3(0.023, 0.13, 0.045)
	elif _is_book(tool): right_hand.position = Vector3(0.208, 0.026, 0.11)
	if tool == identity_document: right_hand.position = Vector3(0.137, -0.036, 0.009)
	elif tool == parcel: right_hand.position = parcel.grip_position
	right_hand.rotation = Vector3.ZERO
	right_hand.visible = true
	_message("Nesne sağ elinde. G ile bir yüzeye bırakabilirsin.")


func _pose_tool() -> void:
	if held_tool == null: return
	if _desk_inspecting:
		held_tool.reparent(self)
		_update_tool_hover()
		return
	held_tool.position = Vector3(0.19, -0.27, -0.46)
	held_tool.rotation = Vector3(0.20, 0, -0.2)
	if held_tool == identity_document:
		held_tool.position = _book_hold_position()
		held_tool.rotation = Vector3.ZERO
	elif _is_book(held_tool):
		held_tool.position = _book_hold_position()
		held_tool.rotation = Vector3(PI / 2, 0, 0)
	elif held_tool == parcel:
		held_tool.position = parcel.carry_position()
		held_tool.rotation = parcel.carry_rotation()
	elif held_tool.action == "scissors": held_tool.rotation = Vector3(0.7, 0, -0.2)


func _update_tool_hover() -> void:
	if held_tool == null: return
	var point: Vector3 = _table_point()
	held_tool.global_position = point + Vector3(0, 0.11, 0)
	held_tool.global_rotation = Vector3(0, _stamp_yaw, 0)
	if held_tool.action.begins_with("stamp_"):
		# Hold the handle beside the projected impression until lowering starts,
		# so the physical tool/hand does not cover the player's alignment target.
		held_tool.global_position += Vector3(0.10, 0, 0.035)
	elif held_tool.action == "scissors":
		held_tool.global_position = point + Vector3(-0.107, -0.0095, 0)
		(held_tool.get_node("Blade0") as Node3D).rotation.y = 0.0
		(held_tool.get_node("Blade1") as Node3D).rotation.y = 0.48
	elif _is_book(held_tool):
		held_tool.global_position = point + Vector3(0, 0.04, 0)
		if held_tool == identity_document: held_tool.quaternion = RationCard3D.table_orientation(true)
	elif held_tool is InspectionLoupe:
		held_tool.global_position = point + Vector3(0, 0.022, 0)
		held_tool.global_rotation = Vector3.ZERO
		held_tool.update_focus(point)
		held_tool.set_active(_ray().get("collider") == card)


func _return_tool_home() -> void:
	if held_tool == null: return
	var tool: Interactable = held_tool
	if tool is InspectionLoupe: tool.set_active(false)
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
	if not card_held: return
	var command: Dictionary = rules.finish_review(Game.state, destination) if document_focus else rules.finish(Game.state, destination, true)
	if not _execute(command): return
	if identity_document.visible:
		if held_tool == identity_document:
			identity_document.reparent(self)
			right_hand.reparent(player.camera)
			right_hand.visible = false
			held_tool = null
		identity_document.collision_layer = 0
		var identity_return: Tween = create_tween()
		_tweens.append(identity_return)
		identity_return.tween_property(identity_document, "position", Vector3(-0.10, 1.08, -2.79), 0.28)
		var identity_epoch: int = _epoch
		var identity_index: int = _index
		identity_return.tween_callback(func() -> void:
			if identity_epoch == _epoch and identity_index == _index: identity_document.visible = false)
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
	var target: Quaternion = Quaternion(Vector3.UP, 0 if card.front_showing else PI) if card_held else Quaternion(Vector3.UP, _table_yaw) * RationCard3D.table_orientation(card.front_showing)
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
	if not _desk_inspecting:
		_message("Kartla E üzerinden etkileşip üstten masa görünümüne geç."); return
	if _ray().get("collider") != card or not card.front_showing: return
	var pointer: Vector2 = _pointer_position()
	var pixel: Vector2 = _paper_pixel()
	if not card.has_paper_at(pixel): return
	if held_tool.action.begins_with("stamp_"):
		_stamp_charging = true
		_stamp_contacted = false
		_stamp_lift_played = false
		_stamp_time = 0
		_stamp_dwell = 0
		_stamp_pressure = 0
		_stamp_height = 0.10
		_stamp_target_height = 0.10
		_stamp_impact_speed = 0
		_stamp_approach_speed = 0
		_stamp_offset = Vector2.ZERO
		_stamp_serial = -1
		_stamp_update_time = 0
		_stamp_pixel = pixel
		_stamp_cursor_before = pointer
		_stamp_kind = held_tool.action.trim_prefix("stamp_")
		held_tool.reparent(self)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_message("Sol tuş basılıyken fareyi aşağı sür: indir/bastır. Yavaş/hızlı hareket ve bekleme izi değiştirir. Bırak: kaldır.")
	elif held_tool.action == "scissors":
		_cut_index = 0
		_cut_tip = pixel
		_cut_points = PackedVector2Array([pixel])
		_cut_length_m = 0
		_snips = 0
		_scissor_stroke = ScissorStroke.new()
		_last_snip_cycle = -1
		held_tool.reparent(self)
		_message("Makasın ucu kadar kesilir. Sol tuşla ilerle; bırakınca gerçek kesik kalır. Kuponun dört kenarını takip et.")

func _end_tool() -> void:
	if _cut_index >= 0: _commit_incision()
	if _stamp_charging:
		if _stamp_contacted: _save_stamp_impression()
		_stamp_charging = false
		_stamp_animating = true
		_busy = true
		_tool_generation += 1
		var gesture: int = _tool_generation
		var generation: int = _epoch
		if _stamp_contacted:
			foley.play_sound("stamp_lift")
			_stamp_lift_played = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().warp_mouse(_stamp_cursor_before)
		_stamp_tween = create_tween()
		_tweens.append(_stamp_tween)
		_stamp_tween.tween_property(held_tool, "global_position", held_tool.global_position + Vector3(0, 0.10, 0), 0.18).set_trans(Tween.TRANS_CUBIC)
		_stamp_tween.tween_callback(func() -> void:
			if generation == _epoch and gesture == _tool_generation:
				_stamp_animating = false
				_stamp_contacted = false
				_busy = false
				_restore_tool_to_hand())

func _stamp_contact() -> void:
	if _stamp_contacted: return
	if not _execute(rules.stamp(Game.state, _stamp_kind, _stamp_pixel, true, _stamp_impression())): return
	_stamp_contacted = true
	var marks: Array = RationDeskRules.desk(Game.state).get("marks", [])
	_stamp_serial = int(marks[-1]["serial"])
	foley.play_sound("stamp_down")
	if not RationCardView.DECISION_RECT.has_point(_stamp_pixel):
		_message("Baskı kâğıtta kaldı. Kararı kaydetmek için SATICI ONAYI alanına bas.")
	_consume_severed_coupon()


func _stamp_impression() -> Dictionary:
	var angle: float = _stamp_ink_angle()
	var local_offset: Vector3 = card.global_basis.inverse() * Vector3(_stamp_offset.x, 0, _stamp_offset.y)
	# The renderer rotates the entire rubber face. Express smudge in its local
	# axes so a world-space lateral slip keeps the same direction on the sheet.
	var smear: Vector2 = Vector2(local_offset.x, -local_offset.y).rotated(-angle).normalized()
	return {"speed": _stamp_impact_speed, "dwell": _stamp_dwell, "pressure": _stamp_pressure,
		"angle": angle, "smudge": _stamp_offset.length(), "smudge_direction": [smear.x, smear.y]}


func _stamp_ink_angle() -> float:
	var local_direction: Vector3 = card.global_basis.inverse() * Basis(Vector3.UP, _stamp_yaw).x
	return atan2(-local_direction.y, local_direction.x)


func _update_stamp_guide() -> void:
	_stamp_guide.visible = false
	if not _desk_inspecting or pause.visible or not card.front_showing or card_held or held_tool == null or not held_tool.action.begins_with("stamp_"): return
	var pixel: Vector2 = _paper_pixel()
	if not card.has_paper_at(pixel): pixel = Vector2(INF, INF)
	_stamp_guide.show_guide(held_tool.action.trim_prefix("stamp_"), pixel, _stamp_ink_angle(), _stamp_assistance and _index < 2, _stamp_charging or _stamp_animating)


func _save_stamp_impression() -> void:
	if _stamp_serial >= 0: _execute(rules.update_impression(Game.state, _stamp_serial, _stamp_impression()))


func _update_stamp(delta: float) -> void:
	_stamp_time += delta
	var before: float = _stamp_height
	_stamp_height = move_toward(_stamp_height, _stamp_target_height, delta * 0.60)
	var velocity_m_s: float = maxf(0, (before - _stamp_height) / maxf(delta, 0.00001))
	_stamp_approach_speed = maxf(velocity_m_s, _stamp_approach_speed * exp(-delta / 0.06))
	var pressure: float = clampf(-_stamp_target_height / 0.004, 0, 1)
	_stamp_pressure = maxf(_stamp_pressure, pressure)
	if _stamp_height <= 0.0001:
		if not _stamp_contacted:
			_stamp_impact_speed = _stamp_approach_speed
			_stamp_contact()
		_stamp_dwell += delta
		_stamp_update_time += delta
		if _stamp_update_time >= 0.10:
			_stamp_update_time = 0
			_save_stamp_impression()
	held_tool.global_position = card.pixel_to_world(_stamp_pixel) + Vector3(_stamp_offset.x, maxf(_stamp_height, 0), _stamp_offset.y)
	held_tool.global_rotation = Vector3(0, _stamp_yaw, 0)

func _start_tool_on_table(at: Vector3) -> void:
	if held_tool == null: return
	held_tool.reparent(self)
	held_tool.global_position = at
	held_tool.rotation = Vector3.ZERO


func _restore_tool_to_hand() -> void:
	if held_tool == null: return
	held_tool.reparent(self if _desk_inspecting else player.camera)
	_pose_tool()

func _update_cut(delta: float = 1.0 / 60.0) -> void:
	if _cut_index < 0 or _scissor_stroke == null: return
	var target: Vector2 = _paper_pixel()
	if not target.is_finite(): return
	target = target.clamp(Vector2.ZERO, Vector2(640, 400))
	var difference: Vector2 = target - _cut_tip
	var travel: float = _scissor_stroke.advance(delta, difference.length() > 0.01)
	var step: Vector2 = difference.limit_length(travel * 640.0 / RationCard3D.WIDTH)
	if step.length() > 0.01:
		_cut_tip += step
		_cut_direction = step.normalized()
		_cut_length_m += step.length() * RationCard3D.WIDTH / 640.0
		_cut_points.append(_cut_tip)
		card.cut_preview(_cut_points)
		if _last_snip_cycle != _scissor_stroke.cycle():
			_last_snip_cycle = _scissor_stroke.cycle()
			_snips += 1
			foley.play_sound("snip")
	var tangent: Vector3 = (card.global_basis * Vector3(_cut_direction.x, -_cut_direction.y, 0)).normalized()
	var normal: Vector3 = card.global_basis.z.normalized()
	held_tool.global_basis = Basis(tangent, normal, tangent.cross(normal))
	# One blade passes underneath the sheet, the other closes over it.
	# Previously both blades floated around a centimetre above their cut.
	held_tool.global_position = card.pixel_to_world(_cut_tip) - tangent * 0.107 - normal * 0.0105
	var jaw: float = _scissor_stroke.jaw_angle()
	(held_tool.get_node("Blade0") as Node3D).rotation.y = 0.0
	(held_tool.get_node("Blade1") as Node3D).rotation.y = jaw
	right_hand.position = Basis(Vector3.UP, jaw * 0.7) * Vector3(-0.065, 0.064, 0.025)
	right_hand.rotation.y = jaw * 0.5
	left_hand.reparent(self)
	left_hand.global_transform = Transform3D(Basis(Vector3.UP, _table_yaw).scaled(Vector3(-1, 1, 1)), card.pixel_to_world(Vector2(-35, 220)) + Vector3.UP * 0.028)
	left_hand.visible = true


func _commit_incision() -> void:
	_cut_index = -1
	left_hand.visible = false
	left_hand.reparent(player.camera)
	right_hand.rotation = Vector3.ZERO
	var path: Array = []
	for pixel: Vector2 in _cut_points: path.append([pixel.x, pixel.y])
	var before: Array = (RationDeskRules.desk(Game.state).get("incisions", []) as Array).duplicate(true)
	var committed: bool = false
	if _cut_length_m >= 0.00005:
		committed = _execute(rules.incise(Game.state, path, true))
		if committed: _message("%.1f cm gerçek kesik kâğıtta kaldı." % (_cut_length_m * 100.0))
	card.clear_cut_preview()
	_cut_points.clear()
	_restore_tool_to_hand()
	if committed:
		var work: Dictionary = RationDeskRules.desk(Game.state)
		var document: Dictionary = rules.current(Game.state).get("card", {})
		for index: int in 3:
			var item: String = RationDeskRules.PRODUCT_ORDER[index]
			var rectangle: Rect2 = RationCardView.coupon_rect(index)
			if item in document.get("available", []) and PaperCutGeometry.coupon_is_severed(work.get("incisions", []), rectangle) and not PaperCutGeometry.coupon_is_severed(before, rectangle):
				# Paper obeys the blade even before a decision or on the wrong coupon.
				# Processing the customer's entitlement remains a separate rules command.
				_detach_coupon(index, item)
				_message("Kuponun dört kenarı ayrıldı; parça koptu.")
	_consume_severed_coupon()


func _consume_severed_coupon() -> void:
	var work: Dictionary = RationDeskRules.desk(Game.state)
	var request: Dictionary = rules.current(Game.state).get("request", {})
	if work.get("stamp") != "approve" or request.is_empty(): return
	var item: String = request["item"]
	var index: int = RationDeskRules.PRODUCT_ORDER.find(item)
	if item not in work.get("cuts", []) and PaperCutGeometry.coupon_is_severed(work.get("incisions", []), RationCardView.coupon_rect(index)):
		if _execute(rules.cut(Game.state, item, true)):
			_message("Kupon işlendi. Karneyi eline alıp müşteriye geri verebilirsin." if document_focus else "Kupon işlendi; ürünü raftan alabilirsin.")


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
	if document_focus and card_held:
		if target == customer_target: return "E · Karneyi iade et    F · Yakından incele"
		if target == drawer: return "E · Karneyi alıkoy    F · Yakından incele"
		return "F · Yakından incele    E / G · Masaya bırak"
	if document_focus and held_tool != null and not _desk_inspecting:
		return "F · Eldeki nesneyi incele    G · Yüzeye bırak    E · Etkileş"
	if _desk_inspecting:
		if _paper_dragging: return "Sol tuşu bırak: masaya koy · Sağ tuş + sürükle: kâğıdı döndür · Q: bırak ve ayrıl"
		if _cut_index >= 0: return "%.1f cm kesildi · Fareyle makası ilerlet · Bırak/Q: kesik kâğıtta kalır" % (_cut_length_m * 100.0)
		if _stamp_charging: return "Fare aşağı: indir/bastır · Basılı tut: mürekkep işlemesi · Bırak: kaldır"
		if held_tool is InspectionLoupe: return "Büyüteci kâğıt üstünde gezdir · Tekerlek: yaklaş · G: bırak · Q: ayrıl"
		if held_tool != null and held_tool.action == "scissors": return "Sol tuş + sürükle: gerçek kesim · Sağ tuş: masayı kaydır · Q: ayrıl"
		if held_tool != null and held_tool.action.begins_with("stamp_"): return "Sol tuş basılı + fare aşağı: damga · Shift + tekerlek: açı · Q: ayrıl"
	if target == null: return "WASD · Yürü    E · Al / ver    G · Yüzeye bırak    Esc · Menü"
	if target == card:
		if RationDeskRules.desk(Game.state).get("location") == "intake": return "E / Sol tık · Karneyi eline al" if document_focus else "E · Uzatılan karneyi masaya al"
		var inspect: String = "Q / WASD · Ayrıl" if _desk_inspecting else "E · Üstten masa görünümü"
		return inspect + "    Sol tut · Masada taşı    R · Eline al    F · Çevir" + ("    Sol tuş · Aracı kullan" if held_tool != null else "")
	var kind: String = str(target.get("action")) if target is Interactable else ""
	match kind:
		"workmat": return "E / G · Karneyi masaya bırak" if card_held else "E · Masadaki karneyi incelemek için eğil    Q · Ayrıl"
		"customer": return "E · Ürünü müşteriye uzat" if held_tool == parcel else ("E · Karneyi iade et" if card_held else "E · Müşterinin isteğini tekrar dinle")
		"drawer": return "E · Elindeki karneyi alıkoyma bölmesine koy"
		"storage": return "E · Bu koliden istenen ürünü hazırla ve al"
		"parcel": return "E · Hazırlanmış ürünü al"
		"bell": return "E · Sonraki müşteriyi çağır"
		"book": return "E · Kural defterini al ve elde incele"
		"identity": return "E · Kimliği eline al    F · İsim, numara ve fotoğrafı incele"
		"order": return "E · Masadaki talep fişini al ve oku"
		"ledger": return "E · Gün sonu defterini al"
		"scissors": return "E · Makası al"
		"loupe": return "E · Büyüteci al; masada belge üzerine getir"
	if kind.begins_with("stamp_"): return "E · %s damgasını al" % {"stamp_approve": "SATIŞ", "stamp_reject": "RET", "stamp_seize": "ALIKOY"}.get(kind, "")
	return "G · Elindeki nesneyi bu yüzeye bırak"


func _toggle_pause() -> void:
	_close_object_inspection()
	_inspect_pending = false
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
	var lines: PackedStringArray = ["[b]EWIDENCJA / BELGE DEFTERİ[/b]" if document_focus else "[b]GÜN SONU DEFTERİ[/b]"]
	if not document_focus: lines.append("Kasa: %s · Cep: %s" % [Money.format(Game.state.money["till"]), Money.format(Game.state.money["pocket"])] )
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
	text_view.add_theme_font_override("normal_font", RationCardView.TYPEWRITER)
	text_view.add_theme_font_override("bold_font", RationCardView.SERIF_BOLD)
	text_view.add_theme_font_size_override("normal_font_size", 32)
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
	return tool != null and tool.action in ["book", "ledger", "order", "identity"]


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
	if solid_mesh:
		if kind == "workmat":
			var mat_mesh: MeshInstance3D = WorkbenchArt.bevel_box(size, 0.004, WorkbenchArt.mat_material())
			mat_mesh.position.y = size.y / 2
			prop.add_child(mat_mesh)
		else: _box(prop, size, Vector3(0, size.y / 2, 0), color)
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
	if kind == "table":
		body.add_child(WorkbenchArt.bevel_box(size, 0.006, WorkbenchArt.desk_material()))
	else: _box(body, size, Vector3.ZERO, color)
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
	return WorkbenchArt.build_hand()

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


func _run_document_selftest() -> void:
	await _run_selftest()


func _run_selftest() -> void:
	var failures: PackedStringArray = []
	if document_focus:
		failures = await preload("res://tests/evidence_review_regressions.gd").new().run(self)
		if "--evidence-only" in OS.get_cmdline_user_args():
			get_tree().quit(0 if failures.is_empty() else 1)
			return
		failures.append_array(await preload("res://tests/paper_inspection_regressions.gd").new().run(self))
		if "--paper-only" in OS.get_cmdline_user_args():
			get_tree().quit(0 if failures.is_empty() else 1)
			return
		failures.append_array(await preload("res://tests/held_inspection_regressions.gd").new().run(self))
		if "--inspection-only" in OS.get_cmdline_user_args():
			get_tree().quit(0 if failures.is_empty() else 1)
			return
		failures.append_array(await preload("res://tests/desk_direct_interaction_regressions.gd").new().run(self))
		failures.append_array(await preload("res://tests/document_review_regressions.gd").new().run(self))
	else:
		failures = await preload("res://tests/fps_ration_regressions.gd").new().run(self)
	await _wait_customer()
	_aim(card.global_position)
	_key(KEY_E)
	if RationDeskRules.desk(Game.state).get("location") != "intake": failures.append("out-of-reach card accepted")
	player.camera.rotation = Vector3.ZERO
	var start: Vector3 = player.position
	_key_down(KEY_W, true)
	await get_tree().create_timer(1.25).timeout
	_key_down(KEY_W, false)
	await get_tree().create_timer(0.15).timeout
	if start.distance_to(player.position) < 1.5 or player.position.z < -1.5: failures.append("walking/counter collision failed")
	await _capture("01_window")
	for i: int in rules.cases.size():
		await _wait_customer()
		var encounter: Dictionary = rules.current(Game.state)
		player.position = Vector3(0, 0.025, -1.25)
		player.velocity = Vector3.ZERO
		await get_tree().physics_frame
		_aim(card.global_position)
		_key(KEY_E)
		await _wait_hands()
		if document_focus:
			_aim(workmat.global_position)
			_key(KEY_G)
			await _wait_hands()
		await _test_camera_settled()
		if card_held or card.get_parent() != self or RationDeskRules.desk(Game.state).get("placement") != "table":
			failures.append("world handoff failed: " + encounter["id"]); break
		_aim(card.global_position)
		_key(KEY_E)
		await _test_camera_settled()
		if document_focus and i in [1, 2]: await _capture("23_worn_thin_card" if i == 1 else "24_thick_stock_card")
		if i == 0:
			if document_focus:
				var screen: Rect2 = get_viewport().get_visible_rect().grow(-12)
				for prop_id: String in ["stamp_approve", "stamp_reject", "stamp_seize", "scissors", "loupe", "book"]:
					if not screen.has_point(player.camera.unproject_position(props[prop_id].global_position + Vector3.UP * 0.08)): failures.append("initial desk hides tool: " + prop_id)
			await _capture("06_overhead_desk")
			_key(KEY_F)
			await _wait_hands()
			await _capture("12_table_back")
			_key(KEY_F)
			await _wait_hands()
		if i == 0 or i == 5:
			_aim(card.global_position)
			_key(KEY_R)
			await _wait_hands()
			await _capture("02_held_front" if i == 0 else "07_tampered_front")
			_key(KEY_F)
			if document_focus:
				await get_tree().create_timer(0.24).timeout
				if i == 5:
					_key(KEY_T)
					await _test_until(func() -> bool: return card.inspection_light_strength > .98)
					await _capture("22_quota_patch_transmission")
				_mouse(MOUSE_BUTTON_RIGHT, true)
				_mouse(MOUSE_BUTTON_RIGHT, false)
				await get_tree().create_timer(0.24).timeout
			else: await _wait_hands()
			await _capture("03_held_back" if i == 0 else "08_tampered_back")
			_key(KEY_F)
			await _wait_hands()
			_aim(workmat.global_position)
			_key(KEY_G)
			await _wait_hands()
			_aim(card.global_position)
			_key(KEY_E)
			await _test_camera_settled()
		if document_focus and i == 5:
			_aim(props["loupe"].global_position + Vector3(0, 0.01, 0))
			_key(KEY_E)
			await _wait_hands()
			for zoom_tick: int in 5:
				_mouse(MOUSE_BUTTON_WHEEL_UP, true)
				_mouse(MOUSE_BUTTON_WHEEL_UP, false)
			_aim(card.pixel_to_world(Vector2(355, 225)))
			await get_tree().physics_frame
			await get_tree().physics_frame
			if held_tool != props["loupe"] or not (props["loupe"] as InspectionLoupe).is_active(): failures.append("optical loupe did not focus on actual paper")
			await _capture("17_loupe_patch")
			_key(KEY_Q)
			await _test_camera_settled()
			if (props["loupe"] as InspectionLoupe).is_active(): failures.append("loupe kept rendering after leaving desk")
			_aim(card.global_position)
			_key(KEY_E)
			await _test_camera_settled()
			_aim(homes[held_tool].origin + Vector3(0, 0.003, 0))
			_key(KEY_G)
			await _wait_hands()
			if held_tool != null: failures.append("loupe could not be parked"); break
		var kind: String = "approve" if RationDeskRules.issues(encounter).is_empty() else ("seize" if RationDeskRules.is_forged(encounter) else "reject")
		_aim(props["stamp_" + kind].global_position + Vector3(0, 0.08, 0))
		_key(KEY_E)
		await _wait_hands()
		if held_tool != props["stamp_" + kind]: failures.append("stamp pickup failed: " + encounter["id"]); break
		_aim(card.pixel_to_world(Vector2(540, 183)))
		_mouse(MOUSE_BUTTON_LEFT, true)
		_test_motion(Vector2(0, 180))
		if not await _test_until(func() -> bool: return _stamp_contacted): failures.append("physical stamp did not contact"); break
		await get_tree().create_timer(0.22).timeout
		if i == 0: await _capture("16_stamp_contact")
		_mouse(MOUSE_BUTTON_LEFT, false)
		await _wait_hands()
		_aim(homes[held_tool].origin + Vector3(0, 0.003, 0))
		_key(KEY_G)
		await _wait_hands()
		if held_tool != null: failures.append("stamp could not be parked: " + encounter["id"]); break
		if RationDeskRules.desk(Game.state).get("stamp") != kind: failures.append("stamp decision not committed")
		if kind == "approve":
			var item: String = encounter["request"]["item"]
			var index: int = RationDeskRules.PRODUCT_ORDER.find(item)
			var rect: Rect2 = RationCardView.coupon_rect(index)
			_aim(props["scissors"].global_position + Vector3(0, 0.015, 0))
			_key(KEY_E)
			await _wait_hands()
			if held_tool != props["scissors"]: failures.append("scissors pickup failed"); break
			var initial: Vector2 = rect.position
			if i == 0:
				_aim(card.pixel_to_world(initial))
				_mouse(MOUSE_BUTTON_LEFT, true)
				if not await _test_trace(initial + Vector2(0.02 * 640.0 / RationCard3D.WIDTH, 0)): failures.append("2 cm travel timeout")
				await _capture("14_cutting_two_cm")
				_mouse(MOUSE_BUTTON_LEFT, false)
				if not (RationDeskRules.desk(Game.state).get("cuts", []) as Array).is_empty(): failures.append("2 cm removed entire coupon")
				await _capture("15_persistent_two_cm")
				initial += Vector2(0.02 * 640.0 / RationCard3D.WIDTH, 0)
			_aim(card.pixel_to_world(initial))
			_mouse(MOUSE_BUTTON_LEFT, true)
			for corner: Vector2 in [Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y), rect.position]:
				if not await _test_trace(corner): failures.append("perimeter travel timeout")
			_mouse(MOUSE_BUTTON_LEFT, false)
			if not item in RationDeskRules.desk(Game.state).get("cuts", []): failures.append("complete perimeter did not detach coupon: " + encounter["id"])
			if i == 0: await _capture("04_table_cut")
			_aim(homes[held_tool].origin + Vector3(0, 0.003, 0))
			_key(KEY_G)
			await _wait_hands()
			_key(KEY_Q)
			await _test_camera_settled()
			if not document_focus:
				# Fixture locations isolate hauling interactions after real walking coverage.
				player.position = Vector3(1.60, 0.025, 0.15)
				player.velocity = Vector3.ZERO
				await get_tree().physics_frame
				_aim(shelves["hidden" if i == 7 else item].global_position + Vector3(0, 0.14, 0))
				_key(KEY_E)
				await _wait_hands()
				if held_tool != parcel: failures.append("goods pickup failed: " + encounter["id"]); break
				if i == 0: await _capture("09_goods_hand")
				elif i == 1: await _capture("11_sugar_hand")
				player.position = Vector3(0, 0.025, -1.25)
				await get_tree().physics_frame
				_aim(Vector3(-0.80, 0.966, -1.66))
				_key(KEY_G)
				await _wait_hands()
				_aim(parcel.global_position + Vector3(0, 0.04, 0))
				if i == 0: await _capture("10_goods_counter")
				_key(KEY_E)
				await _wait_hands()
				_aim(customer_target.global_position + Vector3(0, 0.4, 0))
				_key(KEY_E)
				await _wait_hands()
		else:
			_key(KEY_Q)
			await _test_camera_settled()
		_aim(card.global_position)
		_key(KEY_R)
		await _wait_hands()
		_aim(drawer.global_position + Vector3(0, 0.04, 0) if kind == "seize" else customer_target.global_position + Vector3(0, 0.4, 0))
		_key(KEY_E)
		await _wait_hands()
		if not RationDeskRules.desk(Game.state).get("done", false): failures.append("card handover failed: " + encounter["id"] + ": " + message.text); break
		_aim(bell.global_position + Vector3(0, 0.03, 0))
		_key(KEY_E)
	var results: Array = RationDeskRules.desk(Game.state).get("results", [])
	if results.size() != rules.cases.size(): failures.append("only %d/%d customers completed" % [results.size(), rules.cases.size()])
	for result: Dictionary in results:
		if not result["correct"]: failures.append("incorrect audit: " + result["case"])
		if document_focus and (not result.get("document_review", false) or int(result.get("revenue", -1)) != 0): failures.append("review invented a sale")
	if rules.current(Game.state).is_empty():
		_aim(props["ledger"].global_position)
		_key(KEY_E)
		await _wait_hands()
		await _capture("05_ledger")
	if document_focus and (not RationDeskRules.desk(Game.state).get("parcel", {}).is_empty() or int(Game.state.money["till"]) != 2000): failures.append("paperwork changed stock or money")
	foley.stop_all()
	print("[fps selftest] %s" % (("PASS: document-only handoff, overhead workstation, measured cuts, physical stamp gestures, %d customers, no product or money mutations" % rules.cases.size() if document_focus else "PASS: overhead workstation, measured cuts, physical stamp gestures, provisions, 8 customers") if failures.is_empty() else "FAIL: " + "; ".join(failures)))
	get_tree().quit(0 if failures.is_empty() else 1)


func _test_motion(relative: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.relative = relative
	event.screen_relative = relative
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _test_until(predicate: Callable, timeout_ms: int = 10000) -> bool:
	var deadline: int = Time.get_ticks_msec() + timeout_ms
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	return predicate.call()


func _test_camera_settled() -> void:
	await _test_until(func() -> bool: return _lean_tween == null or not _lean_tween.is_valid())
	await get_tree().physics_frame


func _test_trace(pixel: Vector2) -> bool:
	_aim(card.pixel_to_world(pixel))
	return await _test_until(func() -> bool: return _cut_index >= 0 and _cut_tip.distance_to(pixel) < 0.05)

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
	if _desk_inspecting:
		# Test fixtures must use a point a real cursor can reach. Pan to an
		# offscreen target instead of projecting a ray outside the viewport.
		var frame: Rect2 = get_viewport().get_visible_rect().grow(-24)
		if not frame.has_point(player.camera.unproject_position(at)):
			_desk_center.x = at.x
			_desk_center.z = at.z
			_update_overhead_camera()
		_desk_cursor_override = player.camera.unproject_position(at)
		get_viewport().warp_mouse(_desk_cursor_override)
	else:
		player.camera.look_at(at, Vector3.UP)

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
