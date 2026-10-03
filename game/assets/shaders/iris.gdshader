shader_type canvas_item;
// Transição em íris: progress 0 = tela livre, 1 = tudo coberto. Borda com brilho estelar.
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 center = vec2(0.5, 0.5);
uniform vec2 aspect = vec2(1.7778, 1.0);
uniform vec4 cover : source_color = vec4(0.03, 0.04, 0.16, 1.0);
void fragment() {
	vec2 d = (UV - center) * aspect;
	float r = (1.0 - progress) * 1.25;
	float dist = length(d);
	float a = smoothstep(r - 0.01, r + 0.01, dist);
	float rim = smoothstep(0.03, 0.0, abs(dist - r)) * (1.0 - step(0.999, progress)) * step(0.001, progress);
	COLOR = vec4(mix(cover.rgb, vec3(0.5, 0.95, 1.0), rim), max(a, rim * 0.9));
}
