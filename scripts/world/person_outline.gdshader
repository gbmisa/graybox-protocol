// The people's ink line (r8 graphics review: "inverted-hull black outline"):
// a second pass of the body, pushed out along its normals and drawn from the
// inside, unshaded black. Thicker with distance so it never vanishes.
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;

uniform float width = 0.012;

void vertex() {
	float d = length((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	VERTEX += NORMAL * width * clamp(d / 6.0, 1.0, 3.0);
}

void fragment() {
	ALBEDO = vec3(0.02, 0.01, 0.03);
}
