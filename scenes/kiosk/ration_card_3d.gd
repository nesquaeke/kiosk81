class_name RationCard3D
extends Interactable
## Canvas is used only as paper ink, rendered onto a two-sided physical 3D sheet.

const INK_SCALE: float = 4.0
const WIDTH: float = 0.36
const HEIGHT: float = 0.225
const HALF_THICKNESS: float = PaperCutMesh.HALF_THICKNESS
var front_showing: bool = true
var renderers: Array[RationCardView] = []
var viewports: Array[SubViewport] = []
var materials: Array[ShaderMaterial] = []
var _coupon_edges: Array[MeshInstance3D] = []
var _document: Dictionary = {}
var _incisions: Array = []
var _preview: PackedVector2Array = PackedVector2Array()
var _incision_mask: Image
var _incision_texture: ImageTexture
var _cut_walls: MeshInstance3D
var _missing_rectangles: Array[Rect2] = []
var _held: bool = false
var _edge_materials: Array[ShaderMaterial] = []


static func table_orientation(front: bool) -> Quaternion:
	# Compose the flip in the sheet's local space before laying it flat.
	# Godot's default YXZ Euler rotation instead spins an already-flat sheet.
	return Quaternion(Vector3.RIGHT, -PI / 2) * Quaternion(Vector3.UP, 0.0 if front else PI)


func _ready() -> void:
	action = "card"
	collision_layer = 2
	collision_mask = 0
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(WIDTH, HEIGHT, 0.008)
	collision.shape = shape
	add_child(collision)
	_incision_mask = PaperCutMesh.mask([])
	_incision_texture = ImageTexture.create_from_image(_incision_mask)
	for back: bool in [false, true]:
		var viewport: SubViewport = SubViewport.new()
		viewport.size = Vector2i(RationCardView.PAPER_SIZE * INK_SCALE)
		viewport.disable_3d = true
		viewport.transparent_bg = true
		viewport.gui_disable_input = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		add_child(viewport)
		var renderer: RationCardView = RationCardView.new()
		viewport.add_child(renderer)
		renderer.pivot_offset = Vector2.ZERO
		renderer.scale = Vector2.ONE * INK_SCALE
		renderer.front = not back
		renderer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		renderer.render_tools = false
		viewports.append(viewport)
		renderers.append(renderer)
		var instance: MeshInstance3D = MeshInstance3D.new()
		instance.mesh = PaperCutMesh.surface(Vector2(WIDTH, HEIGHT))
		instance.position.z = -HALF_THICKNESS if back else HALF_THICKNESS
		instance.rotation.y = PI if back else 0
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = preload("res://assets/shaders/ration_paper.gdshader")
		material.set_shader_parameter("paper_texture", viewport.get_texture())
		material.set_shader_parameter("back_face", back)
		material.set_shader_parameter("incision_texture", _incision_texture)
		instance.material_override = material
		materials.append(material)
		add_child(instance)
	add_child(_paper_rim(Rect2(0, 0, 640, 400)))
	for i: int in 3:
		var rim: MeshInstance3D = _paper_rim(RationCardView.coupon_rect(i))
		rim.visible = false
		_coupon_edges.append(rim)
		add_child(rim)
	_cut_walls = MeshInstance3D.new()
	_cut_walls.name = "ExposedCutWallsAndFibres"
	var wall_material: ShaderMaterial = ShaderMaterial.new()
	wall_material.shader = preload("res://assets/shaders/paper_cut_edge.gdshader")
	wall_material.set_shader_parameter("vertex_tint", true)
	_edge_materials.append(wall_material)
	_cut_walls.material_override = wall_material
	add_child(_cut_walls)


func set_held(held: bool) -> void:
	# The same subdivided sheet settles flat on the desk and flexes subtly in
	# a hand. Surface coordinates remain exact for all desk operations.
	_held = held
	var bend: float = 1.0 if _held else 0.0
	for material: ShaderMaterial in materials:
		material.set_shader_parameter("bend_amount", bend)
	for material: ShaderMaterial in _edge_materials:
		material.set_shader_parameter("bend_amount", bend)


func refresh(document: Dictionary, work: Dictionary) -> void:
	if str(document.get("serial", "")) != str(_document.get("serial", "")):
		_preview.clear()
	_document = document.duplicate(true)
	_incisions = (work.get("incisions", []) as Array).duplicate(true)
	_missing_rectangles.clear()
	var mask: Vector3 = Vector3.ZERO
	for i: int in 3:
		var item: String = RationDeskRules.PRODUCT_ORDER[i]
		if item in work.get("cuts", []) or not item in document.get("available", []) or PaperCutGeometry.coupon_is_severed(_incisions, RationCardView.coupon_rect(i)):
			mask[i] = 1
		_coupon_edges[i].visible = mask[i] > 0.5
		if mask[i] > 0.5:
			_missing_rectangles.append(RationCardView.coupon_rect(i))
	for i: int in 2:
		renderers[i].show_card(document, work)
		materials[i].set_shader_parameter("missing", mask)
		materials[i].set_shader_parameter("quota_patch", bool(document.get("patch", false)))
		materials[i].set_shader_parameter("wear", 1.0 if document.get("worn", false) else 0.15)
		materials[i].set_shader_parameter("sheet_seed", float(absi(str(document.get("serial", "")).hash()) % 997))
		viewports[i].render_target_update_mode = SubViewport.UPDATE_ONCE
	_update_incisions()


func has_paper_at(pixel: Vector2) -> bool:
	if not Rect2(Vector2.ZERO, RationCardView.PAPER_SIZE).has_point(pixel): return false
	for missing: Rect2 in _missing_rectangles:
		if missing.has_point(pixel): return false
	return true


func cut_preview(points: PackedVector2Array) -> void:
	if points == _preview:
		return
	_preview = points.duplicate()
	_update_incisions()


func clear_cut_preview() -> void:
	if _preview.is_empty():
		return
	_preview.clear()
	_update_incisions()


func _update_incisions() -> void:
	var strokes: Array[PackedVector2Array] = PaperCutMesh.paths(_incisions, _preview)
	_incision_mask = PaperCutMesh.mask(strokes)
	_incision_texture.update(_incision_mask)
	var edges: ArrayMesh = PaperCutMesh.cut_edges(strokes, _missing_rectangles)
	_cut_walls.visible = edges != null
	if edges != null:
		_cut_walls.mesh = edges
	for material: ShaderMaterial in materials:
		material.set_shader_parameter("has_incisions", not strokes.is_empty())


func incision_openness_at(pixel: Vector2) -> float:
	# The actual physical opening mask, also used by geometry regression tests.
	if _incision_mask == null or pixel.x < 0 or pixel.y < 0 or pixel.x >= 640 or pixel.y >= 400:
		return 0.0
	var point: Vector2i = Vector2i(pixel * PaperCutMesh.MASK_SCALE)
	return _incision_mask.get_pixel(point.x, point.y).r


func create_coupon(index: int) -> Node3D:
	# A snapshot of this document's original ink; the parent card may already
	# have been refreshed with the cut missing. No state or entitlement mutation.
	assert(index >= 0 and index < 3)
	var piece: Node3D = Node3D.new()
	piece.name = "DetachedCoupon_%d" % index
	var rect: Rect2 = RationCardView.coupon_rect(index)
	var piece_size: Vector2 = rect.size / RationCardView.PAPER_SIZE * Vector2(WIDTH, HEIGHT)
	var original: Dictionary = _document.duplicate(true)
	original["available"] = [RationDeskRules.PRODUCT_ORDER[index]]
	for back: bool in [false, true]:
		var crop: Rect2 = rect
		if back:
			crop.position.x = 640 - rect.end.x
		var viewport: SubViewport = SubViewport.new()
		viewport.size = Vector2i(rect.size * INK_SCALE)
		viewport.disable_3d = true
		viewport.transparent_bg = false
		viewport.gui_disable_input = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		piece.add_child(viewport)
		var renderer: RationCardView = RationCardView.new()
		renderer.render_tools = false
		renderer.front = not back
		renderer.show_card(original, {"cuts": [], "marks": []})
		viewport.add_child(renderer)
		# Child ready initializes the legacy Control pivot; set the texture crop
		# after that without introducing an on-screen GUI or a duplicate card.
		piece.ready.connect(func() -> void:
			renderer.pivot_offset = Vector2.ZERO
			renderer.scale = Vector2.ONE * INK_SCALE
			renderer.position = -crop.position * INK_SCALE
			renderer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			renderer.queue_redraw()
			viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		)
		var face: MeshInstance3D = MeshInstance3D.new()
		face.mesh = PaperCutMesh.surface(piece_size, 16, 8)
		face.position.z = -HALF_THICKNESS if back else HALF_THICKNESS
		face.rotation.y = PI if back else 0
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = preload("res://assets/shaders/ration_paper.gdshader")
		material.set_shader_parameter("paper_texture", viewport.get_texture())
		material.set_shader_parameter("back_face", back)
		material.set_shader_parameter("physical_size", piece_size)
		material.set_shader_parameter("wear", 1.0 if _document.get("worn", false) else 0.15)
		face.material_override = material
		piece.add_child(face)
	# Centre the rim on the cropped piece, rather than on the parent sheet.
	var rim: MeshInstance3D = _paper_rim(rect, false)
	rim.position = -Vector3((rect.get_center().x / 640.0 - 0.5) * WIDTH, (0.5 - rect.get_center().y / 400.0) * HEIGHT, 0)
	piece.add_child(rim)
	return piece


func _paper_rim(rect: Rect2, follows_sheet: bool = true) -> MeshInstance3D:
	# Only the thin edges have geometry: never put a solid backing behind a
	# removed coupon, since that would fill its shader hole when flipped.
	var points: PackedVector2Array = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in 4:
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % 4]
		var start: Vector3 = Vector3((a.x / 640.0 - 0.5) * WIDTH, (0.5 - a.y / 400.0) * HEIGHT, 0)
		var end: Vector3 = Vector3((b.x / 640.0 - 0.5) * WIDTH, (0.5 - b.y / 400.0) * HEIGHT, 0)
		var normal: Vector3 = (end - start).cross(Vector3.FORWARD).normalized()
		var front_a: Vector3 = start + Vector3(0, 0, HALF_THICKNESS)
		var front_b: Vector3 = end + Vector3(0, 0, HALF_THICKNESS)
		var back_a: Vector3 = start - Vector3(0, 0, HALF_THICKNESS)
		var back_b: Vector3 = end - Vector3(0, 0, HALF_THICKNESS)
		for vertex: Vector3 in [front_a, front_b, back_b, front_a, back_b, back_a]:
			surface.set_normal(normal)
			surface.add_vertex(vertex)
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = surface.commit()
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/paper_cut_edge.gdshader")
	material.set_shader_parameter("paper_tint", Color("c8b99a"))
	if follows_sheet:
		_edge_materials.append(material)
	instance.material_override = material
	return instance


func cut_progress(index: int, progress: float) -> void:
	renderers[0].show_cut_progress(index, progress)
	viewports[0].render_target_update_mode = SubViewport.UPDATE_ONCE


func pixel_to_world(pixel: Vector2) -> Vector3:
	return global_transform * Vector3((pixel.x / 640.0 - 0.5) * WIDTH, (0.5 - pixel.y / 400.0) * HEIGHT, 0.001)


func ray_pixel(from: Vector3, direction: Vector3) -> Vector2:
	var inverse: Transform3D = global_transform.affine_inverse()
	var origin: Vector3 = inverse * from
	var ray: Vector3 = inverse.basis * direction
	if absf(ray.z) < 0.00001:
		return Vector2(-1, -1)
	var distance: float = (0.001 - origin.z) / ray.z
	if distance < 0:
		return Vector2(-1, -1)
	var point: Vector3 = origin + ray * distance
	return Vector2((point.x / WIDTH + 0.5) * 640, (0.5 - point.y / HEIGHT) * 400)
