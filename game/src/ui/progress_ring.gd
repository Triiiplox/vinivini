class_name ProgressRing
extends Node2D
## Anel de progresso (0..1) em volta de um botão: trilho apagado + arco dourado a partir do topo.

var radius := 50.0
var fraction := 0.0
var color := DS.STAR_GOLD
var width := 7.0


func _init(r: float = 50.0, f: float = 0.0) -> void:
	radius = r
	fraction = clampf(f, 0.0, 1.0)


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(1, 1, 1, 0.18), width, true)
	if fraction > 0.0:
		draw_arc(Vector2.ZERO, radius, -PI * 0.5, -PI * 0.5 + TAU * fraction, 64, color, width, true)
