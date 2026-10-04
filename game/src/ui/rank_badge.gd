class_name RankBadge
extends Control
## Insígnia da patente (ADR-036): escudo azul com borda dourada e N estrelas (1 a 9), uma a mais por patente.
## Lê sem saber ler: mais estrelas = patente mais alta.

var rank := 0


func _init(r: int = 0) -> void:
	rank = r
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_rank(r: int) -> void:
	rank = r
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := size / 2.0
	var r := s * 0.47
	# medalha: fitas atrás, disco azul com aro dourado
	var rib := PackedVector2Array([c + Vector2(-r * 0.55, r * 0.35), c + Vector2(-r * 0.15, r * 0.35),
		c + Vector2(-r * 0.3, r * 1.05), c + Vector2(-r * 0.5, r * 0.85), c + Vector2(-r * 0.7, r * 1.0)])
	draw_colored_polygon(rib, Color("#DC2626"))
	var rib2 := PackedVector2Array()
	for p in rib:
		rib2.append(Vector2(2.0 * c.x - p.x, p.y))
	draw_colored_polygon(rib2, Color("#DC2626"))
	draw_circle(c, r * 0.86, Color("#FACC15"))
	draw_circle(c, r * 0.74, Color("#1E3A8A"))
	var n := clampi(rank + 1, 1, 9)
	# estrelas em fileiras de até 3, de cima para baixo
	var rows := ceili(n / 3.0)
	var sr := s * (0.13 if n <= 3 else 0.1)
	var gap := sr * 2.3
	var k := 0
	for row in rows:
		var in_row := mini(3, n - row * 3)
		for j in in_row:
			var p := c + Vector2((j - (in_row - 1) / 2.0) * gap, (row - (rows - 1) / 2.0) * gap * 0.95 - s * 0.02)
			_star(p, sr)
			k += 1


func _star(p: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(p + Vector2.from_angle(-PI / 2.0 + TAU * i / 10.0) * rr)
	draw_colored_polygon(pts, Color("#FACC15"))
