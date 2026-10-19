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
uniform float contact_tilt = 0.0;
uniform bool wet_mask = false;
uniform float mark_wetness = 0.0;
uniform bool finger_clip = false;
uniform vec2 finger_from = vec2(0.0);
uniform vec2 finger_to = vec2(0.0);
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
    float tilt_side = contact_tilt >= 0.0 ? smoothstep(-65., 65., ink_position.x) : 1. - smoothstep(-65., 65., ink_position.x);
    float tilt_lift = abs(contact_tilt) / .30 * tilt_side * .48;
    float voids = dropout + shoulder + tilt_lift;
    float coverage = smoothstep(voids, voids + .12, fibre);
    float mottling = mix(.66, 1., rubber);
    float finger = 1.;
    if (finger_clip) {
        vec2 path = finger_to - finger_from;
        float along = clamp(dot(ink_position - finger_from, path) / max(dot(path, path), .0001), 0., 1.);
        float distance = length(ink_position - finger_from - path * along);
        finger = 1. - smoothstep(4.8, 6., distance);
    }
    float alpha = ink.a * ink_density * coverage * mottling * finger;
    COLOR = wet_mask ? vec4(vec3(1.), alpha * mark_wetness) : vec4(ink.rgb, alpha);
}
"""

static var _ink_shader: Shader
var impression: Dictionary = {}
var features: Dictionary = {}
var _ink: Color = Color("314f43")
# A separate transparent viewport can reuse precisely this geometry and grain.
# Its only dynamic property is the game's explicit, pausable clock.
var wet_mask: bool = false
var current_wetness: float = 0.0
var _game_time: float = 0.0
var _rub_passes: Array[Control] = []


static func ink_features(mark: Dictionary) -> Dictionary:
	var pressure: float = clampf(float(mark.get("pressure", 0.65)), 0, 1)
	var speed: float = clampf(float(mark.get("speed", 0.35)), 0, 5)
	var dwell: float = clampf(float(mark.get("dwell", 0.15)), 0, 15)
	var wet: float = 1.0 - exp(-dwell * 2.0)
	var load: float = clampf(float(mark.get("ink_load", 1.0)), 0.0, 1.0)
	var tilt: float = clampf(float(mark.get("tilt", 0.0)), -0.30, 0.30)
	var tilt_amount: float = absf(tilt) / 0.30
	var impact: float = clampf((speed - 0.4) / 1.8, 0, 1)
	var direction_data: Array = mark.get("smudge_direction", [0.0, 0.0])
	var direction: Vector2 = Vector2(float(direction_data[0]), float(direction_data[1])) if direction_data.size() >= 2 else Vector2.ZERO
	if direction.length_squared() > 0.00001:
		direction = direction.normalized()
	var smudge: Vector2 = direction * clampf(float(mark.get("smudge", 0)), 0, 0.02) * (640.0 / 0.36)
	return {
		"density": clampf((0.32 + pressure * 0.54 + wet * 0.18) * load * (1.0 - tilt_amount * 0.16), 0, 1),
		"dropout": clampf(0.43 * (1 - pressure) + impact * 0.12 - wet * 0.08 + (1.0 - load) * 0.30 + tilt_amount * 0.08, 0.02, 0.90),
		"spread": 0.12 + pressure * 0.22 + wet * 0.42,
		"impact_offset": impact * 1.1,
		"smudge_pixels": smudge,
		"pressure": pressure,
		"ink_load": load,
		"tilt": tilt,
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
	ink_material.set_shader_parameter("contact_tilt", features["tilt"])
	ink_material.set_shader_parameter("wet_mask", wet_mask)
	material = ink_material
	_rebuild_rub_transfers()
	set_game_time(_game_time)
	queue_redraw()


func set_game_time(now: float) -> bool:
	var previous: float = current_wetness
	_game_time = now
	current_wetness = StampInkState.wetness(impression, now) if wet_mask else 0.0
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("mark_wetness", current_wetness)
	for node: Control in _rub_passes:
		(node.material as ShaderMaterial).set_shader_parameter("mark_wetness", current_wetness)
	return not is_equal_approx(previous, current_wetness)


static func rub_features(rub: Dictionary) -> Dictionary:
	var start: Variant = rub.get("from", [])
	var end: Variant = rub.get("to", [])
	if not start is Array or not end is Array or start.size() != 2 or end.size() != 2:
		return {}
	for point: Array in [start, end]:
		for number: Variant in point:
			if not (number is float or number is int) or not is_finite(float(number)):
				return {}
	var from: Vector2 = Vector2(float(start[0]), float(start[1]))
	var to: Vector2 = Vector2(float(end[0]), float(end[1]))
	var delta: Vector2 = to - from
	if delta.length_squared() < 0.0025 or delta.length() > 800.0:
		return {}
	var footprint: Rect2 = Rect2(-71, -28, 142, 56)
	var touches: bool = footprint.has_point(from) or footprint.has_point(to)
	var corners: Array[Vector2] = [footprint.position, Vector2(footprint.end.x, footprint.position.y), footprint.end, Vector2(footprint.position.x, footprint.end.y)]
	for edge: int in 4:
		if Geometry2D.segment_intersects_segment(from, to, corners[edge], corners[(edge + 1) % 4]) != null:
			touches = true
	var wet: float = clampf(float(rub.get("wetness", 0.0)), 0.0, 1.0)
	if not touches or wet <= 0.0 or not is_finite(wet):
		return {}
	return {"from": from, "to": to, "delta": delta, "wetness": wet, "radius": 6.0}


func _rebuild_rub_transfers() -> void:
	for node: Control in _rub_passes:
		node.free()
	_rub_passes.clear()
	var rubs: Array = impression.get("rubs", [])
	for index: int in mini(rubs.size(), 32):
		if not rubs[index] is Dictionary:
			continue
		var rub: Dictionary = rub_features(rubs[index])
		if rub.is_empty():
			continue
		# Only the actual touched portion of letters/rules is copied. The
		# original impression remains in place; dried residue never disappears.
		for step: int in range(1, 7):
			var fraction: float = float(step) / 6.0
			var transfer: RubTransfer = RubTransfer.new()
			transfer.position = (rub["delta"] as Vector2) * fraction
			transfer.impression = impression
			transfer.ink = Color(_ink, float(rub["wetness"]) * (0.26 - fraction * 0.18))
			transfer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var ink_material: ShaderMaterial = (material as ShaderMaterial).duplicate() as ShaderMaterial
			ink_material.set_shader_parameter("finger_clip", true)
			ink_material.set_shader_parameter("finger_from", rub["from"])
			ink_material.set_shader_parameter("finger_to", rub["to"])
			transfer.material = ink_material
			add_child(transfer)
			_rub_passes.append(transfer)


class RubTransfer extends Control:
	var impression: Dictionary = {}
	var ink: Color = Color.TRANSPARENT

	func _draw() -> void:
		RationStampImpression.draw_face(self, impression, Vector2.ZERO, ink, 1.0)


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
	draw_face(self, impression, offset, ink, weight)


static func draw_face(target: CanvasItem, mark: Dictionary, offset: Vector2, ink: Color, weight: float) -> void:
	var rect: Rect2 = Rect2(Vector2(-65, -22) + offset, Vector2(130, 44))
	target.draw_rect(rect, ink, false, 1.65 * weight)
	target.draw_rect(rect.grow(-3.2), Color(ink, ink.a * 0.65), false, 0.65 * weight)
	var label: String = {"approve": "SPRZEDANO", "reject": "ODMOWA", "seize": "ZATRZYMANO"}.get(str(mark.get("kind", "approve")), "SPRZEDANO")
	var width: float = FACE_FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	target.draw_string(FACE_FONT, offset + Vector2(-width * 0.5, 0.8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ink)
	var date: String = "15.II.1982  /  PZ-81"
	width = DATE_FONT.get_string_size(date, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
	target.draw_line(offset + Vector2(-52, 5), offset + Vector2(52, 5), Color(ink, ink.a * 0.70), 0.7 * weight)
	target.draw_string(DATE_FONT, offset + Vector2(-width * 0.5, 15), date, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, ink)
