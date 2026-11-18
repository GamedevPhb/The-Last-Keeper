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

// Player flashlight, evaluated per pixel. Everything else stays per-vertex (force_vertex_shading),
// but the heightmap terrain has triangles several metres wide: a vertex-lit spot cone that lands
// between vertices simply vanishes. ui/overlay.gd feeds these globals every frame; the light sits
// on the camera, so in view space it is at the origin looking down -Z.
//   psx_flashlight       — x = energy (0 = off), y = range (m), z = cos(outer angle), w = cos(inner angle)
//   psx_flashlight_color — beam tint
global uniform vec4 psx_flashlight;
global uniform vec4 psx_flashlight_color;

// Light reaching a fragment (view-space position / normal). Add as EMISSION += ALBEDO * this.
vec3 psx_flashlight_light(vec3 view_pos, vec3 view_normal) {
	if (psx_flashlight.x <= 0.0) {
		return vec3(0.0);
	}
	float d = length(view_pos);
	if (d >= psx_flashlight.y) {
		return vec3(0.0);
	}
	vec3 to_frag = view_pos / max(d, 0.0001);
	// Hard-ish, banded rim: 4 steps reads as a PS1 light cookie instead of a smooth modern falloff.
	float cone = smoothstep(psx_flashlight.z, psx_flashlight.w, -to_frag.z);
	cone = ceil(cone * 4.0) * 0.25;
	float r = d / psx_flashlight.y;
	float fall = 1.0 - r * r;
	fall *= fall;
	float ndl = max(dot(view_normal, -to_frag), 0.0) * 0.75 + 0.25; // wrap: big flat normals don't go black
	return psx_flashlight_color.rgb * (psx_flashlight.x * cone * fall * ndl);
}
