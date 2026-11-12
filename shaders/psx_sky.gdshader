// Sky: low amber sun with stepped halo and layered low fog banks that hide part
// of the disc. Everything is quantised (PS1 banding) and cheap: no textures.
shader_type sky;

uniform vec3 zenith : source_color = vec3(0.015, 0.03, 0.025);
uniform vec3 horizon : source_color = vec3(0.02, 0.04, 0.03);
uniform vec3 sun_color : source_color = vec3(1.0, 0.4, 0.1);
uniform vec3 bank_color : source_color = vec3(0.3, 0.14, 0.09);
uniform vec3 sun_dir = vec3(0.56, 0.1, 0.83);
uniform float sun_strength : hint_range(0.0, 1.0) = 0.0;
uniform float bank_strength : hint_range(0.0, 1.0) = 0.0;
uniform float time_s = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float elev = d.y;
	// Base gradient, banded in 6 steps.
	float g = floor(smoothstep(0.0, 0.5, elev) * 6.0) / 6.0;
	vec3 col = mix(horizon, zenith, g);
	if (elev < 0.0) {
		col = horizon * 0.8;
	}

	vec3 sd = normalize(sun_dir);
	float ang = acos(clamp(dot(d, sd), -1.0, 1.0));
	// Warm glow around the sun, in hard rings.
	float glow = 1.0 - smoothstep(0.0, 0.7, ang);
	glow = floor(glow * 5.0) / 5.0;
	col += sun_color * glow * 0.45 * sun_strength;
	// Disc.
	float disc = step(ang, 0.075);
	col = mix(col, vec3(2.0, 0.85, 0.25), disc * sun_strength);
	float ring = step(ang, 0.11) - disc;
	col += sun_color * ring * 0.5 * sun_strength;

	// Fog banks: three layers, partial coverage over the horizon and the sun.
	float az = atan(d.x, d.z);
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		float base = 0.0 + fi * 0.06;
		float n = vnoise(vec2(az * (5.0 + fi * 2.0) + time_s * (0.02 + fi * 0.01) + fi * 7.0, fi * 3.1));
		float top = base + 0.03 + n * n * 0.2;
		float edge = floor(clamp((top - elev) / 0.06, 0.0, 1.0) * 3.0) / 3.0;
		float covered = step(base * 0.0 - 0.2, elev) * edge;
		float a = covered * (0.9 - fi * 0.15) * bank_strength;
		vec3 bc = bank_color * (1.0 + fi * 0.35) + sun_color * glow * 0.25 * sun_strength;
		col = mix(col, bc, a);
	}
	COLOR = col;
}
