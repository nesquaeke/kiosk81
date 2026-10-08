class_name DayEndPanel
extends PanelContainer
## Closing the book at the end of the day (roadmap 2.10, prototype).

signal save_requested
signal restart_requested
signal quit_requested

const WIDTH: float = 980.0
const VALUE_INK: Color = Color("#1a2a5a")

var _column: VBoxContainer


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.paper(Color("#ddd3bb")))
	custom_minimum_size = Vector2(WIDTH, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 10)
	add_child(_column)
	visible = false


## window: ShiftPlan.ledger() taken when the shutter came down (the visible customers).
## day: DaySimulator.day_summary() after the background day and the evening.
func show_ledger(window: Dictionary, day: Dictionary, decisions: PackedStringArray, iso_date: String) -> void:
	_clear()
	_column.add_child(UiStyle.label(Loc.ui("ui.ledger.title"), 30, UiStyle.PAPER_INK))
	_column.add_child(UiStyle.label(DecreeNote.format_date(iso_date), 16, Color("#5a5040")))
	_column.add_child(HSeparator.new())
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 36)
	_column.add_child(columns)
	var left: VBoxContainer = _section(columns, "ui.ledger.window")
	_row(left, "ui.ledger.book", "%d · %s" % [window["registered_count"], Money.format(window["registered_total"])])
	_row(left, "ui.ledger.mismatch", Money.format(window["till_mismatch"]))
	_row(left, "ui.ledger.off_book", str(window["unregistered_sales"]))
	_row(left, "ui.ledger.bad_cards", str(window["bad_cards_accepted"]))
	_row(left, "ui.ledger.refused", str(window["good_cards_refused"]))
	var right: VBoxContainer = _section(columns, "ui.ledger.day")
	var inspection: Dictionary = day.get("inspection", {})
	if not inspection.is_empty():
		var fined: bool = not bool(inspection.get("clean", true))
		_row(right, "ui.ledger.inspection", Money.format(inspection["fine"]) if fined else Loc.ui("ui.ledger.inspection_clean"), UiStyle.STAMP_RED if fined else VALUE_INK)
	_row(right, "ui.ledger.routine", "%d · %s" % [day["routine_units"], Money.format(day["routine_revenue"])])
	_row(right, "ui.ledger.returned", str(day["returned"]))
	_row(right, "ui.ledger.handover", Money.format(day["handover"]))
	_row(right, "ui.ledger.commission_today", Money.format(day["commission_today"]))
	var settlement: Dictionary = day.get("settlement", {})
	if settlement.is_empty():
		_row(right, "ui.ledger.commission_week", Money.format(day["commission_week"]))
	else:
		_row(right, "ui.ledger.settlement", Money.format(settlement["payout"]))
		if int(settlement["manko"]) > 0:
			_row(right, "ui.ledger.manko", "−" + Money.format(settlement["manko"]), UiStyle.STAMP_RED)
	_row(right, "ui.ledger.household_cost", "−" + Money.format(day["household_cost"]))
	if int(day["unpaid"]) > 0:
		_row(right, "ui.ledger.unpaid", Money.format(day["unpaid"]), UiStyle.STAMP_RED)
	_row(right, "ui.ledger.household", Money.format(day["household"]))
	_row(right, "ui.ledger.pocket", Money.format(day["pocket"]))
	var rose: bool = int(day["suspicion_to"]) > int(day["suspicion_from"])
	_row(right, "ui.ledger.suspicion", "%d → %d" % [day["suspicion_from"], day["suspicion_to"]], UiStyle.STAMP_RED if rose else VALUE_INK)
	if not decisions.is_empty():
		_column.add_child(HSeparator.new())
		_column.add_child(UiStyle.label(Loc.ui("ui.ledger.decisions"), 18, UiStyle.PAPER_INK))
		for id: String in decisions:
			_column.add_child(UiStyle.label("·  " + Loc.ui("ui.decision." + id), 17, Color("#3a3228"), WIDTH - 48.0))
	var risky: bool = rose or int(window["unregistered_sales"]) > 0 or int(window["bad_cards_accepted"]) > 0 or int(window["till_mismatch"]) != 0
	_column.add_child(HSeparator.new())
	_column.add_child(UiStyle.label(Loc.ui("ui.ledger.risk" if risky else "ui.ledger.clean"), 17, UiStyle.STAMP_RED if risky else Color("#2a4a2a"), WIDTH - 48.0))
	_column.add_child(_button("ui.ledger.save", func() -> void: save_requested.emit()))
	visible = true
	_center()


func show_saved(message: String) -> void:
	_clear()
	_column.add_child(UiStyle.label(message, 22, UiStyle.PAPER_INK, WIDTH - 48.0))
	_column.add_child(UiStyle.label(Loc.ui("ui.ledger.prototype_end"), 17, Color("#3a3228"), WIDTH - 48.0))
	_column.add_child(_button("ui.ledger.restart", func() -> void: restart_requested.emit()))
	_column.add_child(_button("ui.ledger.quit", func() -> void: quit_requested.emit()))
	visible = true
	_center()


func _section(parent: HBoxContainer, title_key: String) -> VBoxContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	box.add_child(UiStyle.label(Loc.ui(title_key), 20, UiStyle.PAPER_INK))
	parent.add_child(box)
	return box


func _row(parent: VBoxContainer, key: String, value: String, value_color: Color = VALUE_INK) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	var caption: Label = UiStyle.label(Loc.ui(key), 16, Color("#3a3228"))
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(caption)
	row.add_child(UiStyle.label(value, 17, value_color))
	parent.add_child(row)


func _button(key: String, on_press: Callable) -> Button:
	var b: Button = UiStyle.choice_button("›  " + Loc.ui(key))
	b.add_theme_color_override("font_color", UiStyle.PAPER_INK)
	b.pressed.connect(on_press)
	return b


func _clear() -> void:
	for child: Node in _column.get_children():
		child.queue_free()


func _center() -> void:
	UiStyle.fit(self, func() -> void: position = (get_viewport_rect().size - size) * 0.5)
