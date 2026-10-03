shader_type canvas_item;
// Céu espacial procedural: gradiente + nebulosa (fbm) + 3 camadas de estrelas com parallax e brilho.
// `parallax` = deslocamento da câmera (px). `quality` 0 = sem nebulosa animada (aparelhos fracos).

uniform vec2 parallax = vec2(0.0);
uniform vec2 screen_px = vec2(1280.0, 720.0);
uniform vec4 top_color : source_color = vec4(0.10, 0.12, 0.38, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.03, 0.04, 0.16, 1.0);
uniform vec4 neb_a : source_color = vec4(0.55, 0.20, 0.85, 1.0);
uniform vec4 neb_b : source_color = vec4(0.15, 0.55, 0.95, 1.0);
uniform vec4 neb_c : source_color = vec4(0.95, 0.30, 0.55, 1.0);
uniform float neb_strength = 0.55;
uniform float quality = 1.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}
float stars(vec2 px, float cell, float density, float size, float t) {
	vec2 g = floor(px / cell);
	vec2 f = fract(px / cell);
	float h = hash(g);
	if (h > density) return 0.0;
	vec2 pos = vec2(hash(g + 3.1), hash(g + 7.7)) * 0.8 + 0.1;
	float d = length(f - pos) * cell;
	float tw = 0.6 + 0.4 * sin(t * (1.0 + h * 3.0) + h * 40.0);
	return smoothstep(size, 0.0, d) * tw;
}
void fragment() {
	vec2 px = UV * screen_px;
	vec3 col = mix(top_color.rgb, bottom_color.rgb, UV.y);
	if (quality > 0.5) {
		vec2 q = (px + parallax * 0.15) / 420.0;
		float n1 = fbm(q + vec2(TIME * 0.01, 0.0));
		float n2 = fbm(q * 1.7 + vec2(4.0, TIME * 0.008));
		vec3 neb = mix(neb_a.rgb, neb_b.rgb, smoothstep(0.3, 0.7, n2));
		neb = mix(neb, neb_c.rgb, smoothstep(0.55, 0.85, n1 * n2 * 1.6));
		col += neb * pow(smoothstep(0.35, 0.85, n1), 1.6) * neb_strength;
	}
	float s = 0.0;
	s += stars(px + parallax * 0.05, 26.0, 0.30, 1.4, TIME) * 0.55;
	s += stars(px + parallax * 0.15, 48.0, 0.35, 2.0, TIME * 1.3) * 0.8;
	s += stars(px + parallax * 0.35, 90.0, 0.30, 3.0, TIME * 0.9);
	col += vec3(s) * vec3(0.95, 0.97, 1.0);
	COLOR = vec4(col, 1.0);
}
