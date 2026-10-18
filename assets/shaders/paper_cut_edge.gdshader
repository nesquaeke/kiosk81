shader_type spatial;
render_mode cull_disabled;

uniform vec3 paper_tint : source_color = vec3(0.78, 0.72, 0.60);
uniform float corner_lift = 1.0;
uniform bool vertex_tint = false;
uniform float bend_amount : hint_range(0.0, 1.0) = 0.0;
uniform float bend_stiffness : hint_range(0.4, 2.0) = 1.0;
uniform float sheet_half_thickness = 0.00016;
uniform vec3 stock_tint : source_color = vec3(1.0);
uniform float fibre_strength : hint_range(0.0, 2.0) = 1.0;
uniform float sheet_seed = 0.0;
varying vec3 edge_local_position;


float sheet_lift(vec2 p) {
	float upper_left = pow(max(0.0, 1.0 - p.x / 0.055 - p.y / 0.075), 2.0) * 0.0035;
	float upper_right = pow(max(0.0, 1.0 - (1.0 - p.x) / 0.065 - p.y / 0.09), 2.0) * 0.007;
	float lower_right = pow(max(0.0, 1.0 - (1.0 - p.x) / 0.035 - (1.0 - p.y) / 0.055), 2.0) * 0.002;
	return (upper_left + upper_right + lower_right) * corner_lift;
}

void vertex() {
	vec2 p = vec2(VERTEX.x / 0.36 + 0.5, 0.5 - VERTEX.y / 0.225);
	// Base cut meshes are shared at +/-0.16 mm. Scale only their depth; the
	// physical path lengths, raised lips and fibre positions remain in metres.
	VERTEX.z *= sheet_half_thickness / 0.00016;
	float curl = pow(abs(p.x - 0.5) * 2.0, 3.0) * 0.0022;
	float fold = sin(p.y * 3.14159265) * sin(p.x * 6.2831853) * 0.00055;
	float dogear = pow(max(0.0, 1.0 - (1.0 - p.x) / 0.065 - p.y / 0.09), 2.0) * corner_lift;
	VERTEX.x -= dogear * 0.008;
	VERTEX.y -= dogear * 0.007;
	VERTEX.z += (curl + fold) * bend_amount / max(0.4, bend_stiffness) + sheet_lift(p);
	edge_local_position = VERTEX;
}

void fragment() {
	float fibre = fract(sin(dot(floor(edge_local_position.xy * vec2(5000.0, 38000.0)),
		vec2(127.1, 311.7)) + sheet_seed) * 43758.5453);
	// Cut fibres are a lighter fresh core, rather than a dark drawn outline.
	vec3 core = vertex_tint ? mix(COLOR.rgb, vec3(0.89, 0.84, 0.72), 0.28) : paper_tint;
	ALBEDO = core * stock_tint * (0.97 + fibre * 0.04 * fibre_strength);
	ROUGHNESS = 0.97;
	SPECULAR = 0.12;
}
