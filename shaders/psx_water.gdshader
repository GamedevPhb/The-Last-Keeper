// Sea surface: low-frequency vertex waves on a subdivided plane, PS1 snapping.
shader_type spatial;
render_mode vertex_lighting, diffuse_lambert, specular_disabled;

#include "res://shaders/psx_common.gdshaderinc"

uniform vec4 deep_color : source_color = vec4(0.03, 0.08, 0.11, 1.0);
uniform vec4 crest_color : source_color = vec4(0.10, 0.20, 0.24, 1.0);
uniform sampler2D noise_texture : filter_nearest, repeat_enable, hint_default_white;
uniform float wave_height = 0.35;
uniform float wave_speed = 0.6;
uniform vec2 uv_scale = vec2(40.0);

varying float crest;
varying vec3 affine_uv;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = sin(world.x * 0.15 + TIME * wave_speed) * 0.6
			+ sin(world.z * 0.21 + TIME * wave_speed * 1.3) * 0.4;
	VERTEX.y += h * wave_height;
	crest = h * 0.5 + 0.5;
	POSITION = psx_snap(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0), VIEWPORT_SIZE);
	affine_uv = psx_affine_uv(UV * uv_scale + vec2(TIME * 0.02, 0.0), POSITION);
}

void fragment() {
	vec2 uv = psx_resolve_uv(UV * uv_scale + vec2(TIME * 0.02, 0.0), affine_uv);
	float n = texture(noise_texture, uv).r;
	ALBEDO = mix(deep_color.rgb, crest_color.rgb, crest * n);
	ROUGHNESS = 1.0;
}
