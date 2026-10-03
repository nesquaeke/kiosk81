// Lit world material with the lo-fi treatment (affine mapping + vertex jitter).
// Grey-box version: flat colour x grime texture, optional tile/ruled lines.
// With box_uv on, texture coordinates are object-space metres projected along the
// dominant normal axis, so every grey box gets the same texel size.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://assets/shaders/lofi_common.gdshaderinc"

uniform vec4 albedo : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform sampler2D grime_texture : hint_default_white, filter_nearest_mipmap, repeat_enable;
uniform float grime : hint_range(0.0, 1.0) = 0.35;
uniform float grime_density = 0.4;   // texture repeats per metre (128 px -> ~2 cm texels)
uniform bool box_uv = true;
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
// Tile or ruled lines (lines per metre on each axis; 0 = none); they make affine wobble visible.
uniform vec2 line_scale = vec2(0.0, 0.0);
uniform float line_width : hint_range(0.0, 0.2) = 0.0;
uniform vec4 line_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;

varying vec3 v_affine;

vec2 planar_metres(vec3 v, vec3 n) {
	vec3 a = abs(n);
	if (a.x >= a.y && a.x >= a.z) {
		return v.zy;
	}
	if (a.y >= a.z) {
		return v.xz;
	}
	return v.xy;
}

void vertex() {
	if (box_uv) {
		UV = planar_metres(VERTEX, NORMAL);
	}
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	clip = lofi_snap(clip);
	POSITION = clip;
	v_affine = vec3(UV * clip.w, clip.w);
}

void fragment() {
	vec2 uv = lofi_affine_uv(UV, v_affine.xy, v_affine.z);
	float g = texture(grime_texture, uv * grime_density).r;
	vec3 base = albedo.rgb * mix(1.0, 0.55 + 0.7 * g, grime);
	if (line_width > 0.0) {
		vec2 f = fract(uv * line_scale);
		vec2 has_axis = step(0.0001, line_scale);
		float on_line = max(step(1.0 - line_width, f.x) * has_axis.x, step(1.0 - line_width, f.y) * has_axis.y);
		base = mix(base, line_color.rgb, on_line);
	}
	ALBEDO = base;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	EMISSION = emission_color.rgb * emission_energy;
}
