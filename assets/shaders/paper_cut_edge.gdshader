shader_type spatial;
render_mode cull_disabled;

uniform vec3 paper_tint : source_color = vec3(0.78, 0.72, 0.60);
uniform bool vertex_tint = false;
uniform float bend_amount : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	vec2 p = vec2(VERTEX.x / 0.36 + 0.5, 0.5 - VERTEX.y / 0.225);
	float curl = pow(abs(p.x - 0.5) * 2.0, 3.0) * 0.0022;
	float fold = sin(p.y * 3.14159265) * sin(p.x * 6.2831853) * 0.00055;
	VERTEX.z += (curl + fold) * bend_amount;
}

void fragment() {
	ALBEDO = vertex_tint ? COLOR.rgb : paper_tint;
	ROUGHNESS = 0.97;
	SPECULAR = 0.12;
}
