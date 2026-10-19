class_name StampDieFace
extends Node3D
## Visible rubber underside of the existing stamp. The raised face reuses the
## real printed letter/frame/date layout; its coating follows the tool's ink.
## This is a small displaced/bump-shaded surface, not individual font geometry.

const PIXEL_METRES: float = 0.36 / 640.0
const FACE_SIZE: Vector2 = Vector2(130, 44) * PIXEL_METRES
const MASK_SIZE: Vector2i = Vector2i(536, 192)
const SHADER_SOURCE: String = """
shader_type spatial;
render_mode cull_back;
uniform sampler2D die_mask : filter_linear, repeat_disable;
uniform vec3 ink_color : source_color = vec3(.192, .325, .275);
uniform float ink_load : hint_range(0.0, 1.0) = .75;

vec2 face_uv(vec2 uv) {
    // The viewport includes two print pixels of padding around the real die.
    return (vec2(2.) + uv * vec2(130., 44.)) / vec2(134., 48.);
}
float relief_at(vec2 uv) {
    return smoothstep(.12, .82, texture(die_mask, face_uv(uv)).a);
}
float pores(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
void vertex() {
    // A fraction of a millimetre under the original contact plane. The
    // coarse displacement gives a raised edge; fine letters use normals.
    VERTEX.y = -.00012 - relief_at(UV) * .00014;
}
void fragment() {
    vec2 uv = UV;
    vec2 millimetres = uv * vec2(73.125, 24.75);
    float edge = min(min(millimetres.x, 73.125 - millimetres.x),
        min(millimetres.y, 24.75 - millimetres.y));
    vec2 point = millimetres;
    vec2 nearest_corner = clamp(point, vec2(1.15), vec2(73.125, 24.75) - vec2(1.15));
    if (length(point - nearest_corner) > 1.15) discard;
    float relief = relief_at(uv);
    float grain = pores(floor(millimetres * 16.));
    float mould_ribs = .5 + .5 * sin(millimetres.y * 23.);
    vec3 rubber = mix(vec3(.102, .089, .078), vec3(.174, .156, .137), relief);
    rubber *= .95 + grain * .05 + mould_ribs * .015;
    // Only raised printing surfaces touch the pad. Empty rubber remains
    // matte; new ink gives the same kind-specific colour and moving sheen.
    float coating = relief * ink_load * (.78 + grain * .22);
    vec3 loaded_ink = ink_color * .38;
    ALBEDO = mix(rubber, loaded_ink, coating * .94);
    ALBEDO *= 1. - (1. - smoothstep(.0, .7, edge)) * .08;
    ROUGHNESS = mix(.90, .27, coating);
    SPECULAR = mix(.18, .47, coating);
    METALLIC = 0.;
    vec2 pixel = 1. / vec2(130., 44.);
    float dx = relief_at(uv + vec2(pixel.x, 0.)) - relief_at(uv - vec2(pixel.x, 0.));
    float dy = relief_at(uv + vec2(0., pixel.y)) - relief_at(uv - vec2(0., pixel.y));
    NORMAL_MAP = vec3(.5 - dx * .32 + (grain - .5) * .025,
        .5 - dy * .32 + (mould_ribs - .5) * .018, 1.);
    NORMAL_MAP_DEPTH = .54;
}
"""

static var _surface_shader: Shader
static var _surface_mesh: ArrayMesh
var kind: String = "approve"
var ink_load: float = 0.75
var _mask_viewport: SubViewport
var _mask: DieMask
var _material: ShaderMaterial


func configure(stamp_kind: String) -> void:
	kind = stamp_kind if stamp_kind in ["approve", "reject", "seize"] else "approve"
	_build()
	_mask.kind = kind
	_mask.queue_redraw()
	_mask_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var ink: Color = {"approve": Color("315346"), "reject": Color("823a36"), "seize": Color("72516b")}[kind]
	_material.set_shader_parameter("ink_color", ink)
	_material.set_shader_parameter("ink_load", ink_load)


func set_ink_load(load: float) -> void:
	ink_load = clampf(load, 0.0, 1.0) if is_finite(load) else 0.75
	if _material != null:
		_material.set_shader_parameter("ink_load", ink_load)


func _ready() -> void:
	if _material == null:
		configure(kind)


func _build() -> void:
	if _material != null:
		return
	name = "RubberPrintingFace"
	_mask_viewport = SubViewport.new()
	_mask_viewport.name = "DieSilhouette"
	_mask_viewport.size = MASK_SIZE
	_mask_viewport.disable_3d = true
	_mask_viewport.transparent_bg = true
	_mask_viewport.gui_disable_input = true
	_mask_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_mask_viewport)
	_mask = DieMask.new()
	_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mask.scale = Vector2.ONE * 4.0
	_mask_viewport.add_child(_mask)
	if _surface_shader == null:
		_surface_shader = Shader.new()
		_surface_shader.code = SHADER_SOURCE
	_material = ShaderMaterial.new()
	_material.shader = _surface_shader
	_material.set_shader_parameter("die_mask", _mask_viewport.get_texture())
	var surface: MeshInstance3D = MeshInstance3D.new()
	surface.name = "RaisedRubberGlyphs"
	surface.mesh = _mesh()
	surface.material_override = _material
	surface.extra_cull_margin = 0.001
	add_child(surface)


static func _mesh() -> ArrayMesh:
	if _surface_mesh != null:
		return _surface_mesh
	var builder: SurfaceTool = SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var columns: int = 65
	var rows: int = 22
	for x: int in columns:
		for y: int in rows:
			var points: Array[Vector2] = [Vector2(x, y), Vector2(x + 1, y), Vector2(x + 1, y + 1), Vector2(x, y + 1)]
			# Clockwise from BELOW. X/Z map to the same printed paper X/Y:
			# looking at the -Y underside naturally mirrors the physical die.
			# Mirroring this UV again would produce backwards text on paper.
			for index: int in [0, 2, 1, 0, 3, 2]:
				var uv: Vector2 = points[index] / Vector2(columns, rows)
				builder.set_normal(Vector3.DOWN)
				builder.set_uv(uv)
				builder.add_vertex(Vector3((uv.x - 0.5) * FACE_SIZE.x, 0.0, (uv.y - 0.5) * FACE_SIZE.y))
	builder.index()
	builder.generate_tangents()
	_surface_mesh = builder.commit()
	return _surface_mesh


class DieMask extends Control:
	var kind: String = "approve"

	func _draw() -> void:
		RationStampImpression.draw_face(self, {"kind": kind}, Vector2(67, 24), Color.WHITE, 1.0)
