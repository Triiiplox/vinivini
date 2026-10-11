class_name FonoFace
extends Node2D
## Rosto que mostra o movimento (academia da boca) e a posição da boca de cada som (pista visual). Desenhado em
## código no estilo das cartelas da fono (macaquinho/gatinho): cabeça grande, boca grande e clara. Movimentos de
## repetição se mexem sozinhos (bico ↔ sorriso, bochecha ↔ bochecha, língua girando) no ritmo da contagem.

const SKIN := Color("#F6C99B")
const INK := Color("#3B2A1A")
const LIP := Color("#E36A6A")
const TONGUE := Color("#F48FA6")
const MOUTH := Color("#5A1E28")
const TEETH := Color("#FFFFFF")
const R := 150.0

var pose := "neutro"
var beat := 0.0  ## 0..1 dentro de uma repetição (a tela avança)
var _t := 0.0


func set_pose(p: String) -> void:
	pose = p
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	# orelhas, cabeça, cabelo, olhos, nariz
	for s in [-1.0, 1.0]:
		draw_circle(Vector2(s * R * 0.98, -R * 0.05), R * 0.28, INK)
		draw_circle(Vector2(s * R * 0.98, -R * 0.05), R * 0.24, SKIN.darkened(0.08))
	draw_circle(Vector2.ZERO, R + 5.0, INK)
	draw_circle(Vector2.ZERO, R, SKIN)
	draw_arc(Vector2(0, -R * 0.15), R * 0.98, PI * 1.08, PI * 1.92, 24, Color("#E9A23B"), R * 0.32, true)
	for s in [-1.0, 1.0]:
		var e := Vector2(s * R * 0.34, -R * 0.2)
		draw_circle(e, R * 0.14, Color.WHITE)
		draw_circle(e + Vector2(0, R * 0.02), R * 0.08, INK)
		draw_circle(e + Vector2(-R * 0.02, -R * 0.02), R * 0.03, Color.WHITE)
		draw_arc(e + Vector2(0, -R * 0.05), R * 0.18, PI * 1.2, PI * 1.8, 10, INK, 5.0, true)
	draw_arc(Vector2(0, R * 0.05), R * 0.08, 0.2, PI - 0.2, 10, INK, 5.0, true)
	var swing := sin(_t * TAU * 0.9)  # vai e volta ~1 vez por segundo
	var cheekl := 0.0
	var cheekr := 0.0
	var m := Vector2(0, R * 0.45)
	match pose:
		"lingua_cima", "ceu_boca", "estalo", "r":
			_open(m, R * 0.34, R * 0.26)
			if pose == "lingua_cima":
				_tongue_out(m + Vector2(0, -R * 0.02), Vector2(0, -1), R * 0.32)
			else:
				_tongue_up_inside(m, R * 0.34, R * 0.26, 0.5 + 0.5 * swing if pose != "ceu_boca" else 1.0)
		"lingua_baixo":
			_open(m, R * 0.3, R * 0.22)
			_tongue_out(m + Vector2(0, R * 0.05), Vector2(0, 1), R * 0.36)
		"lingua_direita", "lingua_esquerda":
			_open(m, R * 0.3, R * 0.18)
			_tongue_out(m, Vector2(-1 if pose == "lingua_direita" else 1, 0.15).normalized(), R * 0.38)
		"bochecha_dentro":
			_smile(m, R * 0.28, false)
			cheekr = 0.5 + 0.5 * swing
		"bico", "ch", "j":
			_pucker(m, R * 0.16 + (0.0 if pose == "bico" else R * 0.03), pose != "bico")
			if pose != "bico":
				_air(m + Vector2(0, R * 0.06), pose == "j")
		"sorriso_fechado", "labios_fechados":
			_smile(m, R * 0.36, false)
		"sorriso_dentes", "s", "ti":
			_smile(m, R * 0.38, true)
			if pose == "s":
				_air(m + Vector2(0, R * 0.08), false)
		"bico_sorriso":
			if swing > 0.0:
				_pucker(m, R * 0.17, false)
			else:
				_smile(m, R * 0.36, false)
		"bico_aberto":
			_open(m, R * 0.18, R * 0.2)
		"inflar":
			_smile(m, R * 0.2, false)
			cheekl = 1.0
			cheekr = 1.0
		"inflar_alterna":
			_smile(m, R * 0.2, false)
			cheekl = 0.5 + 0.5 * swing
			cheekr = 0.5 - 0.5 * swing
		"varrer":
			_open(m, R * 0.34, R * 0.26)
			_tongue_up_inside(m, R * 0.34, R * 0.26, 0.6 + 0.4 * swing)
		"lamber_labios":
			_open(m, R * 0.3, R * 0.2)
			var a := _t * TAU * 0.6
			_tongue_out(m + Vector2(cos(a), sin(a)) * R * 0.2, Vector2(cos(a), sin(a)), R * 0.22)
		"vibrar_labios":
			_smile(m, R * 0.26, false)
			for i in 3:
				var y := m.y - R * 0.12 + i * R * 0.12
				draw_line(Vector2(R * 0.36, y), Vector2(R * 0.5 + 6.0 * sin(_t * 40.0 + i), y), INK, 4.0, true)
		"morder_labio":
			_smile(m, R * 0.3, false)
			for i in 4:
				draw_rect(Rect2(m + Vector2(-R * 0.16 + i * R * 0.08, -R * 0.08), Vector2(R * 0.07, R * 0.08)), TEETH)
		"lingua_larga":
			_open(m, R * 0.34, R * 0.2)
			_tongue_out(m + Vector2(0, R * 0.04), Vector2(0, 1), R * 0.26, 1.6)
		"lingua_fina":
			_open(m, R * 0.26, R * 0.18)
			_tongue_out(m + Vector2(0, R * 0.04), Vector2(0, 1), R * 0.3, 0.55)
		"nd":
			_open(m, R * 0.3, R * 0.2)
			_tongue_up_inside(m, R * 0.3, R * 0.2, 1.0)
		_:
			_smile(m, R * 0.3, false)
	for s in [-1.0, 1.0]:
		var k := cheekl if s < 0 else cheekr
		var c := Vector2(s * R * 0.55, R * 0.3)
		if k > 0.05:
			var cc := c + Vector2(s * R * 0.12 * k, 0)
			var cr := R * (0.2 + 0.12 * k)
			var a0 := -PI / 2.0 + (0.0 if s > 0 else PI)
			draw_circle(cc, cr, SKIN.darkened(0.03))
			draw_arc(cc, cr, a0, a0 + PI, 12, INK, 3.0, true)
		draw_circle(c, R * 0.1, Color(1, 0.45, 0.45, 0.35))


func _smile(m: Vector2, w: float, teeth: bool) -> void:
	if teeth:
		var r := Rect2(m + Vector2(-w, -w * 0.25), Vector2(w * 2.0, w * 0.5))
		draw_rect(r.grow(5.0), LIP)
		draw_rect(r, TEETH)
		for i in 6:
			var x := r.position.x + (i + 1) * r.size.x / 7.0
			draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color(0.7, 0.7, 0.75), 2.0)
		draw_line(Vector2(r.position.x, r.get_center().y), Vector2(r.end.x, r.get_center().y), Color(0.7, 0.7, 0.75), 2.0)
		return
	draw_arc(m + Vector2(0, -w * 0.6), w, 0.35, PI - 0.35, 18, LIP, 10.0, true)


func _open(m: Vector2, w: float, h: float) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(m + Vector2(cos(a) * w, sin(a) * h))
	draw_colored_polygon(pts, MOUTH)
	pts.append(pts[0])
	draw_polyline(pts, LIP, 8.0, true)
	draw_rect(Rect2(m + Vector2(-w * 0.55, -h + 3.0), Vector2(w * 1.1, h * 0.25)), TEETH)


func _pucker(m: Vector2, r: float, open_hole: bool) -> void:
	draw_circle(m, r + 8.0, LIP.darkened(0.15))
	draw_circle(m, r, LIP)
	draw_circle(m, r * (0.45 if open_hole else 0.25), MOUTH)
	for i in 6:
		var a := TAU * i / 6.0
		draw_line(m + Vector2(cos(a), sin(a)) * r * 0.5, m + Vector2(cos(a), sin(a)) * r * 0.95, LIP.darkened(0.3), 2.0, true)


func _tongue_out(base: Vector2, dir: Vector2, length: float, width: float = 1.0) -> void:
	var n := dir.orthogonal()
	var w := R * 0.13 * width
	var tip := base + dir * length
	var pts := PackedVector2Array([base + n * w, tip + n * w * 0.9, tip + dir * w, tip - n * w * 0.9, base - n * w])
	draw_colored_polygon(pts, TONGUE)
	draw_polyline(pts, TONGUE.darkened(0.25), 3.0, true)
	draw_line(base, tip, TONGUE.darkened(0.2), 2.0, true)


## Língua dentro da boca: k = 0 deitada, 1 com a ponta lá em cima (atrás dos dentes / céu da boca).
func _tongue_up_inside(m: Vector2, w: float, h: float, k: float) -> void:
	var tip := m + Vector2(0, lerpf(h * 0.4, -h * 0.65, k))
	var pts := PackedVector2Array([m + Vector2(-w * 0.75, h * 0.6), tip + Vector2(-w * 0.2, 0), tip, tip + Vector2(w * 0.2, 0),
		m + Vector2(w * 0.75, h * 0.6)])
	draw_colored_polygon(pts, TONGUE)


## Linhas de ar saindo (o chiado); j = vibrando (ondinhas).
func _air(m: Vector2, j: bool) -> void:
	for i in 3:
		var k := fmod(_t * 1.6 + i / 3.0, 1.0)
		var y := m.y + R * 0.1 + k * R * 0.5
		var x0 := (i - 1) * R * 0.12
		if j:
			var pts := PackedVector2Array()
			for s in 8:
				pts.append(Vector2(x0 + sin(s * 1.4 + _t * 12.0) * 6.0, y + s * 4.0))
			draw_polyline(pts, Color(0.4, 0.75, 1.0, 1.0 - k), 4.0, true)
		else:
			draw_line(Vector2(x0, y), Vector2(x0, y + R * 0.15), Color(0.4, 0.75, 1.0, 1.0 - k), 5.0, true)
