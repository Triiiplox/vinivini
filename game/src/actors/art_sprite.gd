class_name ArtSprite
extends Node2D
## Objeto de cenário (art2.json) com "suco": quique, balanço, pulso, brilho.
## size = largura em px; centralizado no meio inferior (âncora nos pés) se anchor_bottom.

var group := "props"
var item_name := "crystal"
var colors: Dictionary = {}
var size_px := 100.0
var anchor_bottom := false
var idle := ""  # "", "float", "spin", "wobble", "pulse"
var t := 0.0
var _sprite: Node2D
var _painted: Sprite2D
var _phase := randf() * TAU


func _init(g: String = "props", n: String = "crystal", width: float = 100.0, cols: Dictionary = {}) -> void:
	group = g
	item_name = n
	size_px = width
	colors = cols


## Pintura (assets/art/painted/<grupo>/<nome>.png) quando existe; senão, o desenho vetorial antigo.
static func painted_tex(g: String, n: String) -> Texture2D:
	var path := "res://assets/art/painted/%s/%s.png" % [g, n]
	return load(path) if ResourceLoader.exists(path) else null


func _ready() -> void:
	_sprite = Node2D.new()
	add_child(_sprite)
	refresh()


func refresh() -> void:
	var tex: Texture2D = painted_tex(group, item_name) if colors.is_empty() else null
	if tex:
		_show_painted(tex)
		return
	if _painted:
		_painted.queue_free()
		_painted = null
	var rs := RigSprite.new()
	for c in _sprite.get_children():
		c.queue_free()
	_sprite.add_child(rs)
	var vb := SvgArt.item_vb(group, item_name)
	var units := size_px / float(vb[2])
	var piv := Vector2(float(vb[0]) + float(vb[2]) / 2.0, float(vb[1]) + (float(vb[3]) if anchor_bottom else float(vb[3]) / 2.0))
	var key := "it|%s|%s|%s" % [group, item_name, str(colors.get("c", ""))]
	rs.configure(key, vb, piv, units, SvgArt.item_svg.bind(group, item_name, colors))


## A pintura cabe na mesma caixa size_px × size_px que o desenho ocupava (o maior lado = size_px).
func _show_painted(tex: Texture2D) -> void:
	for c in _sprite.get_children():
		if c != _painted:
			c.queue_free()
	if not _painted:
		_painted = Sprite2D.new()
		_painted.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_sprite.add_child(_painted)
	_painted.texture = tex
	var k := size_px / float(maxi(tex.get_width(), tex.get_height()))
	_painted.scale = Vector2(k, k)
	_painted.position = Vector2(0, -tex.get_height() * k / 2.0) if anchor_bottom else Vector2.ZERO


func set_item(n: String, cols: Dictionary = {}) -> void:
	item_name = n
	if not cols.is_empty():
		colors = cols
	if is_inside_tree():
		refresh()


func height_px() -> float:
	if _painted and _painted.texture:
		return _painted.texture.get_height() * _painted.scale.y
	var tex := painted_tex(group, item_name) if colors.is_empty() else null
	if tex:
		return size_px * float(tex.get_height()) / float(maxi(tex.get_width(), tex.get_height()))
	var vb := SvgArt.item_vb(group, item_name)
	return size_px * float(vb[3]) / float(vb[2])


func _process(delta: float) -> void:
	t += delta
	match idle:
		"float":
			_sprite.position.y = sin(t * 2.0 + _phase) * size_px * 0.04
		"spin":
			_sprite.rotation = sin(t * 1.5 + _phase) * 0.15
		"wobble":
			_sprite.rotation = sin(t * 3.0 + _phase) * 0.06
		"pulse":
			var s := 1.0 + 0.05 * sin(t * 4.0 + _phase)
			_sprite.position.y = 0.0
			scale = Vector2(s, s)


## Pulinho de "pega/acerta".
func bounce(strength: float = 0.25) -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.0 + strength, 1.0 - strength * 0.6), 0.08)
	tw.tween_property(self, "scale", Vector2(1.0 - strength * 0.3, 1.0 + strength * 0.4), 0.1)
	tw.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func shake(px: float = 8.0) -> void:
	var x := position.x
	var tw := create_tween()
	for i in 3:
		tw.tween_property(self, "position:x", x - px, 0.04)
		tw.tween_property(self, "position:x", x + px, 0.04)
	tw.tween_property(self, "position:x", x, 0.04)
