class_name RationStampImpression
extends Control
## A rubber impression, not a UI badge. All variation is anchored to the
## measured contact and its persisted serial; reading a save never rerolls ink.

const FACE_FONT: Font = preload("res://assets/fonts/LiberationSerif-Bold.ttf")
const DATE_FONT: Font = preload("res://assets/fonts/LiberationMono-Regular.ttf")
const INK_SHADER: String = """
shader_type canvas_item;
render_mode unshaded;
uniform float grain_seed = 0.0;
uniform float ink_density = 0.8;
uniform float dropout = 0.1;
uniform float contact_pressure = 0.65;
varying vec2 ink_position;
float grain(vec2 p) {
    return fract(sin(dot(p + vec2(grain_seed * .17, grain_seed * .63), vec2(127.1, 311.7))) * 43758.5453);
}
void vertex() { ink_position = VERTEX; }
void fragment() {
    vec4 ink = COLOR;
    float fibre = grain(floor(ink_position * vec2(3.2, 5.8)));
    float rubber = grain(floor(ink_position * .31));
    // With little pressure, one shoulder of the rubber face has not touched
    // the fibres yet. A firm, held contact fills it; impact leaves dry pores.
    float shoulder = smoothstep(-55., 55., ink_position.x) * (1. - contact_pressure) * .35;
    float voids = dropout + shoulder;
    float coverage = smoothstep(voids, voids + .12, fibre);
    float mottling = mix(.66, 1., rubber);
    COLOR = vec4(ink.rgb, ink.a * ink_density * coverage * mottling);
}
"""

static var _ink_shader: Shader
var impression: Dictionary = {}
var features: Dictionary = {}
var _ink: Color = Color("314f43")


static func ink_features(mark: Dictionary) -> Dictionary:
	var pressure: float = clampf(float(mark.get("pressure", 0.65)), 0, 1)
	var speed: float = clampf(float(mark.get("speed", 0.35)), 0, 5)
	var dwell: float = clampf(float(mark.get("dwell", 0.15)), 0, 15)
	var wet: float = 1.0 - exp(-dwell * 2.0)
	var impact: float = clampf((speed - 0.4) / 1.8, 0, 1)
	var direction_data: Array = mark.get("smudge_direction", [0.0, 0.0])
	var direction: Vector2 = Vector2(float(direction_data[0]), float(direction_data[1])) if direction_data.size() >= 2 else Vector2.ZERO
	if direction.length_squared() > 0.00001:
		direction = direction.normalized()
	var smudge: Vector2 = direction * clampf(float(mark.get("smudge", 0)), 0, 0.02) * (640.0 / 0.36)
	return {
		"density": clampf(0.32 + pressure * 0.54 + wet * 0.18, 0, 1),
		"dropout": clampf(0.43 * (1 - pressure) + impact * 0.12 - wet * 0.08, 0.02, 0.65),
		"spread": 0.12 + pressure * 0.22 + wet * 0.42,
		"impact_offset": impact * 1.1,
		"smudge_pixels": smudge,
		"pressure": pressure,
		"seed": float(absi(("%s:%d:%.4f:%.4f" % [str(mark.get("kind", "")), int(mark.get("serial", 1)), float(mark.get("x", 0)), float(mark.get("y", 0))]).hash()) % 65521),
	}


func set_impression(mark: Dictionary) -> void:
	impression = mark.duplicate(true)
	features = ink_features(mark)
	position = Vector2(float(mark.get("x", 540)), float(mark.get("y", 180)))
	rotation = float(mark.get("angle", 0))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink = {"approve": Color("315346"), "reject": Color("823a36"), "seize": Color("72516b")}.get(str(mark.get("kind", "approve")), Color("315346"))
	if _ink_shader == null:
		_ink_shader = Shader.new()
		_ink_shader.code = INK_SHADER
	var ink_material: ShaderMaterial = ShaderMaterial.new()
	ink_material.shader = _ink_shader
	ink_material.set_shader_parameter("grain_seed", features["seed"])
	ink_material.set_shader_parameter("ink_density", features["density"])
	ink_material.set_shader_parameter("dropout", features["dropout"])
	ink_material.set_shader_parameter("contact_pressure", features["pressure"])
	material = ink_material
	queue_redraw()


func _draw() -> void:
	if impression.is_empty():
		return
	var smear: Vector2 = features["smudge_pixels"]
	# A lateral drag transfers progressively less ink along its real direction.
	if smear.length() > 0.15:
		for step: int in range(7, 0, -1):
			var fraction: float = float(step) / 7.0
			_draw_face(smear * fraction, Color(_ink, 0.035 + (1 - fraction) * 0.055), 0.65)
	var spread: float = float(features["spread"])
	for offset: Vector2 in [Vector2(-spread, 0), Vector2(spread, 0), Vector2(0, -spread), Vector2(0, spread)]:
		_draw_face(offset, Color(_ink, 0.065), 0.45)
	var rebound: float = float(features["impact_offset"])
	if rebound > 0.02:
		_draw_face(Vector2(rebound * 0.35, rebound), Color(_ink, 0.16), 0.9)
	_draw_face(Vector2.ZERO, Color(_ink, 0.93), 1.0)


func _draw_face(offset: Vector2, ink: Color, weight: float) -> void:
	var rect: Rect2 = Rect2(Vector2(-65, -22) + offset, Vector2(130, 44))
	draw_rect(rect, ink, false, 1.65 * weight)
	draw_rect(rect.grow(-3.2), Color(ink, ink.a * 0.65), false, 0.65 * weight)
	var label: String = {"approve": "SPRZEDANO", "reject": "ODMOWA", "seize": "ZATRZYMANO"}.get(str(impression.get("kind", "approve")), "SPRZEDANO")
	var width: float = FACE_FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_string(FACE_FONT, offset + Vector2(-width * 0.5, 0.8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ink)
	var date: String = "15.II.1982  /  PZ-81"
	width = DATE_FONT.get_string_size(date, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
	draw_line(offset + Vector2(-52, 5), offset + Vector2(52, 5), Color(ink, ink.a * 0.70), 0.7 * weight)
	draw_string(DATE_FONT, offset + Vector2(-width * 0.5, 15), date, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, ink)
