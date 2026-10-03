// Full-screen lo-fi pass over the low-resolution 3D image (Gorsel Hedef, section 6).
// Order: lens bend -> edge colour fringing -> grain -> vignette -> 32-level colour + 4x4 Bayer.
// The UI and the document view are drawn above this, at full resolution, untouched.
shader_type canvas_item;

uniform vec2 source_size = vec2(960.0, 540.0);
uniform float color_levels = 32.0;
uniform float dither : hint_range(0.0, 1.0) = 1.0;
uniform float barrel : hint_range(0.0, 0.3) = 0.04;
uniform float vignette : hint_range(0.0, 1.0) = 0.35;
uniform float chroma_px : hint_range(0.0, 1.0) = 1.0;
uniform float grain : hint_range(0.0, 0.3) = 0.05;

const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0
);

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 bend(vec2 uv) {
	vec2 c = uv - 0.5;
	float r2 = dot(c, c);
	// Normalised so the corners stay on the corners.
	return 0.5 + c * (1.0 + barrel * r2) / (1.0 + barrel * 0.5);
}

void fragment() {
	vec2 uv = bend(UV);
	vec2 from_center = uv - 0.5;
	float edge = clamp(dot(from_center, from_center) * 2.0, 0.0, 1.0);  // 0 centre, 1 corner
	vec2 fringe = normalize(from_center + 1e-5) * chroma_px * edge / source_size;
	vec3 col;
	col.r = texture(TEXTURE, uv + fringe).r;
	col.g = texture(TEXTURE, uv).g;
	col.b = texture(TEXTURE, uv - fringe).b;

	vec2 pixel = floor(UV * source_size);
	col += (hash12(pixel + floor(TIME * 24.0) * 37.0) - 0.5) * grain;
	col *= 1.0 - vignette * smoothstep(0.25, 1.0, edge);

	int index = int(mod(pixel.x, 4.0)) + int(mod(pixel.y, 4.0)) * 4;
	float threshold = mix(0.5, (BAYER[index] + 0.5) / 16.0, dither);
	float steps = max(color_levels - 1.0, 1.0);
	col = floor(clamp(col, 0.0, 1.0) * steps + threshold) / steps;
	COLOR = vec4(col, 1.0);
}
