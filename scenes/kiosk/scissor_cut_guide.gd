class_name ScissorCutGuide
extends Node3D
## A removable work aid above the real paper, never ink or a cutting target.
## Every remaining coupon receives the same rail. The guide reads physical
## incisions only; it does not select the requested product or judge evidence.

const RAIL_OFFSET_PX: float = 2.2
const RAIL_WIDTH_PX: float = 0.7
const SURFACE_CLEARANCE_M: float = 0.00042
const UNCUT_COLOR: Color = Color(0.87, 0.73, 0.43, 0.70)
const CUT_COLOR: Color = Color(0.52, 0.58, 0.55, 0.38)

var _rails: MeshInstance3D
var _contact: MeshInstance3D
var _last_key: Array = []


func _ready() -> void:
	name = "ScissorCutGuide"
	_rails = _mesh_instance("CouponBoundaryRails")
	_contact = _mesh_instance("BladeContactCrosshair")
	var cross: ImmediateMesh = ImmediateMesh.new()
	cross.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	# An open cross leaves the blade/paper contact itself visible. Dimensions
	# stay tied to the actual sheet rather than an always-on-top screen HUD.
	for axis: Vector2 in [Vector2.RIGHT, Vector2.DOWN]:
		for direction: float in [-1.0, 1.0]:
			_ribbon(cross, Vector2(320, 200) + axis * 3.0 * direction, Vector2(320, 200) + axis * 8.0 * direction, 0.9, Color(0.96, 0.86, 0.63, 0.85))
	cross.surface_end()
	_contact.mesh = cross
	visible = false


## The main interaction controller owns visibility. In particular this aid is
## removed for the back face, held inspection and tool release. Reparenting
## only this transient node preserves the sheet's exact world transform.
func update_guide(card: RationCard3D, pixel: Vector2, incisions: Array, available: Array, show: bool = true) -> void:
	if not show or not is_instance_valid(card):
		visible = false
		return
	if get_parent() != card:
		if get_parent() != null:
			reparent(card, false)
		else:
			card.add_child(self)
	transform = Transform3D.IDENTITY
	position.z = card.half_thickness + SURFACE_CLEARANCE_M
	visible = true
	var remaining: Array[int] = []
	for index: int in RationDeskRules.PRODUCT_ORDER.size():
		var rectangle: Rect2 = RationCardView.coupon_rect(index)
		if RationDeskRules.PRODUCT_ORDER[index] in available and card.has_paper_at(rectangle.get_center()):
			remaining.append(index)
	var key: Array = [incisions.hash(), remaining]
	if key != _last_key:
		_last_key = key.duplicate(true)
		_rebuild_rails(incisions, remaining)
	_contact.visible = pixel.is_finite() and card.has_paper_at(pixel)
	if _contact.visible:
		_contact.position = _paper_point(pixel)


func _mesh_instance(node_name: String) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = node_name
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = false
	instance.material_override = material
	add_child(instance)
	return instance


func _rebuild_rails(incisions: Array, remaining: Array[int]) -> void:
	if remaining.is_empty():
		_rails.mesh = null
		return
	var mesh: ImmediateMesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in remaining:
		var rectangle: Rect2 = RationCardView.coupon_rect(index)
		var corners: Array[Vector2] = [rectangle.position,
			rectangle.position + Vector2(rectangle.size.x, 0.0), rectangle.end,
			rectangle.position + Vector2(0.0, rectangle.size.y)]
		for edge: int in 4:
			var start: Vector2 = corners[edge]
			var end: Vector2 = corners[(edge + 1) % 4]
			var tangent: Vector2 = (end - start).normalized()
			# A narrow outside rail exposes the real cut and printed border.
			var outward: Vector2 = Vector2(tangent.y, -tangent.x) * RAIL_OFFSET_PX
			for span: Dictionary in boundary_spans(incisions, start, end):
				var cut: bool = bool(span["cut"])
				var color: Color = CUT_COLOR if cut else UNCUT_COLOR
				var from: float = float(span["from"])
				var to: float = float(span["to"])
				# Uncut attachments use short rails; severed sections use isolated
				# dots. Neither category resembles an authenticity/pass indicator.
				var period: float = 10.0 if cut else 7.0
				var ink_length: float = 1.4 if cut else 4.5
				var cursor: float = floorf(from / period) * period
				while cursor < to:
					var a: float = maxf(from, cursor)
					var b: float = minf(to, cursor + ink_length)
					if b > a:
						_ribbon(mesh, start + tangent * a + outward, start + tangent * b + outward, RAIL_WIDTH_PX, color)
					cursor += period
	mesh.surface_end()
	_rails.mesh = mesh


## Returns physical coverage, in pixels along this edge. Missing gaps remain
## visible; unlike detachment tolerance, the aid never bridges a short uncut
## attachment. Diagonal crossings cannot appear as a fully cut boundary.
static func boundary_spans(incisions: Array, start: Vector2, end: Vector2) -> Array[Dictionary]:
	var spans: Array[Dictionary] = []
	var length: float = start.distance_to(end)
	if length <= 0.00001:
		return spans
	var tangent: Vector2 = (end - start) / length
	var intervals: Array[Vector2] = []
	for entry: Variant in incisions:
		if not entry is Dictionary or not entry.get("points", null) is Array:
			continue
		var points: Array = entry["points"]
		for index: int in range(1, points.size()):
			var before: Vector2 = PaperCutGeometry._point(points[index - 1])
			var after: Vector2 = PaperCutGeometry._point(points[index])
			if not before.is_finite() or not after.is_finite():
				continue
			if absf((before - start).cross(tangent)) > PaperCutGeometry.EDGE_TOLERANCE_PX or absf((after - start).cross(tangent)) > PaperCutGeometry.EDGE_TOLERANCE_PX:
				continue
			var a: float = (before - start).dot(tangent)
			var b: float = (after - start).dot(tangent)
			var interval: Vector2 = Vector2(clampf(minf(a, b), 0.0, length), clampf(maxf(a, b), 0.0, length))
			if interval.y > interval.x:
				intervals.append(interval)
	intervals.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var cursor: float = 0.0
	for interval: Vector2 in intervals:
		if interval.y <= cursor:
			continue
		if interval.x > cursor:
			spans.append({"from": cursor, "to": interval.x, "cut": false})
		var left: float = maxf(cursor, interval.x)
		# Adjacent/overlapping entries may remain separate cut spans; drawing
		# uses global edge distance so the dash rhythm is continuous.
		spans.append({"from": left, "to": interval.y, "cut": true})
		cursor = interval.y
	if cursor < length:
		spans.append({"from": cursor, "to": length, "cut": false})
	return spans


static func _paper_point(pixel: Vector2) -> Vector3:
	return Vector3((pixel.x / 640.0 - 0.5) * RationCard3D.WIDTH, (0.5 - pixel.y / 400.0) * RationCard3D.HEIGHT, 0.0)


static func _ribbon(mesh: ImmediateMesh, from: Vector2, to: Vector2, width: float, color: Color) -> void:
	var normal: Vector2 = Vector2(-(to - from).y, (to - from).x).normalized() * width / 2.0
	var a: Vector3 = _paper_point(from - normal)
	var b: Vector3 = _paper_point(from + normal)
	var c: Vector3 = _paper_point(to + normal)
	var d: Vector3 = _paper_point(to - normal)
	mesh.surface_set_color(color)
	for vertex: Vector3 in [a, b, c, a, c, d]:
		mesh.surface_add_vertex(vertex)
