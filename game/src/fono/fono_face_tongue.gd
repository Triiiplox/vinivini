extends RefCounted
## Poses de LÍNGUA do FonoFace: para fora (cima, baixo, lados, cantinhos, larga × fina, girar, lamber lábio, limpar
## dentes, dentro-fora, vibrar) e por dentro (céu da boca, varrer, estalo, ponta no céu/no chão e os sons R, TI, ND).
## Todo ciclo é completo e suave: boca em repouso → abre → a língua vai até o alvo → segura → volta → fecha.
## Tudo no espaço ampliado da boca (ver Mouth.MS). `ph` = fase 0..1 da repetição.

const Paint := preload("res://src/fono/fono_face_paint.gd")
const Mouth := preload("res://src/fono/fono_face_mouth.gd")
const R := 150.0
const M := Mouth.M
const AW := R * 0.035  # espessura das setas
const SEGURA_IN := 0.15  # nas poses "_segura": entra até aqui, segura até 1 - SEGURA_IN e relaxa


## Desenha a pose se ela for de língua; devolve false se não for.
static func draw(ci: CanvasItem, pose: String, ph: float) -> bool:
	match pose:
		"lingua_cima", "lingua_baixo", "lingua_direita", "lingua_esquerda", "lingua_dentro_fora":
			_tongue_dir(ci, pose, ph)
		"cantinhos":
			_corners(ci, ph)
		"lingua_larga", "lingua_larga_segura":
			_wide(ci, ph, pose.ends_with("segura"))
		"lingua_fina", "lingua_fina_segura":
			_thin(ci, ph, pose.ends_with("segura"))
		"lamber_labios":
			_lick(ci, ph)
		"lamber_labio_cima", "lamber_labio_baixo":
			_lick_lip(ci, pose == "lamber_labio_cima", ph)
		"limpar_dentes_cima", "limpar_dentes_baixo":
			_clean_teeth(ci, pose == "limpar_dentes_cima", ph)
		"vibrar_lingua":
			_buzz_tongue(ci, ph)
		"ceu_boca", "varrer", "estalo", "nd", "r", "ti", "ponta_ceu_soltar", "ponta_chao_soltar":
			_inside(ci, pose, ph)
		_:
			return false
	return true


## Entra na posição, segura e relaxa (poses "_segura").
static func hold_firm(ph: float) -> float:
	return smoothstep(0.0, SEGURA_IN, ph) * (1.0 - smoothstep(1.0 - SEGURA_IN, 1.0, ph))


## Boca aberta (a = quanto abriu, 0 = repouso) com a língua deitada lá dentro.
static func _mouth(ci: CanvasItem, target: Dictionary, a: float, tk: float = 0.0) -> Dictionary:
	var q := Mouth.from_rest(target, a)
	q.tk = tk if a > 0.05 else -1.0
	return Mouth.draw(ci, M, q)


# ------------------------------------------------------------------ língua para fora
static func _tongue_dir(ci: CanvasItem, pose: String, ph: float) -> void:
	var a := Mouth.opening(ph)
	var e := Mouth.ext(ph)
	var d := _mouth(ci, Mouth.open_p(R * 0.25, R * 0.1, R * 0.16), a)
	var base := M + Vector2(0, R * 0.06)
	match pose:
		"lingua_cima":
			Mouth.tongue_out(ci, base, base + Vector2(0, -R * 0.33 * e), R * 0.11, R * 0.125, R * 0.11)
			Paint.arrow(ci, M + Vector2(R * 0.38, R * 0.04), M + Vector2(R * 0.44, -R * 0.12), M + Vector2(R * 0.38, -R * 0.26), AW, a)
		"lingua_baixo", "lingua_dentro_fora":
			Mouth.tongue_out(ci, base, base + Vector2(0, R * 0.34 * e), R * 0.11, R * 0.125, R * 0.11)
			if pose == "lingua_baixo":
				Paint.arrow(ci, M + Vector2(R * 0.34, R * 0.12), M + Vector2(R * 0.38, R * 0.28), M + Vector2(R * 0.28, R * 0.42), AW, a)
			else:
				Paint.arrow(ci, M + Vector2(R * 0.36, -R * 0.05), M + Vector2(R * 0.42, R * 0.12), M + Vector2(R * 0.36, R * 0.3), AW,
					a, true)
		_:
			var s := 1.0 if pose == "lingua_direita" else -1.0
			var bs := M + Vector2(s * R * 0.04, R * 0.05)
			Mouth.tongue_out(ci, bs, bs + Vector2(s * R * 0.42 * e, R * 0.06 * e), R * 0.075, R * 0.115, R * 0.1)
			var y: float = d.od[Mouth.N / 2].y + R * 0.1
			Paint.arrow(ci, Vector2(s * R * 0.12, y), Vector2(s * R * 0.3, y + R * 0.04), Vector2(s * R * 0.5, y - R * 0.02), AW, a)


## Ponta da língua: centro → cantinho direito → cantinho esquerdo → centro.
static func _corners(ci: CanvasItem, ph: float) -> void:
	var a := Mouth.opening(ph)
	var x := sin(TAU * smoothstep(0.1, 0.9, ph))
	x = signf(x) * pow(absf(x), 0.6)
	var d := _mouth(ci, Mouth.open_p(R * 0.27, R * 0.08, R * 0.13), a)
	var xo: float = d.xo
	var base := M + Vector2(x * R * 0.05, R * 0.05)
	var len_k := smoothstep(0.05, 0.2, ph) * (1.0 - smoothstep(0.8, 0.95, ph))
	Mouth.tongue_out(ci, base, base.lerp(M + Vector2(x * (xo + R * 0.02), R * 0.02), len_k) + Vector2(0, R * 0.08 * (1.0 - len_k)),
		R * 0.09, R * 0.1, R * 0.085)
	var y: float = d.od[Mouth.N / 2].y + R * 0.1
	Paint.arrow(ci, Vector2(-R * 0.3, y), Vector2(0, y + R * 0.05), Vector2(R * 0.3, y), AW, a, true)


static func _wide(ci: CanvasItem, ph: float, firm: bool) -> void:
	var a := hold_firm(ph) if firm else Mouth.opening(ph)
	var e := hold_firm(ph) if firm else Mouth.ext(ph)
	var base := M + Vector2(0, R * 0.05)
	_mouth(ci, Mouth.open_p(R * 0.28, R * 0.1, R * 0.12), a)
	var hw := R * lerpf(0.12, 0.17, e)
	Mouth.tongue_out(ci, base, base + Vector2(0, R * 0.32 * e), hw, hw * 1.05, hw * 0.92)
	var y := M.y + R * 0.24
	Paint.arrow(ci, Vector2(-R * 0.27, y), Vector2(0, y + R * 0.02), Vector2(R * 0.27, y), AW, e, true)


static func _thin(ci: CanvasItem, ph: float, firm: bool) -> void:
	var a := hold_firm(ph) if firm else Mouth.opening(ph)
	var e := hold_firm(ph) if firm else Mouth.ext(ph)
	var base := M + Vector2(0, R * 0.05)
	_mouth(ci, {"w": R * 0.13, "up": R * 0.07, "dn": R * 0.1, "round": 0.6, "lu": R * 0.06, "ld": R * 0.07, "tu": 0.6}, a)
	Mouth.tongue_out(ci, base, base + Vector2(0, R * 0.44 * e), R * lerpf(0.09, 0.07, e), R * lerpf(0.09, 0.05, e),
		R * lerpf(0.08, 0.024, e))
	var y := M.y + R * 0.3
	for s in [-1.0, 1.0]:
		Paint.arrow(ci, Vector2(s * R * 0.36, y), Vector2(s * R * 0.25, y - R * 0.03), Vector2(s * R * 0.12, y), AW, e)


## Ponto do caminho em volta dos lábios (ângulo a; 0 = direita, -PI/2 = em cima).
static func _rim(d: Dictionary, a: float, grow: float) -> Vector2:
	var q: Dictionary = d.q
	var ry: float = (q.up + q.lu) if sin(a) < 0 else (q.dn + q.ld)
	return M + Vector2(cos(a) * (float(d.xo) + grow - R * 0.03), sin(a) * (ry * 0.75 + grow))


## A língua sai, dá uma volta inteira nos lábios e entra.
static func _lick(ci: CanvasItem, ph: float) -> void:
	var o := Mouth.opening(ph)
	var e := smoothstep(0.06, 0.18, ph) * (1.0 - smoothstep(0.82, 0.94, ph))
	var a := TAU * smoothstep(0.12, 0.88, ph) - PI / 2.0
	var d := _mouth(ci, Mouth.open_p(R * 0.22, R * 0.07, R * 0.1), o)
	for i in 18:
		ci.draw_circle(_rim(d, a + 0.55 + TAU * i / 21.0, R * 0.15), R * 0.016, Color(Paint.ARROW, o), true, -1.0, true)
	var p0 := _rim(d, a + 0.55 + TAU * 18.0 / 21.0, R * 0.15)
	var p1 := _rim(d, a + 0.55 + TAU * 19.6 / 21.0, R * 0.15)
	Paint.arrow(ci, p0 - (p1 - p0), p0, p1, R * 0.028, o)
	var tip := _rim(d, a, R * 0.0) + (_rim(d, a, 0.0) - M).normalized() * R * 0.05
	var base := M + Vector2(0, R * 0.03)
	Mouth.tongue_out(ci, base, base.lerp(tip, e), R * 0.085, R * 0.09, R * 0.08)


## Ponta da língua deslizando de um lado ao outro em cima do lábio (de cima ou de baixo).
static func _lick_lip(ci: CanvasItem, upper: bool, ph: float) -> void:
	var o := Mouth.opening(ph)
	var e := smoothstep(0.06, 0.2, ph) * (1.0 - smoothstep(0.8, 0.94, ph))
	var d := _mouth(ci, Mouth.open_p(R * 0.24, R * 0.08, R * 0.12), o)
	var q: Dictionary = d.q
	var x := sin(TAU * smoothstep(0.15, 0.85, ph)) * R * 0.17
	var y: float = M.y - q.up - q.lu * 0.45 if upper else M.y + q.dn + q.ld * 0.5
	var base := M + Vector2(x * 0.3, R * (0.02 if upper else 0.0))
	var tip := Vector2(x, y + (-R * 0.04 if upper else R * 0.05))
	Mouth.tongue_out(ci, base, base.lerp(tip, e), R * 0.08, R * 0.095, R * 0.085)
	var ay := y + (-R * 0.17 if upper else R * 0.19)
	Paint.arrow(ci, Vector2(-R * 0.22, ay), Vector2(0, ay + (-R * 0.03 if upper else R * 0.03)), Vector2(R * 0.22, ay), AW, o, true)


## Ponta da língua passando nos dentes (por dentro dos lábios), de um lado ao outro.
static func _clean_teeth(ci: CanvasItem, upper: bool, ph: float) -> void:
	var o := Mouth.opening(ph)
	var e := smoothstep(0.06, 0.2, ph) * (1.0 - smoothstep(0.8, 0.94, ph))
	var t := Mouth.open_p(R * 0.27, R * 0.11, R * 0.15)
	t.td = 1.0
	var d := _mouth(ci, t, o)
	var x := sin(TAU * smoothstep(0.15, 0.85, ph)) * R * 0.15
	var y := M.y - R * 0.05 if upper else M.y + R * 0.1
	var base := M + Vector2(x * 0.25, R * 0.07 if upper else -R * 0.02)
	Mouth.tongue_out(ci, base, base.lerp(Vector2(x, y), e), R * 0.075, R * 0.085, R * 0.075)
	var ay: float = (d.ou[Mouth.N / 2].y - R * 0.1) if upper else (d.od[Mouth.N / 2].y + R * 0.1)
	Paint.arrow(ci, Vector2(-R * 0.24, ay), Vector2(0, ay + (-R * 0.03 if upper else R * 0.03)), Vector2(R * 0.24, ay), AW, o, true)


## Língua para fora tremendo (brrr de língua), com linhas de vibração.
static func _buzz_tongue(ci: CanvasItem, ph: float) -> void:
	var o := Mouth.opening(ph)
	var e := Mouth.ext(ph)
	_mouth(ci, Mouth.open_p(R * 0.22, R * 0.07, R * 0.11), o)
	var j := sin(TAU * ph * 14.0) * R * 0.028 * e
	var base := M + Vector2(0, R * 0.05)
	var tip := base + Vector2(j, R * 0.24 * e)
	Mouth.tongue_out(ci, base, tip, R * 0.1, R * 0.11, R * 0.1)
	for s in [-1.0, 1.0]:
		for i in 3:
			var a := (0.55 + 0.45 * sin(TAU * ph * 8.0 + i * 1.7)) * e
			var c := tip + Vector2(s * R * (0.15 + 0.06 * i), -R * 0.06)
			ci.draw_arc(c, R * (0.05 + 0.02 * i), -0.7 if s > 0 else PI - 0.7, 0.7 if s > 0 else PI + 0.7, 8,
				Color(Paint.ARROW, a), R * 0.02, true)


# ------------------------------------------------------------------ língua por dentro (céu da boca, sons)
static func _inside(ci: CanvasItem, pose: String, ph: float) -> void:
	var o := Mouth.opening(ph)
	var k := Mouth.ext(ph)
	var t := Mouth.open_p(R * 0.25, R * 0.13, R * 0.18)
	t.td = 0.5
	match pose:
		"varrer":
			# encosta atrás dos dentes e desliza para trás (some atrás dos dentes, subindo no céu da boca)
			t.tu = 0.5
			t.palate = 1.0
			var touch := smoothstep(0.1, 0.3, ph) * (1.0 - smoothstep(0.75, 0.92, ph))
			var back := smoothstep(0.32, 0.6, ph) * (1.0 - smoothstep(0.6, 0.75, ph))
			k = touch * (1.0 + 0.45 * back)
		"estalo":
			o = smoothstep(0.0, 0.15, ph) * (1.0 - smoothstep(0.85, 1.0, ph))
			k = smoothstep(0.12, 0.35, ph) if ph < 0.55 else (1.0 - smoothstep(0.55, 0.6, ph))
		"ponta_ceu_soltar":
			k = smoothstep(0.12, 0.3, ph) * (1.0 - smoothstep(0.55, 0.72, ph))
		"ponta_chao_soltar":
			k = 0.0
			t.td = 1.0
			t.arch = smoothstep(0.12, 0.3, ph) * (1.0 - smoothstep(0.55, 0.72, ph))
		"r":
			k = (0.6 + 0.4 * cos(TAU * 3.0 * smoothstep(0.15, 0.85, ph))) * smoothstep(0.05, 0.18, ph) * (1.0 - smoothstep(0.82, 0.95, ph))
			t = Mouth.open_p(R * 0.22, R * 0.09, R * 0.14)
			t.td = 0.6
		"ti":
			k = smoothstep(0.1, 0.28, ph) * (1.0 - smoothstep(0.5, 0.58, ph))
			t = Mouth.open_p(R * 0.24, R * 0.08, R * 0.12)
			t.td = 0.8
		"nd":
			t = Mouth.open_p(R * 0.22, R * 0.1, R * 0.14)
	var q := Mouth.from_rest(t, o)
	q.tk = k if o > 0.05 else -1.0
	Mouth.draw(ci, M, q)
	_inside_marks(ci, pose, ph, k, o)


## Setas e efeitos das poses de língua por dentro.
static func _inside_marks(ci: CanvasItem, pose: String, ph: float, k: float, o: float) -> void:
	var ax := R * 0.4
	match pose:
		"varrer":
			Paint.arrow(ci, M + Vector2(ax, R * 0.1), M + Vector2(ax + R * 0.14, -R * 0.06), M + Vector2(ax - R * 0.02, -R * 0.22), AW, o)
		"ceu_boca":
			Paint.arrow(ci, M + Vector2(ax, R * 0.1), M + Vector2(ax + R * 0.03, -R * 0.02), M + Vector2(ax, -R * 0.15), AW, o)
		"ponta_ceu_soltar", "ponta_chao_soltar":
			Paint.arrow(ci, M + Vector2(ax, -R * 0.15), M + Vector2(ax + R * 0.05, 0), M + Vector2(ax, R * 0.15), AW, o, true)
		"estalo":
			var pop := smoothstep(0.55, 0.6, ph) * (1.0 - smoothstep(0.75, 0.9, ph))
			if pop > 0.01:
				var g := 0.6 + 0.6 * smoothstep(0.55, 0.8, ph)
				var c := M + Vector2(R * 0.44, -R * 0.12)
				Paint.star(ci, c, R * 0.11 * g, Color(Paint.ARROW, pop), R * 0.02 * pop, 0.3)
				_spark(ci, c, R * 0.2 * g, pop)
		"r":
			var a := smoothstep(0.85, 1.0, k)
			for i in 2:
				ci.draw_arc(M + Vector2(ax - R * 0.04, -R * 0.02), R * (0.05 + 0.04 * i), -0.8, 0.8, 8, Color(Paint.ARROW, a), R * 0.022, true)
		"ti":
			var puff := smoothstep(0.52, 0.6, ph) * (1.0 - smoothstep(0.78, 0.92, ph))
			if puff > 0.01:
				var y := M.y + R * (0.26 + 0.18 * smoothstep(0.52, 0.92, ph))
				for i in 3:
					Paint.glow(ci, Vector2((i - 1) * R * 0.08, y + absf(i - 1) * R * 0.02), R * 0.07, R * 0.05,
						Color(Mouth.AIR, puff), Color(Mouth.AIR, 0.0), 14)
		"nd":
			for s in [-1.0, 1.0]:
				for i in 2:
					var a := fmod(ph * 2.0 + i * 0.5, 1.0)
					ci.draw_arc(Mouth.un(Vector2(s * R * 0.05, R * 0.16)), R * (0.08 + 0.08 * a), -0.6 if s > 0 else PI - 0.6,
						0.6 if s > 0 else PI + 0.6, 10, Color(Mouth.AIR, (1.0 - a) * k), R * 0.022, true)


## Raiozinhos de "pop".
static func _spark(ci: CanvasItem, c: Vector2, r: float, a: float) -> void:
	for i in 6:
		var dv := Vector2.from_angle(TAU * i / 6.0 + 0.26)
		ci.draw_line(c + dv * r * 0.55, c + dv * r, Color(Paint.ARROW, a), R * 0.018, true)
