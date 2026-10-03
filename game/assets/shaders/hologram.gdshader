shader_type canvas_item;
// Painel holográfico: tinta ciano, linhas de varredura, borda brilhante e leve tremulação.

uniform vec4 tint : source_color = vec4(0.35, 0.9, 1.0, 1.0);
uniform float alpha = 0.55;
uniform float scan_density = 140.0;
uniform float border = 0.012;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	float scan = 0.85 + 0.15 * sin((UV.y * scan_density - TIME * 6.0) * 3.14159);
	float edge = max(smoothstep(border * 2.0, 0.0, min(UV.x, 1.0 - UV.x)), smoothstep(border * 3.5, 0.0, min(UV.y, 1.0 - UV.y)));
	float flicker = 0.94 + 0.06 * sin(TIME * 23.0) * sin(TIME * 7.0);
	vec3 col = mix(tint.rgb * 0.35, tint.rgb, edge) * scan;
	COLOR = vec4(col, (alpha * 0.55 + edge * 0.6) * base.a * flicker);
}
