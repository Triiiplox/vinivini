// Troca a cor do traje do Vini: azul-marinho -> navy_to e ciano luminoso -> glow_to (pele, cabelo, branco e
// estrela dourada não mudam porque estão fora da faixa de matiz azul). amount = 0 desliga.
shader_type canvas_item;

uniform vec4 navy_to : source_color = vec4(0.14, 0.22, 0.5, 1.0);
uniform vec4 glow_to : source_color = vec4(0.13, 0.83, 0.93, 1.0);
uniform float amount = 1.0;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * clamp(p - 1.0, 0.0, 1.0);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	vec3 h = rgb2hsv(c.rgb);
	float blue = smoothstep(0.47, 0.52, h.x) * (1.0 - smoothstep(0.74, 0.78, h.x)) * smoothstep(0.18, 0.3, h.y);
	if (blue > 0.0 && amount > 0.0) {
		float glow = smoothstep(0.6, 0.8, h.z) * smoothstep(0.55, 0.7, h.y);
		vec3 tn = rgb2hsv(navy_to.rgb);
		vec3 tg = rgb2hsv(glow_to.rgb);
		vec3 t = mix(tn, tg, glow);
		float ref_v = mix(0.42, 0.95, glow);
		vec3 n = vec3(t.x, clamp(h.y * t.y / 0.8, 0.0, 1.0), clamp(h.z * t.z / ref_v, 0.0, 1.0));
		c.rgb = mix(c.rgb, hsv2rgb(n), blue * amount);
	}
	COLOR = c;
}
