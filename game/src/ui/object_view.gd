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
		"alien":
			CharacterView.paint_kind(ci, "alien", "happy", c, r / 68.0, time)
		"planet":
			PlanetView.paint(ci, {"color": "#9B5DE5", "color2": "#7B2CBF", "style": "bands", "rings": true}, c, r * 0.6, 0.0)
		_:
			var side := r * 2.2
			SvgArt.draw_in(ci, Rect2(c - Vector2(side, side) / 2, Vector2(side, side)), "ob|" + k, [0, 0, 100, 100], SvgArt.object_svg.bind(k))
