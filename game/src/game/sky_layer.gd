class_name SkyLayer
extends CanvasLayer
## Céu procedural (shader) atrás de tudo, com parallax da câmera e temas de cor.

const THEMES := {
	"space": [Color(0.10, 0.12, 0.38), Color(0.03, 0.04, 0.16), Color(0.55, 0.20, 0.85), Color(0.15, 0.55, 0.95), Color(0.95, 0.30, 0.55),
		0.55],
	"moon": [Color(0.05, 0.07, 0.22), Color(0.02, 0.03, 0.10), Color(0.30, 0.35, 0.80), Color(0.20, 0.45, 0.85), Color(0.6, 0.6, 0.9),
		0.35],
	"mars": [Color(0.35, 0.12, 0.18), Color(0.12, 0.04, 0.10), Color(0.95, 0.45, 0.25), Color(0.8, 0.25, 0.3), Color(1.0, 0.6, 0.3), 0.45],
	"ice": [Color(0.08, 0.16, 0.40), Color(0.03, 0.06, 0.20), Color(0.3, 0.7, 1.0), Color(0.5, 0.9, 1.0), Color(0.8, 0.9, 1.0), 0.45],
	"saturn": [Color(0.20, 0.14, 0.36), Color(0.05, 0.04, 0.16), Color(0.95, 0.75, 0.35), Color(0.55, 0.35, 0.85), Color(0.95, 0.55, 0.45),
		0.5],
}

## Céus pintados (assets/scenes): tema -> [arquivo, cor]. Os outros temas usam só o shader.
const PAINTED := {
	"space": ["space_sky", Color.WHITE], "saturn": ["space_sky", Color(1.0, 0.92, 0.85)],
	"moon": ["space_sky", Color(0.62, 0.66, 0.85)],
}

var rect: ColorRect
var painted: TextureRect
var mat: ShaderMaterial
var theme := "space"
var _vp := Vector2(1280, 720)


func _ready() -> void:
	layer = -10
	rect = ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat = ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/space_sky.gdshader")
	rect.material = mat
	add_child(rect)
	rect.resized.connect(func(): mat.set_shader_parameter("screen_px", rect.size))
	painted = TextureRect.new()
	painted.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painted.texture = load("res://assets/scenes/space_sky.jpg")
	painted.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	painted.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	painted.modulate.a = 0.0
	add_child(painted)
	# Celulares largos (19,5:9) mostram mais que 1280 de largura: o céu pintado cobre a tela inteira + folga.
	get_viewport().size_changed.connect(_fit_painted)
	_fit_painted()
	set_theme("space", 0.0)
	set_quality(not bool(SaveService.settings.get_value("reduced_effects")))


func _fit_painted() -> void:
	_vp = get_viewport().get_visible_rect().size
	painted.size = _vp + Vector2(160, 90)
	painted.position = Vector2(-80, -45)


func set_parallax(v: Vector2) -> void:
	mat.set_shader_parameter("parallax", v)
	# Céu pintado: anda bem pouco (bem longe), com folga de 80 px para cada lado.
	painted.position = Vector2(-80.0 - clampf(v.x * 0.03, -80.0, 80.0), -45.0 - clampf(v.y * 0.03, -45.0, 45.0))


func set_quality(high: bool) -> void:
	mat.set_shader_parameter("quality", 1.0 if high else 0.0)


func set_theme(name: String, fade: float = 0.8) -> void:
	theme = name
	var pt: Array = PAINTED.get(name, [])
	var target := Color(pt[1]) if not pt.is_empty() else Color(1, 1, 1, 0)
	if fade <= 0.0:
		painted.modulate = target
	else:
		create_tween().tween_property(painted, "modulate", target, fade)
	var t: Array = THEMES.get(name, THEMES["space"])
	var keys := ["top_color", "bottom_color", "neb_a", "neb_b", "neb_c", "neb_strength"]
	for i in keys.size():
		var cur: Variant = mat.get_shader_parameter(keys[i])
		if fade <= 0.0 or cur == null:
			mat.set_shader_parameter(keys[i], t[i])
		else:
			var tw := create_tween()
			tw.tween_method(func(v): mat.set_shader_parameter(keys[i], v), cur, t[i], fade)
