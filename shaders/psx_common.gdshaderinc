// Shared PS1-style helpers. Intensity is driven by project-wide shader globals
// (Project Settings > Shader Globals) so options menus can tweak them at runtime:
//   psx_vertex_snap     — grid cell size in screen pixels (0 disables the jitter)
//   psx_affine_strength — 0 = perspective-correct UVs, 1 = full affine warping

global uniform float psx_vertex_snap;
global uniform float psx_affine_strength;

// Snaps a clip-space position to the low-res pixel grid (the PS1 "wobble").
vec4 psx_snap(vec4 clip, vec2 viewport_size) {
	if (psx_vertex_snap <= 0.0 || clip.w <= 0.0) {
		return clip;
	}
	vec2 grid = viewport_size * 0.5 / psx_vertex_snap;
	clip.xy = round(clip.xy / clip.w * grid) / grid * clip.w;
	return clip;
}

// Pre-multiplies UVs by w so the fragment divide cancels perspective correction.
vec3 psx_affine_uv(vec2 uv, vec4 clip) {
	return vec3(uv * clip.w, clip.w);
}

vec2 psx_resolve_uv(vec2 perspective_uv, vec3 affine_uv) {
	return mix(perspective_uv, affine_uv.xy / affine_uv.z, psx_affine_strength);
}
