class_name PaperCutGeometry
extends RefCounted
## Shared physical paper measurements, independent from views and campaign state.
## Persisted paths use print coordinates on a 640 x 400, 36 x 22.5 cm sheet.

const PRINT_SIZE: Vector2 = Vector2(640.0, 400.0)
const SHEET_SIZE_M: Vector2 = Vector2(0.36, 0.225)
## A half-millimeter blade/contact tolerance accommodates native pointer sampling.
## It never changes the stored path or its measured physical length.
const EDGE_TOLERANCE_PX: float = 0.0005 * 640.0 / 0.36
const JOIN_TOLERANCE_PX: float = EDGE_TOLERANCE_PX


static func path_length_m(points: Array) -> float:
	var length: float = 0.0
	for index: int in range(1, points.size()):
		var before: Vector2 = _point(points[index - 1])
		var after: Vector2 = _point(points[index])
		if not before.is_finite() or not after.is_finite():
			return 0.0
		length += ((after - before) * SHEET_SIZE_M / PRINT_SIZE).length()
	return length


## Each edge must be continuously cut. A single top-edge stroke does not
## magically detach the remaining three attached sides. Separate strokes may
## join, but a visible uncut gap cannot be bridged by an accumulated percentage.
static func coupon_is_severed(incisions: Array, rectangle: Rect2) -> bool:
	if rectangle.size.x <= 0.0 or rectangle.size.y <= 0.0:
		return false
	var corners: Array[Vector2] = [rectangle.position,
		rectangle.position + Vector2(rectangle.size.x, 0.0), rectangle.end,
		rectangle.position + Vector2(0.0, rectangle.size.y)]
	for edge: int in range(4):
		var start: Vector2 = corners[edge]
		var end: Vector2 = corners[(edge + 1) % 4]
		if not _edge_is_cut(incisions, start, end):
			return false
	return true


static func _edge_is_cut(incisions: Array, start: Vector2, end: Vector2) -> bool:
	var length: float = start.distance_to(end)
	var tangent: Vector2 = (end - start) / length
	var intervals: Array[Vector2] = []
	for incision: Variant in incisions:
		if not incision is Dictionary or not incision.get("points", null) is Array:
			continue
		var points: Array = incision["points"]
		for index: int in range(1, points.size()):
			var before: Vector2 = _point(points[index - 1])
			var after: Vector2 = _point(points[index])
			if not before.is_finite() or not after.is_finite():
				continue
			# Both endpoints must follow this edge. A diagonal crossing its middle
			# is a cut through the coupon, not a cut along its entire attachment.
			if absf((before - start).cross(tangent)) > EDGE_TOLERANCE_PX or absf((after - start).cross(tangent)) > EDGE_TOLERANCE_PX:
				continue
			var a: float = (before - start).dot(tangent)
			var b: float = (after - start).dot(tangent)
			var interval: Vector2 = Vector2(clampf(minf(a, b), 0.0, length), clampf(maxf(a, b), 0.0, length))
			if interval.y > interval.x:
				intervals.append(interval)
	intervals.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var covered: float = 0.0
	for interval: Vector2 in intervals:
		if interval.x > covered + JOIN_TOLERANCE_PX:
			return false
		covered = maxf(covered, interval.y)
	return covered >= length - JOIN_TOLERANCE_PX


static func _point(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and value.size() == 2 and (typeof(value[0]) == TYPE_INT or typeof(value[0]) == TYPE_FLOAT) and (typeof(value[1]) == TYPE_INT or typeof(value[1]) == TYPE_FLOAT):
		return Vector2(float(value[0]), float(value[1]))
	return Vector2(INF, INF)
