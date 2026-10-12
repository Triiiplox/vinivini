class_name FonoFace
extends Node2D
## Rosto-guia da fono (personagem genérico, não é o Vini): mostra o movimento da academia da boca e a posição da
## boca de cada som. Desenhado em código, estilo livro infantil: cabeça com volume (degradê), cabelo em mechas com
## presilha de estrela, olhos grandes com brilho que acompanham a língua, bochechas que enchem de verdade.
## A boca (a protagonista) e as poses ficam em fono_face_mouth.gd / fono_face_poses.gd.
## Movimentos de repetição seguem `beat` (0..1, a academia avança); sem beat, um relógio próprio (~1,6 s).

const Paint := preload("res://src/fono/fono_face_paint.gd")
const Poses := preload("res://src/fono/fono_face_poses.gd")
const R := 150.0
const INK := Color("#3D2216")
const SKIN := Color("#F6C49E")
const SKIN_HI := Color("#FFE3CC")
const SKIN_LO := Color("#E5A47C")
const EAR_IN := Color("#E58F78")
const HAIR := Color("#7B4424")
const HAIR_HI := Color("#B4713F")
const HAIR_LO := Color("#4F2814")
const BLUSH := Color("#FF7E8C")
const IRIS_TOP := Color("#2B160B")
const IRIS_BOT := Color("#8C5631")
const OUT_W := R * 0.047  # contorno da silhueta (fica nítido até em 0,26×)
const LINE_W := R * 0.032
const CYCLE := 1.6

var pose := "neutro"
var beat := 0.0  ## 0..1 dentro de uma repetição (a tela avança)
var _t := 0.0
var _last_beat := 0.0
var _beat_live := 0.0  # > 0: a fase vem do beat; senão, do relógio próprio


func set_pose(p: String) -> void:
	pose = p
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if not is_equal_approx(beat, _last_beat):
		_last_beat = beat
		_beat_live = 0.4
	else:
		_beat_live = maxf(0.0, _beat_live - delta)
	queue_redraw()


func _phase() -> float:
	return clampf(beat, 0.0, 1.0) if _beat_live > 0.0 else fmod(_t / CYCLE, 1.0)


func _draw() -> void:
	var ph := _phase()
	var lk: Dictionary = Poses.look(pose, ph, _t)
	_ears()
	_head(lk.puff_l, lk.puff_r)
	_hair()
	_blush(lk.puff_l, lk.puff_r)
	_eyes(lk.gaze, lk.squint)
	_brows(lk.brow_up, lk.brow_tilt)
	_nose()
	Poses.draw(self, pose, ph, _t)
	if lk.effort > 0.0:
		_sweat(lk.effort)


func _ears() -> void:
	for s in [-1.0, 1.0]:
		var c := Vector2(s * R * 1.0, R * 0.07)
		var e := Paint.ellipse(c, R * 0.19, R * 0.23, 28)
		Paint.fill_lin(self, e, c + Vector2(0, -R * 0.2), SKIN, c + Vector2(0, R * 0.2), SKIN_LO)
		Paint.stroke(self, e, INK, OUT_W * 0.85)
		var ci := c + Vector2(s * R * 0.05, R * 0.01)
		Paint.glow(self, ci, R * 0.09, R * 0.14, EAR_IN, Color(EAR_IN, 0.25), 20)
		draw_arc(ci + Vector2(-s * R * 0.01, 0), R * 0.07, -PI / 2.0 if s > 0 else PI / 2.0,
			PI / 2.0 if s > 0 else PI * 1.5, 10, Color(INK, 0.55), LINE_W * 0.7, true)


## Silhueta da cabeça; as bochechas estufam para fora quando cheias de ar.
func _head_pts(pl: float, pr: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 80:
		var a := TAU * i / 80.0
		var r := R * (1.0 + 0.04 * sin(a))
		r += R * 0.2 * pr * exp(-pow(angle_difference(a, 0.55) / 0.45, 2.0))
		r += R * 0.2 * pl * exp(-pow(angle_difference(a, PI - 0.55) / 0.45, 2.0))
		pts.append(Vector2(cos(a) * r * 1.02, sin(a) * r * 0.97))
	return pts


func _head(pl: float, pr: float) -> void:
	var pts := _head_pts(pl, pr)
	Paint.fill_lin(self, pts, Vector2(-R * 0.45, -R * 0.9), SKIN_HI, Vector2(R * 0.35, R * 1.0), SKIN_LO)
	Paint.glow(self, Vector2(-R * 0.25, -R * 0.35), R * 0.6, R * 0.5, Color(1, 1, 1, 0.28), Color(1, 1, 1, 0.0))
	Paint.stroke(self, pts, INK, OUT_W)
	for s in [-1.0, 1.0]:
		var k: float = pr if s > 0 else pl
		if k > 0.05:
			var c := Vector2(s * R * (0.72 + 0.12 * k), R * 0.36)
			Paint.glow(self, c + Vector2(-s * R * 0.05, -R * 0.08), R * 0.13 * k, R * 0.09 * k, Color(1, 1, 1, 0.75 * k),
				Color(1, 1, 1, 0.0), 16)
			draw_arc(c, R * 0.24 * (0.6 + 0.4 * k), -0.4 if s > 0 else PI - 0.6, 0.6 if s > 0 else PI + 0.4, 10,
				Color(SKIN_LO.darkened(0.1), 0.6 * k), LINE_W * 0.6, true)


func _hair() -> void:
	# tufinho no alto (fica atrás do cabelo)
	var tuft := Paint.bez(Vector2(-R * 0.18, -R * 0.86), Vector2(-R * 0.05, -R * 1.32), Vector2(R * 0.28, -R * 1.22), 10)
	tuft.append_array(Paint.bez(Vector2(R * 0.28, -R * 1.22), Vector2(R * 0.05, -R * 1.12), Vector2(R * 0.12, -R * 0.86), 10))
	Paint.blob(self, tuft, HAIR_HI, HAIR, OUT_W * 0.85)
	var pts := PackedVector2Array()
	for i in 41:
		var a := lerpf(PI + 0.1, TAU - 0.1, i / 40.0)
		var r := R * (1.08 + 0.025 * sin(i * 0.9))
		pts.append(Vector2(cos(a) * r * 1.02, sin(a) * r * 0.98 - R * 0.02))
	var x0 := pts[pts.size() - 1].x
	var cusps := []
	var locks := 6
	for i in 73:
		var u := i / 72.0
		var x := lerpf(x0, -x0, u)
		var xn := x / x0
		var y_base := -R * 0.66 + R * 0.5 * xn * xn
		var fr := fmod(u * locks, 1.0)
		var depth := R * (0.15 - 0.03 * absf(xn))
		pts.append(Vector2(x, y_base + depth * pow(sin(PI * pow(fr, 1.35)), 0.8)))
		if i % 12 == 0 and i > 0 and i < 72:
			cusps.append(Vector2(x, y_base))
	Paint.fill_lin(self, pts, Vector2(0, -R * 1.1), HAIR_HI, Vector2(0, -R * 0.35), HAIR)
	for c in cusps:
		Paint.stroke(self, Paint.bez(c * Vector2(0.6, 1.0) + Vector2(0, -R * 0.3), c + Vector2(0, -R * 0.2), c + Vector2(0, -R * 0.02), 8),
			Color(HAIR_LO, 0.7), LINE_W * 0.7, false)
	# brilho em meia-lua (afina nas pontas)
	var shine := PackedVector2Array()
	for i in 15:
		var a := lerpf(PI + 0.5, PI + 1.3, i / 14.0)
		shine.append(Vector2(cos(a), sin(a) * 0.97) * R * (0.95 + 0.05 * sin(PI * i / 14.0)))
	for i in range(14, -1, -1):
		var a := lerpf(PI + 0.5, PI + 1.3, i / 14.0)
		shine.append(Vector2(cos(a), sin(a) * 0.97) * R * 0.95)
	Paint.fill(self, shine, Color(HAIR_HI.lightened(0.4), 0.8))
	Paint.stroke(self, pts, INK, OUT_W)
	Paint.star(self, Vector2(R * 0.6, -R * 0.66), R * 0.11, Color("#FFC93C"), LINE_W * 0.75, 0.2)


func _blush(pl: float, pr: float) -> void:
	for s in [-1.0, 1.0]:
		var k: float = pr if s > 0 else pl
		var c := Vector2(s * R * (0.58 + 0.14 * k), R * (0.25 + 0.05 * k))
		Paint.glow(self, c, R * (0.15 + 0.04 * k), R * (0.1 + 0.03 * k), Color(BLUSH, 0.55), Color(BLUSH, 0.0), 20)


func _eyes(gaze: Vector2, squint: float) -> void:
	var blink := fmod(_t + 1.3, 4.3) > 4.16
	for s in [-1.0, 1.0]:
		var e := Vector2(s * R * 0.36, -R * 0.07)
		var rx := R * 0.135
		var ry := R * 0.16
		if blink:
			draw_arc(e + Vector2(0, -ry * 0.2), rx, PI * 0.15, PI * 0.85, 12, INK, LINE_W * 1.1, true)
			continue
		var sc := Paint.ellipse(e, rx, ry, 32)
		Paint.fill_lin(self, sc, e + Vector2(0, -ry), Color.WHITE, e + Vector2(0, ry), Color("#DCE5F2"))
		var ic := e + Vector2(gaze.x * R * 0.04, gaze.y * R * 0.05 + R * 0.015)
		Paint.fill_clip(self, Paint.ellipse(ic, R * 0.098, R * 0.105, 28), sc, IRIS_TOP, IRIS_BOT)
		Paint.fill_clip(self, Paint.ellipse(ic, R * 0.05, R * 0.054, 20), sc, Color("#120904"), Color("#2A170C"))
		draw_circle(ic + Vector2(-R * 0.035, -R * 0.04), R * 0.036, Color.WHITE, true, -1.0, true)
		draw_circle(ic + Vector2(R * 0.035, R * 0.035), R * 0.016, Color(1, 1, 1, 0.9), true, -1.0, true)
		if squint > 0.01:
			var cut := Paint.ellipse(e + Vector2(0, ry * (2.15 - squint * 1.1)), rx * 1.7, ry * 1.25, 32)
			for poly in Geometry2D.intersect_polygons(cut, sc):
				Paint.fill(self, poly, SKIN)
			draw_arc(e + Vector2(0, ry * (2.15 - squint * 1.1)), ry * 1.25, -PI / 2.0 - 0.5, -PI / 2.0 + 0.5, 10,
				Color(INK, 0.8), LINE_W * 0.7, true)
		Paint.stroke(self, sc, INK, LINE_W * 0.8)
		# pálpebra de cima mais grossa e cílios no canto de fora
		var lid := PackedVector2Array()
		for i in 13:
			var a := lerpf(PI + 0.25, TAU - 0.25, i / 12.0)
			lid.append(e + Vector2(cos(a) * rx * 1.02, sin(a) * ry * 1.02))
		Paint.stroke(self, lid, INK, LINE_W * 1.3, false)
		var corner := e + Vector2(s * rx * 0.9, -ry * 0.45)
		for i in 2:
			var d := Vector2(s * (0.8 - 0.35 * i), -0.6 - 0.5 * i).normalized()
			Paint.stroke(self, Paint.bez(corner - Vector2(s * i * R * 0.03, i * R * 0.03), corner + d * R * 0.04 + Vector2(0, -R * 0.01),
				corner + d * R * 0.075 + Vector2(s * R * 0.01, 0), 6), INK, LINE_W * 0.65, false)


func _brows(up: float, tilt: float) -> void:
	for s in [-1.0, 1.0]:
		var c := Vector2(s * R * 0.36, -R * (0.36 + 0.07 * up))
		var a := c + Vector2(-s * R * 0.13, R * 0.02 - tilt * R * 0.05)
		var b := c + Vector2(s * R * 0.13, R * 0.025 + tilt * R * 0.01)
		Paint.stroke(self, Paint.bez(a, c + Vector2(0, -R * 0.06), b, 10), HAIR_LO, R * 0.06, false)


func _nose() -> void:
	var c := Vector2(0, R * 0.17)
	Paint.glow(self, c + Vector2(0, R * 0.01), R * 0.085, R * 0.06, Color(SKIN_LO.darkened(0.05), 0.9), Color(SKIN_LO, 0.0), 18)
	draw_arc(c + Vector2(0, -R * 0.02), R * 0.055, 0.45, PI - 0.45, 10, Color(INK, 0.75), LINE_W * 0.8, true)
	draw_circle(c + Vector2(-R * 0.025, -R * 0.03), R * 0.02, Color(1, 1, 1, 0.75), true, -1.0, true)


## Gotinha de esforço (exercícios de "segurar firme").
func _sweat(k: float) -> void:
	var c := Vector2(R * 0.9, -R * 0.5 + sin(_t * 3.0) * R * 0.02)
	var pts := PackedVector2Array()
	for i in 21:
		var a := lerpf(-0.6, PI + 0.6, i / 20.0)
		pts.append(c + Vector2(cos(a), sin(a)) * R * 0.065)
	pts.append(c + Vector2(0, -R * 0.15))
	Paint.blob(self, pts, Color("#E8F7FF", k), Color("#7CCBFF", k), LINE_W * 0.7)
	draw_circle(c + Vector2(-R * 0.02, -R * 0.0), R * 0.018, Color(1, 1, 1, 0.9 * k), true, -1.0, true)
