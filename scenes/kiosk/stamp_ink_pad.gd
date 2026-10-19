class_name StampInkPad
extends Interactable
## One physical open ink pad, in metres. The root is the underside centre of
## the case; +Y is up and the fixed, open lid hinges along the rear (-Z) edge.
## It has no campaign/rule authority and never chooses a stamp's ink colour.

const CASE_SIZE: Vector3 = Vector3(0.160, 0.020, 0.100)
const FELT_SIZE: Vector2 = Vector2(0.136, 0.074)
const FELT_SURFACE_Y: float = 0.021
const MAX_COMPRESSION: float = 0.0009
const CONTACT_RADIUS: Vector2 = Vector2(0.046, 0.021)
const FELT_SHADER: String = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform float saturation : hint_range(0.0, 1.0) = 0.8;
uniform float pressure : hint_range(0.0, 1.0) = 0.0;
uniform vec2 contact_xz = vec2(0.0);
varying vec2 felt_position;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float noise21(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(cell), hash21(cell + vec2(1.0, 0.0)), u.x),
		mix(hash21(cell + vec2(0.0, 1.0)), hash21(cell + vec2(1.0)), u.x), u.y);
}
float footprint(vec2 p) {
	float radius = length((p - contact_xz) / vec2(0.046, 0.021));
	return 1.0 - smoothstep(0.56, 1.0, radius);
}
void vertex() {
	felt_position = VERTEX.xz;
	VERTEX.y -= pressure * 0.0009 * footprint(VERTEX.xz);
}
void fragment() {
	vec2 p = felt_position;
	float nap = noise21(p * 2200.0);
	float threads = noise21(vec2(p.x * 250.0, p.y * 1600.0));
	float blotches = noise21(p * 76.0 + 18.0) * 0.65 + noise21(p * 19.0) * 0.35;
	float compressed = pressure * footprint(p);
	vec3 dry_felt = vec3(0.052, 0.060, 0.063);
	vec3 wet_felt = vec3(0.016, 0.024, 0.031);
	ALBEDO = mix(dry_felt, wet_felt, saturation) * (0.82 + nap * 0.23 + threads * 0.08 + blotches * 0.09);
	ROUGHNESS = clamp(0.90 - saturation * 0.13 - compressed * 0.10 + (nap - 0.5) * 0.035, 0.64, 0.96);
	METALLIC = 0.0;
	SPECULAR = 0.22 + saturation * 0.13;
	float fibre = (nap - 0.5) * (0.036 - compressed * 0.02);
	NORMAL_MAP = normalize(vec3(fibre, (threads - 0.5) * 0.023, 1.0)) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.28;
}
"""

var dimensions: Vector3 = Vector3(0.160, 0.107, 0.136)
var felt_size: Vector2 = FELT_SIZE
var felt_surface_y: float = FELT_SURFACE_Y
var saturation: float = 0.8
var pressure: float = 0.0
var compression_depth: float = 0.0
var _contact_xz: Vector2 = Vector2.ZERO
var _felt_material: ShaderMaterial
var _felt: MeshInstance3D


func _ready() -> void:
	action = "ink_pad"
	collision_layer = 2
	collision_mask = 0
	name = "StampInkPad"
	_build_model()
	_sync_felt()


func felt_world_point(local_xz: Vector2 = Vector2.ZERO) -> Vector3:
	# No snapping/clamping: callers can reject an incomplete die footprint.
	return to_global(Vector3(local_xz.x, felt_surface_y - _depression_at(local_xz), local_xz.y))


func contains_felt(world_point: Vector3, inset: float = 0.0) -> bool:
	if not world_point.is_finite() or not is_finite(inset):
		return false
	var local: Vector3 = to_local(world_point)
	var half: Vector2 = felt_size * 0.5 - Vector2.ONE * maxf(inset, 0.0)
	return half.x >= 0.0 and half.y >= 0.0 and absf(local.x) <= half.x and absf(local.z) <= half.y


func press_at(world_point: Vector3, amount: float = 1.0) -> void:
	if not world_point.is_finite() or not is_finite(amount):
		return
	var local: Vector3 = to_local(world_point)
	_contact_xz = Vector2(local.x, local.z)
	pressure = clampf(amount, 0.0, 1.0) if contains_felt(world_point) else 0.0
	compression_depth = pressure * MAX_COMPRESSION
	_sync_felt()


func release_press() -> void:
	pressure = 0.0
	compression_depth = 0.0
	_sync_felt()


func set_saturation(value: float) -> void:
	if not is_finite(value):
		return
	saturation = clampf(value, 0.0, 1.0)
	_sync_felt()


func _depression_at(local_xz: Vector2) -> float:
	var radius: float = ((local_xz - _contact_xz) / CONTACT_RADIUS).length()
	return compression_depth * (1.0 - smoothstep(0.56, 1.0, radius))


func _sync_felt() -> void:
	if _felt_material == null:
		return
	_felt_material.set_shader_parameter("saturation", saturation)
	_felt_material.set_shader_parameter("pressure", pressure)
	_felt_material.set_shader_parameter("contact_xz", _contact_xz)


func _build_model() -> void:
	var casing: ShaderMaterial = WorkbenchArt.metal_material(Color("343a35"), 0.53)
	casing.set_shader_parameter("metalness", 0.38)
	casing.set_shader_parameter("wear_amount", 0.62)
	var edge: ShaderMaterial = WorkbenchArt.metal_material(Color("797d70"), 0.45)
	var dark: StandardMaterial3D = _solid(Color("181c1b"), 0.9)
	var label: StandardMaterial3D = _solid(Color("a79b73"), 0.79)
	var lining: StandardMaterial3D = _solid(Color("282f2b"), 0.87)
	# Four rubber feet let the lower sheet-steel lip stand clear of the desk.
	for x: float in [-0.058, 0.058]:
		for z: float in [-0.032, 0.032]:
			_box(self, "RubberFoot", Vector3(0.014, 0.003, 0.012), Vector3(x, 0.0015, z), 0.001, dark)
	_box(self, "RolledCase", Vector3(0.160, 0.012, 0.100), Vector3(0, 0.009, 0), 0.004, casing)
	_box(self, "LowerWornLip", Vector3(0.158, 0.0012, 0.098), Vector3(0, 0.004, 0), 0.0005, edge)
	_box(self, "FeltTray", Vector3(0.149, 0.002, 0.087), Vector3(0, 0.016, 0), 0.001, edge)
	for x: float in [-0.075, 0.075]:
		_box(self, "RolledSideRim", Vector3(0.006, 0.006, 0.090), Vector3(x, 0.017, 0), 0.0012, casing)
	for z: float in [-0.044, 0.044]:
		_box(self, "RolledEndRim", Vector3(0.146, 0.006, 0.006), Vector3(0, 0.017, z), 0.0012, casing)
	_felt = MeshInstance3D.new()
	_felt.name = "CompressibleInkFelt"
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = felt_size
	plane.subdivide_width = 40
	plane.subdivide_depth = 24
	_felt.mesh = plane
	_felt.position.y = felt_surface_y
	_felt_material = ShaderMaterial.new()
	var felt_shader: Shader = Shader.new()
	felt_shader.code = FELT_SHADER
	_felt_material.shader = felt_shader
	_felt.material_override = _felt_material
	add_child(_felt)
	_build_felt_sides()
	var lid: Node3D = Node3D.new()
	lid.name = "OpenHingedLid"
	lid.position = Vector3(0, 0.017, -0.049)
	lid.rotation.x = deg_to_rad(-110.0)
	add_child(lid)
	_box(lid, "LidShell", Vector3(0.158, 0.003, 0.094), Vector3(0, 0, 0.047), 0.0013, casing)
	_box(lid, "LidInnerRecess", Vector3(0.141, 0.0011, 0.078), Vector3(0, -0.002, 0.047), 0.0004, lining)
	# The static, worn label belongs to the object, never to a current customer.
	_box(lid, "PrintedTinLabel", Vector3(0.080, 0.0005, 0.031), Vector3(0, -0.0028, 0.052), 0.0002, label)
	var lettering: Label3D = Label3D.new()
	lettering.name = "InkPadLabel"
	lettering.text = "TUSZ\nMÜREKKEP"
	lettering.position = Vector3(0, -0.00315, 0.052)
	lettering.rotation.x = PI / 2.0
	lettering.pixel_size = 0.000085
	lettering.font_size = 38
	lettering.outline_size = 0
	lettering.modulate = Color("34372f")
	lettering.shaded = true
	lettering.no_depth_test = false
	lid.add_child(lettering)
	for x: float in [-0.054, 0.054]:
		_cylinder(self, "HingeBarrel", 0.0031, 0.025, Vector3(x, 0.017, -0.047), edge)
	_cylinder(self, "HingePin", 0.0014, 0.143, Vector3(0, 0.017, -0.047), edge)
	_box(self, "FrontLidCatch", Vector3(0.023, 0.006, 0.003), Vector3(0, 0.014, 0.0505), 0.0008, edge)
	var selection: CollisionShape3D = CollisionShape3D.new()
	selection.name = "PadSelectionVolume"
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(CASE_SIZE.x, felt_surface_y, CASE_SIZE.z)
	selection.shape = shape
	selection.position.y = felt_surface_y * 0.5
	add_child(selection)
	var lid_selection: CollisionShape3D = CollisionShape3D.new()
	lid_selection.name = "OpenLidSelectionVolume"
	var lid_shape: BoxShape3D = BoxShape3D.new()
	lid_shape.size = Vector3(0.158, 0.006, 0.094)
	lid_selection.shape = lid_shape
	lid_selection.transform = lid.transform * Transform3D(Basis.IDENTITY, Vector3(0, -0.0015, 0.047))
	add_child(lid_selection)


func _build_felt_sides() -> void:
	# No solid box top under the felt: it would hide the sub-millimetre dip.
	# The open skirt shares the exact displacement shader along the perimeter.
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half: Vector2 = felt_size * 0.5
	var corners: Array[Vector2] = [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)]
	for edge_index: int in 4:
		var start: Vector2 = corners[edge_index]
		var end: Vector2 = corners[(edge_index + 1) % 4]
		var edge: Vector2 = end - start
		surface.set_normal(Vector3(edge.y, 0, -edge.x).normalized())
		var a: Vector3 = Vector3(start.x, 0, start.y)
		var b: Vector3 = Vector3(end.x, 0, end.y)
		for point: Vector3 in [a, b + Vector3.DOWN * 0.004, b, a, a + Vector3.DOWN * 0.004, b + Vector3.DOWN * 0.004]:
			surface.set_uv(Vector2(point.x, point.z))
			surface.add_vertex(point)
	var sides: MeshInstance3D = MeshInstance3D.new()
	sides.name = "CompressibleFeltEdges"
	sides.mesh = surface.commit()
	sides.material_override = _felt_material
	sides.position.y = felt_surface_y
	add_child(sides)


static func _box(parent: Node3D, part_name: String, size: Vector3, offset: Vector3, bevel: float, material: Material) -> MeshInstance3D:
	var mesh: MeshInstance3D = WorkbenchArt.bevel_box(size, bevel, material)
	mesh.name = part_name
	mesh.position = offset
	parent.add_child(mesh)
	return mesh


static func _cylinder(parent: Node3D, part_name: String, radius: float, length_metres: float, offset: Vector3, material: Material) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = part_name
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = length_metres
	cylinder.radial_segments = 20
	mesh.mesh = cylinder
	mesh.material_override = material
	mesh.position = offset
	mesh.rotation.z = PI / 2.0
	parent.add_child(mesh)


static func _solid(color: Color, roughness: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
