class_name WatchOverlay
extends PanelContainer
## Tadeusz's wristwatch (roadmap 2.9): hold Q to read the time. No clock on screen otherwise.

var _time: Label
var _date: Label


func _ready() -> void:
	var s: StyleBoxFlat = UiStyle.dark_panel(0.92)
	s.set_corner_radius_all(90)
	s.border_color = Color("#8a8070")
	s.set_border_width_all(4)
	add_theme_stylebox_override("panel", s)
	custom_minimum_size = Vector2(190, 190)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(column)
	_time = UiStyle.label("", 44, UiStyle.INK)
	_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_time)
	_date = UiStyle.label("", 15, UiStyle.DIM)
	_date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_date)
	visible = false


func _process(_delta: float) -> void:
	var holding: bool = Input.is_action_pressed("look_watch")
	if holding != visible:
		visible = holding
		if holding:
			show_state(Game.state)


func show_state(s: CampaignState) -> void:
	_time.text = "%02d:%02d" % [s.minute_of_day / 60, s.minute_of_day % 60]
	_date.text = DecreeNote.format_date(s.calendar_date)
	var view: Vector2 = get_viewport_rect().size
	position = Vector2(36.0, view.y - 190.0 - 36.0)
