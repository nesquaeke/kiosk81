shader_type spatial;
render_mode cull_disabled;

uniform vec3 paper_tint : source_color = vec3(0.78, 0.72, 0.60);
uniform float corner_lift = 1.0;
uniform bool vertex_tint = false;
uniform float bend_amount : hint_range(0.0, 1.0) = 0.0;


float sheet_lift(vec2 p) {
	float upper_left = pow(max(0.0, 1.0 - p.x / 0.055 - p.y / 0.075), 2.0) * 0.0035;
	float upper_right = pow(max(0.0, 1.0 - (1.0 - p.x) / 0.065 - p.y / 0.09), 2.0) * 0.007;
	float lower_right = pow(max(0.0, 1.0 - (1.0 - p.x) / 0.035 - (1.0 - p.y) / 0.055), 2.0) * 0.002;
	return (upper_left + upper_right + lower_right) * corner_lift;
}

void vertex() {
	vec2 p = vec2(VERTEX.x / 0.36 + 0.5, 0.5 - VERTEX.y / 0.225);
	float curl = pow(abs(p.x - 0.5) * 2.0, 3.0) * 0.0022;
	float fold = sin(p.y * 3.14159265) * sin(p.x * 6.2831853) * 0.00055;
	float dogear = pow(max(0.0, 1.0 - (1.0 - p.x) / 0.065 - p.y / 0.09), 2.0) * corner_lift;
	VERTEX.x -= dogear * 0.008;
	VERTEX.y -= dogear * 0.007;
	VERTEX.z += (curl + fold) * bend_amount + sheet_lift(p);
}

void fragment() {
	ALBEDO = vertex_tint ? COLOR.rgb : paper_tint;
	ROUGHNESS = 0.97;
	SPECULAR = 0.12;
}
