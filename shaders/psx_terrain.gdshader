// Terreno da ilha: como psx_lit, mas multiplica pela cor de vertice (areia/grama/rocha/mata)
// e usa UV planar (xz) para a textura nao esticar nos declives.
shader_type spatial;
render_mode vertex_lighting, diffuse_lambert, specular_disabled;

#include "res://shaders/psx_common.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_enable, hint_default_white;
uniform vec2 uv_scale = vec2(1.0);

varying vec3 affine_uv;
varying vec3 vcol;

void vertex() {
	POSITION = psx_snap(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0), VIEWPORT_SIZE);
	affine_uv = psx_affine_uv(UV * uv_scale, POSITION);
	vcol = COLOR.rgb;
}

void fragment() {
	vec4 tex = texture(albedo_texture, psx_resolve_uv(UV * uv_scale, affine_uv));
	ALBEDO = albedo.rgb * tex.rgb * vcol;
	EMISSION = ALBEDO * (psx_flashlight_light(VERTEX, NORMAL) + psx_lamp_light(VERTEX, NORMAL, INV_VIEW_MATRIX));
	ROUGHNESS = 1.0;
}
