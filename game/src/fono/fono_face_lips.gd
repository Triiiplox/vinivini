extends RefCounted
## Poses de LÁBIOS e BOCHECHAS do FonoFace: bico (e os sons CH/J), sorrisos (e o S), bico ↔ sorriso, Ô e A, lábios
## apertados, morder lábio, bochechas cheias/alternadas/chupadas (cara de peixe), língua empurrando a bochecha e
## vibrar os lábios. Todo ciclo parte do repouso, vai ao alvo, segura e volta. Espaço ampliado da boca (Mouth.MS).

const Paint := preload("res://src/fono/fono_face_paint.gd")
const Mouth := preload("res://src/fono/fono_face_mouth.gd")
const Tongue := preload("res://src/fono/fono_face_tongue.gd")
const R := 150.0
const M := Mouth.M
const AW := R * 0.035
const SKIN_HI := Color("#FBD7B6")
const SKIN_LO := Color("#C98A5C")


## Desenha a pose (qualquer id desconhecido vira o rosto neutro, parado).
static func draw(ci: CanvasItem, pose: String, ph: float) -> void:
	var g := Mouth.hold(ph)
	match pose:
		"bico", "bico_segura", "ch", "j", "bico_dentes_travados":
			_pucker(ci, pose, ph)
		"bico_sorriso":
			_pucker_smile(ci, ph)
		"bico_aberto":
			Mouth.draw(ci, M, _rest_to({"w": R * 0.11, "up": R * 0.11, "dn": R * 0.14, "round": 1.0, "lu": R * 0.06,
				"ld": R * 0.07, "tu": 0.5}, g, 0.0))
		"boca_de_a":
			var q := Mouth.open_p(R * 0.27, R * 0.15, R * 0.26)
			q.td = 0.4
			Mouth.draw(ci, M, _rest_to(q, g, 0.0))
		"sorriso_fechado", "sorriso_segura":
			var k := Tongue.hold_firm(ph) if pose == "sorriso_segura" else g
			var d := Mouth.draw(ci, M, Mouth.from_rest(Mouth.smile_p(R * 0.34, R * 0.12), k))
			_dimples(ci, d, k)
		"labios_fechados", "apertar_labios":
			_pressed(ci, g, pose == "apertar_labios")
		"sorriso_dentes", "s":
			var k := smoothstep(0.0, 0.18, ph) * (1.0 - smoothstep(0.82, 1.0, ph)) if pose == "s" else g
			var d := Mouth.draw(ci, M, _rest_to({"w": R * 0.33, "up": R * 0.08, "dn": R * 0.11, "curve": R * 0.1, "box": 3.0,
				"lu": R * 0.03, "ld": R * 0.042, "tu": 1.0, "td": 1.0, "bite": 1.0}, k, -1.0))
			_dimples(ci, d, k)
			if pose == "s":
				Mouth.air(ci, M + Vector2(R * 0.2, R * 0.02), [Vector2(1, 0.12)], ph, false, 0.55, smoothstep(0.6, 1.0, k))
		"inflar", "inflar_alterna":
			_puff(ci, pose, ph)
		"chupar_bochechas":
			_fish(ci, g)
		"vibrar_labios":
			_buzz(ci, ph, g)
		"morder_labio":
			_bite(ci, true, g)
		"morder_labio_cima":
			_bite(ci, false, g)
		"bochecha_dentro", "bochecha_alterna":
			_cheek_push(ci, ph, pose == "bochecha_alterna")
		_:
			Mouth.draw(ci, M, Mouth.neutral_p())


## Repouso → alvo, com a língua deitada (tk) quando a boca abre.
static func _rest_to(target: Dictionary, a: float, tk: float) -> Dictionary:
	var q := Mouth.from_rest(target, a)
	q.tk = tk if a > 0.1 else -1.0
	return q


## Lado e força da língua empurrando a bochecha (usado também pela expressão do rosto).
static func cheek_side(ph: float, alternate: bool) -> Vector2:
	if not alternate:
		return Vector2(1.0, Mouth.hold(ph))
	return Vector2(1.0 if ph < 0.5 else -1.0, Mouth.hold(fmod(ph * 2.0, 1.0)))


static func _cheek_push(ci: CanvasItem, ph: float, alternate: bool) -> void:
	var sk := cheek_side(ph, alternate)
	var s := sk.x
	var k := sk.y
	var q := Mouth.from_rest(Mouth.smile_p(R * 0.2, R * 0.025), k)
	Mouth.draw(ci, M + Vector2(-s * R * 0.03 * k, 0), q)
	if k < 0.02:
		return
	var c := Mouth.un(Vector2(s * R * 0.52, R * 0.47))
	var rb := R * (0.04 + 0.09 * k)
	Paint.glow(ci, c, rb * 1.15, rb * 1.15, Color(Mouth.TONGUE, 0.4 * k), Color(Mouth.TONGUE, 0.0))
	Paint.glow(ci, c + Vector2(-s * rb * 0.25, -rb * 0.3), rb * 0.9, rb * 0.8, Color(SKIN_HI, 0.95 * k), Color(SKIN_HI, 0.0))
	var a0 := -1.0 if s > 0 else PI - 1.0
	ci.draw_arc(c, rb, a0, a0 + 2.0, 16, Color(Paint.INK, 0.85 * k), R * 0.024, true)
	Paint.arrow(ci, c + Vector2(s * rb * 1.35, 0), c + Vector2(s * (rb * 1.35 + R * 0.08), -R * 0.03),
		c + Vector2(s * (rb * 1.35 + R * 0.17), R * 0.0), AW, smoothstep(0.5, 0.9, k))


static func _dimples(ci: CanvasItem, d: Dictionary, k: float) -> void:
	if k < 0.3:
		return
	var ou: PackedVector2Array = d.ou
	for p in [ou[0], ou[ou.size() - 1]]:
		var s := signf(p.x)
		var c: Vector2 = p + Vector2(s * R * 0.035, -R * 0.005)
		ci.draw_arc(c, R * 0.035, PI / 2.0 + s * 0.9 - 0.6, PI / 2.0 + s * 0.9 + 0.6, 8,
			Color(Paint.INK, 0.65 * smoothstep(0.3, 0.8, k)), R * 0.018, true)


## Lábios fechadinhos (repouso → apertados um contra o outro → solta), com setas.
static func _pressed(ci: CanvasItem, k: float, strong: bool) -> void:
	var press := {"w": R * 0.21, "lu": R * (0.03 if strong else 0.034), "ld": R * (0.036 if strong else 0.042), "curve": 0.0}
	var d := Mouth.draw(ci, M, Mouth.from_rest(press, k))
	var x: float = d.xo + R * 0.1
	var a := 0.25 + 0.75 * k
	Paint.arrow(ci, M + Vector2(x, -R * 0.2), M + Vector2(x + R * 0.01, -R * 0.13), M + Vector2(x, -R * 0.05), AW * 0.9, a)
	Paint.arrow(ci, M + Vector2(x, R * 0.2), M + Vector2(x + R * 0.01, R * 0.13), M + Vector2(x, R * 0.05), AW * 0.9, a)
	for s in [-1.0, 1.0]:
		var c := M + Vector2(s * (float(d.xo) + R * 0.025), 0)
		ci.draw_line(c + Vector2(0, -R * 0.03), c + Vector2(0, R * 0.03), Color(Paint.INK, 0.6 * k), R * 0.016, true)


## Bico (repouso → bico → volta). CH/J: bico com os dentes juntinhos lá dentro e o ar saindo em loop.
static func _pucker(ci: CanvasItem, pose: String, ph: float) -> void:
	var sound := pose == "ch" or pose == "j"
	var k := Mouth.hold(ph)
	if pose == "bico_segura":
		k = Tongue.hold_firm(ph)
	elif sound:
		k = smoothstep(0.0, 0.15, ph) * (1.0 - smoothstep(0.85, 1.0, ph))
	var hole := 0.0
	if sound:
		hole = 1.0
	elif pose == "bico_dentes_travados":
		hole = 1.35
	Mouth.draw(ci, M, _rest_to(Mouth.pucker_p(hole), k, -1.0))
	if not sound:
		return
	var air := smoothstep(0.5, 1.0, k)
	Mouth.air(ci, M + Vector2(R * 0.1, R * 0.03), [Vector2(1, -0.25), Vector2(1, 0.3), Vector2(0.8, 0.85)], ph, pose == "j",
		1.0, air)
	if pose == "j":
		for s in [-1.0, 1.0]:
			for i in 2:
				var a := (0.5 + 0.5 * sin(TAU * ph * 6.0 + i * 1.5)) * air
				ci.draw_arc(M + Vector2(s * R * 0.02, 0), R * (0.24 + 0.06 * i), -0.5 if s > 0 else PI - 0.5,
					0.5 if s > 0 else PI + 0.5, 10, Color(Mouth.AIR, 0.4 + 0.6 * a), R * 0.022, true)


## Quanto do bico e do sorriso aparecem no exercício bico ↔ sorriso (repouso → bico → sorriso → repouso).
static func pucker_smile(ph: float) -> Vector2:
	var pb := smoothstep(0.0, 0.15, ph) * (1.0 - smoothstep(0.42, 0.58, ph))
	var ps := smoothstep(0.42, 0.58, ph) * (1.0 - smoothstep(0.85, 1.0, ph))
	return Vector2(pb, ps)


static func _pucker_smile(ci: CanvasItem, ph: float) -> void:
	var a := pucker_smile(ph)
	var q := Mouth.mix(Mouth.from_rest(Mouth.pucker_p(0.0), a.x), Mouth.smile_p(R * 0.34, R * 0.12), a.y)
	var d := Mouth.draw(ci, M, q)
	var xo: float = d.xo
	for s in [-1.0, 1.0]:
		var c := M + Vector2(s * (xo + R * 0.13), -R * 0.02)
		Paint.arrow(ci, c - Vector2(s * R * 0.08, 0), c, c + Vector2(s * R * 0.1, -R * 0.02), R * 0.03, a.y)
		Paint.arrow(ci, c + Vector2(s * R * 0.1, 0), c, c - Vector2(s * R * 0.06, 0), R * 0.03, a.x)


## Ar nas bochechas: inflar = as duas enchem e esvaziam; alterna = o ar passa de um lado para o outro.
static func puffs(pose: String, ph: float) -> Vector2:
	if pose == "inflar":
		var k := Mouth.hold(ph)
		return Vector2(k, k)
	var air := smoothstep(0.0, 0.12, ph) * (1.0 - smoothstep(0.88, 1.0, ph))
	var a := smoothstep(0.18, 0.42, ph) - smoothstep(0.58, 0.82, ph)
	return Vector2(air * a, air * (1.0 - a))


static func _puff(ci: CanvasItem, pose: String, ph: float) -> void:
	var p := puffs(pose, ph)
	var k := maxf(p.x, p.y)
	Mouth.draw(ci, M, Mouth.from_rest({"w": R * 0.1, "round": 0.5, "lu": R * 0.052, "ld": R * 0.058, "curve": 0.0}, k))
	if pose != "inflar_alterna":
		return
	var go := smoothstep(0.2, 0.26, ph) * (1.0 - smoothstep(0.36, 0.44, ph))
	var back := smoothstep(0.6, 0.66, ph) * (1.0 - smoothstep(0.76, 0.84, ph))
	var y := M.y - R * 0.2
	Paint.arrow(ci, Vector2(R * 0.3, y), Vector2(0, y - R * 0.1), Vector2(-R * 0.3, y), AW, go)
	Paint.arrow(ci, Vector2(-R * 0.3, y), Vector2(0, y - R * 0.1), Vector2(R * 0.3, y), AW, back)


## Cara de peixe: bochechas chupadas para dentro (a silhueta afina) e lábios em bico.
static func _fish(ci: CanvasItem, k: float) -> void:
	for s in [-1.0, 1.0]:
		var c := Mouth.un(Vector2(s * R * 0.6, R * 0.42))
		ci.draw_arc(c, R * 0.13, PI / 2.0 - s * 0.2 - 1.0, PI / 2.0 - s * 0.2 + 1.0, 12, Color(SKIN_LO.darkened(0.15), 0.8 * k),
			R * 0.022, true)
		var o := Mouth.un(Vector2(s * R * 1.25, R * 0.4))
		var i := Mouth.un(Vector2(s * R * 0.95, R * 0.4))
		Paint.arrow(ci, o, (o + i) * 0.5 + Vector2(0, -R * 0.02), i, AW * 0.9, k)
	Mouth.draw(ci, M, Mouth.from_rest({"w": R * 0.055, "up": R * 0.035, "dn": R * 0.035, "round": 1.0, "lu": R * 0.08,
		"ld": R * 0.09}, k))


static func _buzz(ci: CanvasItem, ph: float, k: float) -> void:
	var shake := smoothstep(0.5, 1.0, k)
	var jit := sin(TAU * ph * 16.0) * R * 0.01 * shake
	var q := Mouth.from_rest({"w": R * 0.14, "round": 0.4, "lu": R * 0.055, "ld": R * 0.065}, k)
	q.wave = R * 0.016 * shake
	q.wph = TAU * ph * 14.0
	Mouth.draw(ci, M + Vector2(jit, 0), q)
	for s in [-1.0, 1.0]:
		for i in 3:
			var a := (0.55 + 0.45 * sin(TAU * ph * 10.0 + i)) * shake
			var c := M + Vector2(s * R * (0.3 + 0.07 * i), 0)
			ci.draw_arc(c, R * (0.06 + 0.02 * i), -0.7 if s > 0 else PI - 0.7, 0.7 if s > 0 else PI + 0.7, 8,
				Color(Paint.ARROW, a), R * 0.022, true)
	for i in 6:
		var u := fmod(ph * 3.0 + i / 6.0, 1.0)
		var dv := Vector2(sin(i * 2.4) * 0.9, 0.5 + 0.4 * cos(i * 1.7)).normalized()
		var p := M + dv * R * (0.12 + 0.35 * u)
		Paint.glow(ci, p, R * 0.028, R * 0.032, Color(Mouth.AIR, (1.0 - u) * shake), Color(Mouth.AIR, 0.0), 10)
		ci.draw_circle(p, R * 0.013, Color(1, 1, 1, (1.0 - u) * shake), true, -1.0, true)


## Dentes descendo e mordendo o lábio: upper = dentes de cima no lábio de baixo; senão, os de baixo no lábio de cima.
static func _bite(ci: CanvasItem, upper: bool, k: float) -> void:
	var t := {"w": R * 0.24, "up": R * 0.02 if upper else 0.0, "dn": 0.0 if upper else R * 0.02, "curve": R * 0.015,
		"lu": R * 0.045, "ld": R * 0.055}
	var d := Mouth.draw(ci, M, Mouth.from_rest(t, k))
	if k < 0.05:
		return
	var edge: PackedVector2Array = d.iu if upper else d.idn
	var a := PackedVector2Array()
	var b := PackedVector2Array()
	var dir := 1.0 if upper else -1.0
	for p in edge:
		if absf(p.x) <= R * 0.16:
			var front := R * 0.014 if absf(p.x) < R * 0.075 else 0.0
			a.append(p)
			b.append(p + Vector2(0, dir * (R * 0.085 + front) * k))
	b.reverse()
	var poly := a + b
	Paint.glow(ci, M + Vector2(0, dir * R * 0.09 * k), R * 0.19, R * 0.045, Color(Mouth.LIP_LO, 0.9 * k), Color(Mouth.LIP_LO, 0.0),
		16)
	Paint.blob(ci, poly, Color.WHITE if upper else Mouth.TEETH_SH, Mouth.TEETH_SH if upper else Color.WHITE, R * 0.02)
	for x in [0.0, -R * 0.075, R * 0.075]:
		var y0 := M.y + dir * R * 0.005
		ci.draw_line(Vector2(x, y0), Vector2(x, y0 + dir * R * 0.07 * k), Mouth.TEETH_SH.darkened(0.15), R * 0.012, true)
