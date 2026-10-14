class_name RationCard3D
extends Interactable
## Canvas is used only as paper ink, rendered onto a two-sided physical 3D sheet.

const WIDTH: float = 0.36
const HEIGHT: float = 0.225
var front_showing: bool = true
var renderers: Array[RationCardView] = []
var viewports: Array[SubViewport] = []
var materials: Array[ShaderMaterial] = []


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


func refresh(document: Dictionary, work: Dictionary) -> void:
	var mask: Vector3 = Vector3.ZERO
	for i: int in 3:
		var item: String = RationDeskRules.PRODUCT_ORDER[i]
		if item in work.get("cuts", []) or not item in document.get("available", []):
			mask[i] = 1
	for i: int in 2:
		renderers[i].show_card(document, work)
		materials[i].set_shader_parameter("missing", mask)
		viewports[i].render_target_update_mode = SubViewport.UPDATE_ONCE


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
