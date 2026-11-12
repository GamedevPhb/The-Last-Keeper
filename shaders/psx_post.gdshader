// Full-screen pass: reduced color depth with random per-pixel dithering (no regular grid),
// film/VHS-style grain that re-rolls at grain_hz, and a CRT tube without periodic masks.
// The game renders natively at 320x240 (viewport stretch), so one fragment
// here is one final "PS1 pixel".
shader_type canvas_item;

global uniform float psx_brightness;
global uniform float psx_crt; // 0 = CRT off, 1 = full strength (Options)
global uniform float psx_grain; // 0 = no grain/glitches, 1 = full strength (Options)
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float color_levels = 24.0; // per channel; 32 = 15-bit, lower = harsher PS1-style banding
uniform float dither_strength = 1.0; // random threshold amplitude, in quantization steps
uniform float grain_strength = 0.045; // luminance grain amplitude (0..1 color) at psx_grain = 1
uniform float grain_chroma = 0.35; // chroma grain relative to luminance grain
uniform float grain_hz = 12.0; // grain re-roll rate, so it boils like film/VHS
uniform float black_floor = 0.03; // lifted blacks like a CRT, keeps dark areas readable
uniform float glitch_rate = 0.0025; // chance per row per tick of a shifted row
uniform float glitch_px = 4.0; // max horizontal shift of a glitch row
// Grade: murky green-teal cast, crushed shadows and a heavy vignette.
uniform vec3 tint : source_color = vec3(0.78, 1.0, 0.82);
uniform float saturation = 0.65;
uniform float gamma = 1.15; // >1 darkens the midtones
uniform float vignette = 0.6;

// CRT tube. All effects scale with psx_crt; at 0 the whole block is skipped.
uniform float crt_curve = 0.10; // barrel; image is shrunk so edge midpoints are never cropped
uniform float crt_scanline = 0.07; // random per-row brightness wobble (not periodic)
uniform float crt_aberration = 0.7; // px of R/B split at the corners
uniform float crt_bloom = 0.22; // cheap halo from 4 neighbour taps
uniform float crt_flicker = 0.012;
uniform float crt_corner = 0.45; // dark rounded corners

// PCG hash: integer, texture-free, no visible lattice.
uint pcg(uint v) {
	uint state = v * 747796405u + 2891336453u;
	uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
	return (word >> 22u) ^ word;
}
float rnd(uvec3 p) {
	return float(pcg(p.x + pcg(p.y + pcg(p.z)))) * (1.0 / 4294967295.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;
	vec3 color;
	float crt = clamp(psx_crt, 0.0, 1.0);
	float inside = 1.0;
	float grain = clamp(psx_grain, 0.0, 1.0);
	ivec2 fc = ivec2(FRAGCOORD.xy);
	uint tick = uint(TIME * grain_hz);
	// Rare dirty-tape glitch: a whole native row shifted a few pixels for one tick.
	float row_roll = rnd(uvec3(uint(fc.y), tick, 7u));
	float glitch = step(row_roll, glitch_rate * grain) * (rnd(uvec3(uint(fc.y), tick, 9u)) * 2.0 - 1.0);
	uv.x += glitch * glitch_px * px.x * grain;
	if (crt > 0.0) {
		vec2 p = uv - 0.5;
		float k = crt_curve * crt;
		uv = 0.5 + p * (1.0 + k * dot(p, p) * 4.0) / (1.0 + k);
		vec2 q = abs(uv - 0.5);
		inside = step(max(q.x, q.y), 0.5);
		vec2 off = (uv - 0.5) * vec2(2.0, 2.0) * px * crt_aberration * crt;
		color.r = textureLod(screen_texture, uv + off, 0.0).r;
		vec3 c = textureLod(screen_texture, uv, 0.0).rgb;
		color.g = c.g;
		color.b = textureLod(screen_texture, uv - off, 0.0).b;
		vec3 halo = textureLod(screen_texture, uv + vec2(px.x * 1.5, 0.0), 0.0).rgb
			+ textureLod(screen_texture, uv - vec2(px.x * 1.5, 0.0), 0.0).rgb
			+ textureLod(screen_texture, uv + vec2(0.0, px.y * 1.5), 0.0).rgb
			+ textureLod(screen_texture, uv - vec2(0.0, px.y * 1.5), 0.0).rgb;
		color += halo * 0.25 * crt_bloom * crt * smoothstep(0.25, 0.8, dot(halo * 0.25, vec3(0.333)));
	} else {
		color = textureLod(screen_texture, uv, 0.0).rgb;
	}
	float luma = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(luma), color, saturation) * tint;
	color = pow(color * psx_brightness, vec3(gamma));
	float edge = length((SCREEN_UV - 0.5) * vec2(1.0, 0.9));
	color *= mix(1.0, smoothstep(0.85, 0.2, edge), vignette);
	// Random dither: triangular noise per native pixel and tick breaks the banding without a grid.
	float n1 = rnd(uvec3(uint(fc.x), uint(fc.y), tick));
	float n2 = rnd(uvec3(uint(fc.x) + 4099u, uint(fc.y), tick));
	float n3 = rnd(uvec3(uint(fc.x), uint(fc.y) + 7919u, tick + 13u));
	color += (n1 + n2 - 1.0) * dither_strength / color_levels;
	// Luminance and chroma grain, 1 native pixel blocks, stronger in the midtones.
	float mid = 0.6 + 0.4 * smoothstep(0.0, 0.3, luma);
	color += ((n3 - 0.5) + (vec3(n1, n2, n3) - 0.5) * grain_chroma) * grain_strength * grain * mid;
	color = black_floor + color * (1.0 - black_floor);
	color = floor(color * (color_levels - 1.0) + 0.5) / (color_levels - 1.0);
	if (crt > 0.0) {
		color *= 1.0 - crt_scanline * crt * rnd(uvec3(uint(fc.y), tick / 2u, 3u));
		vec2 d = abs(SCREEN_UV - 0.5) * 2.0;
		float corner = pow(d.x, 6.0) + pow(d.y, 6.0);
		color *= 1.0 - clamp(corner * 0.5, 0.0, 1.0) * crt_corner * crt;
		color *= 1.0 + crt_flicker * crt * sin(TIME * 47.0) * sin(TIME * 5.3);
		color *= inside;
	}
	COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
}
