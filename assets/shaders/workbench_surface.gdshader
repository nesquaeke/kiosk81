shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Coordinates are metres on the mesh, so wear and grain retain their size when
// the workstation camera moves close. No screen-space texture is involved.
uniform vec4 base_color : source_color = vec4(0.25, 0.12, 0.055, 1.0);
uniform int surface_kind = 0; // 0: varnished wood, 1: vulcanised rubber, 2: steel
uniform int grain_axis = 0;
uniform float base_roughness : hint_range(0.0, 1.0) = 0.44;
uniform float metalness : hint_range(0.0, 1.0) = 0.0;
uniform float wear_amount : hint_range(0.0, 1.0) = 0.45;
varying vec3 local_position;
varying vec3 local_normal;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(cell), hash21(cell + vec2(1.0, 0.0)), u.x),
		mix(hash21(cell + vec2(0.0, 1.0)), hash21(cell + vec2(1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	return noise(p) * 0.55 + noise(p * 2.03 + 17.0) * 0.28
		+ noise(p * 4.11 + 31.0) * 0.12 + noise(p * 8.17) * 0.05;
}

void vertex() {
	local_position = VERTEX;
	local_normal = NORMAL;
}

void fragment() {
	vec2 p = local_position.xz;
	if (abs(local_normal.y) < 0.5) {
		p = abs(local_normal.x) > 0.5 ? local_position.zy : local_position.xy;
	}
	if (grain_axis == 1) { p = vec2(local_position.y, local_position.x + local_position.z); }
	float mottling = fbm(p * 11.0 + 9.0);
	float micro = noise(p * 1700.0);
	vec3 tone = base_color.rgb;
	float roughness_value = base_roughness;
	float bump = 0.0;
	if (surface_kind == 0) {
		float plank = floor((p.y + 3.0) / 0.183);
		float plank_offset = hash21(vec2(plank, 4.1));
		// Irregular elongated vessels bend at several scales. Low contrast
		// grain avoids the perfectly parallel bright stripes of a sine wave.
		float drift = (fbm(vec2(p.x * 1.7 + plank_offset, p.y * 7.0)) - 0.5) * 0.025;
		vec2 wood = vec2(p.x * 2.8 + plank_offset * 3.0, (p.y + drift) * 210.0);
		float growth = fbm(wood);
		float fibres = noise(vec2(p.x * 23.0 + plank_offset * 7.0, (p.y + drift) * 1850.0));
		float pores = smoothstep(0.68, 0.91, fibres);
		float grain = (growth - 0.5) * 0.12 - pores * 0.035;
		float seam = 1.0 - smoothstep(0.0005, 0.0015, min(mod(p.y + 3.0, 0.183), 0.183 - mod(p.y + 3.0, 0.183)));
		if (grain_axis == 1) { seam = 0.0; }
		// Fine longitudinal scratches in the varnish; broad handling wear alters
		// roughness before it alters colour, as on a repeatedly cleaned desk.
		float scratches = pow(noise(vec2(p.x * 18.0, p.y * 1150.0)), 24.0)
			* smoothstep(0.35, 0.75, noise(p * 37.0));
		float handling = smoothstep(0.31, 0.72, mottling) * wear_amount;
		tone *= 0.96 + grain + (mottling - 0.5) * 0.045 + (plank_offset - 0.5) * 0.045;
		tone = mix(tone, tone * 0.68, seam * 0.38);
		tone += vec3(0.028, 0.022, 0.015) * scratches * wear_amount;
		roughness_value += handling * 0.10 + pores * 0.035 + scratches * 0.04;
		bump = (fibres - 0.5) * 0.013 + seam * 0.025;
	} else if (surface_kind == 1) {
		vec2 cells = abs(fract(p * 420.0) - 0.5);
		float pebbled = smoothstep(0.46, 0.10, max(cells.x, cells.y));
		float polished = smoothstep(0.34, 0.78, mottling);
		tone *= 0.91 + mottling * 0.12 + micro * 0.035;
		roughness_value = base_roughness - polished * 0.11 + pebbled * 0.025;
		bump = (pebbled - 0.5) * 0.028;
	} else {
		float brushed = noise(vec2(p.x * 50.0, p.y * 2600.0));
		float oxidation = smoothstep(0.62, 0.85, mottling) * wear_amount;
		tone *= 0.91 + brushed * 0.12;
		tone = mix(tone, vec3(0.17, 0.145, 0.105), oxidation * 0.25);
		roughness_value += brushed * 0.075 + oxidation * 0.20;
		bump = (brushed - 0.5) * 0.008;
	}
	ALBEDO = tone;
	METALLIC = metalness;
	ROUGHNESS = clamp(roughness_value, 0.12, 0.98);
	SPECULAR = surface_kind == 0 ? 0.29 : (surface_kind == 1 ? 0.30 : 0.53);
	// Subtle tangent-space micro relief; grazing highlights carry the detail.
	NORMAL_MAP = normalize(vec3(bump, -bump * 0.45, 1.0)) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.35;
}
