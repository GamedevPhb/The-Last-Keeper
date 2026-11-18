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
// Puxa a profundidade em direcao a camera (0 = desligado) sem mexer na posicao na tela.
// Para superficies rentes ao chao (trilhas): o snap de vertice desloca chao e trilha em ate
// uma celula, e so a elevacao geometrica nao basta de longe. Cresce com a distancia e o snap.
uniform float depth_pull = 0.0;

varying vec3 affine_uv;

void vertex() {
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	float pull = clamp(depth_pull * (psx_vertex_snap + 0.5) * length(view.xyz), 0.0, 0.3);
	view.xyz *= 1.0 - pull;
	POSITION = psx_snap(PROJECTION_MATRIX * view, VIEWPORT_SIZE);
	affine_uv = psx_affine_uv(UV * uv_scale, POSITION);
}

void fragment() {
	vec4 tex = texture(albedo_texture, psx_resolve_uv(UV * uv_scale, affine_uv));
	ALBEDO = albedo.rgb * tex.rgb;
	EMISSION = emission.rgb * emission_energy + ALBEDO * psx_flashlight_light(VERTEX, NORMAL);
	ROUGHNESS = 1.0;
}
