class_name Starfield
extends Control
## Fundo espacial: gradiente + estrelas piscando + estrela cadente ocasional.

const STAR_COUNT := 90

var _stars: Array = []
var _t := 0.0
var _shoot := Vector4(-1, 0, 0, 0)  # x, y, progresso, ativo
var _rng := RandomNumberGenerator.new()
var _acc := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 77
	for i in STAR_COUNT:
		_stars.append([_rng.randf(), _rng.randf(), _rng.randf_range(1.0, 3.2), _rng.randf_range(0.5, 2.5), _rng.randf() * TAU])


func _process(delta: float) -> void:
	_t += delta
	_acc += delta
	if _shoot.w <= 0.0 and _rng.randf() < delta * 0.08:
		_shoot = Vector4(_rng.randf_range(0.2, 0.9), _rng.randf_range(0.05, 0.4), 0.0, 1.0)
	if _shoot.w > 0.0:
		_shoot.z += delta * 1.4
		if _shoot.z >= 1.0:
			_shoot.w = 0.0
	if _acc >= 1.0 / 30.0:
		_acc = 0.0
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_polygon(
		PackedVector2Array([r.position, Vector2(r.end.x, 0), r.end, Vector2(0, r.end.y)]),
		PackedColorArray([Palette.BG_TOP, Palette.BG_TOP, Palette.BG_BOTTOM, Palette.BG_BOTTOM])
	)
	# Nebulosas são suaves: rasteriza em baixa resolução e estica (barato e sem serrilhado visível).
	var neb := SvgArt.get_texture("bg|nebula", 640, 1280, SvgArt.background_svg)
	if neb:
		draw_texture_rect(neb, r, false)
	for s in _stars:
		var a: float = 0.45 + 0.55 * (0.5 + 0.5 * sin(_t * s[3] + s[4]))
		draw_circle(Vector2(s[0] * size.x, s[1] * size.y), s[2], Color(1, 1, 1, a), true, -1.0, true)
	if _shoot.w > 0.0:
		var p := Vector2(_shoot.x * size.x, _shoot.y * size.y) + Vector2(-260, 140) * _shoot.z
		draw_line(p, p + Vector2(70, -38), Color(1, 1, 1, 0.8 * (1.0 - _shoot.z)), 3.0, true)
