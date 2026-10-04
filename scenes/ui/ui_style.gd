class_name UiStyle
extends RefCounted
## Shared look for the prototype's 2D panels (full resolution, never distorted).

const INK: Color = Color("#e8e0d0")
const DIM: Color = Color("#a89f8a")
const AMBER: Color = Color("#e0b878")
const PALE: Color = Color("#9fb4c8")
const PAPER: Color = Color("#e6dcc4")
const PAPER_INK: Color = Color("#1e1a16")
const STAMP_RED: Color = Color("#9a2a22")


static func dark_panel(alpha: float = 0.9) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = Color(0.086, 0.07, 0.094, alpha)
	s.border_color = Color("#3e3a43")
	s.set_border_width_all(1)
	s.set_content_margin_all(22)
	s.set_corner_radius_all(2)
	return s


static func paper(color: Color = PAPER) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = color.darkened(0.35)
	s.set_border_width_all(2)
	s.set_content_margin_all(24)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 10
	return s


## width > 0: the label wraps at that width; width 0: one line, no wrapping.
## (A wrapping label without a width collapses to one letter per line in a container.)
static func label(text: String, size: int, color: Color, width: float = 0.0) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if width > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = width
	return l


## Shrinks a panel back to its content after its children change, then places it.
static func fit(panel: Control, place: Callable) -> void:
	await panel.get_tree().process_frame
	panel.reset_size()
	place.call()


static func choice_button(text: String) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", AMBER)
	b.add_theme_color_override("font_focus_color", AMBER)
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.set_content_margin_all(6)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("#2f2c39")
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", normal)
	return b
