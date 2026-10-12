extends RefCounted
## Pincéis do FonoFace: preenchimento com degradê (cor por vértice), brilho radial, contorno suave e setas.
## Tudo é estático e desenha no CanvasItem recebido (chamar só de dentro do _draw dele).

const INK := Color("#3D2216")
const ARROW := Color("#FFD23F")


static func ellipse(c: Vector2, rx: float, ry: float, n: int = 36) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		p.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return p


## Curva de Bézier quadrática a → b puxada por c.
static func bez(a: Vector2, c: Vector2, b: Vector2, n: int = 14) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n + 1:
		var u := i / float(n)
		p.append(a.lerp(c, u).lerp(c.lerp(b, u), u))
	return p


static func fill(ci: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	fill_lin(ci, pts, Vector2.ZERO, col, Vector2.DOWN, col)


## Polígono com degradê linear de p0 (cor c0) até p1 (cor c1). Polígono inválido é ignorado em silêncio.
static func fill_lin(ci: CanvasItem, pts: PackedVector2Array, p0: Vector2, c0: Color, p1: Vector2, c1: Color) -> void:
	if pts.size() < 3:
		return
	var idx := Geometry2D.triangulate_polygon(pts)
	if idx.is_empty():
		return
	var d := p1 - p0
	var dd := maxf(d.length_squared(), 0.0001)
	var cols := PackedColorArray()
	cols.resize(pts.size())
	for i in pts.size():
		cols[i] = c0.lerp(c1, clampf((pts[i] - p0).dot(d) / dd, 0.0, 1.0))
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), idx, pts, cols)


## Degradê de várias paradas ao longo de p0 → p1 (stops em 0..1, crescentes).
static func fill_grad(ci: CanvasItem, pts: PackedVector2Array, p0: Vector2, p1: Vector2, cols: Array, stops: Array) -> void:
	if pts.size() < 3:
		return
	var idx := Geometry2D.triangulate_polygon(pts)
	if idx.is_empty():
		return
	var d := p1 - p0
	var dd := maxf(d.length_squared(), 0.0001)
	var out := PackedColorArray()
	out.resize(pts.size())
	for i in pts.size():
		var u := clampf((pts[i] - p0).dot(d) / dd, 0.0, 1.0)
		var k := 1
		while k < stops.size() - 1 and u > float(stops[k]):
			k += 1
		var a := inverse_lerp(float(stops[k - 1]), float(stops[k]), u)
		out[i] = (cols[k - 1] as Color).lerp(cols[k], clampf(a, 0.0, 1.0))
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), idx, pts, out)


## Recorta `pts` por `clip` (ex.: íris dentro do branco do olho) e pinta com degradê vertical.
static func fill_clip(ci: CanvasItem, pts: PackedVector2Array, clip: PackedVector2Array, c0: Color, c1: Color) -> void:
	for poly in Geometry2D.intersect_polygons(pts, clip):
		var top := INF
		var bot := -INF
		for p in poly:
			top = minf(top, p.y)
			bot = maxf(bot, p.y)
		fill_lin(ci, poly, Vector2(0, top), c0, Vector2(0, bot), c1)


## Brilho/sombra radial: cor c_in no centro esmaecendo até c_out na borda da elipse.
static func glow(ci: CanvasItem, c: Vector2, rx: float, ry: float, c_in: Color, c_out: Color, n: int = 28) -> void:
	var pts := PackedVector2Array([c])
	var cols := PackedColorArray([c_in])
	var idx := PackedInt32Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		cols.append(c_out)
		idx.append_array([0, 1 + i, 1 + (i + 1) % n])
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), idx, pts, cols)


## Contorno suavizado; aberto ganha pontas redondas.
static func stroke(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float, closed: bool = true) -> void:
	if pts.size() < 2:
		return
	var p := pts
	if closed:
		p = pts.duplicate()
		p.append(pts[0])
		p.append(pts[1])
	ci.draw_polyline(p, col, w, true)
	if not closed:
		ci.draw_circle(pts[0], w * 0.5, col, true, -1.0, true)
		ci.draw_circle(pts[pts.size() - 1], w * 0.5, col, true, -1.0, true)


## Forma com degradê vertical (claro em cima) e contorno de tinta.
static func blob(ci: CanvasItem, pts: PackedVector2Array, top: Color, bottom: Color, ink_w: float) -> void:
	var y0 := INF
	var y1 := -INF
	for p in pts:
		y0 = minf(y0, p.y)
		y1 = maxf(y1, p.y)
	fill_lin(ci, pts, Vector2(0, y0), top, Vector2(0, y1), bottom)
	if ink_w > 0.0:
		stroke(ci, pts, INK, ink_w)


## Seta curva amarela com contorno (a → b, puxada por c). `both` põe ponta nos dois lados.
static func arrow(ci: CanvasItem, a: Vector2, c: Vector2, b: Vector2, w: float, alpha: float = 1.0, both: bool = false) -> void:
	if alpha <= 0.02:
		return
	var line := bez(a, c, b, 16)
	var head := w * 2.1
	var tips := [[b, (b - c).normalized()]]
	if both:
		tips.append([a, (a - c).normalized()])
	var body := PackedVector2Array()
	for p in line:
		if p.distance_to(b) > head * 0.8 and (not both or p.distance_to(a) > head * 0.8):
			body.append(p)
	var ink := Color(INK, alpha)
	var col := Color(ARROW, alpha)
	var tris := []
	for tp in tips:
		var tip: Vector2 = tp[0]
		var dir: Vector2 = tp[1]
		var base := tip - dir * head
		var n := dir.orthogonal() * head * 0.8
		tris.append(PackedVector2Array([tip + dir * w * 0.2, base + n, base - n]))
	stroke(ci, body, ink, w * 1.9, false)
	for t in tris:
		stroke(ci, t, ink, w * 0.9)
	stroke(ci, body, col, w, false)
	for t in tris:
		fill(ci, t, col)


## Estrelinha (enfeite espacial / "pow" do estalo).
static func star(ci: CanvasItem, c: Vector2, r: float, col: Color, ink_w: float, rot: float = 0.0) -> void:
	var p := PackedVector2Array()
	for i in 10:
		var a := rot - PI / 2.0 + PI * i / 5.0
		p.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.48))
	fill_lin(ci, p, c + Vector2(0, -r), col.lightened(0.35), c + Vector2(0, r), col)
	if ink_w > 0.0:
		stroke(ci, p, INK, ink_w)
