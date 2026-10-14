shader_type spatial;
render_mode cull_back;

uniform sampler2D paper_texture : source_color, filter_linear;
uniform vec3 missing = vec3(0.0);
uniform bool back_face = false;

void fragment() {
	vec2 p = vec2(back_face ? 1.0 - UV.x : UV.x, UV.y);
	if (p.y > 285.0 / 400.0 && p.y < 375.0 / 400.0) {
		if (missing.x > 0.5 && p.x > 30.0 / 640.0 && p.x < 210.0 / 640.0) discard;
		if (missing.y > 0.5 && p.x > 225.0 / 640.0 && p.x < 405.0 / 640.0) discard;
		if (missing.z > 0.5 && p.x > 420.0 / 640.0 && p.x < 600.0 / 640.0) discard;
	}
	vec4 ink = texture(paper_texture, UV);
	if (ink.a < 0.5) discard;
	ALBEDO = ink.rgb;
	EMISSION = ink.rgb * 0.06;
	ROUGHNESS = 0.95;
}
