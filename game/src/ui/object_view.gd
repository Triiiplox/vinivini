class_name ObjectView
extends Control
## Objeto contável tocável (estrela, alien, foguete, cristal, planeta, lua).
## Ao tocar acende e mostra o número da contagem.

signal touched(obj: ObjectView)

var kind := "star"
var lit := false
var number := 0
var show_number := false
var t := 0.0


func _init(k: String = "star") -> void:
	kind = k
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = Vector2.ZERO


func _gui_input(e: InputEvent) -> void:
	if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or (e is InputEventScreenTouch and e.pressed):
		touched.emit(self)
		accept_event()


func set_lit(on: bool, n: int = 0) -> void:
	lit = on
	number = n
	show_number = on and n > 0
	pivot_offset = size / 2
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.25, 1.25), 0.08)
	tw.tween_property(self, "scale", Vector2.ONE, 0.15)
	queue_redraw()


func _process(delta: float) -> void:
	t += delta
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.42
	var c := size / 2.0 + Vector2(0, sin(t * 2.0 + get_index()) * 2.0)
	if lit:
		draw_circle(c, r * 1.25, Color(1, 1, 0.6, 0.3), true, -1.0, true)
	paint(self, kind, c, r, t)
	if show_number:
		var bc := c + Vector2(r * 0.75, -r * 0.75)
		draw_circle(bc, r * 0.45, Palette.WHITE, true, -1.0, true)
		var f := UITheme.title_font()
		var fs := int(r * 0.6)
		var txt := str(number)
		var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, bc + Vector2(-tw / 2, fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.TEXT_DARK)


static func paint(ci: CanvasItem, k: String, c: Vector2, r: float, time: float = 0.0) -> void:
	match k:
		"star":
			ci.draw_colored_polygon(IconDraw.star_points(c, r, r * 0.45), Palette.YELLOW)
		"alien":
			CharacterView.paint_kind(ci, "alien", "happy", c, r / 85.0, time)
		"rocket":
			var s := r / 50.0
			var pts := PackedVector2Array()
			for p in [Vector2(0, -50), Vector2(18, -22), Vector2(18, 22), Vector2(-18, 22), Vector2(-18, -22)]:
				pts.append(c + p * s)
			ci.draw_colored_polygon(pts, Color("#F1F5FF"))
			ci.draw_colored_polygon(
				PackedVector2Array([c + Vector2(-18, 4) * s, c + Vector2(-34, 34) * s, c + Vector2(-18, 26) * s]), Palette.PINK
			)
			ci.draw_colored_polygon(
				PackedVector2Array([c + Vector2(18, 4) * s, c + Vector2(34, 34) * s, c + Vector2(18, 26) * s]), Palette.PINK
			)
			ci.draw_circle(c + Vector2(0, -12) * s, 9 * s, Palette.BLUE, true, -1.0, true)
			ci.draw_colored_polygon(
				PackedVector2Array([c + Vector2(-10, 22) * s, c + Vector2(10, 22) * s, c + Vector2(0, 46 + sin(time * 18) * 4) * s]),
				Palette.ORANGE
			)
		"crystal":
			var pts2 := PackedVector2Array(
				[c + Vector2(0, -r), c + Vector2(r * 0.62, -r * 0.2), c + Vector2(0, r), c + Vector2(-r * 0.62, -r * 0.2)]
			)
			ci.draw_colored_polygon(pts2, Color("#4CC9F0"))
			ci.draw_colored_polygon(
				PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.62, -r * 0.2), c + Vector2(0, -r * 0.1)]), Color("#A0E7FF")
			)
			ci.draw_polyline(pts2 + PackedVector2Array([pts2[0]]), Color("#1E96C8"), 2.0, true)
		"planet":
			PlanetView.paint(ci, {"color": "#9B5DE5", "color2": "#7B2CBF", "style": "bands", "rings": true}, c, r * 0.62, time)
		"moon":
			ci.draw_circle(c, r * 0.85, Color("#F6E27F"), true, -1.0, true)
			ci.draw_circle(c + Vector2(r * 0.42, -r * 0.2), r * 0.72, Palette.BG_TOP, true, -1.0, true)
		_:
			ci.draw_circle(c, r, Palette.WHITE, true, -1.0, true)
