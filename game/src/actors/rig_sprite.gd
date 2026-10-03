class_name RigSprite
extends Sprite2D
## Peça vetorial rasterizada sob demanda, posicionada pelo pivô (unidades do SVG).
## unit_px = quantos pixels (locais) vale 1 unidade do SVG.

var key := ""
var vb: Array = [0, 0, 100, 100]
var pivot := Vector2.ZERO
var unit_px := 1.0
var builder: Callable
var _loaded_key := ""


func configure(k: String, viewbox: Array, piv: Vector2, units: float, b: Callable) -> void:
	key = k
	vb = viewbox
	pivot = piv
	unit_px = units
	builder = b
	centered = false
	_try_load()


func _process(_d: float) -> void:
	if _loaded_key != key:
		_try_load()


func _try_load() -> void:
	if key == "" or not builder.is_valid():
		return
	var px := float(vb[2]) * unit_px * (SvgArt.screen_scale(self) if is_inside_tree() else 1.0)
	var tex := SvgArt.get_texture(key, maxf(px, 32.0), float(vb[2]), builder)
	if tex == null:
		return
	texture = tex
	var ppu := float(tex.get_width()) / float(vb[2])
	offset = -(pivot - Vector2(float(vb[0]), float(vb[1]))) * ppu
	scale = Vector2.ONE * unit_px / ppu
	_loaded_key = key
	set_meta("svg_ref", tex)
