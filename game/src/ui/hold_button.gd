class_name HoldButton
extends Control
## Botão que só dispara ao segurar por `hold_time` segundos (porta dos pais).

signal held

var hold_time := 2.0
var icon_name := "lock"
## Só o anel de progresso (por cima de um botão visível, ex.: casa no voo).
var plain := false
var _progress := 0.0
var _holding := false


func _init(icon_id: String = "lock", seconds: float = 2.0) -> void:
	icon_name = icon_id
	hold_time = seconds
	custom_minimum_size = Vector2(84, 84)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		_holding = e.pressed
		if not e.pressed:
			_progress = 0.0
		accept_event()
	elif e is InputEventScreenTouch:
		_holding = e.pressed
		if not e.pressed:
			_progress = 0.0


func _process(delta: float) -> void:
	if _holding:
		_progress += delta / hold_time
		if _progress >= 1.0:
			_holding = false
			_progress = 0.0
			held.emit()
	queue_redraw()


func _draw() -> void:
	var c := size / 2
	var r := minf(size.x, size.y) / 2 - 4
	if not plain:
		draw_circle(c, r, Color(1, 1, 1, 0.12), true, -1.0, true)
	if _progress > 0.0:
		draw_arc(c, r, -PI / 2, -PI / 2 + TAU * _progress, 40, Palette.YELLOW, 9 if plain else 7, true)
	if plain:
		return
	var s := r * 1.1 / 100.0
	draw_set_transform(c - Vector2(50, 50) * s, 0.0, Vector2(s, s))
	IconDraw.draw_icon(self, icon_name, Color(1, 1, 1, 0.75))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
