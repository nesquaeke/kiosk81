class_name DocumentPortrait
extends RefCounted
## One deterministic print source for both documents. The variant is visible
## evidence, never an authenticity flag or a customer's occupation.

static func draw(canvas: CanvasItem, rect: Rect2, portrait_id: int, faded: bool = false) -> void:
	var variant: int = RationEvidence.portrait_key(portrait_id)
	var paper: Color = Color("b8b6a7")
	var dark: Color = Color("424843")
	if faded: dark = dark.lerp(paper, 0.27)
	canvas.draw_rect(rect, paper)
	for index: int in 36:
		var y: float = (index + 0.5) / 36.0
		canvas.draw_line(_at(rect, 0, y), _at(rect, 1, y), Color(0.2, 0.24, 0.21, 0.08), 0.45, true)
	var head_width: float = [0.25, 0.22, 0.28, 0.23, 0.26, 0.24, 0.21, 0.29][variant]
	var head_height: float = [0.28, 0.31, 0.26, 0.29, 0.28, 0.30, 0.31, 0.25][variant]
	_oval(canvas, rect, Vector2(0.5, 0.96), Vector2(0.49, 0.27), dark)
	canvas.draw_colored_polygon(PackedVector2Array([_at(rect, 0.39, 0.65), _at(rect, 0.60, 0.65), _at(rect, 0.64, 0.81), _at(rect, 0.5, 0.90), _at(rect, 0.36, 0.81)]), paper.darkened(0.18))
	_oval(canvas, rect, Vector2(0.5, 0.38), Vector2(head_width + 0.027, head_height + 0.045), dark)
	if variant in [2, 4, 6]:
		_oval(canvas, rect, Vector2(0.5, 0.52), Vector2(head_width + 0.07, 0.30), dark)
	_oval(canvas, rect, Vector2(0.5, 0.43), Vector2(head_width, head_height), paper.lightened(0.16))
	# Deliberately different hairlines; both papers draw the exact same variant.
	if variant in [0, 1, 3, 7]:
		canvas.draw_colored_polygon(PackedVector2Array([_at(rect, 0.5 - head_width, 0.34), _at(rect, 0.5 - head_width, 0.18), _at(rect, 0.46, 0.09), _at(rect, 0.5 + head_width, 0.19), _at(rect, 0.5 + head_width, 0.34), _at(rect, 0.53, 0.22)]), dark)
	else:
		canvas.draw_line(_at(rect, 0.29, 0.30), _at(rect, 0.64, 0.18), dark, maxf(1.0, rect.size.x * 0.07), true)
	for side: float in [-1.0, 1.0]:
		var x: float = 0.5 + side * head_width * 0.46
		canvas.draw_line(_at(rect, x - 0.035, 0.40), _at(rect, x + 0.035, 0.40), dark, maxf(0.8, rect.size.x * 0.023), true)
		canvas.draw_line(_at(rect, x - 0.045, 0.36), _at(rect, x + 0.04, 0.355), Color(dark, 0.7), 0.6, true)
	canvas.draw_polyline(PackedVector2Array([_at(rect, 0.5, 0.42), _at(rect, 0.47, 0.53), _at(rect, 0.53, 0.54)]), Color(dark, 0.7), 0.65, true)
	canvas.draw_line(_at(rect, 0.43, 0.61), _at(rect, 0.57, 0.61 + (variant % 3 - 1) * 0.012), dark, 0.75, true)
	if variant in [1, 4, 6]:
		for side: float in [-1.0, 1.0]:
			var eye: Vector2 = Vector2(0.5 + side * 0.12, 0.405)
			_oval(canvas, rect, eye, Vector2(0.096, 0.072), Color.TRANSPARENT, dark)
		canvas.draw_line(_at(rect, 0.475, 0.40), _at(rect, 0.525, 0.40), dark, 0.7, true)
	if variant in [3, 5, 7]:
		canvas.draw_line(_at(rect, 0.42, 0.575), _at(rect, 0.58, 0.575), dark, maxf(1.2, rect.size.x * 0.035), true)
	canvas.draw_polyline(PackedVector2Array([_at(rect, 0.32, 0.82), _at(rect, 0.39, 0.93), _at(rect, 0.5, 0.86), _at(rect, 0.61, 0.93), _at(rect, 0.68, 0.82)]), paper.darkened(0.05), 0.8, true)
	canvas.draw_rect(rect, Color(dark, 0.75), false, 0.8)


static func _at(rect: Rect2, x: float, y: float) -> Vector2:
	return rect.position + rect.size * Vector2(x, y)


static func _oval(canvas: CanvasItem, rect: Rect2, center: Vector2, radius: Vector2, fill: Color, outline: Color = Color.TRANSPARENT) -> void:
	var points: PackedVector2Array = []
	for index: int in 41:
		var angle: float = index * TAU / 40.0
		points.append((rect.position + (center + radius * Vector2(cos(angle), sin(angle))) * rect.size).clamp(rect.position, rect.end))
	if fill.a > 0: canvas.draw_colored_polygon(points, fill)
	if outline.a > 0: canvas.draw_polyline(points, outline, 0.7, true)
