class_name ShaderPlanet
extends Node2D
## Planeta "3D" girando (shader sobre textura equiretangular). Centralizado na origem.
## id = textura em assets/planets (earth, mars, ...) ou "pattern_*" + cores (use_tint).

const ATMOS := {"earth": Color(0.55, 0.8, 1.0), "mars": Color(1.0, 0.6, 0.45), "venus": Color(1.0, 0.85, 0.5),
	"jupiter": Color(1.0, 0.85, 0.7), "saturn": Color(1.0, 0.9, 0.6), "uranus": Color(0.6, 1.0, 1.0),
	"neptune": Color(0.5, 0.65, 1.0), "mercury": Color(0.8, 0.8, 0.8), "moon": Color(0.85, 0.88, 1.0), "sun": Color(1.0, 0.8, 0.3)}

var planet_id := "earth"
var radius := 80.0
var rect: ColorRect
var mat: ShaderMaterial
var rings := false
var _glow := 0.0


func _init(id: String = "earth", r: float = 80.0, tint_a: Color = Color.TRANSPARENT, tint_b: Color = Color.TRANSPARENT) -> void:
	planet_id = id
	radius = r
	rings = id == "saturn"
	mat = ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/planet.gdshader")
	mat.set_shader_parameter("surface", load("res://assets/planets/%s.png" % id))
	mat.set_shader_parameter("spin_offset", randf())
	mat.set_shader_parameter("atmosphere", ATMOS.get(id, Color(0.7, 0.8, 1.0)))
	if id == "sun":
		mat.set_shader_parameter("shading", 0.0)
		mat.set_shader_parameter("glow", 0.6)
	if tint_a.a > 0.0:
		mat.set_shader_parameter("use_tint", true)
		mat.set_shader_parameter("color_a", tint_a)
		mat.set_shader_parameter("color_b", tint_b)
	rect = ColorRect.new()
	rect.material = mat
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	_layout()


func _layout() -> void:
	rect.size = Vector2(radius, radius) * 2.0
	rect.position = -rect.size / 2.0
	queue_redraw()


func set_radius(r: float) -> void:
	radius = r
	_layout()


## Brilho temporário (planeta "cantando" / selecionado).
func flash(strength: float = 0.8, dur: float = 0.5) -> void:
	var tw := create_tween()
	tw.tween_method(_set_glow, strength, 0.0, dur)
	var tw2 := create_tween()
	tw2.tween_property(self, "scale", Vector2(1.15, 1.15), dur * 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw2.tween_property(self, "scale", Vector2.ONE, dur * 0.7)


func _set_glow(v: float) -> void:
	_glow = v
	mat.set_shader_parameter("glow", v + (0.6 if planet_id == "sun" else 0.0))
	queue_redraw()


func _draw() -> void:
	if _glow > 0.01:
		for i in 6:
			draw_circle(Vector2.ZERO, radius * (1.05 + i * 0.07), Color(1, 1, 0.8, 0.07 * _glow))
	if rings:
		# Anéis de Saturno: elipse atrás (metade de cima é coberta pelo planeta no rect).
		var pts := PackedVector2Array()
		for i in 65:
			var a := TAU * i / 64.0
			pts.append(Vector2(cos(a) * radius * 1.9, sin(a) * radius * 0.45))
		draw_polyline(pts, Color(0.95, 0.85, 0.6, 0.9), radius * 0.14, true)
		draw_polyline(pts, Color(0.13, 0.125, 0.29, 0.6), 3.0, true)
