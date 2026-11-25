// The people's skin and clothes (Humanoid). The Quaternius bodies come in
// underwear; tools/blender/people.py bakes a clothing mask into the vertex
// colours (R top, G bottom, B shoes, black = skin).
//
// r8 (Gregory: "the people models don't fit the scene"): the level is Kenney
// low-poly — flat colours, hard facets, no photo detail. So are the people
// now: faceted normals, one flat colour per region, no normal map. The skin
// texture survives only as crude dark marks where it is darkest (eyes,
// brows, mouth), so a face still reads at 10m.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D skin_tex : source_color, filter_linear_mipmap;
uniform vec3 skin_col = vec3(0.78, 0.56, 0.44);
uniform vec4 top_col : source_color = vec4(0.6, 0.1, 0.1, 1.0);
uniform vec4 bottom_col : source_color = vec4(0.1, 0.1, 0.2, 1.0);
uniform vec4 shoe_col : source_color = vec4(0.05, 0.05, 0.05, 1.0);
// The guard's aim tell recolours his clothes; a hit flashes all of him.
uniform vec4 tint_col : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform float tint_mix = 0.0;
uniform float flash = 0.0;

void fragment() {
	// Flat shading: one normal per triangle, from the screen derivatives.
	NORMAL = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	// The low-poly bake smears the mask across big triangles; snap it so
	// each region is one hard-edged colour, the strongest channel winning.
	vec3 v = COLOR.rgb;
	float c = step(0.5, v.r + v.g + v.b);
	float hi = max(v.r, max(v.g, v.b));
	vec3 m = step(vec3(hi - 0.001), v) * c;
	m /= max(1.0, m.r + m.g + m.b);
	float lum = dot(texture(skin_tex, UV).rgb, vec3(0.299, 0.587, 0.114));
	float mark = 1.0 - smoothstep(0.16, 0.24, lum);
	vec3 skin = mix(skin_col, skin_col * 0.22, mark);
	vec3 cloth = top_col.rgb * m.r + bottom_col.rgb * m.g + shoe_col.rgb * m.b;
	cloth = mix(cloth, tint_col.rgb, tint_mix * clamp(m.r + m.g, 0.0, 1.0));
	vec3 col = mix(skin, cloth, c);
	ALBEDO = mix(col, vec3(1.0), flash);
	EMISSION = vec3(flash) * 0.6;
	ROUGHNESS = 1.0;
}
