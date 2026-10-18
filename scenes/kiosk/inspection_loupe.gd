class_name InspectionLoupe
extends Interactable
## A diegetic optical tool. Its own camera photographs the shared 3D world;
## no duplicate card, UI document or authenticity overlay is rendered.
## Origin: underside of the lens centre. +Y is the lens normal; handle is +Z.

const LENS_DIAMETER: float = 0.085
const FOOTPRINT_METRES: float = 0.035
const CAMERA_HEIGHT: float = 0.047
const LENS_LAYER: int = 1 << 19
const VIEW_SIZE: Vector2i = Vector2i(512, 512)
const LENS_SHADER: String = """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D magnified_world : source_color, filter_linear, repeat_disable;
uniform bool active = false;
void fragment() {
	vec2 centred = UV - vec2(0.5);
	float radius = length(centred);
	if (radius > 0.499) discard;
	// Restrained barrel distortion and a grazing reflection at the bevel.
	vec2 sample_uv = vec2(0.5) + centred * (0.978 + dot(centred, centred) * 0.085);
	vec3 world_colour = texture(magnified_world, sample_uv).rgb;
	float bevel = smoothstep(0.455, 0.496, radius);
	float reflection = pow(max(0.0, dot(normalize(centred + vec2(0.0001)), normalize(vec2(-0.6, -0.8)))), 12.0);
	ALBEDO = active ? mix(world_colour, vec3(0.79, 0.86, 0.82), bevel * (0.08 + reflection * 0.14)) : vec3(0.72, 0.83, 0.80);
	ALPHA = active ? 1.0 : 0.095 + bevel * 0.11;
}
"""

var viewport: SubViewport
var focus_camera: Camera3D
var lens: MeshInstance3D
var _lens_material: ShaderMaterial
var _configured_world: World3D
var _active: bool = false
var _focus_point: Vector3 = Vector3.ZERO
var _has_focus: bool = false


func _ready() -> void:
	action = "loupe"
	collision_layer = 2
	collision_mask = 0
	name = "InspectionLoupe"
	_build_model()
	_build_optics()
	if _configured_world == null:
		_configured_world = get_world_3d()
	viewport.world_3d = _configured_world
	if _has_focus:
		_apply_focus()
	set_active(_active)


func configure(world: World3D) -> void:
	_configured_world = world
	if viewport != null:
		viewport.world_3d = world


func set_active(enabled: bool) -> void:
	_active = enabled
	if viewport == null:
		return
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if enabled else SubViewport.UPDATE_DISABLED
	_lens_material.set_shader_parameter("active", enabled)


func is_active() -> bool:
	return _active


func update_focus(paper_point: Vector3) -> void:
	if not paper_point.is_finite():
		return
	_focus_point = paper_point
	_has_focus = true
	if focus_camera != null:
		_apply_focus()


func _apply_focus() -> void:
	# The lens camera is a child of a SubViewport, not of the hand transform.
	# Its world position therefore stays on the physical point being examined.
	focus_camera.position = _focus_point + Vector3.UP * CAMERA_HEIGHT
	focus_camera.rotation = Vector3(-PI / 2.0, 0, 0)


func _build_optics() -> void:
	viewport = SubViewport.new()
	viewport.name = "MagnifierOpticalView"
	viewport.size = VIEW_SIZE
	viewport.own_world_3d = false
	viewport.gui_disable_input = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	focus_camera = Camera3D.new()
	focus_camera.name = "PaperMacroCamera"
	focus_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	focus_camera.size = FOOTPRINT_METRES
	focus_camera.near = 0.001
	focus_camera.far = 0.30
	# All loupe parts, including its lens, live on the last visual layer. The
	# main eye camera sees that layer; this camera excludes it to avoid feedback.
	focus_camera.cull_mask = ((1 << 20) - 1) & ~LENS_LAYER
	viewport.add_child(focus_camera)
	focus_camera.current = true
	_lens_material = ShaderMaterial.new()
	var glass_shader: Shader = Shader.new()
	glass_shader.code = LENS_SHADER
	_lens_material.shader = glass_shader
	_lens_material.set_shader_parameter("magnified_world", viewport.get_texture())
	var glass: QuadMesh = QuadMesh.new()
	glass.size = Vector2.ONE * LENS_DIAMETER
	lens = MeshInstance3D.new()
	lens.name = "OpticalGlass"
	lens.mesh = glass
	lens.material_override = _lens_material
	lens.layers = LENS_LAYER
	lens.position.y = 0.010
	lens.rotation.x = -PI / 2.0
	lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lens)


func _build_model() -> void:
	var metal: ShaderMaterial = WorkbenchArt.metal_material(Color("a7aaa2"), 0.25)
	var dark_metal: ShaderMaterial = WorkbenchArt.metal_material(Color("5a6059"), 0.32)
	var handle_material: StandardMaterial3D = StandardMaterial3D.new()
	handle_material.albedo_color = Color("292b23")
	handle_material.roughness = 0.37
	var ring: TorusMesh = TorusMesh.new()
	ring.inner_radius = 0.0428
	ring.outer_radius = 0.0482
	ring.rings = 64
	ring.ring_segments = 12
	_mesh("NickelLensHousing", ring, Vector3(0, 0.009, 0), metal)
	var lower_rim: TorusMesh = TorusMesh.new()
	lower_rim.inner_radius = 0.0435
	lower_rim.outer_radius = 0.0465
	lower_rim.rings = 64
	lower_rim.ring_segments = 8
	_mesh("LowerRetainingRing", lower_rim, Vector3(0, 0.0035, 0), dark_metal)
	var collar: CylinderMesh = CylinderMesh.new()
	collar.bottom_radius = 0.008
	collar.top_radius = 0.0065
	collar.height = 0.032
	collar.radial_segments = 24
	var collar_model: MeshInstance3D = _mesh("MetalHandleCollar", collar, Vector3(0, 0.009, 0.058), metal)
	collar_model.rotation.x = PI / 2.0
	var grip: CapsuleMesh = CapsuleMesh.new()
	grip.radius = 0.0092
	grip.height = 0.114
	grip.radial_segments = 24
	grip.rings = 8
	var grip_model: MeshInstance3D = _mesh("PolishedDarkHandle", grip, Vector3(0, 0.0092, 0.125), handle_material)
	grip_model.rotation.x = PI / 2.0
	for z: float in [0.078, 0.084, 0.167]:
		var band: TorusMesh = TorusMesh.new()
		band.inner_radius = 0.0085
		band.outer_radius = 0.0094
		band.rings = 24
		band.ring_segments = 6
		var model: MeshInstance3D = _mesh("GripBand", band, Vector3(0, 0.0092, z), dark_metal)
		model.rotation.x = PI / 2.0
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "LensPickupVolume"
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(0.100, 0.023, 0.233)
	collision.shape = shape
	collision.position = Vector3(0, 0.010, 0.067)
	add_child(collision)
	highlight_meshes = [NodePath("NickelLensHousing"), NodePath("PolishedDarkHandle")]


func _mesh(part_name: String, mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var result: MeshInstance3D = MeshInstance3D.new()
	result.name = part_name
	result.mesh = mesh
	result.position = at
	result.material_override = material
	result.layers = LENS_LAYER
	add_child(result)
	return result
