class_name RationCard3D
extends Interactable
## Canvas is used only as paper ink, rendered onto a two-sided physical 3D sheet.

const WIDTH: float = 0.36
const HEIGHT: float = 0.225
const HALF_THICKNESS: float = 0.0006
var front_showing: bool = true
var renderers: Array[RationCardView] = []
var viewports: Array[SubViewport] = []
var materials: Array[ShaderMaterial] = []
var _coupon_edges: Array[MeshInstance3D] = []
var _document: Dictionary = {}


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
	for back: bool in [false, true]:
		var viewport: SubViewport = SubViewport.new()
		viewport.size = Vector2i(1280, 800)
		viewport.disable_3d = true
		viewport.transparent_bg = true
		viewport.gui_disable_input = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		add_child(viewport)
		var renderer: RationCardView = RationCardView.new()
		viewport.add_child(renderer)
		renderer.pivot_offset = Vector2.ZERO
		renderer.scale = Vector2.ONE * 2
		renderer.front = not back
		renderer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		renderer.render_tools = false
		viewports.append(viewport)
		renderers.append(renderer)
		var mesh: QuadMesh = QuadMesh.new()
		mesh.size = Vector2(WIDTH, HEIGHT)
		var instance: MeshInstance3D = MeshInstance3D.new()
		instance.mesh = mesh
		instance.position.z = -0.0006 if back else 0.0006
		instance.rotation.y = PI if back else 0
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = preload("res://assets/shaders/ration_paper.gdshader")
		material.set_shader_parameter("paper_texture", viewport.get_texture())
		material.set_shader_parameter("back_face", back)
		instance.material_override = material
		materials.append(material)
		add_child(instance)
	add_child(_paper_rim(Rect2(0, 0, 640, 400)))
	for i: int in 3:
		var rim: MeshInstance3D = _paper_rim(RationCardView.coupon_rect(i))
		rim.visible = false
		_coupon_edges.append(rim)
		add_child(rim)


func refresh(document: Dictionary, work: Dictionary) -> void:
	_document = document.duplicate(true)
	var mask: Vector3 = Vector3.ZERO
	for i: int in 3:
		var item: String = RationDeskRules.PRODUCT_ORDER[i]
		if item in work.get("cuts", []) or not item in document.get("available", []):
			mask[i] = 1
		_coupon_edges[i].visible = mask[i] > 0.5
	for i: int in 2:
		renderers[i].show_card(document, work)
		materials[i].set_shader_parameter("missing", mask)
		materials[i].set_shader_parameter("wear", 1.0 if document.get("worn", false) else 0.15)
		materials[i].set_shader_parameter("sheet_seed", float(absi(str(document.get("serial", "")).hash()) % 997))
		viewports[i].render_target_update_mode = SubViewport.UPDATE_ONCE


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
		viewport.size = Vector2i(rect.size * 2)
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
			renderer.scale = Vector2.ONE * 2
			renderer.position = -crop.position * 2
			renderer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			renderer.queue_redraw()
			viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		)
		var face: MeshInstance3D = MeshInstance3D.new()
		var quad: QuadMesh = QuadMesh.new()
		quad.size = piece_size
		face.mesh = quad
		face.position.z = -HALF_THICKNESS if back else HALF_THICKNESS
		face.rotation.y = PI if back else 0
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = preload("res://assets/shaders/ration_paper.gdshader")
		material.set_shader_parameter("paper_texture", viewport.get_texture())
		material.set_shader_parameter("back_face", back)
		material.set_shader_parameter("wear", 1.0 if _document.get("worn", false) else 0.15)
		face.material_override = material
		piece.add_child(face)
	# Centre the rim on the cropped piece, rather than on the parent sheet.
	var rim: MeshInstance3D = _paper_rim(rect)
	rim.position = -Vector3((rect.get_center().x / 640.0 - 0.5) * WIDTH, (0.5 - rect.get_center().y / 400.0) * HEIGHT, 0)
	piece.add_child(rim)
	return piece


func _paper_rim(rect: Rect2) -> MeshInstance3D:
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
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color("b9a680")
	material.roughness = 1
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
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
