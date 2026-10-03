class_name LoFiView
extends SubViewportContainer
## Draws its SubViewport (the 3D world) at low resolution, scales it up with
## nearest filtering and runs the lo-fi screen pass over it. UI placed outside
## this node stays at full resolution and is never distorted.
## Follows Settings.retro_level (Kapali / Hafif / Orta / Guclu).

const POST_SHADER: Shader = preload("res://assets/shaders/lofi_post.gdshader")

var profile: LoFiProfile = LoFiProfile.for_level(LoFiProfile.DEFAULT_LEVEL)
var _post: ShaderMaterial = ShaderMaterial.new()


func _ready() -> void:
	stretch = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_post.shader = POST_SHADER
	material = _post
	Settings.retro_level_changed.connect(apply_level)
	resized.connect(_update_source_size)
	apply_level(Settings.retro_level)


func apply_level(level: int) -> void:
	profile = LoFiProfile.for_level(level)
	stretch_shrink = profile.shrink
	_post.set_shader_parameter("color_levels", float(profile.color_levels))
	_post.set_shader_parameter("dither", profile.dither)
	_post.set_shader_parameter("barrel", profile.barrel)
	_post.set_shader_parameter("vignette", profile.vignette)
	_post.set_shader_parameter("chroma_px", profile.chroma_px)
	_post.set_shader_parameter("grain", profile.grain)
	RenderingServer.global_shader_parameter_set("lofi_affine", profile.affine)
	RenderingServer.global_shader_parameter_set("lofi_snap_grid", Vector2(profile.jitter_grid))
	_update_source_size()


func internal_size() -> Vector2i:
	return profile.internal_size(Vector2i(size))


func _update_source_size() -> void:
	_post.set_shader_parameter("source_size", Vector2(internal_size()))
