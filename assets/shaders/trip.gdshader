// HOLLOWAY's look, applied over the world and the viewmodel, under the HUD
// (fx/post_fx.gd). Dithered colour banding, chromatic fringe toward the edges,
// a slow acid hue breathing in the shadows, a faint warp, grain, vignette.
// `alarm` pushes the fringe and the warp and reddens the frame.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float strength : hint_range(0.0, 1.5) = 1.0;
uniform float alarm : hint_range(0.0, 1.0) = 0.0;
uniform float levels = 22.0;
uniform float hurt : hint_range(0.0, 1.0) = 0.0;

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int i = y * 4 + x;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
		3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return m[i] / 16.0 - 0.5;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	float r2 = dot(c, c);
	float t = TIME;
	float s = strength;
	// Breathing warp, strongest at the edges, never at the crosshair.
	float wob = (0.0009 + alarm * 0.002 + hurt * 0.004) * s;
	uv += vec2(sin(uv.y * 11.0 + t * 0.7), cos(uv.x * 9.0 + t * 0.55)) * wob * (r2 * 3.0);
	// Chromatic fringe.
	float ca = (0.0008 + r2 * 0.010) * s * (1.0 + alarm * 1.5 + hurt * 3.0);
	vec3 col;
	col.r = texture(screen_tex, uv + c * ca).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - c * ca).b;
	// Acid in the shadows: darks pick up a hue that slowly cycles across the
	// frame. Highlights keep their own colour.
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 acid = 0.5 + 0.5 * cos(6.2831 * (vec3(0.0, 0.33, 0.67) + t * 0.025 + uv.x * 0.18 - uv.y * 0.07));
	col += acid * 0.045 * (1.0 - smoothstep(0.0, 0.3, l)) * s;
	// Lift saturation a touch, then band it, dithered.
	col = mix(vec3(l), col, 1.0 + 0.18 * s);
	float lv = mix(256.0, levels, clamp(s, 0.0, 1.0));
	col = floor(col * lv + 0.5 + bayer4(FRAGCOORD.xy)) / lv;
	// Grain and vignette.
	col += (hash(FRAGCOORD.xy + fract(t) * 91.7) - 0.5) * 0.035 * s;
	col *= 1.0 - r2 * (0.85 + hurt) * s;
	// Alarm: the frame goes red at the edges.
	col = mix(col, col * vec3(1.35, 0.55, 0.55), alarm * (0.25 + r2 * 1.2));
	COLOR = vec4(col, 1.0);
}
