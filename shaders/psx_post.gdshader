// Full-screen pass: reduced color depth with 4x4 ordered (Bayer) dithering.
// The game renders natively at 320x240 (viewport stretch), so one fragment
// here is one final "PS1 pixel".
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float color_levels = 32.0; // per channel; 32 = 15-bit color like the PS1
uniform float dither_strength = 1.0;
// Grade: murky green-teal cast, crushed shadows and a heavy vignette.
uniform vec3 tint : source_color = vec3(0.78, 1.0, 0.82);
uniform float saturation = 0.65;
uniform float gamma = 1.15; // >1 darkens the midtones
uniform float vignette = 0.6;

const float BAYER[16] = float[](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0
);

void fragment() {
	vec3 color = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	float luma = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(luma), color, saturation) * tint;
	color = pow(color, vec3(gamma));
	float edge = length((SCREEN_UV - 0.5) * vec2(1.0, 0.9));
	color *= mix(1.0, smoothstep(0.85, 0.2, edge), vignette);
	ivec2 cell = ivec2(FRAGCOORD.xy) % 4;
	float threshold = BAYER[cell.y * 4 + cell.x] / 16.0 - 0.5;
	color += threshold * dither_strength / color_levels;
	color = floor(color * (color_levels - 1.0) + 0.5) / (color_levels - 1.0);
	COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
}
