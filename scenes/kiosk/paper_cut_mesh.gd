class_name PaperCutMesh
extends RefCounted
## Physical paper surfaces and kerf walls. Coordinates are always the printed
## front of the sheet, in 640 x 400 units; one unit is 0.5625 mm.

const PRINT_SIZE: Vector2 = Vector2(640, 400)
const SHEET_SIZE: Vector2 = Vector2(0.36, 0.225)
const HALF_THICKNESS: float = 0.00016
const KERF_METRES: float = 0.00046
const MASK_SCALE: float = 2.0
const MASK_SIZE: Vector2i = Vector2i(1280, 800)


static func local_point(point: Vector2, height: float = 0.0) -> Vector3:
	return Vector3((point.x / PRINT_SIZE.x - 0.5) * SHEET_SIZE.x,
		(0.5 - point.y / PRINT_SIZE.y) * SHEET_SIZE.y, height)


static func surface(size: Vector2, columns: int = 48, rows: int = 30) -> ArrayMesh:
	# A real tessellated sheet, so the held-paper bend has geometry to deform.
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	for row: int in rows + 1:
		for column: int in columns + 1:
			var uv: Vector2 = Vector2(float(column) / columns, float(row) / rows)
			vertices.append(Vector3((uv.x - 0.5) * size.x, (0.5 - uv.y) * size.y, 0))
			normals.append(Vector3.BACK)
			uvs.append(uv)
	for row: int in rows:
		for column: int in columns:
			var top: int = row * (columns + 1) + column
			# Godot uses clockwise front faces.
			indices.append_array(PackedInt32Array([top, top + 1, top + columns + 2,
				top, top + columns + 2, top + columns + 1]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func paths(incisions: Array, preview: PackedVector2Array = PackedVector2Array()) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for incision: Variant in incisions:
		if not incision is Dictionary:
			continue
		var stroke: PackedVector2Array = PackedVector2Array()
		for point: Variant in (incision as Dictionary).get("points", []):
			if point is Array and (point as Array).size() >= 2:
				stroke.append(Vector2(float(point[0]), float(point[1])))
			elif point is Vector2:
				stroke.append(point)
		if stroke.size() >= 2:
			result.append(stroke)
	if preview.size() >= 2:
		result.append(preview)
	return result


static func mask(strokes: Array[PackedVector2Array]) -> Image:
	# Rasterise every persisted stroke. A texture avoids fixed shader-array
	# limits which otherwise make older cuts disappear after a long session.
	var result: Image = Image.create(MASK_SIZE.x, MASK_SIZE.y, false, Image.FORMAT_R8)
	result.fill(Color.BLACK)
	var radius: float = KERF_METRES / (SHEET_SIZE.x / PRINT_SIZE.x) * MASK_SCALE * 0.5
	for stroke: PackedVector2Array in strokes:
		for index: int in stroke.size() - 1:
			_mask_segment(result, stroke[index] * MASK_SCALE, stroke[index + 1] * MASK_SCALE, radius)
	return result


static func _mask_segment(target: Image, start: Vector2, end: Vector2, radius: float) -> void:
	var delta: Vector2 = end - start
	var squared_length: float = delta.length_squared()
	if squared_length < 0.000001:
		return
	var bounds: Rect2i = Rect2i(Vector2i((start.min(end) - Vector2.ONE * (radius + 1)).floor()),
		Vector2i((start.max(end) + Vector2.ONE * (radius + 1)).ceil()) - Vector2i((start.min(end) - Vector2.ONE * (radius + 1)).floor()))
	bounds = bounds.intersection(Rect2i(Vector2i.ZERO, MASK_SIZE))
	for y: int in range(bounds.position.y, bounds.end.y):
		for x: int in range(bounds.position.x, bounds.end.x):
			var sample: Vector2 = Vector2(x + 0.5, y + 0.5)
			var along: float = clampf((sample - start).dot(delta) / squared_length, 0.0, 1.0)
			var distance: float = sample.distance_to(start + delta * along)
			# A narrow antialiased lip around an actual transparent opening.
			var coverage: float = clampf((radius + 0.55 - distance) / 1.1, 0.0, 1.0)
			if coverage > target.get_pixel(x, y).r:
				target.set_pixel(x, y, Color(coverage, 0, 0))


static func cut_edges(strokes: Array[PackedVector2Array], removed: Array[Rect2]) -> ArrayMesh:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count: int = 0
	for stroke: PackedVector2Array in strokes:
		for index: int in stroke.size() - 1:
			for segment: PackedVector2Array in _visible_segments(stroke[index], stroke[index + 1], removed):
				count += _edge_segment(surface_tool, segment[0], segment[1])
	if count == 0:
		return null
	return surface_tool.commit()


static func _visible_segments(start: Vector2, end: Vector2, removed: Array[Rect2]) -> Array[PackedVector2Array]:
	var fractions: Array[float] = [0.0, 1.0]
	var delta: Vector2 = end - start
	if delta.length_squared() < 0.00001:
		return []
	for rect: Rect2 in removed:
		var corners: PackedVector2Array = PackedVector2Array([rect.position,
			Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
		for index: int in 4:
			var crossing: Variant = Geometry2D.segment_intersects_segment(start, end, corners[index], corners[(index + 1) % 4])
			if crossing is Vector2:
				fractions.append(clampf(((crossing as Vector2) - start).dot(delta) / delta.length_squared(), 0, 1))
	fractions.sort()
	var result: Array[PackedVector2Array] = []
	for index: int in fractions.size() - 1:
		var low: float = fractions[index]
		var high: float = fractions[index + 1]
		if high - low < 0.00001:
			continue
		var midpoint: Vector2 = start + delta * ((low + high) * 0.5)
		var inside: bool = false
		for rect: Rect2 in removed:
			if rect.grow(-0.1).has_point(midpoint):
				inside = true
				break
		if not inside:
			result.append(PackedVector2Array([start + delta * low, start + delta * high]))
	return result


static func _edge_segment(surface_tool: SurfaceTool, start: Vector2, end: Vector2) -> int:
	var direction: Vector2 = end - start
	if direction.length_squared() < 0.00001:
		return 0
	var perpendicular: Vector2 = Vector2(-direction.y, direction.x).normalized()
	var kerf_pixels: float = KERF_METRES / (SHEET_SIZE.x / PRINT_SIZE.x)
	for sign_value: float in [-1.0, 1.0]:
		var offset: Vector2 = perpendicular * kerf_pixels * 0.5 * sign_value
		var a: Vector3 = local_point(start + offset, HALF_THICKNESS)
		var b: Vector3 = local_point(end + offset, HALF_THICKNESS)
		var c: Vector3 = local_point(end + offset, -HALF_THICKNESS)
		var d: Vector3 = local_point(start + offset, -HALF_THICKNESS)
		var normal: Vector3 = Vector3(-perpendicular.x, perpendicular.y, 0) * sign_value
		_quad(surface_tool, a, b, c, d, normal, Color("ac9570"))
		# A narrow raised lip catches raking light without substituting a white
		# drawn line for the empty space between the two cut walls.
		var outside: Vector2 = perpendicular * 0.18 * sign_value
		_quad(surface_tool, a, local_point(start + offset + outside, HALF_THICKNESS + 0.000025),
			local_point(end + offset + outside, HALF_THICKNESS + 0.000025), b,
			Vector3.BACK, Color("dccaaa"))
	# Sparse torn fibres are geometry, not screen-aligned particles.
	var fiber_count: int = mini(12, int(direction.length() / 3.0))
	for index: int in fiber_count:
		var amount: float = float(index + 1) / (fiber_count + 1)
		var side: float = -1.0 if index % 2 == 0 else 1.0
		var point: Vector2 = start.lerp(end, amount)
		var edge: Vector2 = point + perpendicular * kerf_pixels * 0.5 * side
		var root_a: Vector3 = local_point(edge - direction.normalized() * 0.035, HALF_THICKNESS)
		var root_b: Vector3 = local_point(edge + direction.normalized() * 0.035, HALF_THICKNESS)
		var tip: Vector3 = local_point(edge - perpendicular * 0.27 * side, HALF_THICKNESS + 0.00004)
		_triangle(surface_tool, root_a, root_b, tip, Vector3.BACK, Color("e6d5b6"))
	return 1


static func _quad(surface_tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3, color: Color) -> void:
	_triangle(surface_tool, a, b, c, normal, color)
	_triangle(surface_tool, a, c, d, normal, color)


static func _triangle(surface_tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3, color: Color) -> void:
	for point: Vector3 in [a, b, c]:
		surface_tool.set_normal(normal)
		surface_tool.set_color(color)
		surface_tool.add_vertex(point)
