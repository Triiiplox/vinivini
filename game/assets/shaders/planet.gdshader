shader_type canvas_item;
// Planeta girando: amostra uma textura equiretangular sobre uma esfera, com luz, terminador,
// borda atmosférica e contorno cartoon. Use num ColorRect/TextureRect quadrado.

uniform sampler2D surface : source_color, filter_linear_mipmap, repeat_enable;
uniform float spin_speed = 0.03;
uniform float spin_offset = 0.0;
uniform vec3 light_dir = vec3(-0.6, -0.5, 0.65);
uniform vec4 atmosphere : source_color = vec4(0.6, 0.8, 1.0, 1.0);
uniform float atmosphere_strength = 0.5;
uniform vec4 outline_color : source_color = vec4(0.13, 0.125, 0.29, 1.0);
uniform float outline_width = 0.035;
uniform float shading = 0.55;
uniform float tilt = 0.0;
uniform float glow = 0.0;
uniform bool use_tint = false;
uniform vec4 color_a : source_color = vec4(0.6, 0.3, 0.9, 1.0);
uniform vec4 color_b : source_color = vec4(1.0, 0.5, 0.7, 1.0);

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float body = 1.0 - outline_width;
	if (r > 1.0) {
		discard;
	}
	if (r > body) {
		COLOR = outline_color;
	} else {
		vec2 sp = p / body;
		float c = cos(tilt); float s = sin(tilt);
		sp = vec2(c * sp.x - s * sp.y, s * sp.x + c * sp.y);
		float z = sqrt(max(0.0, 1.0 - dot(sp, sp)));
		vec3 n = vec3(sp, z);
		float lon = atan(n.x, n.z) / 6.2831853 + 0.5 + TIME * spin_speed + spin_offset;
		float lat = asin(clamp(n.y, -1.0, 1.0)) / 3.1415926 + 0.5;
		vec3 tex = texture(surface, vec2(lon, lat)).rgb;
		if (use_tint) {
			tex = mix(color_a.rgb, color_b.rgb, tex.r);
		}
		vec3 L = normalize(light_dir);
		float diff = clamp(dot(vec3(p.x, p.y, z), vec3(L.x, L.y, L.z)), 0.0, 1.0);
		float light = mix(1.0 - shading, 1.15, smoothstep(-0.15, 0.6, diff));
		vec3 col = tex * light;
		float rim = pow(1.0 - z, 2.5);
		col += atmosphere.rgb * rim * atmosphere_strength;
		float spec = pow(clamp(dot(reflect(-L, vec3(p, z)), vec3(0.0, 0.0, 1.0)), 0.0, 1.0), 24.0);
		col += vec3(spec * 0.25);
		col += vec3(glow) * 0.25;
		COLOR = vec4(col, 1.0);
	}
}
