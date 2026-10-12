class_name FonoFace
extends Node2D
## Rosto-guia da fono: o Vini em versão cartoon, de astronauta (gola do traje), desenhado em código. Cabelo
## acobreado de cachinhos, pele morena clara, olhos castanhos grandes que acompanham a língua, orelhas salientes,
## bochechas que enchem de verdade. A boca (a protagonista) e as poses ficam em fono_face_mouth.gd,
## fono_face_tongue.gd, fono_face_lips.gd e fono_face_poses.gd.
## Todo exercício se mexe em ciclo completo (repouso → posição → volta). O ciclo segue `beat` (0..1) enquanto a
## academia o avança; sem beat, um relógio próprio (1,6 s; 3,5 s nas poses "_segura").

const Paint := preload("res://src/fono/fono_face_paint.gd")
const Poses := preload("res://src/fono/fono_face_poses.gd")
const R := 150.0
const INK := Color("#3A2015")
const SKIN := Color("#EEBC92")
const SKIN_HI := Color("#FCDCBE")
const SKIN_LO := Color("#D3976A")
const EAR_IN := Color("#D9806C")
const HAIR := Color("#A8653A")
const HAIR_HI := Color("#E3A468")
const HAIR_LO := Color("#6A3A1E")
const BROW := Color("#5A2F17")
const BLUSH := Color("#F2766A")
const IRIS_RIM := Color("#24110A")
const IRIS_TOP := Color("#3A1C0D")
const IRIS_BOT := Color("#9A5A2C")
const SUIT := Color("#F4F7FC")
const SUIT_LO := Color("#C9D3E4")
const SUIT_BLUE := Color("#2C59CF")
const SUIT_ORANGE := Color("#FF8A24")
const LIGHT_ON := Color("#FFC93C")
const OUT_W := R * 0.047  # contorno da silhueta (fica nítido até em 0,26×)
const LINE_W := R * 0.032
## Sons novos usam a boca mais parecida: LH (meio da língua no céu da boca), encontros e R final (toque do R).
const ALIAS := {"lh": "ceu_boca", "encontros_r": "r", "r_final": "r", "encontros_l": "lingua_cima"}

var pose := "neutro"
var beat := 0.0  ## 0..1 dentro de uma repetição (a tela avança)
var _t := 0.0
var _last_beat := 0.0
var _beat_live := 0.0  # > 0: a fase vem do beat; senão, do relógio próprio


func set_pose(p: String) -> void:
	pose = str(ALIAS.get(p, p))
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
	return clampf(beat, 0.0, 1.0) if _beat_live > 0.0 else fmod(_t / Poses.cycle(pose), 1.0)


func _draw() -> void:
	var ph := _phase()
	var lk: Dictionary = Poses.look(pose, ph)
	_collar(lk.dots)
	_ears()
	_head(lk.puff_l, lk.puff_r)
	_hair()
	_blush(lk.puff_l, lk.puff_r)
	_eyes(lk.gaze, lk.squint)
	_brows(lk.brow_up, lk.brow_tilt)
	_nose()
	Poses.draw(self, pose, ph)
	if lk.effort > 0.01:
		_sweat(lk.effort)


## Gola do traje de astronauta (branca, faixa azul, detalhes laranja) com 3 luzinhas: nas poses "_segura" elas
## acendem uma a uma enquanto ele segura a posição.
func _collar(dots: float) -> void:
	var neck := PackedVector2Array([Vector2(-R * 0.3, R * 0.7), Vector2(R * 0.3, R * 0.7), Vector2(R * 0.3, R * 1.05),
		Vector2(-R * 0.3, R * 1.05)])
	Paint.fill(self, neck, SKIN_LO)
	var ring := Paint.ellipse(Vector2(0, R * 1.04), R * 0.76, R * 0.15, 40)
	Paint.fill_lin(self, ring, Vector2(0, R * 0.92), SUIT, Vector2(0, R * 1.18), SUIT_LO)
	Paint.stroke(self, ring, INK, OUT_W * 0.8)
	var band := Paint.ellipse(Vector2(0, R * 0.985), R * 0.5, R * 0.075, 32)
	Paint.fill_lin(self, band, Vector2(0, R * 0.92), SUIT_BLUE.lightened(0.2), Vector2(0, R * 1.06), SUIT_BLUE.darkened(0.2))
	Paint.stroke(self, band, INK, LINE_W * 0.6)
	for s in [-1.0, 1.0]:
		var c := Vector2(s * R * 0.6, R * 1.06)
		var tab := Paint.ellipse(c, R * 0.075, R * 0.04, 16)
		Paint.fill_lin(self, tab, c + Vector2(0, -R * 0.04), SUIT_ORANGE.lightened(0.25), c + Vector2(0, R * 0.04), SUIT_ORANGE)
		Paint.stroke(self, tab, INK, LINE_W * 0.5)
	for i in 3:
		var c := Vector2((i - 1) * R * 0.19, R * (1.115 + (0.014 if i == 1 else 0.0)))
		var on := clampf(dots - i, 0.0, 1.0)
		if on > 0.0:
			Paint.glow(self, c, R * 0.1 * on, R * 0.08 * on, Color(LIGHT_ON, 0.7 * on), Color(LIGHT_ON, 0.0), 14)
		draw_circle(c, R * 0.046, Color("#7F8CA6").lerp(LIGHT_ON, on), true, -1.0, true)
		draw_circle(c + Vector2(-R * 0.014, -R * 0.014), R * 0.014, Color(1, 1, 1, 0.8), true, -1.0, true)
		draw_arc(c, R * 0.046, 0.0, TAU, 16, INK, LINE_W * 0.45, true)


func _ears() -> void:
	for s in [-1.0, 1.0]:
		var c := Vector2(s * R * 1.0, R * 0.08)
		var e := Paint.ellipse(c, R * 0.2, R * 0.24, 28)
		Paint.fill_lin(self, e, c + Vector2(0, -R * 0.24), SKIN, c + Vector2(0, R * 0.24), SKIN_LO)
		Paint.stroke(self, e, INK, OUT_W * 0.85)
		var ci := c + Vector2(s * R * 0.05, R * 0.01)
		Paint.glow(self, ci, R * 0.1, R * 0.15, EAR_IN, Color(EAR_IN, 0.2), 20)
		draw_arc(ci + Vector2(-s * R * 0.015, 0), R * 0.08, -PI / 2.0 if s > 0 else PI / 2.0,
			PI / 2.0 if s > 0 else PI * 1.5, 10, Color(INK, 0.5), LINE_W * 0.7, true)


## Silhueta da cabeça; as bochechas estufam para fora quando cheias de ar (ou afinam, chupadas).
func _head_pts(pl: float, pr: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 80:
		var a := TAU * i / 80.0
		var r := R * (1.0 + 0.045 * sin(a))
		r += R * 0.2 * pr * exp(-pow(angle_difference(a, 0.55) / 0.45, 2.0))
		r += R * 0.2 * pl * exp(-pow(angle_difference(a, PI - 0.55) / 0.45, 2.0))
		pts.append(Vector2(cos(a) * r * 1.02, sin(a) * r * 0.97))
	return pts


func _head(pl: float, pr: float) -> void:
	var pts := _head_pts(pl, pr)
	Paint.fill_lin(self, pts, Vector2(-R * 0.45, -R * 0.9), SKIN_HI, Vector2(R * 0.35, R * 1.0), SKIN_LO)
	Paint.glow(self, Vector2(-R * 0.25, -R * 0.3), R * 0.6, R * 0.5, Color(1, 1, 1, 0.22), Color(1, 1, 1, 0.0))
	Paint.stroke(self, pts, INK, OUT_W)
	for s in [-1.0, 1.0]:
		var k: float = pr if s > 0 else pl
		if k > 0.05:
			var c := Vector2(s * R * (0.72 + 0.12 * k), R * 0.36)
			Paint.glow(self, c + Vector2(-s * R * 0.05, -R * 0.08), R * 0.13 * k, R * 0.09 * k, Color(1, 1, 1, 0.65 * k),
				Color(1, 1, 1, 0.0), 16)
			draw_arc(c, R * 0.24 * (0.6 + 0.4 * k), -0.4 if s > 0 else PI - 0.6, 0.6 if s > 0 else PI + 0.6, 10,
				Color(SKIN_LO.darkened(0.1), 0.6 * k), LINE_W * 0.6, true)


## Cachinhos: (x, y, raio) em unidades de R, de trás para a frente. Volume em cima, laterais curtinhas.
func _curls() -> Array:
	var c := []
	for i in 10:
		var a := lerpf(PI + 0.42, TAU - 0.42, i / 9.0)
		c.append(Vector3(cos(a) * 0.97, sin(a) * 0.95 - 0.03, 0.22 + 0.03 * sin(i * 2.7)))
	for s in [-1.0, 1.0]:
		c.append(Vector3(s * 0.87, -0.32, 0.15))
		c.append(Vector3(s * 0.93, -0.15, 0.1))
	for i in 6:
		var a := lerpf(PI + 0.62, TAU - 0.62, i / 5.0)
		c.append(Vector3(cos(a) * 0.64, sin(a) * 0.66 - 0.12, 0.21 + 0.02 * cos(i * 1.9)))
	for i in 5:
		var x := lerpf(-0.52, 0.52, i / 4.0)
		c.append(Vector3(x + 0.03 * sin(i * 2.0), -0.63 + 0.13 * x * x / 0.27, 0.17 + 0.015 * sin(i * 3.1)))
	return c


func _hair() -> void:
	var curls := _curls()
	for v in curls:
		draw_circle(Vector2(v.x, v.y) * R, v.z * R + OUT_W * 0.6, INK, true, -1.0, true)
	var base := PackedVector2Array()
	for i in 21:
		var a := lerpf(PI + 0.3, TAU - 0.3, i / 20.0)
		base.append(Vector2(cos(a) * 0.95, sin(a) * 0.92) * R)
	base.append(Vector2(0.55, -0.5) * R)
	base.append(Vector2(-0.55, -0.5) * R)
	Paint.fill(self, base, HAIR_LO)
	for i in curls.size():
		var v: Vector3 = curls[i]
		var c := Vector2(v.x, v.y) * R
		var r := v.z * R
		draw_circle(c, r, HAIR, true, -1.0, true)
		Paint.glow(self, c + Vector2(-r * 0.25, -r * 0.3), r * 0.75, r * 0.7, Color(HAIR_HI, 0.85), Color(HAIR_HI, 0.0), 16)
		draw_arc(c, r, 0.0, TAU, 20, Color(HAIR_LO, 0.9), LINE_W * 0.5, true)
		# o "cacho": uma voltinha (nos da frente) e um brilho
		if i >= 14:
			var rot := float(i) * 1.3
			draw_arc(c + Vector2(r * 0.08, r * 0.1), r * 0.48, rot, rot + 3.2, 12, Color(HAIR_LO, 0.55), LINE_W * 0.5, true)
		draw_arc(c, r * 0.72, PI * 1.1, PI * 1.45, 6, Color(HAIR_HI.lightened(0.35), 0.8), LINE_W * 0.45, true)


func _blush(pl: float, pr: float) -> void:
	for s in [-1.0, 1.0]:
		var k: float = pr if s > 0 else pl
		var c := Vector2(s * R * (0.58 + 0.14 * k), R * (0.25 + 0.05 * k))
		Paint.glow(self, c, R * (0.15 + 0.04 * k), R * (0.1 + 0.03 * k), Color(BLUSH, 0.45), Color(BLUSH, 0.0), 20)


func _eyes(gaze: Vector2, squint: float) -> void:
	var blink := fmod(_t + 1.3, 4.3) > 4.16
	for s in [-1.0, 1.0]:
		var e := Vector2(s * R * 0.36, -R * 0.07)
		var rx := R * 0.14
		var ry := R * 0.165
		if blink:
			draw_arc(e + Vector2(0, -ry * 0.2), rx, PI * 0.15, PI * 0.85, 12, INK, LINE_W * 1.1, true)
			continue
		var sc := Paint.ellipse(e, rx, ry, 32)
		Paint.fill_lin(self, sc, e + Vector2(0, -ry), Color("#D9E1EE"), e + Vector2(0, ry * 0.2), Color.WHITE)
		var ic := e + Vector2(gaze.x * R * 0.04, gaze.y * R * 0.05 + R * 0.015)
		Paint.fill_clip(self, Paint.ellipse(ic, R * 0.102, R * 0.108, 28), sc, IRIS_RIM, IRIS_RIM)
		Paint.fill_clip(self, Paint.ellipse(ic, R * 0.086, R * 0.092, 28), sc, IRIS_TOP, IRIS_BOT)
		Paint.fill_clip(self, Paint.ellipse(ic, R * 0.048, R * 0.052, 20), sc, Color("#0E0703"), Color("#21110A"))
		Paint.fill_clip(self, Paint.ellipse(ic + Vector2(0, R * 0.05), R * 0.06, R * 0.03, 16), sc, Color(1, 0.8, 0.55, 0.0),
			Color(1, 0.8, 0.55, 0.35))
		draw_circle(ic + Vector2(-R * 0.035, -R * 0.04), R * 0.037, Color.WHITE, true, -1.0, true)
		draw_circle(ic + Vector2(R * 0.036, R * 0.034), R * 0.016, Color(1, 1, 1, 0.9), true, -1.0, true)
		if squint > 0.01:
			var cut := Paint.ellipse(e + Vector2(0, ry * (2.15 - squint * 1.1)), rx * 1.7, ry * 1.25, 32)
			for poly in Geometry2D.intersect_polygons(cut, sc):
				Paint.fill(self, poly, SKIN)
			draw_arc(e + Vector2(0, ry * (2.15 - squint * 1.1)), ry * 1.25, -PI / 2.0 - 0.5, -PI / 2.0 + 0.5, 10,
				Color(INK, 0.8), LINE_W * 0.7, true)
		Paint.stroke(self, sc, INK, LINE_W * 0.8)
		# pálpebra de cima mais grossa, com um cílio no canto de fora
		var lid := PackedVector2Array()
		for i in 13:
			var a := lerpf(PI + 0.25, TAU - 0.25, i / 12.0)
			lid.append(e + Vector2(cos(a) * rx * 1.02, sin(a) * ry * 1.02))
		Paint.stroke(self, lid, INK, LINE_W * 1.3, false)
		var corner := e + Vector2(s * rx * 0.88, -ry * 0.5)
		Paint.stroke(self, Paint.bez(corner, corner + Vector2(s * R * 0.04, -R * 0.015), corner + Vector2(s * R * 0.065, -R * 0.005), 6),
			INK, LINE_W * 0.7, false)


func _brows(up: float, tilt: float) -> void:
	for s in [-1.0, 1.0]:
		var c := Vector2(s * R * 0.36, -R * (0.37 + 0.07 * up))
		var a := c + Vector2(-s * R * 0.13, R * 0.02 - tilt * R * 0.05)
		var b := c + Vector2(s * R * 0.13, R * 0.025 + tilt * R * 0.01)
		Paint.stroke(self, Paint.bez(a, c + Vector2(0, -R * 0.06), b, 10), BROW, R * 0.062, false)


func _nose() -> void:
	var c := Vector2(0, R * 0.17)
	Paint.glow(self, c + Vector2(0, R * 0.01), R * 0.09, R * 0.065, Color(SKIN_LO, 0.8), Color(SKIN_LO, 0.0), 18)
	draw_arc(c + Vector2(0, -R * 0.02), R * 0.06, 0.45, PI - 0.45, 10, Color(INK, 0.75), LINE_W * 0.8, true)
	draw_circle(c + Vector2(-R * 0.025, -R * 0.03), R * 0.022, Color(1, 1, 1, 0.7), true, -1.0, true)


## Gotinha de esforço (exercícios de "segurar firme").
func _sweat(k: float) -> void:
	var c := Vector2(R * 0.95, -R * 0.45)
	var pts := PackedVector2Array()
	for i in 21:
		var a := lerpf(-0.6, PI + 0.6, i / 20.0)
		pts.append(c + Vector2(cos(a), sin(a)) * R * 0.065)
	pts.append(c + Vector2(0, -R * 0.15))
	Paint.blob(self, pts, Color("#E8F7FF", k), Color("#7CCBFF", k), LINE_W * 0.7 * k)
	draw_circle(c + Vector2(-R * 0.02, 0), R * 0.018, Color(1, 1, 1, 0.9 * k), true, -1.0, true)
