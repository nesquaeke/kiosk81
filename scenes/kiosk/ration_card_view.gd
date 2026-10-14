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
	if _stamp_held:
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
	draw_style_box(_paper_style(Color(0, 0, 0, 0.23), 10), Rect2(Vector2(5, 9), PAPER_SIZE))
	draw_style_box(_paper_style(Color("e9dfc5"), 3), Rect2(Vector2.ZERO, PAPER_SIZE))
	for fibre: Vector2 in _fibres:
		draw_line(fibre, fibre + Vector2(2, 0.3), Color(0.35, 0.27, 0.15, 0.065), 1)
	var spec: Dictionary = RationDeskRules.CLASSES.get(card.get("class", ""), {})
	var color: Color = spec.get("color", Color.GRAY)
	draw_rect(Rect2(14, 14, 612, 48), color)
	_text(Vector2(30, 46), "KARTA ZAOPATRZENIA", 28, Color("fff7df"))
	_text(Vector2(445, 44), "STYCZEŃ · 1982" if card.get("month") == "1982-01" else "LUTY · 1982", 18, Color("fff7df"))
	if front:
		_draw_front(spec)
	else:
		_draw_back(spec)
	if card.get("worn", false):
		for x: float in [110.0, 320.0, 510.0]:
			draw_line(Vector2(x, 66), Vector2(x + 4, 276), Color(0.30, 0.22, 0.14, 0.10), 2)
		draw_line(Vector2(8, 235), Vector2(631, 243), Color(0.30, 0.22, 0.14, 0.12), 2)
	if _stamp_held:
		var depression: float = minf(_stamp_time / 0.08, 1)
		draw_circle(_press - Vector2(0, 22 - depression * 8), 16, Color("534130"))
		draw_rect(Rect2(_press - Vector2(55, 11 - depression * 5), Vector2(110, 20)), Color("34312c"))
	if _cut_index >= 0:
		var rect: Rect2 = coupon_rect(_cut_index)
		var tip: Vector2 = rect.position + Vector2(rect.size.x * _cut_progress, 0)
		draw_line(rect.position, tip, Color("354844"), 4)
		draw_line(tip - Vector2(22, 14), tip + Vector2(12, 3), Color("747f80"), 4)
		draw_line(tip - Vector2(22, -14), tip + Vector2(12, -3), Color("747f80"), 4)
		draw_arc(tip - Vector2(30, 19), 9, 0, TAU, 24, Color("393c39"), 4)
		draw_arc(tip - Vector2(30, -19), 9, 0, TAU, 24, Color("393c39"), 4)


func _draw_front(spec: Dictionary) -> void:
	_text(Vector2(30, 94), spec.get("name", "BİLİNMEYEN SINIF"), 25)
	_text(Vector2(30, 123), "IMIĘ I NAZWISKO / AD SOYAD", 15, Color("797160"))
	_text(Vector2(30, 151), card.get("holder", ""), 28)
	_text(Vector2(30, 187), "NR  " + str(card.get("serial", "")), 22)
	_text(Vector2(275, 187), "AY  " + str(card.get("month", "")), 22)
	_text(Vector2(30, 223), "ET HAKKI  %s" % RationDeskRules.amount_text("meat", int(card.get("meat", 0))), 25)
	_text(Vector2(30, 255), "Kupon, ürün hazırlandıktan sonra kesilir.", 17, Color("797160"))
	draw_rect(DECISION_RECT, Color(0.3, 0.25, 0.15, 0.04))
	draw_rect(DECISION_RECT, Color("a39373"), false, 1)
	_text(Vector2(475, 158), "KARAR / DECYZJA", 15, Color("8b7f64"))
	for mark: Dictionary in work.get("marks", []):
		_draw_mark(mark)
	for i: int in 3:
		var rect: Rect2 = coupon_rect(i)
		var item: String = RationDeskRules.PRODUCT_ORDER[i]
		if item in work.get("cuts", []) or not item in card.get("available", []):
			draw_rect(rect, Color("354844"))
			_text(rect.position + Vector2(17, 48), "AYRILMIŞ KUPON", 17, Color("94a499"))
		else:
			draw_rect(rect, Color(0.65, 0.53, 0.30, 0.08))
			draw_rect(rect, Color("ab9a76"), false, 1)
			_text(rect.position + Vector2(13, 30), RationDeskRules.GOODS[item], 19)
			_text(rect.position + Vector2(13, 60), RationDeskRules.amount_text(item, int(card.get(item, 0))), 27)
		for x: int in range(0, 180, 10):
			draw_line(rect.position + Vector2(x, 0), rect.position + Vector2(x + 5, 0), Color("75694f"), 1.5)


func _draw_back(spec: Dictionary) -> void:
	_text(Vector2(30, 94), "KURUM KAYDI / POTWIERDZENIE", 25)
	_text(Vector2(30, 136), "KURUM KODU", 18, Color("797160"))
	_text(Vector2(30, 180), str(card.get("institution", "")), 42)
	_text(Vector2(30, 222), "SERİ  " + str(card.get("serial", "")), 23)
	if card.get("seal", false):
		draw_arc(Vector2(350, 184), 64, 0, TAU, 80, Color("645470"), 3)
		draw_arc(Vector2(350, 184), 57, 0, TAU, 80, Color("645470"), 1)
		_text(Vector2(307, 176), "ONAYLI", 21, Color("645470"))
		_text(Vector2(323, 204), str(card.get("institution", "")), 26, Color("645470"))
	else:
		draw_rect(Rect2(278, 130, 144, 108), Color("a39373"), false, 1)
	if card.get("patch", false):
		draw_rect(Rect2(467, 119, 128, 100), Color("eee9d7"))
		draw_rect(Rect2(467, 119, 128, 100), Color("ae9e7e"), false, 1)
		for y: int in range(122, 220, 13):
			draw_line(Vector2(465, y), Vector2(474, y + 4), Color("b6a585"), 1)
	_text(Vector2(30, 287), "Karne bedava ürün sağlamaz; ödeme gereklidir.", 20)
	_text(Vector2(30, 322), "Kartı ürünle birlikte müşteriye geri veriniz.", 20)
	_text(Vector2(30, 365), "Kuponlar başka bir kartla birleştirilemez.", 17, Color("797160"))


func _draw_mark(mark: Dictionary) -> void:
	var kind: String = mark["kind"]
	var color: Color = Color("476952") if kind == "approve" else Color("9b463b")
	var at: Vector2 = Vector2(float(mark["x"]), float(mark["y"]))
	var rect: Rect2 = Rect2(at - Vector2(65, 22), Vector2(130, 44))
	draw_rect(rect, color, false, 3)
	draw_rect(rect.grow(-4), Color(color, 0.6), false, 1)
	_text(at + Vector2(-51, 8), {"approve": "SATIŞ", "reject": "RET", "seize": "ALIKOY"}[kind], 24, color)


func _text(at: Vector2, text: String, font_size: int, color: Color = Color("393a31")) -> void:
	draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _paper_style(color: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style
