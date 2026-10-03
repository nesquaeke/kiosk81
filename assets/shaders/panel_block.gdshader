// Prefab panel block (wielka plyta) facade for distant buildings.
// Windows and panel seams come from object-space position, so any box size works.
// Some windows are lit: warm yellow dots (Gorsel Hedef, light language).
shader_type spatial;
render_mode cull_back, diffuse_burley;

#include "res://assets/shaders/lofi_common.gdshaderinc"

uniform vec4 wall_color : source_color = vec4(0.42, 0.41, 0.44, 1.0);
uniform vec4 seam_color : source_color = vec4(0.25, 0.24, 0.27, 1.0);
uniform vec4 glass_color : source_color = vec4(0.06, 0.06, 0.08, 1.0);
uniform vec4 lit_color : source_color = vec4(0.93, 0.70, 0.36, 1.0);
uniform float lit_energy = 1.6;
uniform float lit_ratio : hint_range(0.0, 1.0) = 0.3;
uniform vec2 cell_size = vec2(3.0, 2.8);   // metres per window column / storey
uniform vec2 window_size = vec2(1.5, 1.35);
uniform float ground_floor = 2.8;          // no windows below this height
uniform float seed = 1.0;

varying vec4 v_affine;   // xyz = local position * w, w = w
varying vec3 v_local;
varying vec3 v_normal_local;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
	v_local = VERTEX;
	v_normal_local = NORMAL;
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	clip = lofi_snap(clip);
	POSITION = clip;
	v_affine = vec4(VERTEX * clip.w, clip.w);
}

void fragment() {
	vec3 affine_local = v_affine.xyz / max(v_affine.w, 0.0001);
	vec3 p = mix(v_local, affine_local, clamp(lofi_affine * lofi_weight, 0.0, 1.0));
	// Facade coordinates: horizontal axis depends on which way the face points.
	vec2 facade = abs(v_normal_local.z) > 0.5 ? vec2(p.x, p.y) : vec2(p.z, p.y);
	float height = p.y + 1000.0;  // keep positive for fract/floor
	vec2 cell = floor(vec2(facade.x + 1000.0, height) / cell_size);
	vec2 in_cell = fract(vec2(facade.x + 1000.0, height) / cell_size) * cell_size;
	vec2 margin = (cell_size - window_size) * 0.5;
	bool is_window = all(greaterThan(in_cell, margin)) && all(lessThan(in_cell, margin + window_size));
	bool is_roof = abs(v_normal_local.y) > 0.5;
	vec3 col = wall_color.rgb;
	// Horizontal seam at every storey, vertical seam every two columns.
	if (in_cell.y < 0.08 || (mod(cell.x, 2.0) < 0.5 && in_cell.x < 0.05)) {
		col = seam_color.rgb;
	}
	vec3 emit = vec3(0.0);
	if (is_window && !is_roof && p.y > ground_floor) {
		col = glass_color.rgb;
		if (hash12(cell + seed * 17.0 + sign(v_normal_local.z + v_normal_local.x) * 101.0) < lit_ratio) {
			emit = lit_color.rgb * lit_energy;
			col = lit_color.rgb * 0.3;
		}
	}
	ALBEDO = col;
	ROUGHNESS = 0.95;
	EMISSION = emit;
}
