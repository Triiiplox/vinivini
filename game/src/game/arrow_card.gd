class_name ArrowCard
extends Interactable
## Cartão de comando do robô (seta). dir: Vector2i (1,0)=direita, (-1,0), (0,-1)=cima, (0,1)=baixo.

var dir := Vector2i.RIGHT
var size_px := 96.0
var color := Palette.ORANGE


func _init(d: Vector2i = Vector2i.RIGHT, s: float = 96.0) -> void:
	dir = d
	size_px = s
	payload = d
	radius = s * 0.6
	color = {Vector2i.RIGHT: Palette.ORANGE, Vector2i.LEFT: Palette.PURPLE, Vector2i.UP: Palette.TEAL, Vector2i.DOWN: Palette.PINK}.get(d,
		Palette.ORANGE)


func _draw() -> void:
	var h := size_px / 2.0
	var r := Rect2(-h, -h, size_px, size_px)
	draw_style_box(UITheme.rounded(color, int(size_px * 0.22), 5, Color("#22204A")), r)
	var a := Vector2(dir).angle()
	var pts := PackedVector2Array([Vector2(-0.32, -0.12), Vector2(0.05, -0.12), Vector2(0.05, -0.3), Vector2(0.36, 0.0),
		Vector2(0.05, 0.3), Vector2(0.05, 0.12), Vector2(-0.32, 0.12)])
	var out := PackedVector2Array()
	for p in pts:
		out.append((p * size_px).rotated(a))
	draw_colored_polygon(out, Color.WHITE)
	out.append(out[0])
	draw_polyline(out, Color("#22204A"), 4.0, true)
