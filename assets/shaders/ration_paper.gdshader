shader_type spatial;
render_mode cull_back;

uniform sampler2D paper_texture : source_color, filter_linear;
uniform sampler2D incision_texture : filter_linear, repeat_disable;
uniform vec3 missing = vec3(0.0);
uniform bool back_face = false;
uniform bool has_incisions = false;
uniform bool quota_patch = false;
uniform vec2 physical_size = vec2(0.36, 0.225);
uniform float wear : hint_range(0.0, 1.0) = 0.15;
uniform float sheet_seed = 0.0;
uniform float corner_lift = 1.0;
uniform float bend_amount : hint_range(0.0, 1.0) = 0.0;
// The same material coordinates survive a coupon crop and a physical flip.
// xy = canonical front UV origin, zw = canonical front UV extent.
uniform vec4 sheet_uv_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec3 stock_tint : source_color = vec3(1.0);
uniform float fibre_strength : hint_range(0.0, 2.0) = 1.0;
uniform float grain_scale : hint_range(0.25, 2.0) = 1.0;
uniform float bend_stiffness : hint_range(0.4, 2.0) = 1.0;
uniform float sheet_half_thickness = 0.00016;
uniform float inspection_backlight : hint_range(0.0, 1.0) = 0.0;
// Direction from the sheet towards the inspection lamp, in card-root space.
uniform vec3 inspection_light_direction_local = vec3(0.0, 0.0, 1.0);
varying vec3 sheet_normal_local;

float grain_hash(vec2 value) {
	return fract(sin(dot(value, vec2(127.1, 311.7)) + sheet_seed) * 43758.5453);
}


float soft_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 along = fract(p);
	along = along * along * (3.0 - 2.0 * along);
	return mix(mix(grain_hash(cell), grain_hash(cell + vec2(1.0, 0.0)), along.x),
		mix(grain_hash(cell + vec2(0.0, 1.0)), grain_hash(cell + vec2(1.0)), along.x), along.y);
}


float patch_mask(vec2 sheet_p, float softness) {
	vec2 q = sheet_p * vec2(640.0, 400.0);
	return smoothstep(282.0 - softness, 287.0 + softness, q.x)
		* (1.0 - smoothstep(420.0 - softness, 424.0 + softness, q.x))
		* smoothstep(206.0 - softness, 210.0 + softness, q.y)
		* (1.0 - smoothstep(240.0 - softness, 245.0 + softness, q.y));
}


float sheet_lift(vec2 p) {
	float upper_left = pow(max(0.0, 1.0 - p.x / 0.055 - p.y / 0.075), 2.0) * 0.0035;
	float upper_right = pow(max(0.0, 1.0 - (1.0 - p.x) / 0.065 - p.y / 0.09), 2.0) * 0.007;
	float lower_right = pow(max(0.0, 1.0 - (1.0 - p.x) / 0.035 - (1.0 - p.y) / 0.055), 2.0) * 0.002;
	return (upper_left + upper_right + lower_right) * corner_lift;
}


float paper_height(vec2 p) {
	float curl = pow(abs(p.x - 0.5) * 2.0, 3.0) * 0.0022;
	float fold = sin(p.y * 3.14159265) * sin(p.x * 6.2831853) * 0.00055;
	return (curl + fold) * bend_amount / max(0.4, bend_stiffness) + sheet_lift(p);
}


void vertex() {
	// A tessellated, physically scaled sheet: the shallow held-paper curl is
	// zero while cutting on a table, so tool and printed coordinates agree.
	vec2 p = vec2(back_face ? 1.0 - UV.x : UV.x, UV.y);
	float dogear = pow(max(0.0, 1.0 - (1.0 - p.x) / 0.065 - p.y / 0.09), 2.0) * corner_lift;
	VERTEX.x += (back_face ? 1.0 : -1.0) * dogear * 0.008;
	VERTEX.y -= dogear * 0.007;
	VERTEX.z += (back_face ? -1.0 : 1.0) * paper_height(p);
	float du = (paper_height(p + vec2(0.001, 0.0)) - paper_height(p - vec2(0.001, 0.0))) / (0.002 * physical_size.x);
	float dv = (paper_height(p + vec2(0.0, 0.001)) - paper_height(p - vec2(0.0, 0.001))) / (0.002 * physical_size.y);
	NORMAL = normalize(vec3(-du, back_face ? -dv : dv, 1.0));
	sheet_normal_local = normalize(vec3(-du, dv, 1.0));
	// A pasted alteration has a raised paper edge, not just a painted label.
	if (quota_patch && !back_face) {
		vec2 sheet_p = sheet_uv_rect.xy + p * sheet_uv_rect.zw;
		vec2 q = sheet_p * vec2(640.0, 400.0);
		float patch = patch_mask(sheet_p, 0.0);
		VERTEX.z += patch * (0.00032 + pow(clamp((q.x - 285.0) / 137.0, 0.0, 1.0), 5.0) * 0.00048);
	}
}


float line_mark(vec2 point, vec2 start, vec2 end, float width) {
	vec2 segment = end - start;
	float amount = clamp(dot(point - start, segment) / dot(segment, segment), 0.0, 1.0);
	return 1.0 - smoothstep(width, width + 0.65, length(point - start - segment * amount));
}


float watermark(vec2 millimetres) {
	// An invented paper-mill rosette, with an asymmetric stem to make its
	// physical reverse unmistakable. It is not an authenticity classification.
	float radius = length(millimetres);
	float angle = atan(millimetres.y, millimetres.x);
	float outer = 1.0 - smoothstep(0.38, 1.0, abs(radius - (25.0 + sin(angle * 11.0) * 1.65)));
	float inner = 1.0 - smoothstep(0.28, 0.90, abs(radius - 20.5));
	float stem = line_mark(millimetres, vec2(-5.0, -12.0), vec2(-5.0, 12.0), 0.65);
	float branch_a = line_mark(millimetres, vec2(-5.0, -3.0), vec2(9.0, -10.0), 0.65);
	float branch_b = line_mark(millimetres, vec2(-5.0, 4.0), vec2(7.0, 11.0), 0.65);
	float branch_c = line_mark(millimetres, vec2(-5.0, 2.0), vec2(-12.0, -3.0), 0.65);
	return clamp(max(outer * 0.9, max(inner * 0.55, max(stem, max(branch_a, max(branch_b, branch_c))))), 0.0, 1.0);
}


void fragment() {
	vec2 p = vec2(back_face ? 1.0 - UV.x : UV.x, UV.y);
	vec2 sheet_p = sheet_uv_rect.xy + p * sheet_uv_rect.zw;
	if (p.y > 285.0 / 400.0 && p.y < 375.0 / 400.0) {
		if (missing.x > 0.5 && p.x > 30.0 / 640.0 && p.x < 210.0 / 640.0) discard;
		if (missing.y > 0.5 && p.x > 225.0 / 640.0 && p.x < 405.0 / 640.0) discard;
		if (missing.z > 0.5 && p.x > 420.0 / 640.0 && p.x < 600.0 / 640.0) discard;
	}
	// One front-coordinate mask opens the same physical slit on both sides.
	// It contains all recorded paths and does not approximate their lengths
	// with a progress bar or reveal a whole coupon after one short snip.
	float incision = has_incisions ? texture(incision_texture, sheet_p).r : 0.0;
	if (incision > 0.48) discard;
	vec4 ink = texture(paper_texture, UV);
	if (ink.a < 0.5) discard;

	vec2 full_size = physical_size / max(sheet_uv_rect.zw, vec2(0.0001));
	vec2 millimetres = sheet_p * full_size * 1000.0;
	float grain = grain_hash(floor(millimetres * 12.0 * grain_scale));
	// Fine short fibres are physically scaled. Their low-frequency envelope
	// prevents the close-up from turning into uniform electronic noise.
	float fibres = soft_noise(millimetres * vec2(0.65, 11.0) * grain_scale);
	float fibre_strands = smoothstep(0.66, 0.86, fibres) * fibre_strength;
	float edge = min(min(p.x * physical_size.x, (1.0 - p.x) * physical_size.x),
		min(p.y * physical_size.y, (1.0 - p.y) * physical_size.y));
	// The silhouette is gently rounded and microscopically ragged rather
	// than a perfectly square image plane. Detail is in world millimetres.
	float corner_radius = 0.0013 + wear * 0.00045;
	vec2 point_metres = p * physical_size;
	vec2 nearest_corner = clamp(point_metres, vec2(corner_radius), physical_size - vec2(corner_radius));
	float corner_distance = length(point_metres - nearest_corner);
	if (corner_distance > corner_radius - (grain - 0.5) * 0.00013) discard;
	if (edge < (grain - 0.45) * 0.00012 * wear) discard;
	// A detached coupon inherits only the old sheet's perimeter wear. Its
	// newly exposed cuts must not acquire a freshly generated aged border.
	float aged_edge = min(min(sheet_p.x * full_size.x, (1.0 - sheet_p.x) * full_size.x),
		min(sheet_p.y * full_size.y, (1.0 - sheet_p.y) * full_size.y));
	float rubbed_edge = (1.0 - smoothstep(0.0005, 0.006, aged_edge)) * wear;
	float fold = exp(-abs(sheet_p.x - 0.5) * 330.0);
	float cross_fold = exp(-abs(sheet_p.y - 0.612) * 330.0) * wear;
	float lip = smoothstep(0.05, 0.40, incision);
	// Broad, quiet handling marks stay below the printed evidence. All dirt
	// derives from the paper seed/wear, never from whether the card is valid.
	float mottling = soft_noise(millimetres * 0.026);
	float moisture = smoothstep(0.61, 0.91, mottling) * wear;
	float edge_discolour = rubbed_edge * (0.6 + soft_noise(millimetres * 0.18) * 0.4);
	vec3 paper = ink.rgb * stock_tint * (0.985 + grain * 0.020 - fibre_strands * 0.020);
	paper *= vec3(1.0 - moisture * 0.055 - edge_discolour * 0.075,
		1.0 - moisture * 0.070 - edge_discolour * 0.092,
		1.0 - moisture * 0.100 - edge_discolour * 0.125);
	// Transmission comes from an explicitly positioned inspection lamp. Tilt
	// matters; the same front-coordinate mark is visible through either face.
	float incidence = pow(clamp(abs(dot(normalize(sheet_normal_local),
		normalize(inspection_light_direction_local + vec3(0.000001)))), 0.0, 1.0), 1.7);
	float thinness = clamp(0.00014 / max(0.0001, sheet_half_thickness * 2.0), 0.18, 1.0);
	float transmission = inspection_backlight * incidence * (0.45 + thinness * 0.55);
	float extra_layer = quota_patch ? patch_mask(sheet_p, 2.0) : 0.0;
	vec2 mark_mm = (sheet_p - vec2(350.0 / 640.0, 225.0 / 400.0)) * full_size * 1000.0;
	float mark = watermark(mark_mm) * (1.0 - extra_layer * 0.94);
	vec3 lit_paper = paper * (1.0 - transmission * mark * 0.26 - extra_layer * transmission * 0.13);
	ALBEDO = mix(lit_paper, vec3(0.74, 0.67, 0.52) * stock_tint, lip * 0.22);
	ROUGHNESS = clamp(0.89 + grain * 0.065 + fibres * fibre_strength * 0.025 - moisture * 0.025, 0.0, 1.0);
	SPECULAR = 0.18;
	NORMAL_MAP = vec3(0.5 + (grain - 0.5) * 0.10 + sign(sheet_p.x - 0.5) * fold * 0.10,
		0.5 + (fibres - 0.5) * fibre_strength * 0.10 + sign(sheet_p.y - 0.612) * cross_fold * 0.075, 1.0);
	NORMAL_MAP_DEPTH = 0.22;
	BACKLIGHT = paper * (0.025 + thinness * 0.025);
	EMISSION = paper * transmission * 0.15 * (1.0 - mark * 0.62) * (1.0 - extra_layer * 0.78);
}
