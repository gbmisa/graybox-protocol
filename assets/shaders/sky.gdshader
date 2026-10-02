// The night over Holloway Road: violet overhead going to a sick acid haze at
// the horizon, slow bands drifting through it, a swollen pale moon low in the
// north-east, and stars that don't quite hold still.
shader_type sky;

uniform vec3 zenith : source_color = vec3(0.035, 0.02, 0.09);
uniform vec3 horizon : source_color = vec3(0.16, 0.20, 0.10);
uniform vec3 band : source_color = vec3(0.32, 0.08, 0.30);
uniform vec3 moon_col : source_color = vec3(1.0, 0.92, 0.75);
uniform vec3 moon_dir = vec3(0.55, 0.28, -0.79);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x),
		mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p = rot * p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 d = EYEDIR;
	float h = clamp(d.y, -0.2, 1.0);
	vec3 col = mix(horizon, zenith, pow(smoothstep(-0.05, 0.6, h), 0.7));
	// Drifting bands, only above the horizon.
	float az = atan(d.x, d.z);
	vec2 bp = vec2(sin(az) * 2.5 + TIME * 0.008, cos(az) * 2.5) / max(h + 0.25, 0.25);
	float b = fbm(bp * 1.3 + vec2(0.0, TIME * 0.01));
	col += band * smoothstep(0.45, 0.8, b) * smoothstep(0.0, 0.3, h) * 0.55;
	// Stars, twitching.
	vec2 sp = vec2(az * 220.0, h * 220.0);
	vec2 cell = floor(sp);
	vec2 off = vec2(hash(cell + 3.1), hash(cell + 7.7)) * 0.6 + 0.2;
	float st = step(0.985, hash(cell)) * smoothstep(0.18, 0.0, length(fract(sp) - off));
	st *= 0.6 + 0.4 * sin(TIME * 3.0 + hash(cell) * 40.0);
	col += vec3(st) * smoothstep(0.08, 0.4, h);
	// The moon, with a halo, and a faint second ring that shouldn't be there.
	float m = dot(d, normalize(moon_dir));
	col += moon_col * smoothstep(0.9975, 0.9985, m);
	col += moon_col * pow(max(m, 0.0), 180.0) * 0.35;
	col += vec3(0.4, 0.9, 0.5) * smoothstep(0.004, 0.0, abs(m - 0.985)) * 0.25;
	COLOR = col;
}
