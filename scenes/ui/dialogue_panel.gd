class_name DialoguePanel
extends PanelContainer
## Bottom-of-screen dialogue box (roadmap 2.8, prototype). Shows the current
## node's lines and the choices on offer; number keys pick a choice.

signal choice_made(index: int)
signal close_requested

const WIDTH: float = 1180.0

var _lines: VBoxContainer
var _choices: VBoxContainer
var _buttons: Array[Button] = []


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.dark_panel())
	custom_minimum_size = Vector2(WIDTH, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	add_child(column)
	_lines = VBoxContainer.new()
	_lines.add_theme_constant_override("separation", 8)
	column.add_child(_lines)
	column.add_child(HSeparator.new())
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 2)
	column.add_child(_choices)
	visible = false
	resized.connect(_place)
	get_viewport().size_changed.connect(_place)


## names: speaker id -> display name.
func show_step(step: DialogueRunner.Step, names: Dictionary) -> void:
	for child: Node in _lines.get_children():
		child.queue_free()
	for line: Dictionary in step.lines:
		var rich: RichTextLabel = RichTextLabel.new()
		rich.bbcode_enabled = true
		rich.fit_content = true
		rich.scroll_active = false
		rich.custom_minimum_size.x = WIDTH - 48.0
		rich.add_theme_font_size_override("normal_font_size", 22)
		rich.add_theme_color_override("default_color", UiStyle.INK)
		var speaker: String = line["speaker"]
		var color: Color = UiStyle.PALE if speaker == "player" else UiStyle.AMBER
		rich.text = "[color=#%s]%s[/color]   %s" % [color.to_html(false), names.get(speaker, speaker), _escape(line["text"])]
		_lines.add_child(rich)
	show_choices(step)
	visible = true
	UiStyle.fit(self, _place)


func show_choices(step: DialogueRunner.Step) -> void:
	for child: Node in _choices.get_children():
		child.queue_free()
	_buttons.clear()
	if step.finished:
		_add_button(Loc.ui("ui.dialogue.leave"), func() -> void: close_requested.emit())
		return
	for i: int in step.choices.size():
		var choice: Dictionary = step.choices[i]
		var index: int = choice["index"]
		_add_button("%d.  %s" % [i + 1, choice["text"]], func() -> void: choice_made.emit(index))
	if visible:
		UiStyle.fit(self, _place)


func _add_button(text: String, on_press: Callable) -> void:
	var b: Button = UiStyle.choice_button(text)
	b.custom_minimum_size.x = WIDTH - 48.0
	b.pressed.connect(on_press)
	_choices.add_child(b)
	_buttons.append(b)


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed() or event.is_echo():
		return
	var key: InputEventKey = event as InputEventKey
	if key == null:
		return
	var n: int = key.physical_keycode - KEY_1
	if n >= 0 and n < _buttons.size() and n < 9:
		_buttons[n].pressed.emit()
		get_viewport().set_input_as_handled()


func _place() -> void:
	var view: Vector2 = get_viewport_rect().size
	position = Vector2((view.x - size.x) * 0.5, view.y - size.y - 28.0)


func _escape(text: String) -> String:
	return text.replace("[", "[lb]")
