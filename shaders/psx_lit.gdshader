// Default material for world geometry: vertex lighting, vertex snapping,
// affine texture mapping and nearest-filtered textures.
shader_type spatial;
render_mode vertex_lighting, diffuse_lambert, specular_disabled;

#include "res://shaders/psx_common.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_enable, hint_default_white;
uniform vec2 uv_scale = vec2(1.0);
uniform vec4 emission : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;

varying vec3 affine_uv;

void vertex() {
	POSITION = psx_snap(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0), VIEWPORT_SIZE);
	affine_uv = psx_affine_uv(UV * uv_scale, POSITION);
}

void fragment() {
	vec4 tex = texture(albedo_texture, psx_resolve_uv(UV * uv_scale, affine_uv));
	ALBEDO = albedo.rgb * tex.rgb;
	EMISSION = emission.rgb * emission_energy;
	ROUGHNESS = 1.0;
}
