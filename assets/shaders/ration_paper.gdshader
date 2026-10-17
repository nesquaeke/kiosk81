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
uniform float bend_amount : hint_range(0.0, 1.0) = 0.0;

float grain_hash(vec2 value) {
	return fract(sin(dot(value, vec2(127.1, 311.7)) + sheet_seed) * 43758.5453);
}

void vertex() {
	// A tessellated, physically scaled sheet: the shallow held-paper curl is
	// zero while cutting on a table, so tool and printed coordinates agree.
	vec2 p = vec2(back_face ? 1.0 - UV.x : UV.x, UV.y);
	float curl = pow(abs(p.x - 0.5) * 2.0, 3.0) * 0.0022;
	float fold = sin(p.y * 3.14159265) * sin(p.x * 6.2831853) * 0.00055;
	VERTEX.z += (back_face ? -1.0 : 1.0) * (curl + fold) * bend_amount;
	// A pasted alteration has a raised paper edge, not just a painted label.
	if (quota_patch && !back_face) {
		vec2 q = p * vec2(640.0, 400.0);
		float patch = smoothstep(282.0, 287.0, q.x) * (1.0 - smoothstep(420.0, 424.0, q.x))
			* smoothstep(206.0, 210.0, q.y) * (1.0 - smoothstep(240.0, 245.0, q.y));
		VERTEX.z += patch * (0.00032 + pow(clamp((q.x - 285.0) / 137.0, 0.0, 1.0), 5.0) * 0.00048);
	}
}

void fragment() {
	vec2 p = vec2(back_face ? 1.0 - UV.x : UV.x, UV.y);
	if (p.y > 285.0 / 400.0 && p.y < 375.0 / 400.0) {
		if (missing.x > 0.5 && p.x > 30.0 / 640.0 && p.x < 210.0 / 640.0) discard;
		if (missing.y > 0.5 && p.x > 225.0 / 640.0 && p.x < 405.0 / 640.0) discard;
		if (missing.z > 0.5 && p.x > 420.0 / 640.0 && p.x < 600.0 / 640.0) discard;
	}
	// One front-coordinate mask opens the same physical slit on both sides.
	// It contains all recorded paths and does not approximate their lengths
	// with a progress bar or reveal a whole coupon after one short snip.
	float incision = has_incisions ? texture(incision_texture, p).r : 0.0;
	if (incision > 0.48) discard;
	vec4 ink = texture(paper_texture, UV);
	if (ink.a < 0.5) discard;

	vec2 millimetres = p * physical_size * 1000.0;
	float grain = grain_hash(floor(millimetres * 12.0));
	float fibres = grain_hash(vec2(floor(millimetres.x * 2.0), floor(millimetres.y * 28.0)));
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
	float rubbed_edge = (1.0 - smoothstep(0.0005, 0.006, edge)) * wear;
	float fold = exp(-abs(p.x - 0.5) * 330.0);
	float cross_fold = exp(-abs(p.y - 0.612) * 330.0) * wear;
	float lip = smoothstep(0.05, 0.40, incision);
	vec3 paper = ink.rgb * (0.982 + grain * 0.024 + fibres * 0.008 - rubbed_edge * 0.045);
	ALBEDO = mix(paper, vec3(0.63, 0.53, 0.37), lip * 0.22);
	ROUGHNESS = clamp(0.89 + grain * 0.075 + fibres * 0.025, 0.0, 1.0);
	SPECULAR = 0.18;
	NORMAL_MAP = vec3(0.5 + (grain - 0.5) * 0.13 + sign(p.x - 0.5) * fold * 0.10,
		0.5 + (fibres - 0.5) * 0.11 + sign(p.y - 0.612) * cross_fold * 0.075, 1.0);
	NORMAL_MAP_DEPTH = 0.22;
	BACKLIGHT = ink.rgb * 0.035;
}
