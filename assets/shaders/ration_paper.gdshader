shader_type spatial;
render_mode cull_back;

uniform sampler2D paper_texture : source_color, filter_linear;
uniform vec3 missing = vec3(0.0);
uniform bool back_face = false;
uniform float wear : hint_range(0.0, 1.0) = 0.15;
uniform float sheet_seed = 0.0;

float grain_hash(vec2 value) {
	return fract(sin(dot(value, vec2(127.1, 311.7)) + sheet_seed) * 43758.5453);
}

void fragment() {
	vec2 p = vec2(back_face ? 1.0 - UV.x : UV.x, UV.y);
	if (p.y > 285.0 / 400.0 && p.y < 375.0 / 400.0) {
		if (missing.x > 0.5 && p.x > 30.0 / 640.0 && p.x < 210.0 / 640.0) discard;
		if (missing.y > 0.5 && p.x > 225.0 / 640.0 && p.x < 405.0 / 640.0) discard;
		if (missing.z > 0.5 && p.x > 420.0 / 640.0 && p.x < 600.0 / 640.0) discard;
	}
	vec4 ink = texture(paper_texture, UV);
	if (ink.a < 0.5) discard;
	// Tiny fibre colour variation and a shallow crease change with the light.
	// Geometry stays planar so printed cutting coordinates remain exact.
	float grain = grain_hash(floor(p * vec2(1152.0, 720.0)));
	float edge = min(min(p.x, 1.0 - p.x), min(p.y, 1.0 - p.y));
	float rubbed_edge = (1.0 - smoothstep(0.002, 0.027, edge)) * wear;
	float fold = exp(-abs(p.x - 0.5) * 330.0);
	float cross_fold = exp(-abs(p.y - 0.612) * 330.0) * wear;
	ALBEDO = ink.rgb * (0.985 + grain * 0.025 - rubbed_edge * 0.055);
	EMISSION = ink.rgb * 0.06;
	ROUGHNESS = 0.91 + grain * 0.07;
	SPECULAR = 0.12;
	NORMAL_MAP = vec3(0.5 + sign(p.x - 0.5) * fold * 0.09,
		0.5 + sign(p.y - 0.612) * cross_fold * 0.07, 1.0);
	NORMAL_MAP_DEPTH = 0.18;
}
