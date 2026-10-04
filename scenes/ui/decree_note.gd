class_name DecreeNote
extends PanelContainer
## The day's rules pinned beside the window (roadmap 2.5, prototype).
## In-world heading is Polish; the rules are UI text in the player's language.

var _date: Label
var _rules: VBoxContainer


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.paper(Color("#d8cfb8")))
	custom_minimum_size = Vector2(330, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	column.add_child(UiStyle.label("ZARZĄDZENIE", 20, UiStyle.PAPER_INK))
	_date = UiStyle.label("", 14, Color("#5a5040"))
	column.add_child(_date)
	_rules = VBoxContainer.new()
	column.add_child(_rules)
	refresh("")


func refresh(iso_date: String) -> void:
	_date.text = Loc.ui("ui.decree.title") + ("   " + format_date(iso_date) if iso_date != "" else "")
	for child: Node in _rules.get_children():
		child.queue_free()
	for i: int in range(1, 5):
		_rules.add_child(UiStyle.label("%d. %s" % [i, Loc.ui("ui.decree.rule%d" % i)], 15, UiStyle.PAPER_INK, 282.0))
	UiStyle.fit(self, _place)


func _place() -> void:
	var view: Vector2 = get_viewport_rect().size
	position = Vector2(view.x - size.x - 28.0, 28.0)


## "1982-02-15" -> "15.02.1982"
static func format_date(iso_date: String) -> String:
	var p: PackedStringArray = iso_date.split("-")
	return "%s.%s.%s" % [p[2], p[1], p[0]] if p.size() == 3 else iso_date
