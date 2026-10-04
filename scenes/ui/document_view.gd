class_name DocumentView
extends PanelContainer
## Inspection view for a document (roadmap 2.4, prototype). Drawn in 2D at full
## resolution, above every visual effect: it must always be readable.
## The ration card is an invented, simplified card for the prototype; its
## in-world text is Polish.

signal closed

const MONTHS_PL: PackedStringArray = ["styczeń", "luty", "marzec", "kwiecień", "maj", "czerwiec",
	"lipiec", "sierpień", "wrzesień", "październik", "listopad", "grudzień"]
const COUPONS_PRINTED: int = 4

var _body: VBoxContainer


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.paper())
	custom_minimum_size = Vector2(560, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 12)
	add_child(_body)
	visible = false


func show_document(doc: Dictionary) -> void:
	for child: Node in _body.get_children():
		child.queue_free()
	_body.add_child(UiStyle.label("KARTKA ZAOPATRZENIA", 30, UiStyle.PAPER_INK))
	_body.add_child(UiStyle.label("Wyroby tytoniowe", 20, UiStyle.PAPER_INK))
	_body.add_child(HSeparator.new())
	_body.add_child(_row("Imię i nazwisko:", str(doc.get("holder", "")) if str(doc.get("holder", "")) != "" else "—"))
	_body.add_child(_row("Miesiąc:", month_text(str(doc.get("month", "")))))
	var stamp_row: HBoxContainer = HBoxContainer.new()
	stamp_row.add_theme_constant_override("separation", 16)
	stamp_row.add_child(UiStyle.label("Pieczęć urzędu:", 20, UiStyle.PAPER_INK))
	stamp_row.add_child(_stamp(doc.get("stamped", false) == true))
	_body.add_child(stamp_row)
	var coupons: HBoxContainer = HBoxContainer.new()
	coupons.add_theme_constant_override("separation", 8)
	coupons.add_child(UiStyle.label("Odcinki:", 20, UiStyle.PAPER_INK))
	var left: int = int(doc.get("coupons_left", 0))
	for i: int in COUPONS_PRINTED:
		coupons.add_child(_coupon(i < COUPONS_PRINTED - left))
	_body.add_child(coupons)
	_body.add_child(UiStyle.label(Loc.ui("ui.doc.hint"), 15, Color("#5a5040"), 500.0))
	visible = true
	UiStyle.fit(self, _place)


func close() -> void:
	if visible:
		visible = false
		closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("cancel"):
		close()
		get_viewport().set_input_as_handled()


static func month_text(iso_month: String) -> String:
	var parts: PackedStringArray = iso_month.split("-")
	if parts.size() != 2 or not parts[1].is_valid_int():
		return iso_month
	var m: int = parts[1].to_int()
	return "%s %s" % [MONTHS_PL[clampi(m, 1, 12) - 1], parts[0]]


func _row(caption: String, value: String) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(UiStyle.label(caption, 20, UiStyle.PAPER_INK))
	var v: Label = UiStyle.label(value, 24, Color("#1a2a5a"))  # written in ink
	row.add_child(v)
	return row


func _stamp(present: bool) -> Control:
	var box: PanelContainer = PanelContainer.new()
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	s.set_border_width_all(3 if present else 1)
	s.border_color = UiStyle.STAMP_RED if present else Color("#b8ad96")
	s.set_corner_radius_all(40)
	s.set_content_margin_all(10)
	box.add_theme_stylebox_override("panel", s)
	box.custom_minimum_size = Vector2(120, 70)
	var text: Label = UiStyle.label("URZĄD\nDZIELNICOWY" if present else "", 13, UiStyle.STAMP_RED)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(text)
	return box


func _coupon(cut: bool) -> Control:
	var box: PanelContainer = PanelContainer.new()
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = Color("#cfc4a8") if not cut else Color("#8a8070")
	s.border_color = Color("#8a7a5a")
	s.set_border_width_all(1)
	box.add_theme_stylebox_override("panel", s)
	box.custom_minimum_size = Vector2(54, 40)
	var mark: Label = UiStyle.label("✕" if cut else "", 22, UiStyle.PAPER_INK)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(mark)
	return box


func _place() -> void:
	var view: Vector2 = get_viewport_rect().size
	position = Vector2(view.x * 0.5 + 40.0, 150.0)
