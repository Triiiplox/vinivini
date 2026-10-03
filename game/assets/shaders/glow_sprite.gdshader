shader_type canvas_item;
render_mode blend_add;
// Halo aditivo radial (brilho de energia, estrelas, portais).
uniform vec4 glow_color : source_color = vec4(1.0, 0.85, 0.3, 1.0);
uniform float intensity = 1.0;
uniform float pulse = 0.0;
void fragment() {
	float d = length(UV * 2.0 - 1.0);
	float a = pow(clamp(1.0 - d, 0.0, 1.0), 2.2) * intensity * (1.0 + pulse * 0.25 * sin(TIME * 4.0));
	COLOR = vec4(glow_color.rgb * a, a);
}
