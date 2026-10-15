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
var _font: Font = ThemeDB.fallback_font
var _flip_tween: Tween


func _ready() -> void:
	size = PAPER_SIZE
	pivot_offset = PAPER_SIZE / 2
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1982
	for i: int in 260:
		_fibres.append(Vector2(rng.randf_range(8, 632), rng.randf_range(8, 392)))
	queue_redraw()


func show_card(document: Dictionary, state: Dictionary) -> void:
	card = document
	work = state
	queue_redraw()


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
				if work.get("stamp") != "approve" or (work.get("parcel", {}) as Dictionary).get("item", "") != item:
					feedback.emit("SATIŞ damgasını bas, ürünü hazırla, sonra ilgili kuponu kes.")
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
	var spec: Dictionary = RationDeskRules.CLASSES.get(card.get("class", ""), {})
	var color: Color = spec.get("color", Color.GRAY)
	_draw_paper(color)
	draw_rect(Rect2(14, 14, 612, 47), color.darkened(0.13))
	_text(Vector2(29, 43), "KARTA ZAOPATRZENIA", 26, Color("fff7df"))
	_text(Vector2(463, 42), _month_name(), 17, Color("fff7df"))
	_text(Vector2(31, 59), "WARSZAWA · PUNKT ZAOPATRZENIA 81", 9, Color("f0e3c7"))
	if front:
		_draw_front(spec)
	else:
		_draw_back(spec)
	_draw_folds()
	_text(Vector2(31, 391), "DRUK PZ-81  /  %s  /  %s" % [str(card.get("serial", "")), "01" if front else "02"], 9, Color("8c7d60"))
	if _stamp_held and render_tools:
		var depression: float = minf(_stamp_time / 0.08, 1)
		draw_circle(_press - Vector2(0, 22 - depression * 8), 16, Color("534130"))
		draw_rect(Rect2(_press - Vector2(55, 11 - depression * 5), Vector2(110, 20)), Color("34312c"))
	if _cut_index >= 0:
		var rect: Rect2 = coupon_rect(_cut_index)
		var tip: Vector2 = rect.position + Vector2(rect.size.x * _cut_progress, 0)
		draw_line(rect.position, tip, Color("354844"), 2)
		if not render_tools:
			return
		draw_line(tip - Vector2(22, 14), tip + Vector2(12, 3), Color("747f80"), 4)
		draw_line(tip - Vector2(22, -14), tip + Vector2(12, -3), Color("747f80"), 4)
		draw_arc(tip - Vector2(30, 19), 9, 0, TAU, 24, Color("393c39"), 4)
		draw_arc(tip - Vector2(30, -19), 9, 0, TAU, 24, Color("393c39"), 4)


func _draw_front(spec: Dictionary) -> void:
	var tint: Color = spec.get("color", Color.GRAY)
	draw_rect(Rect2(26, 73, 413, 30), Color(tint, 0.10))
	draw_rect(Rect2(26, 73, 4, 30), tint)
	_text(Vector2(38, 95), spec.get("name", "BİLİNMEYEN SINIF"), 21)
	_draw_rosette(Vector2(540, 96), 27, Color(tint, 0.25))
	_text(Vector2(30, 120), "IMIĘ I NAZWISKO / AD SOYAD", 11, Color("797160"))
	_text(Vector2(30, 148), card.get("holder", ""), 27)
	draw_line(Vector2(30, 155), Vector2(435, 155), Color("b9aa88"), 0.7)
	_text(Vector2(30, 171), "NUMER / SERİ", 10, Color("797160"))
	_text(Vector2(246, 171), "MIESIĄC / GEÇERLİ AY", 10, Color("797160"))
	_text(Vector2(30, 195), str(card.get("serial", "")), 23)
	_text(Vector2(246, 195), str(card.get("month", "")), 23)
	draw_rect(Rect2(30, 205, 405, 42), Color(tint, 0.08))
	_text(Vector2(40, 221), "PRZYDZIAŁ MIĘSA / ET HAKKI", 10, Color("797160"))
	if card.get("patch", false):
		# This is the altered quota's paper patch, not a truth indicator.
		draw_rect(Rect2(285, 208, 137, 34), Color("e9e1c8"))
		draw_line(Vector2(285, 209), Vector2(421, 208), Color(0.47, 0.40, 0.28, 0.30), 0.7)
		draw_line(Vector2(286, 241), Vector2(421, 242), Color(0.47, 0.40, 0.28, 0.22), 0.7)
	_text(Vector2(40, 239), "MIESIĘCZNIE / AYLIK", 10, Color("797160"))
	_text(Vector2(295, 235), RationDeskRules.amount_text("meat", int(card.get("meat", 0))), 25)
	_text(Vector2(30, 265), "ODCINKI TOWAROWE / ÜRÜN KUPONLARI", 12, Color("746b55"))
	_text(Vector2(30, 278), "Kesik çizgiden ayırınız. Haklar yalnızca bu kart için geçerlidir.", 10, Color("8b7d63"))
	draw_rect(DECISION_RECT, Color(tint, 0.045))
	_dashed_rect(DECISION_RECT, Color("a39373"), 5.0)
	_text(Vector2(474, 151), "KARAR / DECYZJA", 12, Color("8b7f64"))
	_text(Vector2(474, 216), "PIECZĘĆ SPRZEDAWCY", 10, Color("9b8e73"))
	for mark: Dictionary in work.get("marks", []):
		_draw_mark(mark)
	for i: int in 3:
		_draw_coupon(i, false, tint)


func _draw_back(spec: Dictionary) -> void:
	var tint: Color = spec.get("color", Color.GRAY)
	_text(Vector2(30, 94), "KURUM KAYDI / POTWIERDZENIE", 23)
	draw_line(Vector2(30, 103), Vector2(609, 103), Color("b9aa88"), 0.7)
	_text(Vector2(30, 128), "KOD INSTYTUCJI / KURUM KODU", 11, Color("797160"))
	_text(Vector2(30, 168), str(card.get("institution", "")), 40)
	_text(Vector2(30, 190), "REJESTR / ÖN YÜZ SERİSİ", 10, Color("797160"))
	_text(Vector2(30, 214), str(card.get("serial", "")), 23)
	_text(Vector2(30, 236), "OKRES / DÖNEM  " + str(card.get("month", "")), 13)
	var seal_at: Vector2 = Vector2(520, 167)
	# The issuing seal is separate from the player's decision stamp.
	draw_arc(seal_at, 53, 0, TAU, 72, Color(0.46, 0.41, 0.31, 0.18), 0.7, true)
	_text(Vector2(471, 231), "PIECZĘĆ ZAKŁADU", 10, Color("8b7f64"))
	if card.get("seal", false):
		var ink: Color = Color("67546e")
		for i: int in 36:
			var angle: float = float(i) / 36.0 * TAU
			# Small gaps and imperfect pressure resemble a rubber institution seal.
			if i not in [5, 16, 29]:
				draw_arc(seal_at, 49, angle, angle + 0.14, 5, Color(ink, 0.74 + float(i % 3) * 0.07), 2, true)
		draw_arc(seal_at, 43, 0, TAU, 80, Color(ink, 0.68), 0.9, true)
		_text(Vector2(481, 147), "WARSZAWA", 12, Color(ink, 0.80))
		_center_text(seal_at + Vector2(0, 10), str(card.get("institution", "")), 28, Color(ink, 0.86))
		_center_text(seal_at + Vector2(0, 29), "ZATWIERDZONO", 9, Color(ink, 0.79))
	if card.get("patch", false):
		# Mirror the changed field's position through the same physical sheet.
		var patch: Rect2 = Rect2(218, 208, 137, 34)
		draw_rect(patch.grow(2), Color(0.56, 0.43, 0.21, 0.12))
		draw_rect(patch, Color("e7e0c9"))
		draw_rect(patch, Color(0.51, 0.43, 0.30, 0.35), false, 0.8)
		for y: int in range(211, 240, 6):
			draw_line(Vector2(216, y), Vector2(223, y + 2), Color(0.52, 0.43, 0.27, 0.36), 0.8)
	_text(Vector2(30, 261), "Karne ödeme yerine geçmez. Kuponları başka bir kartla birleştirmeyiniz.", 12, Color("746b55"))
	_text(Vector2(30, 278), "Kurum onayını, sınıfı ve geçerli ayı ön yüzdeki kayıtla karşılaştırınız.", 11, Color("8b7d63"))
	for i: int in 3:
		_draw_coupon(i, true, tint)


func _draw_mark(mark: Dictionary) -> void:
	var kind: String = mark["kind"]
	var color: Color = Color("355f46") if kind == "approve" else Color("8c3c32")
	var at: Vector2 = Vector2(float(mark["x"]), float(mark["y"]))
	var rect: Rect2 = Rect2(at - Vector2(65, 22), Vector2(130, 44))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(at.x * 17 + at.y * 31) + kind.hash()
	# Deterministic ink wear stays anchored to the contact coordinates.
	for edge: int in 4:
		var start: Vector2 = [rect.position, rect.position + Vector2(130, 0), rect.end, rect.position + Vector2(0, 44)][edge]
		var end: Vector2 = [rect.position + Vector2(130, 0), rect.end, rect.position + Vector2(0, 44), rect.position][edge]
		for step: int in 22:
			if rng.randf() > 0.075:
				draw_line(start.lerp(end, float(step) / 22.0), start.lerp(end, float(step + 1) / 22.0), Color(color, rng.randf_range(0.66, 0.93)), 2.6, true)
	draw_rect(rect.grow(-4), Color(color, 0.46), false, 0.8)
	_center_text(at + Vector2(0, 7), {"approve": "SATIŞ", "reject": "RET", "seize": "ALIKOY"}[kind], 24, Color(color, 0.86))
	for i: int in 34:
		var spot: Vector2 = rect.position + Vector2(rng.randf_range(3, 127), rng.randf_range(3, 41))
		draw_circle(spot, rng.randf_range(0.2, 0.9), Color("e9dfc5"))


func _draw_paper(tint: Color) -> void:
	if render_tools:
		draw_style_box(_paper_style(Color(0, 0, 0, 0.23), 10), Rect2(Vector2(5, 9), PAPER_SIZE))
	draw_style_box(_paper_style(Color("e9dfc5"), 2), Rect2(Vector2.ZERO, PAPER_SIZE))
	draw_rect(Rect2(10, 10, 620, 380), Color("ab9a77"), false, 0.8)
	draw_rect(Rect2(12, 12, 616, 376), Color(0.63, 0.55, 0.39, 0.20), false, 0.6)
	for fibre: Vector2 in _fibres:
		draw_line(fibre, fibre + Vector2(2, 0.3), Color(0.35, 0.27, 0.15, 0.08), 0.7)
	# Fine printing stays low contrast so it never obscures evidence fields.
	for strand: int in 9:
		var points: PackedVector2Array = PackedVector2Array()
		for i: int in 93:
			var x: float = 20 + float(i) * 6.5
			var y: float = 68 + float(strand) * 24 + sin(x * 0.037 + float(strand) * 0.62) * 5.0
			points.append(Vector2(x, y))
		draw_polyline(points, Color(tint, 0.08), 0.5, true)


func _draw_folds() -> void:
	var worn: bool = card.get("worn", false)
	var strength: float = 0.15 if worn else 0.045
	var x: float = 319.0 if front else 321.0
	draw_line(Vector2(x, 4), Vector2(x + 1, 396), Color(0.30, 0.22, 0.14, strength), 1.6)
	draw_line(Vector2(x + 2, 4), Vector2(x + 3, 396), Color(1.0, 0.97, 0.87, strength * 1.6), 1.1)
	if not worn:
		return
	draw_line(Vector2(4, 243), Vector2(636, 246), Color(0.30, 0.22, 0.14, strength * 0.8), 1.9)
	draw_line(Vector2(4, 245), Vector2(636, 248), Color(1.0, 0.97, 0.87, strength * 1.4), 1.0)
	for i: int in 23:
		var y: float = 21.0 + float(i) * 15.0
		draw_line(Vector2(3, y), Vector2(7 + i % 4, y + 4), Color(0.44, 0.34, 0.18, 0.19), 1.2)
		draw_line(Vector2(636, y + 4), Vector2(630 - i % 3, y + 8), Color(0.44, 0.34, 0.18, 0.16), 1.1)


func _draw_coupon(index: int, reverse: bool, tint: Color) -> void:
	var item: String = RationDeskRules.PRODUCT_ORDER[index]
	var rect: Rect2 = coupon_rect(index)
	if reverse:
		rect.position.x = PAPER_SIZE.x - rect.end.x
	var missing: bool = item in work.get("cuts", []) or not item in card.get("available", [])
	if missing:
		# The 3D shader discards this area, including fold and reverse ink.
		if render_tools:
			draw_rect(rect, Color("354844"))
			_text(rect.position + Vector2(17, 48), "AYRILMIŞ KUPON", 17, Color("94a499"))
		return
	draw_rect(rect, Color(tint, 0.085))
	_dashed_rect(rect, Color("9a8865"), 5)
	if reverse:
		_draw_rosette(rect.get_center(), 29, Color(tint, 0.20))
		_center_text(rect.position + Vector2(90, 25), "PZ-81 / %02d" % (index + 1), 12, Color("8a7c62"))
		_center_text(rect.position + Vector2(90, 51), str(card.get("serial", "")), 19, Color("706952"))
		_center_text(rect.position + Vector2(90, 74), str(card.get("month", "")), 11, Color("8a7c62"))
	else:
		_text(rect.position + Vector2(12, 25), RationDeskRules.GOODS[item], 18)
		_text(rect.position + Vector2(12, 56), RationDeskRules.amount_text(item, int(card.get(item, 0))), 28)
		_text(rect.position + Vector2(12, 77), "%s  /  %02d" % [str(card.get("serial", "")), index + 1], 10, Color("8a7c62"))


func _draw_rosette(at: Vector2, radius: float, tint: Color) -> void:
	for strand: int in 3:
		var points: PackedVector2Array = PackedVector2Array()
		for i: int in 161:
			var angle: float = float(i) / 160.0 * TAU
			var r: float = radius * (0.76 + 0.18 * sin(angle * 13 + float(strand) * 0.9))
			points.append(at + Vector2(cos(angle), sin(angle)) * r)
		draw_polyline(points, tint, 0.65, true)


func _dashed_rect(rect: Rect2, color: Color, dash: float) -> void:
	for offset: int in range(0, int(rect.size.x), int(dash * 2)):
		var width: float = minf(dash, rect.size.x - float(offset))
		draw_line(rect.position + Vector2(offset, 0), rect.position + Vector2(offset + width, 0), color, 1.1)
		draw_line(rect.position + Vector2(offset, rect.size.y), rect.position + Vector2(offset + width, rect.size.y), color, 0.7)
	for offset: int in range(0, int(rect.size.y), int(dash * 2)):
		var height: float = minf(dash, rect.size.y - float(offset))
		draw_line(rect.position + Vector2(0, offset), rect.position + Vector2(0, offset + height), color, 0.7)
		draw_line(rect.position + Vector2(rect.size.x, offset), rect.position + Vector2(rect.size.x, offset + height), color, 0.7)


func _month_name() -> String:
	var month: String = str(card.get("month", ""))
	var parts: PackedStringArray = month.split("-")
	if parts.size() != 2:
		return month
	var names: PackedStringArray = ["STYCZEŃ", "LUTY", "MARZEC", "KWIECIEŃ", "MAJ", "CZERWIEC", "LIPIEC", "SIERPIEŃ", "WRZESIEŃ", "PAŹDZIERNIK", "LISTOPAD", "GRUDZIEŃ"]
	var index: int = parts[1].to_int() - 1
	return "%s · %s" % [names[index], parts[0]] if index >= 0 and index < names.size() else month


func _center_text(at: Vector2, text: String, font_size: int, color: Color) -> void:
	var width: float = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_text(at - Vector2(width * 0.5, 0), text, font_size, color)


func _text(at: Vector2, text: String, font_size: int, color: Color = Color("393a31")) -> void:
	draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _paper_style(color: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style
