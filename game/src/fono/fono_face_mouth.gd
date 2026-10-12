extends RefCounted
## Boca do FonoFace (a protagonista): uma boca paramétrica só — lábios com arco do cupido, interior escuro com
## profundidade, céu da boca, dentes de cima/baixo e língua por dentro — mais a língua para fora, rugas do bico e o ar.
## Os parâmetros (dicionário) podem ser misturados com mix(): é assim que o bico vira sorriso sem "pulo".

const Paint := preload("res://src/fono/fono_face_paint.gd")
const R := 150.0
const N := 24
const INK := Color("#3D2216")
const SKIN_LO := Color("#C98A5C")
const UVULA := Color("#C9475F")
const LIP := Color("#E8877F")
const LIP_HI := Color("#F8B6A8")
const LIP_LO := Color("#CB6A64")
const LIP_INK := Color("#7E3A2E")  ## contorno dos lábios: mais macio que a tinta do rosto
const MOUTH := Color("#6A1A2C")
const MOUTH_DEEP := Color("#2E0812")
const PALATE := Color("#A33A52")
const TEETH := Color("#FFFFFF")
const TEETH_SH := Color("#D5DEEC")
const TONGUE := Color("#F27D95")
const TONGUE_HI := Color("#FFB4C3")
const TONGUE_LO := Color("#C94D6A")
const AIR := Color("#9ADBFF")
const M := Vector2(0, R * 0.5)  ## centro da boca no rosto
const MS := 1.28  ## a boca (e o que se desenha nela) sai 28% maior: ela é a protagonista
## w: meia largura da abertura; up/dn: abertura acima/abaixo da linha; curve: cantos para cima (sorriso);
## lu/ld: espessura dos lábios; round: 1 = lábios em anel (bico); box: expoente do formato (2 = oval, 3 = quadradinho);
## tu/td: dentes de cima/baixo (0..1); bite: dentes encostados; tk: língua dentro (-1 nenhuma, 0 deitada, 1 no céu);
## tx: ponta da língua para o lado; arch: dorso arqueado; palate: mostra o céu da boca;
## wave: lábios tremendo (amplitude); wph: fase.
const DEF := {"w": R * 0.2, "up": 0.0, "dn": 0.0, "curve": 0.0, "lu": R * 0.035, "ld": R * 0.05, "round": 0.0,
	"box": 2.0, "tu": 0.0, "td": 0.0, "bite": 0.0, "tk": -1.0, "tx": 0.0, "arch": 0.0, "palate": 0.0, "wave": 0.0, "wph": 0.0}


## Vai, segura e volta (0 → 1 → 0) dentro da repetição, com ease in/out.
static func hold(ph: float) -> float:
	return smoothstep(0.0, 0.3, ph) * (1.0 - smoothstep(0.7, 1.0, ph))


## A boca abre um pouco antes do movimento e fecha um pouco depois (0 → 1 → 0).
static func opening(ph: float) -> float:
	return smoothstep(0.0, 0.16, ph) * (1.0 - smoothstep(0.84, 1.0, ph))


## O movimento em si (língua saindo/entrando), dentro da janela em que a boca está aberta.
static func ext(ph: float) -> float:
	return smoothstep(0.12, 0.38, ph) * (1.0 - smoothstep(0.62, 0.88, ph))


## Boca de repouso (início e fim de todo ciclo).
static func neutral_p() -> Dictionary:
	return {"w": R * 0.2, "curve": R * 0.06, "lu": R * 0.036, "ld": R * 0.052}


## Repouso → alvo.
static func from_rest(target: Dictionary, a: float) -> Dictionary:
	return mix(neutral_p(), target, a)


## Vai e volta suave (0 → 1 → 0).
static func swing(ph: float) -> float:
	return 0.5 - 0.5 * cos(TAU * ph)


## Ponto do rosto convertido para o espaço (ampliado) da boca.
static func un(p: Vector2) -> Vector2:
	return M + (p - M) / MS


static func open_p(w: float, up: float, dn: float) -> Dictionary:
	return {"w": w, "up": up, "dn": dn, "curve": R * 0.025, "lu": R * 0.036, "ld": R * 0.05, "box": 2.3, "tu": 1.0}


static func pucker_p(hole: float) -> Dictionary:
	return {"w": R * (0.07 + 0.025 * hole), "up": R * (0.016 + 0.035 * hole), "dn": R * (0.016 + 0.04 * hole),
		"round": 1.0, "lu": R * 0.09, "ld": R * 0.1, "tu": hole, "td": hole, "bite": 1.0 if hole > 0.0 else 0.0}


static func smile_p(w: float, cv: float) -> Dictionary:
	return {"w": w, "curve": cv, "lu": R * 0.034, "ld": R * 0.05}


static func params(p: Dictionary) -> Dictionary:
	var q := DEF.duplicate()
	q.merge(p, true)
	return q


## Mistura dois conjuntos de parâmetros (a = 0 → p, 1 → q).
static func mix(p: Dictionary, q: Dictionary, a: float) -> Dictionary:
	var pp := params(p)
	var qq := params(q)
	var o := {}
	for k in pp:
		o[k] = lerpf(float(pp[k]), float(qq[k]), a)
	return o


static func _f(t: float, p: float) -> float:
	return pow(maxf(0.0, 1.0 - pow(absf(t), p)), 1.0 / p)


## Contornos da boca (relativos ao centro): iu/idn = borda interna de cima/baixo, ou/od = borda externa dos lábios.
static func contour(q: Dictionary) -> Dictionary:
	var w: float = q.w
	var xo: float = w + float(q.round) * maxf(q.lu, q.ld)
	var iu := PackedVector2Array()
	var idn := PackedVector2Array()
	var ou := PackedVector2Array()
	var od := PackedVector2Array()
	for i in N + 1:
		var t := -cos(PI * i / N)
		var h := sqrt(maxf(0.0, 1.0 - t * t))
		var f := _f(t, q.box)
		var y0: float = -float(q.curve) * t * t + float(q.wave) * sin(float(q.wph) + t * 6.0) * h
		var bow: float = q.lu * (0.42 * exp(-pow(t / 0.12, 2.0)) - 0.16 * exp(-pow((absf(t) - 0.3) / 0.14, 2.0)))
		bow *= 1.0 - float(q.round) * 0.35
		iu.append(Vector2(t * w, -float(q.up) * f + y0))
		idn.append(Vector2(t * w, float(q.dn) * f + y0))
		ou.append(Vector2(t * xo, -float(q.up) * f - float(q.lu) * h + bow + y0))
		od.append(Vector2(t * xo, float(q.dn) * f + float(q.ld) * h + y0))
	return {"iu": iu, "idn": idn, "ou": ou, "od": od, "xo": xo}


static func _shift(p: PackedVector2Array, m: Vector2) -> PackedVector2Array:
	var o := PackedVector2Array()
	for v in p:
		o.append(v + m)
	return o


## Junta a borda a (ida) com a borda b (volta), sem repetir os cantos.
static func _ring(a: PackedVector2Array, b: PackedVector2Array) -> PackedVector2Array:
	var o := a.duplicate()
	for i in range(b.size() - 1, -1, -1):
		if b[i].distance_to(a[0]) > 0.5 and b[i].distance_to(a[a.size() - 1]) > 0.5:
			o.append(b[i])
	return o


## Desenha a boca toda em m. Devolve os contornos já posicionados (para a língua de fora, setas etc.).
static func draw(ci: CanvasItem, m: Vector2, p: Dictionary) -> Dictionary:
	var q := params(p)
	var c := contour(q)
	var iu := _shift(c.iu, m)
	var idn := _shift(c.idn, m)
	var ou := _shift(c.ou, m)
	var od := _shift(c.od, m)
	var xo: float = c.xo
	var lip_w := maxf(2.5, R * 0.021)
	# sombrinha na pele embaixo do lábio (dá volume) e, no bico, a boca "saindo" do rosto
	Paint.glow(ci, m + Vector2(0, float(q.dn) + float(q.ld) + R * 0.04), xo * 0.75, R * 0.05, Color(SKIN_LO, 0.55),
		Color(SKIN_LO, 0.0))
	if q.round > 0.3:
		Paint.glow(ci, m + Vector2(0, R * 0.02), xo * 1.6, (q.up + q.lu) * 2.0, Color(SKIN_LO, 0.5 * q.round),
			Color(SKIN_LO, 0.0))
	var open: bool = q.up + q.dn > 1.5
	var hole := PackedVector2Array()
	if open:
		hole = _ring(iu, idn)
		Paint.fill(ci, hole, MOUTH)
		var mid := m + Vector2(0, (q.dn - q.up) * 0.5 - q.curve * 0.3)
		Paint.glow(ci, mid + Vector2(0, (q.up + q.dn) * 0.12), q.w * 0.62, (q.up + q.dn) * 0.36, MOUTH_DEEP,
			Color(MOUTH_DEEP, 0.0))
		_throat(ci, m, q, hole)
		if q.palate > 0.01:
			_palate(ci, m, q, hole)
		if q.tk >= 0.0:
			_tongue_in(ci, m, q, hole)
		if q.tu > 0.01:
			_teeth(ci, iu, idn, q, true, hole)
		if q.td > 0.01:
			_teeth(ci, iu, idn, q, false, hole)
	# lábios: o de cima um pouco mais escuro (sombra), o de baixo mais cheio e claro
	var top_lip := _ring(ou, iu)
	var bot_lip := _ring(idn, od)
	Paint.fill_lin(ci, top_lip, m + Vector2(0, -q.up - q.lu), LIP_LO, m + Vector2(0, -q.up), LIP)
	Paint.fill_lin(ci, bot_lip, m + Vector2(0, q.dn), LIP_HI, m + Vector2(0, q.dn + q.ld), LIP)
	if q.round > 0.4:
		_wrinkles(ci, m, q)
	if open:
		Paint.stroke(ci, hole, Color(INK, 0.85), lip_w * 0.8)
	else:
		Paint.stroke(ci, iu, LIP_INK, lip_w, false)
	Paint.stroke(ci, _ring(ou, od), LIP_INK, lip_w)
	# brilhos
	Paint.glow(ci, m + Vector2(-xo * 0.22, q.dn + q.ld * 0.5 - q.curve * 0.05), xo * 0.2, q.ld * 0.26,
		Color(1, 1, 1, 0.6), Color(1, 1, 1, 0.0), 16)
	Paint.glow(ci, m + Vector2(-xo * 0.3, -q.up - q.lu * 0.55 - q.curve * 0.09), xo * 0.1, q.lu * 0.2,
		Color(1, 1, 1, 0.4), Color(1, 1, 1, 0.0), 12)
	return {"iu": iu, "idn": idn, "ou": ou, "od": od, "xo": xo, "q": q}


## Boca bem aberta: garganta mais escura lá no fundo e a úvula ("sininho") pendurada.
static func _throat(ci: CanvasItem, m: Vector2, q: Dictionary, hole: PackedVector2Array) -> void:
	var deep := smoothstep(R * 0.2, R * 0.36, float(q.up) + float(q.dn)) * (1.0 - smoothstep(0.3, 0.7, float(q.tk)))
	if deep < 0.02:
		return
	var top_y: float = m.y - q.up + R * 0.085 * maxf(float(q.tu), 0.3)
	var mid_y: float = m.y + (q.dn - q.up) * 0.25
	Paint.glow(ci, Vector2(m.x, mid_y), q.w * 0.4, (q.up + q.dn) * 0.28, Color(MOUTH_DEEP.darkened(0.4), deep),
		Color(MOUTH_DEEP, 0.0), 20)
	var uv := Paint.bez(Vector2(m.x - R * 0.04, top_y - R * 0.02), Vector2(m.x - R * 0.025, top_y + R * 0.05),
		Vector2(m.x, top_y + R * 0.075), 8)
	uv.append_array(Paint.bez(Vector2(m.x, top_y + R * 0.075), Vector2(m.x + R * 0.025, top_y + R * 0.05),
		Vector2(m.x + R * 0.04, top_y - R * 0.02), 8))
	Paint.fill_clip(ci, uv, hole, Color(UVULA.darkened(0.25), deep), Color(UVULA, deep))
	Paint.glow(ci, Vector2(m.x - R * 0.008, top_y + R * 0.055), R * 0.009, R * 0.012, Color(1, 1, 1, 0.45 * deep),
		Color(1, 1, 1, 0.0), 8)


## Céu da boca: abóbada mais clara logo abaixo dos dentes de cima, com as "ruguinhas" (rugas palatinas).
static func _palate(ci: CanvasItem, m: Vector2, q: Dictionary, hole: PackedVector2Array) -> void:
	var top: float = m.y - q.up
	var dome := Paint.ellipse(Vector2(m.x, top), q.w * 0.78, (q.up + q.dn) * 0.42, 28)
	Paint.fill_clip(ci, dome, hole, Color(PALATE, q.palate), Color(PALATE.darkened(0.25), q.palate * 0.6))
	for i in 3:
		var y: float = top + (q.up + q.dn) * (0.16 + 0.08 * i)
		var hw: float = q.w * (0.32 - 0.07 * i)
		Paint.stroke(ci, Paint.bez(Vector2(m.x - hw, y + R * 0.01), Vector2(m.x, y - R * 0.02), Vector2(m.x + hw, y + R * 0.01), 8),
			Color(PALATE.lightened(0.35), 0.75 * q.palate), R * 0.014, false)


## Dentes de cima (borda de baixo levemente recortada, dois da frente maiores) ou de baixo.
static func _teeth(ci: CanvasItem, iu: PackedVector2Array, idn: PackedVector2Array, q: Dictionary, upper: bool,
		hole: PackedVector2Array) -> void:
	var th: float = R * (0.085 if upper else 0.065) * float(q.tu if upper else q.td)
	var a := PackedVector2Array()
	var b := PackedVector2Array()
	var cx := (iu[0].x + iu[N].x) * 0.5
	for i in N + 1:
		var u := iu[i]
		var d := idn[i]
		if absf(u.x - cx) > q.w * 0.8:
			continue
		var seam := (u.y + d.y) * 0.5
		var front := R * 0.012 if absf(u.x - cx) < q.w * 0.24 else 0.0
		if upper:
			var y1: float = seam + R * 0.004 if q.bite > 0.5 else minf(u.y + th + front, d.y - 1.0)
			a.append(Vector2(u.x, u.y - 4.0))
			b.append(Vector2(u.x, maxf(y1, u.y + 0.5)))
		else:
			var y0: float = seam - R * 0.004 if q.bite > 0.5 else maxf(d.y - th, u.y + 1.0)
			a.append(Vector2(d.x, minf(y0, d.y - 0.5)))
			b.append(Vector2(d.x, d.y + 4.0))
	if a.size() < 3:
		return
	b.reverse()
	var poly := a + b
	var y_top := a[a.size() / 2].y
	var y_bot := b[b.size() / 2].y
	var c0 := TEETH_SH.darkened(0.06) if upper else TEETH
	var c1 := TEETH if upper else TEETH_SH.darkened(0.06)
	Paint.fill_clip(ci, poly, hole, c0, c1)
	# separação entre dentes
	for xf in [0.0, -0.25, 0.25, -0.5, 0.5]:
		var x: float = cx + xf * q.w
		var y_a := INF
		var y_b := -INF
		for p in poly:
			if absf(p.x - x) < q.w * 0.09:
				y_a = minf(y_a, p.y)
				y_b = maxf(y_b, p.y)
		if y_b - y_a > 3.0:
			var ya := maxf(y_a, y_top - 2.0) if upper else y_a + (y_b - y_a) * 0.35
			var yb := y_b - (y_b - y_a) * 0.3 if upper else minf(y_b, y_bot)
			ci.draw_line(Vector2(x, ya), Vector2(x, yb), TEETH_SH.darkened(0.12), maxf(1.5, R * 0.01), true)


## Língua por dentro: k = 0 deitada (montinho com sulco), 1 com a ponta lá em cima (no céu da boca / atrás dos dentes).
## Com a ponta levantada aparece a parte de baixo da língua (rosa mais escuro, com o "freio" no meio).
## arch: dorso da língua arqueado (ponta lá embaixo, atrás dos dentes de baixo).
static func _tongue_in(ci: CanvasItem, m: Vector2, q: Dictionary, hole: PackedVector2Array) -> void:
	var k: float = clampf(q.tk, 0.0, 1.6)
	var w: float = q.w
	var floor_y: float = m.y + q.dn
	var roof_y: float = m.y - q.up + R * 0.085 * maxf(q.tu, 0.5)
	var hump: float = (q.up + q.dn) * (0.3 + 0.32 * float(q.arch))
	var tx: float = m.x + float(q.tx)
	var sig := R * 0.14
	var lift := (floor_y - roof_y) * k
	var top := PackedVector2Array()
	var under := PackedVector2Array()
	for i in 33:
		var x := m.x + lerpf(-w * 0.98, w * 0.98, i / 32.0)
		var u := (x - m.x) / (w * 0.98)
		var rest := hump * pow(maxf(0.0, 1.0 - u * u), 0.6)
		var peak := lift * exp(-pow(absf(x - tx) / sig, 4.0))
		top.append(Vector2(x, floor_y - maxf(rest * (1.0 - 0.35 * k), peak)))
		under.append(Vector2(x, floor_y - lift * 0.72 * exp(-pow(absf(x - tx) / (sig * 0.86), 3.0))))
	var body := top.duplicate()
	body.append(Vector2(m.x + w, floor_y + R * 0.1))
	body.append(Vector2(m.x - w, floor_y + R * 0.1))
	Paint.fill_clip(ci, body, hole, TONGUE_HI, TONGUE)
	if k > 0.15:
		var u_poly := under.duplicate()
		u_poly.append(Vector2(m.x + w, floor_y + R * 0.1))
		u_poly.append(Vector2(m.x - w, floor_y + R * 0.1))
		var und := TONGUE.darkened(0.24)
		Paint.fill_clip(ci, u_poly, hole, Color(und, k), Color(und.darkened(0.15), k))
		var tip_y := floor_y - lift * 0.72
		ci.draw_line(Vector2(tx, floor_y), Vector2(tx, lerpf(floor_y, tip_y, 0.8)), Color(TONGUE_LO.darkened(0.2), k),
			R * 0.016, true)
		for s in [-1.0, 1.0]:
			ci.draw_line(Vector2(tx + s * sig * 0.3, floor_y), Vector2(tx + s * sig * 0.42, lerpf(floor_y, tip_y, 0.55)),
				Color(0.62, 0.42, 0.7, 0.3 * k), R * 0.01, true)
	else:
		ci.draw_line(Vector2(m.x, floor_y - hump * 0.95), Vector2(m.x, floor_y - hump * 0.45), TONGUE_LO, R * 0.016, true)
	var edge := PackedVector2Array()
	for p in top:
		if Geometry2D.is_point_in_polygon(p, hole):
			edge.append(p)
	if edge.size() > 1:
		Paint.stroke(ci, edge, Color(TONGUE_LO.darkened(0.15), 0.9), R * 0.018, false)


## Língua para fora, da base (dentro da boca, no escuro) até a ponta arredondada. wb/wm: meia largura na base e no
## meio; wt: raio da ponta (pequeno = língua fina e pontuda).
static func tongue_out(ci: CanvasItem, base: Vector2, tip: Vector2, wb: float, wm: float, wt: float) -> void:
	var d := tip - base
	if d.length() < wt + 2.0:
		return
	var dir := d.normalized()
	var n := dir.orthogonal()
	var tc := tip - dir * wt
	var dc := tc - base
	var side_a := PackedVector2Array()
	var side_b := PackedVector2Array()
	for i in 11:
		var u := i / 10.0
		var hw := (1.0 - u) * (1.0 - u) * wb + 2.0 * u * (1.0 - u) * wm + u * u * wt
		side_a.append(base + dc * u + n * hw)
		side_b.append(base + dc * u - n * hw)
	var pts := side_a.duplicate()
	for i in range(1, 12):
		var a := PI * i / 12.0
		pts.append(tc + (n * cos(a) + dir * sin(a)) * wt)
	side_b.reverse()
	pts.append_array(side_b)
	var dark := minf(d.length() * 0.35, wm * 1.3)
	Paint.fill_grad(ci, pts, base, tip, [TONGUE.darkened(0.42), TONGUE, TONGUE.lerp(TONGUE_HI, 0.55)],
		[0.0, dark / d.length(), 1.0])
	var groove := Paint.bez(base + d * 0.15, base + d * 0.45 + n * wm * 0.06, tc - dir * wt * 0.35, 8)
	Paint.stroke(ci, groove, Color(TONGUE_LO.darkened(0.1), 0.8), maxf(1.5, R * 0.014), false)
	Paint.glow(ci, tc - n * wt * 0.4 + dir * wt * 0.1, wt * 0.38, wt * 0.24, Color(1, 1, 1, 0.65), Color(1, 1, 1, 0.0), 14)
	var outline := pts.slice(1, pts.size() - 1)
	Paint.stroke(ci, outline, INK, maxf(3.0, R * 0.026), false)


## Rugas do bico (linhas que irradiam do furinho).
static func _wrinkles(ci: CanvasItem, m: Vector2, q: Dictionary) -> void:
	var a := clampf((q.round - 0.4) / 0.6, 0.0, 1.0)
	for ang in [-PI / 2.0, -PI / 2.0 - 0.6, -PI / 2.0 + 0.6, -PI / 2.0 - 1.1, -PI / 2.0 + 1.1, PI / 2.0,
			PI / 2.0 - 0.5, PI / 2.0 + 0.5, PI / 2.0 - 1.0, PI / 2.0 + 1.0]:
		var dv := Vector2(cos(ang), sin(ang))
		var ry: float = q.up if dv.y < 0 else q.dn
		var lip: float = q.lu if dv.y < 0 else q.ld
		var p0 := m + Vector2(dv.x * (q.w + lip * 0.3), dv.y * (ry + lip * 0.3))
		var p1 := m + Vector2(dv.x * (q.w + lip * 0.8), dv.y * (ry + lip * 0.8))
		ci.draw_line(p0, p1, Color(LIP_LO.darkened(0.1), 0.85 * a), maxf(1.5, R * 0.014), true)


## Ar saindo da boca: rajadas de vento curvas que saem para o lado (wavy = ondinhas de vibração do J).
## ph = fase do ciclo (duas rajadas por ciclo, o GIF fecha sem emenda); amount = 0 sem ar, 1 cheio.
static func air(ci: CanvasItem, o: Vector2, dirs: Array, ph: float, wavy: bool, width: float = 1.0, amount: float = 1.0) -> void:
	if amount < 0.02:
		return
	for i in dirs.size():
		var dv: Vector2 = (dirs[i] as Vector2).normalized()
		var nn := dv.orthogonal()
		for j in 2:
			var k := fmod(ph * 2.0 + i * 0.29 + j * 0.5, 1.0)
			var pts := PackedVector2Array()
			var steps := 22 if wavy else 10
			for s in steps + 1:
				var u := k * 0.55 + s / float(steps) * 0.45
				var bend := nn * u * u * R * 0.12
				var wig := nn * sin(u * 13.0 - ph * TAU * 4.0) * R * 0.02 if wavy else Vector2.ZERO
				pts.append(o + dv * u * R * 0.55 + bend + wig)
			var al := sin(k * PI) * amount
			for seg in pts.size() - 1:
				var taper := sin(PI * (seg + 0.5) / (pts.size() - 1))
				var p0 := pts[seg]
				var p1 := pts[seg + 1]
				ci.draw_line(p0, p1, Color(AIR.darkened(0.4), 0.3 * al), R * 0.042 * width * taper, true)
				ci.draw_line(p0, p1, Color(AIR, 0.95 * al), R * 0.026 * width * taper, true)
				ci.draw_line(p0, p1, Color(1, 1, 1, 0.8 * al), R * 0.009 * width * taper, true)
		Paint.glow(ci, o + dv * R * 0.08, R * 0.07 * width, R * 0.06 * width, Color(AIR, 0.45 * amount), Color(AIR, 0.0), 14)
