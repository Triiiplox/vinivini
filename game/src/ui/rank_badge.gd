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
	# escudo: círculo com ponta embaixo
	var pts := PackedVector2Array()
	for i in 40:
		var a := PI * 0.75 + (PI * 1.5) * i / 39.0  # de baixo-esquerda até baixo-direita passando por cima
		pts.append(c + Vector2.from_angle(a + PI) * r * Vector2(1, 0.92))
	pts.append(c + Vector2(0, r * 1.05))
	draw_colored_polygon(pts, Color("#1E3A8A"))
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color("#FACC15"), maxf(3.0, s * 0.05), true)
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
