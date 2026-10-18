class_name RationCardView
extends Control
## The same paper object is dragged, tilted, flipped, stamped and cut.

signal pickup_requested
signal dropped(at: Vector2)
signal stamp_requested(kind: String, at: Vector2)
signal cut_requested(item: String)
signal contact(name: String)
signal feedback(message: String)

const PAPER_SIZE: Vector2 = Vector2(640, 400)
const DECISION_RECT: Rect2 = Rect2(460, 135, 160, 90)
var card: Dictionary = {}
var work: Dictionary = {}
var front: bool = true
var tool: String = "hand"
var busy: bool = false
var reduced_motion: bool = false
var render_tools: bool = true
var _dragging: bool = false
var _offset: Vector2 = Vector2.ZERO
var _press: Vector2 = Vector2.ZERO
var _stamp_held: bool = false
var _stamp_time: float = 0.0
var _cut_index: int = -1
var _cut_progress: float = 0.0
var _snips: int = 0
var _fibres: Array[Vector2] = []
var _paper_profile: Dictionary = {}
var _print_seed: int = 1982
const StampInk: GDScript = preload("res://scenes/kiosk/stamp_impression_renderer.gd")
const StockProfile: GDScript = preload("res://scenes/kiosk/paper_stock_profile.gd")
const SERIF: Font = preload("res://assets/fonts/LiberationSerif-Regular.ttf")
const SERIF_BOLD: Font = preload("res://assets/fonts/LiberationSerif-Bold.ttf")
const SERIF_ITALIC: Font = preload("res://assets/fonts/LiberationSerif-Italic.ttf")
const TYPEWRITER: Font = preload("res://assets/fonts/LiberationMono-Regular.ttf")
const INK: Color = Color("302d25")
const FADED_INK: Color = Color("4f493c")
var _stamp_nodes: Array[Control] = []
var _flip_tween: Tween


func _ready() -> void:
	size = PAPER_SIZE
	pivot_offset = PAPER_SIZE / 2
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_refresh_paper_profile()
	queue_redraw()


func show_card(document: Dictionary, state: Dictionary) -> void:
	card = document
	work = state
	_refresh_paper_profile()
	_sync_impressions()
	queue_redraw()


func _refresh_paper_profile() -> void:
	_paper_profile = StockProfile.resolve(card)
	_print_seed = StockProfile.stable_seed(str(card.get("serial", "")))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _print_seed
	_fibres.clear()
	for i: int in 300:
		_fibres.append(Vector2(rng.randf_range(3, 637), rng.randf_range(3, 397)))


func reset_pose() -> void:
	if _flip_tween != null and _flip_tween.is_valid():
		_flip_tween.kill()
	front = true
	rotation = 0
	scale = Vector2.ONE
	_dragging = false
	_stamp_held = false
	_cut_index = -1
	busy = false
	queue_redraw()


func flip() -> void:
	if busy or _dragging or _stamp_held or _cut_index >= 0 or work.get("location") != "desk" or work.get("done", false):
		return
	contact.emit("paper_flip")
	if reduced_motion:
		front = not front
		queue_redraw()
		return
	busy = true
	var zoom: Vector2 = scale
	var tween: Tween = create_tween()
	_flip_tween = tween
	tween.tween_property(self, "scale:x", 0.04, 0.15).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void: front = not front; queue_redraw())
	tween.tween_property(self, "scale:x", zoom.x, 0.20).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void: busy = false)


func tilt(degrees: float) -> void:
	if not busy and not reduced_motion:
		rotation_degrees = clampf(rotation_degrees + degrees, -18, 18)


static func coupon_rect(index: int) -> Rect2:
	return Rect2(30 + index * 195, 285, 180, 90)


func show_cut_progress(index: int, progress: float) -> void:
	_cut_index = index
	_cut_progress = progress
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if busy or work.get("done", false):
		return
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.pressed and mouse.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			if work.get("location") == "desk":
				var zoom: float = clampf(scale.y + (0.10 if mouse.button_index == MOUSE_BUTTON_WHEEL_UP else -0.10), 0.75, 1.3)
				scale = Vector2.ONE * zoom
			accept_event()
		elif mouse.button_index == MOUSE_BUTTON_RIGHT and mouse.pressed:
			flip()
			accept_event()
		elif mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				_begin(mouse.position)
			else:
				_end(mouse.position)
			accept_event()
	elif event is InputEventMouseMotion:
		var mouse: InputEventMouseMotion = event as InputEventMouseMotion
		if _dragging:
			global_position = get_global_transform() * mouse.position - _offset
		elif _cut_index >= 0:
			_advance_cut(mouse.position)
		queue_redraw()


func _begin(at: Vector2) -> void:
	if work.get("location") == "intake":
		pickup_requested.emit()
		return
	if work.get("location") != "desk":
		return
	_press = at
	if tool == "hand":
		_dragging = true
		_offset = get_global_transform() * at - global_position
		contact.emit("paper_pick")
	elif tool in ["approve", "reject", "seize"]:
		if not front or not DECISION_RECT.has_point(at):
			feedback.emit("Ön yüzdeki KARAR alanına damga bas.")
			return
		_stamp_held = true
		_stamp_time = 0.0
	elif tool == "scissors":
		if not front:
			feedback.emit("Kupon kesmek için ön yüzü çevir.")
			return
		for i: int in 3:
			var rect: Rect2 = coupon_rect(i)
			var item: String = RationDeskRules.PRODUCT_ORDER[i]
			if Rect2(rect.position - Vector2(10, 14), Vector2(45, 28)).has_point(at):
				if item in work.get("cuts", []) or not item in card.get("available", []):
					feedback.emit("Bu kupon zaten ayrılmış.")
					return
				if work.get("stamp") != "approve":
					feedback.emit("Önce SATIŞ damgasını bas; erzakları kesimden sonra toplayabilirsin.")
					return
				_cut_index = i
				_cut_progress = 0.0
				_snips = 0
				return
		feedback.emit("Makasla kuponun sol üstünden başla; kesik çizgiyi sağa doğru izle.")
	queue_redraw()


func _advance_cut(at: Vector2) -> void:
	var rect: Rect2 = coupon_rect(_cut_index)
	if absf(at.y - rect.position.y) > 24 or at.x < rect.position.x - 18:
		_cut_index = -1
		_cut_progress = 0.0
		feedback.emit("Kesim çizgisinden çıktın. Kupon tüketilmedi; tekrar başlayabilirsin.")
		return
	_cut_progress = maxf(_cut_progress, clampf((at.x - rect.position.x) / rect.size.x, 0, 1))
	var steps: int = int(_cut_progress * 5)
	if steps > _snips:
		contact.emit("snip")
		_snips = steps
	queue_redraw()


func _end(at: Vector2) -> void:
	if _dragging:
		_dragging = false
		contact.emit("paper_place")
		dropped.emit(get_global_transform() * (PAPER_SIZE / 2))
	if _stamp_held and render_tools:
		_stamp_held = false
		if _stamp_time >= 0.07 and at.distance_to(_press) < 24:
			stamp_requested.emit(tool, _press)
		else:
			feedback.emit("Damgayı kısa süre basılı tutup kaldır.")
	if _cut_index >= 0:
		var item: String = RationDeskRules.PRODUCT_ORDER[_cut_index]
		if _cut_progress >= 0.92:
			cut_requested.emit(item)
		else:
			feedback.emit("Kesim kısa kaldı; kupon tüketilmedi.")
		_cut_index = -1
		_cut_progress = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if _stamp_held:
		var before: float = _stamp_time
		_stamp_time += delta
		if before < 0.07 and _stamp_time >= 0.07:
			contact.emit("stamp_down")
		queue_redraw()
	if _dragging and not reduced_motion:
		rotation = lerpf(rotation, clampf(get_last_mouse_velocity().x * 0.00002, -0.045, 0.045), delta * 8)


func get_last_mouse_velocity() -> Vector2:
	return Input.get_last_mouse_velocity()


func _draw() -> void:
	if card.is_empty():
		return
	for stamp: Control in _stamp_nodes:
		stamp.visible = front
	var spec: Dictionary = RationDeskRules.CLASSES.get(card.get("class", ""), {})
	var tint: Color = spec.get("color", Color.GRAY)
	_draw_paper(tint)
	_draw_bleedthrough()
	_draw_heading(tint)
	if front:
		_draw_front(spec)
	else:
		_draw_back(spec)
	_draw_folds()
	_text(Vector2(30, 390), "PZ–81  /  DRUK ŚCISŁEGO ZARACHOWANIA  /  %s  /  STR. %d" % [str(card.get("serial", "")), 1 if front else 2], 7, FADED_INK)
	if _stamp_held and render_tools:
		var depression: float = minf(_stamp_time / 0.08, 1)
		draw_circle(_press - Vector2(0, 22 - depression * 8), 16, Color("534130"))
		draw_rect(Rect2(_press - Vector2(55, 11 - depression * 5), Vector2(110, 20)), Color("34312c"))
	# Only the archived 2D scene draws a tool preview. The FPS renderer never
	# paints a pretend incision: its persistent kerf is physical sheet geometry.
	if _cut_index >= 0 and render_tools:
		var rect: Rect2 = coupon_rect(_cut_index)
		var tip: Vector2 = rect.position + Vector2(rect.size.x * _cut_progress, 0)
		draw_line(rect.position, tip, Color("354844"), 1)
		draw_line(tip - Vector2(22, 14), tip + Vector2(12, 3), Color("747f80"), 4)
		draw_line(tip - Vector2(22, -14), tip + Vector2(12, -3), Color("747f80"), 4)
		draw_arc(tip - Vector2(30, 19), 9, 0, TAU, 24, Color("393c39"), 4)
		draw_arc(tip - Vector2(30, -19), 9, 0, TAU, 24, Color("393c39"), 4)


func _sync_impressions() -> void:
	for stamp: Control in _stamp_nodes:
		remove_child(stamp)
		stamp.queue_free()
	_stamp_nodes.clear()
	for mark: Dictionary in work.get("marks", []):
		var stamp: Control = StampInk.new()
		add_child(stamp)
		stamp.set_impression(mark)
		stamp.visible = front
		_stamp_nodes.append(stamp)


func _draw_heading(tint: Color) -> void:
	# Offset relief and fine ornaments belong to the printed stock; they are
	# deliberately small enough to leave the variable evidence clearly legible.
	draw_set_transform(_registration_offset())
	_draw_family_emblem(Vector2(56, 43), tint)
	draw_set_transform(Vector2.ZERO)
	_center_text(Vector2(56, 39), "PZ", 14, Color(tint.darkened(0.32), 0.88), SERIF_BOLD)
	_center_text(Vector2(56, 52), "81", 11, Color(tint.darkened(0.32), 0.88), SERIF_BOLD)
	_text(Vector2(94, 24), "WARSZAWSKA SPÓŁDZIELNIA ZAOPATRZENIA", 9, INK)
	_text(Vector2(92, 48), "KARTA ZAOPATRZENIA" if front else "EWIDENCJA UPRAWNIEŃ", 25, tint.darkened(0.60), SERIF_BOLD)
	_text(Vector2(95, 63), "PUNKT SPRZEDAŻY NR 81   •   WARSZAWA–WOLA", 8, FADED_INK)
	draw_line(Vector2(29, 73), Vector2(611, 73), Color(tint.darkened(0.2), 0.65), 0.8)
	draw_line(Vector2(29, 75.2), Vector2(611, 75.2), Color(tint, 0.30), 0.4)
	_text(Vector2(482, 23), "OKRES WAŻNOŚCI", 7, FADED_INK)
	_center_text(Vector2(546, 42), _month_name(), 10, INK, SERIF_BOLD)
	var forms: Dictionary = {"worker": "PZ–81–R", "teacher": "PZ–81–N", "retired": "PZ–81–E"}
	_center_text(Vector2(546, 59), "WZÓR  /  %s" % forms.get(str(card.get("class", "")), "PZ–81–K"), 7, FADED_INK)


func _draw_front(spec: Dictionary) -> void:
	var tint: Color = spec.get("color", Color.GRAY)
	var class_names: Dictionary = {"worker": "ROBOTNIK", "teacher": "NAUCZYCIEL", "retired": "EMERYT"}
	_text(Vector2(30, 90), "KATEGORIA UPRAWNIONEGO  /  SINIF", 8, FADED_INK)
	_text(Vector2(30, 113), class_names.get(str(card.get("class", "")), "INNA KATEGORIA"), 20, tint.darkened(0.58), SERIF_BOLD)
	_text(Vector2(308, 90), "NR PUNKTU", 7, FADED_INK)
	_typed(Vector2(308, 109), "081 / W–04", 13)
	draw_line(Vector2(30, 120), Vector2(434, 120), Color(tint, 0.35), 0.6)
	_text(Vector2(30, 134), "IMIĘ I NAZWISKO  /  AD SOYAD", 8, FADED_INK)
	_typed(Vector2(30, 157), str(card.get("holder", "")), 21)
	draw_line(Vector2(30, 163), Vector2(433, 163), Color(tint, 0.36), 0.5)
	_text(Vector2(30, 177), "NUMER EWIDENCYJNY  /  SERİ", 8, FADED_INK)
	_text(Vector2(263, 177), "MIESIĄC  /  GEÇERLİ AY", 8, FADED_INK)
	_typed(Vector2(30, 199), str(card.get("serial", "")), 19)
	_typed(Vector2(263, 199), str(card.get("month", "")), 18)
	draw_line(Vector2(30, 206), Vector2(434, 206), Color(tint, 0.36), 0.5)
	_text(Vector2(30, 224), "PRZYDZIAŁ MIĘSA / ET HAKKI", 9, INK)
	_text(Vector2(30, 240), "Norma miesięczna; wydanie po odłączeniu odcinka.", 8, FADED_INK, SERIF_ITALIC)
	if card.get("patch", false):
		_draw_quota_repair(false)
	_typed(Vector2(307, 235), _document_amount("meat", int(card.get("meat", 0))), 24)
	_draw_rosette(Vector2(540, 104), 21, Color(tint.darkened(0.15), 0.17))
	_center_text(Vector2(540, 108), "PZ–81", 9, Color(tint.darkened(0.25), 0.72))
	# A real unfilled rubber-stamp space, without a coloured UI panel.
	_dashed_rect(DECISION_RECT, Color(tint.darkened(0.35), 0.70), 2.4)
	_center_text(Vector2(540, 150), "SATICI ONAYI / KARAR", 10, INK, SERIF_BOLD)
	_center_text(Vector2(540, 216), "PIECZĘĆ SPRZEDAWCY / DAMGA", 7, FADED_INK)
	_dashed_rect(Rect2(475, 158, 130, 44), Color(tint.darkened(0.25), 0.18), 1.2)
	_center_text(Vector2(540, 185), "PUNKT 081", 12, Color(tint.darkened(0.25), 0.14), SERIF_BOLD)
	_text(Vector2(30, 262), "ODCINKI TOWAROWE", 10, INK, SERIF_BOLD)
	_text(Vector2(188, 261), "Odłącza sprzedawca po sprawdzeniu uprawnień.", 8, FADED_INK, SERIF_ITALIC)
	_text(Vector2(30, 276), "Karta nie stanowi środka płatniczego. Zachować do końca miesiąca.", 8, FADED_INK)
	for i: int in 3:
		_draw_coupon(i, false, tint)


func _draw_back(spec: Dictionary) -> void:
	var tint: Color = spec.get("color", Color.GRAY)
	if card.get("patch", false):
		# Reverse adhesive is beneath the original typing. It must not erase the
		# month simply because that field crosses the repaired sheet position.
		_draw_quota_repair(true)
	_text(Vector2(30, 95), "POTWIERDZENIE ZAKŁADU PRACY LUB INSTYTUCJI", 11, tint.darkened(0.6), SERIF_BOLD)
	_text(Vector2(30, 115), "KOD INSTYTUCJI / KURUM KODU", 8, FADED_INK)
	_typed(Vector2(30, 149), str(card.get("institution", "")), 29)
	draw_line(Vector2(30, 155), Vector2(391, 155), Color(tint, 0.35), 0.6)
	_text(Vector2(30, 171), "NR KARTY / ÖN YÜZ SERİSİ", 8, FADED_INK)
	_typed(Vector2(30, 194), str(card.get("serial", "")), 19)
	_text(Vector2(280, 171), "PODPIS UPOWAŻNIONEGO", 7, FADED_INK)
	_draw_hand_signature(Rect2(281, 177, 124, 24))
	_text(Vector2(30, 217), "MIESIĄC  /  DÖNEM", 8, FADED_INK)
	_typed(Vector2(163, 219), str(card.get("month", "")), 15)
	var seal_at: Vector2 = Vector2(520, 166)
	_draw_rosette(seal_at + Vector2(-0.5, 0.5), 53, Color(0.33, 0.29, 0.21, 0.13))
	_draw_rosette(seal_at + Vector2(0.5, -0.5), 53, Color(0.98, 0.94, 0.81, 0.34))
	_center_text(Vector2(520, 232), "PIECZĘĆ ZAKŁADU", 8, FADED_INK)
	if card.get("seal", false):
		_draw_institution_seal(seal_at)
	_text(Vector2(30, 255), "1. Karta jest imienna. Odcinki ważne wyłącznie z kartą macierzystą.", 9, INK)
	_text(Vector2(30, 268), "2. Sprawdzić kategorię, okres ważności i potwierdzenie instytucji.", 9, INK)
	_text(Vector2(30, 279), "Potwierdzenie: podpis osoby upoważnionej i pieczęć instytucji.", 8, FADED_INK, SERIF_ITALIC)
	for i: int in 3:
		_draw_coupon(i, true, tint)


func _draw_institution_seal(at: Vector2) -> void:
	var ink: Color = Color("66506a")
	for i: int in 54:
		var angle: float = float(i) / 54.0 * TAU
		if i not in [5, 16, 29, 42]:
			draw_arc(at, 44, angle, angle + 0.099, 5, Color(ink, 0.58 + float(i % 4) * 0.08), 1.55, true)
	draw_arc(at, 39.5, 0, TAU, 80, Color(ink, 0.59), 0.75, true)
	_center_text(at + Vector2(0, -19), "WARSZAWA · WOLA", 8, Color(ink, 0.79), SERIF_BOLD)
	_center_text(at + Vector2(0, 6), str(card.get("institution", "")), 25, Color(ink, 0.83), SERIF_BOLD)
	draw_line(at + Vector2(-25, 12), at + Vector2(25, 12), Color(ink, 0.63), 0.65)
	_center_text(at + Vector2(0, 24), "ZATWIERDZONO", 7, Color(ink, 0.72))


func _draw_paper(tint: Color) -> void:
	if render_tools:
		draw_style_box(_paper_style(Color(0, 0, 0, 0.20), 2), Rect2(Vector2(5, 7), PAPER_SIZE))
	# The mesh/shader owns thickness, ragged silhouette, roughness and light.
	# There is no rounded screen frame or image border on a physical sheet.
	var substrate: Color = Color("e9e4d5")
	# World paper applies this multiplier in its material, once. The archived
	# Control has no 3D material and needs the same stock tint here instead.
	if render_tools:
		substrate *= Color(_paper_profile.get("stock_tint", Color.WHITE))
	draw_rect(Rect2(Vector2.ZERO, PAPER_SIZE), substrate)
	var fibre_strength: float = float(_paper_profile.get("fibre_strength", 1.0))
	for fibre: Vector2 in _fibres:
		draw_line(_sheet_point(fibre), _sheet_point(fibre + Vector2(1.6, 0.23)), Color(0.33, 0.28, 0.20, 0.045 * fibre_strength), 0.35)
	_draw_storage_wear()
	# Registration varies by print run, and between sides. Only ornaments move:
	# evidence fields, coupon boundaries and later rubber stamps stay canonical.
	draw_set_transform(_registration_offset())
	_draw_family_stationery(tint)
	for strand: int in 13:
		var points: PackedVector2Array = PackedVector2Array()
		for i: int in 137:
			var x: float = 26 + float(i) * 4.3
			var y: float = 87 + float(strand) * 12.8 + sin(x * 0.046 + float(strand) * 0.34) * 4.0
			points.append(Vector2(x, y))
		draw_polyline(points, Color(tint.darkened(0.16), 0.045), 0.35, true)
	_draw_rosette(Vector2(282, 166), 70, Color(tint.darkened(0.1), 0.055))
	draw_set_transform(Vector2.ZERO)


func _registration_offset() -> Vector2:
	var run: int = _print_seed % 11
	return Vector2(float(run % 5 - 2) * 0.17, float(run % 3 - 1) * 0.16) + (Vector2(0.48, -0.26) if front else Vector2(-0.39, 0.31))


func _sheet_point(at: Vector2) -> Vector2:
	return at if front else Vector2(PAPER_SIZE.x - at.x, at.y)


func _draw_family_stationery(tint: Color) -> void:
	var ink: Color = Color(tint.darkened(0.28), 0.45)
	var faint: Color = Color(tint.darkened(0.15), 0.22)
	var family: String = str(card.get("class", ""))
	# Narrow marginal furniture leaves the entire working face unobstructed.
	draw_line(Vector2(12, 14), Vector2(628, 14), ink, 0.8, true)
	draw_line(Vector2(12, 382), Vector2(628, 382), faint, 0.6, true)
	for x: float in [12.0, 628.0]:
		draw_line(Vector2(x, 14), Vector2(x, 66), ink, 0.65, true)
		draw_line(Vector2(x, 80), Vector2(x, 278), faint, 0.65, true)
		draw_line(Vector2(x, 282), Vector2(x, 382), faint, 0.65, true)
	match family:
		"worker":
			# A squared industrial form: narrow rules and repeated diagonal slugs.
			draw_line(Vector2(17, 82), Vector2(17, 274), ink, 1.1, true)
			draw_line(Vector2(22, 82), Vector2(22, 274), faint, 0.6, true)
			for y: int in range(86, 272, 9):
				draw_line(Vector2(13, y + 3), Vector2(17, y), ink, 0.65, true)
			for x: int in range(26, 610, 13):
				draw_rect(Rect2(x, 8.5, 5, 1.5), faint)
		"teacher":
			# A fine academic stationer's chain and double hairline header.
			draw_line(Vector2(18, 18), Vector2(622, 18), faint, 0.45, true)
			for y: int in range(89, 270, 16):
				var diamond: PackedVector2Array = PackedVector2Array([Vector2(18, y - 4), Vector2(21, y), Vector2(18, y + 4), Vector2(15, y), Vector2(18, y - 4)])
				draw_polyline(diamond, ink, 0.55, true)
				draw_line(Vector2(18, y + 4), Vector2(18, y + 12), faint, 0.5, true)
			for x: int in [27, 612]:
				draw_circle(Vector2(x, 17.5), 1.5, ink, false, 0.5, true)
		"retired":
			# A quieter dotted frame with a restrained leaf ribbon at the margin.
			for x: int in range(25, 617, 7):
				draw_circle(Vector2(x, 10), 0.55, ink, true, -1, true)
			for y: int in range(88, 271, 14):
				draw_line(Vector2(18, y - 6), Vector2(18, y + 8), faint, 0.6, true)
				draw_arc(Vector2(15, y), 3.4, -1.1, 1.1, 8, ink, 0.5, true)
				draw_arc(Vector2(21, y + 6), 3.4, PI - 1.1, PI + 1.1, 8, ink, 0.5, true)
		_:
			draw_line(Vector2(18, 82), Vector2(18, 274), faint, 0.6, true)


func _draw_family_emblem(at: Vector2, tint: Color) -> void:
	var ink: Color = Color(tint.darkened(0.28), 0.58)
	var family: String = str(card.get("class", ""))
	if family == "worker":
		draw_arc(at, 20, 0, TAU, 64, ink, 0.8, true)
		draw_arc(at, 17.5, 0, TAU, 64, ink, 0.45, true)
		for i: int in 16:
			var direction: Vector2 = Vector2.from_angle(float(i) * TAU / 16.0)
			draw_line(at + direction * 20.2, at + direction * 23.1, ink, 1.3, true)
	elif family == "teacher":
		for radius: float in [19.0, 22.5]:
			var frame: PackedVector2Array = PackedVector2Array([at + Vector2(0, -radius), at + Vector2(radius, 0), at + Vector2(0, radius), at + Vector2(-radius, 0), at + Vector2(0, -radius)])
			draw_polyline(frame, ink, 0.7, true)
		draw_arc(at, 16.5, 0, TAU, 48, Color(ink, 0.30), 0.4, true)
	elif family == "retired":
		draw_arc(at, 19, 0, TAU, 64, ink, 0.65, true)
		for side: float in [-1.0, 1.0]:
			for i: int in 6:
				var y: float = float(i) * 6.0 - 15.0
				var x: float = sqrt(maxf(0, 22.5 * 22.5 - y * y)) * side
				var leaf: Vector2 = at + Vector2(x, y)
				draw_line(leaf - Vector2(2.1 * side, 1.2), leaf + Vector2(1.1 * side, -2.6), ink, 0.85, true)
	else:
		_draw_rosette(at, 22, ink)


func _draw_storage_wear() -> void:
	# Diffuse handling wear occurs on valid and invalid documents alike. The
	# seed depends only on the physical sheet serial, never on its rule outcome.
	var wear: float = clampf(float(_paper_profile.get("wear", 0.15)), 0, 1)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _print_seed + 6151
	for i: int in 3:
		var centre: Vector2 = Vector2(rng.randf_range(3, 19) if i % 2 == 0 else rng.randf_range(622, 638), rng.randf_range(80, 370))
		var radius: Vector2 = Vector2(rng.randf_range(11, 20), rng.randf_range(14, 28))
		for ring: int in range(5, 0, -1):
			var contour: PackedVector2Array = PackedVector2Array()
			for step: int in 33:
				var angle: float = float(step) * TAU / 32.0
				var ripple: float = 1.0 + sin(angle * 5 + float(i)) * 0.09
				var point: Vector2 = centre + Vector2(cos(angle), sin(angle)) * radius * (0.55 + float(ring) * 0.09) * ripple
				point = point.clamp(Vector2(0.5, 0.5), PAPER_SIZE - Vector2(0.5, 0.5))
				contour.append(_sheet_point(point))
			draw_colored_polygon(contour, Color(0.38, 0.31, 0.19, wear * 0.009))
	if wear < 0.4:
		return
	for i: int in 42:
		var at: Vector2 = Vector2(rng.randf_range(1, 8) if i % 2 == 0 else rng.randf_range(632, 639), rng.randf_range(17, 376))
		var length: float = rng.randf_range(1.0, 4.2)
		draw_line(_sheet_point(at), _sheet_point(at + Vector2(length if i % 2 == 0 else -length, rng.randf_range(-1, 1))), Color(0.99, 0.97, 0.89, wear * 0.34), 0.55, true)


func _draw_quota_repair(reverse: bool) -> void:
	# The front repair and reverse adhesive penetration occupy the SAME sheet
	# position. This is observable material evidence, with no verdict annotation.
	var patch: Rect2 = Rect2(218 if reverse else 285, 208, 137, 34)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _print_seed + 409
	var glue: Color = Color(0.40, 0.32, 0.18, 0.11 if reverse else 0.16)
	draw_rect(patch.grow(1.7), glue)
	var repair: Color = Color("e5dfcb") if not reverse else Color("e5dfcf")
	if render_tools:
		repair *= Color(_paper_profile.get("stock_tint", Color.WHITE))
	draw_rect(patch, Color(repair, 0.42) if reverse else repair)
	draw_line(patch.position + Vector2(0, 0.5), patch.position + Vector2(patch.size.x, 0), Color(0.99, 0.98, 0.91, 0.74), 0.7, true)
	draw_line(patch.position + Vector2(0, patch.size.y), patch.end + Vector2(0.5, 0.5), Color(0.39, 0.31, 0.19, 0.26), 0.8, true)
	draw_line(patch.position + Vector2(patch.size.x, 0), patch.end + Vector2(0.5, 0), Color(0.39, 0.31, 0.19, 0.18), 0.65, true)
	for i: int in 52:
		var t: float = rng.randf_range(0.02, 0.98)
		var horizontal: bool = i % 3 != 0
		var at: Vector2
		var direction: Vector2
		if horizontal:
			at = patch.position + Vector2(t * patch.size.x, 0 if i % 2 == 0 else patch.size.y)
			direction = Vector2(rng.randf_range(-0.6, 0.6), -1 if i % 2 == 0 else 1)
		else:
			at = patch.position + Vector2(0 if i % 2 == 0 else patch.size.x, t * patch.size.y)
			direction = Vector2(-1 if i % 2 == 0 else 1, rng.randf_range(-0.5, 0.5))
		var length: float = rng.randf_range(1.0, 3.7)
		draw_line(at - direction * 0.4, at + direction * length, Color(0.99, 0.98, 0.91, 0.64 if not reverse else 0.35), 0.45, true)
		if i % 4 == 0:
			draw_line(at + direction * 0.6, at + direction * (length + 0.7), Color(0.39, 0.31, 0.20, 0.20 if not reverse else 0.12), 0.35, true)
	# A rubbed top margin exposes short fibres. Keep the quota digits clear.
	if not reverse:
		for i: int in 22:
			var at: Vector2 = patch.position + Vector2(rng.randf_range(3, 133), rng.randf_range(0.7, 2.5))
			draw_line(at, at + Vector2(rng.randf_range(1.0, 3.0), rng.randf_range(-0.4, 0.5)), Color(0.98, 0.96, 0.87, 0.57), 0.45, true)


func _draw_hand_signature(rect: Rect2) -> void:
	# Deliberately drawn pen strokes, separate from serif printer forms and
	# typewriter fields. Signature shape follows issuer, never authenticity.
	var issuer: String = str(card.get("institution", ""))
	var signature_seed: int = StockProfile.stable_seed(issuer)
	var paths: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(0.03, 0.31), Vector2(0.18, 0.10), Vector2(0.14, 0.61), Vector2(0.09, 0.88), Vector2(0.02, 0.77), Vector2(0.06, 0.56)]),
		PackedVector2Array([Vector2(0.21, 0.71), Vector2(0.26, 0.11), Vector2(0.24, 0.55), Vector2(0.35, 0.18), Vector2(0.27, 0.47), Vector2(0.34, 0.76), Vector2(0.39, 0.50), Vector2(0.43, 0.48), Vector2(0.42, 0.72), Vector2(0.38, 0.67), Vector2(0.44, 0.53), Vector2(0.46, 0.72), Vector2(0.49, 0.52), Vector2(0.51, 0.70), Vector2(0.54, 0.48), Vector2(0.57, 0.71), Vector2(0.61, 0.22), Vector2(0.58, 0.71), Vector2(0.64, 0.53), Vector2(0.66, 0.71), Vector2(0.68, 0.49), Vector2(0.72, 0.74), Vector2(0.76, 0.15), Vector2(0.73, 0.69), Vector2(0.78, 0.47), Vector2(0.76, 0.60), Vector2(0.80, 0.72), Vector2(0.84, 0.49), Vector2(0.87, 0.52), Vector2(0.84, 0.71), Vector2(0.91, 0.60), Vector2(0.96, 0.57)]),
		PackedVector2Array([Vector2(0.17, 0.88), Vector2(0.44, 0.81), Vector2(0.72, 0.78), Vector2(0.98, 0.80)])
	]
	for stroke: int in paths.size():
		var knots: PackedVector2Array = paths[stroke]
		var curve: PackedVector2Array = PackedVector2Array()
		for i: int in knots.size() - 1:
			var previous: Vector2 = knots[maxi(0, i - 1)]
			var following: Vector2 = knots[mini(knots.size() - 1, i + 2)]
			for step: int in 6:
				var point: Vector2 = knots[i].cubic_interpolate(knots[i + 1], previous, following, float(step) / 6.0)
				point.y += sin(point.x * 8.0 + float(signature_seed % 17)) * 0.025
				curve.append(rect.position + point * rect.size)
		curve.append(rect.position + knots[knots.size() - 1] * rect.size)
		draw_polyline(curve, Color(0.20, 0.24, 0.29, 0.83 if stroke < 2 else 0.65), 0.76 if stroke < 2 else 0.55, true)


func _draw_bleedthrough() -> void:
	# Thin uncoated stock shows a trace of reverse ink; it is mirrored through
	# the same sheet rather than acting as another visible UI layer.
	var opacity: float = {"thin": 0.049, "medium": 0.026, "thick": 0.011}.get(str(_paper_profile.get("stock", "medium")), 0.026)
	var ghost: Color = Color(0.31, 0.27, 0.23, opacity)
	if front and card.get("seal", false):
		draw_arc(Vector2(120, 166), 44, 0, TAU, 70, ghost, 1.4, true)
		draw_arc(Vector2(120, 166), 39.5, 0, TAU, 70, ghost, 0.7, true)
	elif not front:
		for mark: Dictionary in work.get("marks", []):
			var at: Vector2 = Vector2(640 - float(mark.get("x", 540)), float(mark.get("y", 180)))
			draw_set_transform(at, -float(mark.get("angle", 0)), Vector2(-1, 1))
			draw_rect(Rect2(-65, -22, 130, 44), Color(0.29, 0.25, 0.22, opacity * 1.25), false, 1.5)
			draw_set_transform(Vector2.ZERO)


func _draw_folds() -> void:
	var wear: float = clampf(float(_paper_profile.get("wear", 0.15)), 0, 1)
	var strength: float = lerpf(0.018, 0.12, wear)
	var x: float = 319.0 if front else 321.0
	draw_line(Vector2(x, 4), Vector2(x + 1, 396), Color(0.30, 0.22, 0.14, strength), 0.9)
	draw_line(Vector2(x + 1.2, 4), Vector2(x + 2.2, 396), Color(1.0, 0.97, 0.87, strength * 1.3), 0.65)
	if wear < 0.4:
		return
	draw_line(Vector2(4, 243), Vector2(636, 246), Color(0.30, 0.22, 0.14, strength * 0.7), 1.0)
	draw_line(Vector2(4, 245), Vector2(636, 248), Color(1.0, 0.97, 0.87, strength * 1.1), 0.7)
	for i: int in 23:
		var y: float = 21.0 + float(i) * 15.0
		draw_line(Vector2(3, y), Vector2(7 + i % 4, y + 4), Color(0.44, 0.34, 0.18, 0.12), 0.7)
		draw_line(Vector2(636, y + 4), Vector2(630 - i % 3, y + 8), Color(0.44, 0.34, 0.18, 0.10), 0.65)


func _draw_coupon(index: int, reverse: bool, tint: Color) -> void:
	var item: String = RationDeskRules.PRODUCT_ORDER[index]
	var rect: Rect2 = coupon_rect(index)
	if reverse:
		rect.position.x = PAPER_SIZE.x - rect.end.x
	var missing: bool = item in work.get("cuts", []) or not item in card.get("available", [])
	if missing:
		if render_tools:
			draw_rect(rect, Color("354844"))
		return
	_dashed_rect(rect, Color(tint.darkened(0.2), 0.55), 3)
	if reverse:
		_draw_rosette(rect.get_center(), 28, Color(tint.darkened(0.12), 0.16))
		_center_text(rect.position + Vector2(90, 20), "PZ–81 / ODCINEK %02d" % (index + 1), 9, FADED_INK)
		_center_text(rect.position + Vector2(90, 48), str(card.get("serial", "")), 15, INK, TYPEWRITER)
		_center_text(rect.position + Vector2(90, 69), str(card.get("month", "")), 11, FADED_INK, TYPEWRITER)
		_center_text(rect.position + Vector2(90, 82), "WARSZAWSKA SPÓŁDZIELNIA ZAOPATRZENIA", 5, FADED_INK)
	else:
		var goods: Dictionary = {"meat": "MIĘSO", "sugar": "CUKIER", "soap": "MYDŁO"}
		_text(rect.position + Vector2(11, 20), goods.get(item, item), 14, tint.darkened(0.6), SERIF_BOLD)
		_text(rect.position + Vector2(121, 18), "%02d / 82" % (index + 1), 7, FADED_INK, TYPEWRITER)
		_typed(rect.position + Vector2(11, 51), _document_amount(item, int(card.get(item, 0))), 23)
		_text(rect.position + Vector2(11, 67), "%s / %02d" % [str(card.get("serial", "")), index + 1], 8, FADED_INK, TYPEWRITER)
		_text(rect.position + Vector2(11, 81), "Ważny z kartą macierzystą", 7, FADED_INK, SERIF_ITALIC)


func _draw_rosette(at: Vector2, radius: float, tint: Color) -> void:
	for strand: int in 4:
		var points: PackedVector2Array = PackedVector2Array()
		for i: int in 257:
			var angle: float = float(i) / 256.0 * TAU
			var r: float = radius * (0.77 + 0.15 * sin(angle * 13 + float(strand) * 0.64))
			points.append(at + Vector2(cos(angle), sin(angle)) * r)
		draw_polyline(points, tint, 0.45, true)


func _dashed_rect(rect: Rect2, color: Color, dash: float) -> void:
	for offset: int in range(0, int(rect.size.x), maxi(1, int(dash * 2))):
		var width: float = minf(dash, rect.size.x - float(offset))
		draw_line(rect.position + Vector2(offset, 0), rect.position + Vector2(offset + width, 0), color, 0.9, true)
		draw_line(rect.position + Vector2(offset, rect.size.y), rect.position + Vector2(offset + width, rect.size.y), color, 0.8, true)
	for offset: int in range(0, int(rect.size.y), maxi(1, int(dash * 2))):
		var height: float = minf(dash, rect.size.y - float(offset))
		draw_line(rect.position + Vector2(0, offset), rect.position + Vector2(0, offset + height), color, 0.8, true)
		draw_line(rect.position + Vector2(rect.size.x, offset), rect.position + Vector2(rect.size.x, offset + height), color, 0.8, true)


func _month_name() -> String:
	var month: String = str(card.get("month", ""))
	var parts: PackedStringArray = month.split("-")
	if parts.size() != 2:
		return month
	var names: PackedStringArray = ["STYCZEŃ", "LUTY", "MARZEC", "KWIECIEŃ", "MAJ", "CZERWIEC", "LIPIEC", "SIERPIEŃ", "WRZESIEŃ", "PAŹDZIERNIK", "LISTOPAD", "GRUDZIEŃ"]
	var index: int = parts[1].to_int() - 1
	return "%s %s" % [names[index], parts[0]] if index >= 0 and index < names.size() else month


func _center_text(at: Vector2, text: String, font_size: int, color: Color, face: Font = SERIF) -> void:
	var width: float = face.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_text(at - Vector2(width * 0.5, 0), text, font_size, color, face)


func _text(at: Vector2, text: String, font_size: int, color: Color = INK, face: Font = SERIF) -> void:
	draw_string(face, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


static func _document_amount(item: String, amount: int) -> String:
	return "%d szt." % amount if item == "soap" else "%d g" % amount


func _typed(at: Vector2, text: String, font_size: int) -> void:
	# A fixed typewriter key impression: slight baseline and ink-density
	# variation depends on the document serial and character, never frame time.
	var advance: float = 0
	var seed: int = absi(str(card.get("serial", "")).hash())
	for index: int in text.length():
		var glyph: String = text.substr(index, 1)
		var grain: int = absi((seed + index * 7919 + glyph.unicode_at(0) * 137) % 997)
		var baseline: float = float(grain % 5 - 2) * 0.10
		var density: float = 0.82 + float(grain % 17) * 0.01
		draw_string(TYPEWRITER, at + Vector2(advance, baseline), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(INK, density))
		advance += TYPEWRITER.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


func _paper_style(color: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style
