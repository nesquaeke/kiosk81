class_name DayEndPanel
extends PanelContainer
## Closing the book at the end of the day (roadmap 2.10, prototype).

signal save_requested
signal restart_requested
signal quit_requested

var _column: VBoxContainer


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.paper(Color("#ddd3bb")))
	custom_minimum_size = Vector2(620, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 10)
	add_child(_column)
	visible = false


func show_ledger(book: Dictionary, decisions: PackedStringArray, iso_date: String) -> void:
	_clear()
	_column.add_child(UiStyle.label(Loc.ui("ui.ledger.title"), 30, UiStyle.PAPER_INK))
	_column.add_child(UiStyle.label(DecreeNote.format_date(iso_date), 16, Color("#5a5040")))
	_column.add_child(HSeparator.new())
	_row("ui.ledger.till", Money.format(book["till"]))
	_row("ui.ledger.book", "%d · %s" % [book["registered_count"], Money.format(book["registered_total"])])
	_row("ui.ledger.mismatch", Money.format(book["till_mismatch"]))
	_row("ui.ledger.pocket", Money.format(book["pocket"]))
	_row("ui.ledger.off_book", str(book["unregistered_sales"]))
	_row("ui.ledger.bad_cards", str(book["bad_cards_accepted"]))
	_row("ui.ledger.refused", str(book["good_cards_refused"]))
	if not decisions.is_empty():
		_column.add_child(HSeparator.new())
		_column.add_child(UiStyle.label(Loc.ui("ui.ledger.decisions"), 18, UiStyle.PAPER_INK))
		for id: String in decisions:
			_column.add_child(UiStyle.label("·  " + Loc.ui("ui.decision." + id), 17, Color("#3a3228"), 572.0))
	var risky: bool = int(book["unregistered_sales"]) > 0 or int(book["bad_cards_accepted"]) > 0 or int(book["till_mismatch"]) != 0
	_column.add_child(HSeparator.new())
	_column.add_child(UiStyle.label(Loc.ui("ui.ledger.risk" if risky else "ui.ledger.clean"), 17, UiStyle.STAMP_RED if risky else Color("#2a4a2a"), 572.0))
	_column.add_child(_button("ui.ledger.save", func() -> void: save_requested.emit()))
	visible = true
	_center()


func show_saved(message: String) -> void:
	_clear()
	_column.add_child(UiStyle.label(message, 22, UiStyle.PAPER_INK, 572.0))
	_column.add_child(UiStyle.label(Loc.ui("ui.ledger.prototype_end"), 17, Color("#3a3228"), 572.0))
	_column.add_child(_button("ui.ledger.restart", func() -> void: restart_requested.emit()))
	_column.add_child(_button("ui.ledger.quit", func() -> void: quit_requested.emit()))
	visible = true
	_center()


func _row(key: String, value: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	var caption: Label = UiStyle.label(Loc.ui(key), 19, UiStyle.PAPER_INK)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(caption)
	row.add_child(UiStyle.label(value, 19, Color("#1a2a5a")))
	_column.add_child(row)


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
