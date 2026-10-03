// Shared lo-fi helpers for world (spatial) shaders. Gorsel Hedef, section 9.
// The global values are set by LoFiView from the active LoFiProfile.
// A material's own `lofi_weight` scales them: 1 = world, 0 = exempt
// (faces, hands, documents, text that gameplay needs).

global uniform float lofi_affine;      // 0..1 affine texture mix
global uniform vec2 lofi_snap_grid;    // vertex snap grid in pixels; 0 = off

uniform float lofi_weight : hint_range(0.0, 1.0) = 1.0;

// Clip-space vertex snapping ("vertex jitter").
vec4 lofi_snap(vec4 clip) {
	if (lofi_weight <= 0.0 || lofi_snap_grid.x <= 0.0 || clip.w <= 0.0001) {
		return clip;
	}
	vec2 half_grid = lofi_snap_grid * 0.5;
	vec2 ndc = clip.xy / clip.w;
	vec2 snapped = round(ndc * half_grid) / half_grid;
	clip.xy = mix(ndc, snapped, lofi_weight) * clip.w;
	return clip;
}

// Mix between perspective-correct and affine coordinates.
// `affine_numerator` = coord * w and `affine_w` = w, both interpolated as varyings.
vec2 lofi_affine_uv(vec2 perspective_uv, vec2 affine_numerator, float affine_w) {
	vec2 affine_uv = affine_numerator / max(affine_w, 0.0001);
	return mix(perspective_uv, affine_uv, clamp(lofi_affine * lofi_weight, 0.0, 1.0));
}
