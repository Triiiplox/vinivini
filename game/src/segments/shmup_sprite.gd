class_name ShmupSprite
extends Node2D
## Arte desenhada em código das fases de nave (11/10, o Andro: "os gráficos não tão legais; o mestre deveria ser
## algo legal"): robôs bagunceiros com olhos, itens que brilham e tiros inimigos grandes e lentos (criança de 4 anos
## precisa VER o perigo). Contorno escuro grosso + cor viva + brilho somado: lê bem em cima do fundo de nebulosa.
## Cada tipo se anima sozinho (piscar, girar, pulsar). Troca por arte pintada quando o Andro gerar (docs/NAVE_V5.md).

const INK := Color("#1A1033")
const COLORS := {"bolinha": Color("#4ADE80"), "seta": Color("#F43F5E"), "giro": Color("#A78BFA"),
	"olho": Color("#F59E0B"), "cometa": Color("#38BDF8"), "casco": Color("#22D3EE"), "mina": Color("#FB7185"),
	"P": Color("#FACC15"), "A": Color("#38BDF8"), "S": Color("#60A5FA"), "coracao": Color("#F43F5E"),
	"bala": Color("#FF5FA2"), "estrela": Color("#FFD23F"), "anel": Color("#F2C879"), "pedra": Color("#B08968")}

var kind := "bolinha"
var size := 70.0
var col := Color.WHITE
var flash := 0.0
var happy := false
var look := Vector2.LEFT
## Mini-mestre: coroa e cara brava (o robô gigante não pode parecer só o inimigo comum ampliado).
var chief := false
## Arte pintada (inimigos: foe_<tipo>.png; cápsulas: cap_<letra>.png). Sem o arquivo, o desenho em código.
var _tex: Texture2D
var _t := 0.0
var _blink := 2.0


func _init(k: String = "bolinha", s: float = 70.0, c: Color = Color(0, 0, 0, 0)) -> void:
	kind = k
	size = s
	col = c if c.a > 0.0 else COLORS.get(k, Color.WHITE)
	_t = randf() * 10.0
	_blink = randf_range(1.0, 3.5)
	var p := painted(k)
	if p != "" and ResourceLoader.exists(p):
		_tex = load(p)


static func painted(k: String) -> String:
	if k in ["bolinha", "seta", "giro", "olho", "casco", "mina"]:
		return "res://assets/art/painted/shmup/foe_%s.png" % k
	if k in ["P", "A", "S", "coracao"]:
		return "res://assets/art/painted/shmup/cap_%s.png" % k
	return ""


func hit() -> void:
	flash = 1.0


func _process(delta: float) -> void:
	_t += delta
	_blink -= delta
	if _blink < -0.12:
		_blink = randf_range(1.5, 4.0)
	flash = maxf(0.0, flash - delta * 6.0)
	queue_redraw()


func _draw() -> void:
	var r := size / 2.0
	var c := col.lerp(Color.WHITE, flash * 0.85)
	if _tex != null:
		_draw_painted(r)
		return
	match kind:
		"bolinha":
			_glow(r * 1.5, col)
			_blob(Vector2.ZERO, r, c)
			_antenna(Vector2(0, -r), -0.3, c)
			_eyes(Vector2(0, -r * 0.05), r * 0.3, r * 0.42, 2)
		"seta":
			_glow(r * 1.4, col)
			var pts := PackedVector2Array([Vector2(-r * 1.1, 0), Vector2(r * 0.6, -r * 0.85), Vector2(r * 0.25, 0),
				Vector2(r * 0.6, r * 0.85)])
			_poly(pts, c)
			_eyes(Vector2(-r * 0.15, 0), r * 0.22, r * 0.3, 1)
		"giro":
			_glow(r * 1.6, col)
			for i in 4:
				var a := _t * 3.0 + i * TAU / 4.0
				_blob(Vector2.RIGHT.rotated(a) * r * 0.85, r * 0.32, c.darkened(0.15))
			_blob(Vector2.ZERO, r * 0.72, c)
			_eyes(Vector2.ZERO, r * 0.22, r * 0.3, 2)
		"olho":
			_glow(r * 1.5, col)
			_rock(r, c)
			_eyes(Vector2(0, -r * 0.05), r * 0.45, 0.0, 1)
		"cometa":
			for i in 5:
				var k := float(i) / 5.0
				draw_circle(Vector2(r * (0.9 + k * 2.2), sin(_t * 9.0 + i) * 4.0), r * (0.7 - k * 0.12), Color(col, 0.5 - k * 0.09))
			_glow(r * 1.4, col)
			_blob(Vector2.ZERO, r * 0.8, c)
			_eyes(Vector2(-r * 0.1, 0), r * 0.22, r * 0.3, 2)
		"casco":
			_glow(r * 1.6, col)
			draw_circle(Vector2.ZERO, r + 4.0, INK)
			draw_circle(Vector2.ZERO, r, c.darkened(0.25))
			draw_arc(Vector2.ZERO, r * 0.98, PI * 0.55, PI * 1.45, 24, Color("#E2E8F0").lerp(Color.WHITE, flash), r * 0.38)
			_eyes(Vector2(r * 0.15, -r * 0.1), r * 0.2, r * 0.28, 2)
		"mina":
			_glow(r * 1.5, col)
			for i in 8:
				var a := i * TAU / 8.0 + _t * 0.8
				draw_line(Vector2.RIGHT.rotated(a) * r * 0.6, Vector2.RIGHT.rotated(a) * r * 1.15, INK, 9.0, true)
				draw_circle(Vector2.RIGHT.rotated(a) * r * 1.15, r * 0.14, Color("#FDE68A"))
			_blob(Vector2.ZERO, r * 0.75, c.lerp(Color.WHITE, 0.5 * (0.5 + 0.5 * sin(_t * 8.0))))
			_eyes(Vector2.ZERO, r * 0.2, r * 0.28, 2)
		"bala":
			var p := 1.0 + 0.12 * sin(_t * 18.0)
			draw_circle(Vector2.ZERO, r * 1.6 * p, Color(col, 0.25))
			draw_circle(Vector2.ZERO, r * p + 3.0, INK)
			draw_circle(Vector2.ZERO, r * p, col)
			draw_circle(Vector2.ZERO, r * 0.45, Color.WHITE)
		"anel":
			var rr := r * (1.0 + 0.06 * sin(_t * 10.0))
			draw_arc(Vector2.ZERO, rr, 0.0, TAU, 32, INK, r * 0.42, true)
			draw_arc(Vector2.ZERO, rr, 0.0, TAU, 32, Color.from_hsv(fmod(_t * 0.6, 1.0), 0.5, 1.0), r * 0.28, true)
			draw_arc(Vector2.ZERO, rr, _t * 6.0, _t * 6.0 + 1.2, 10, Color(1, 1, 1, 0.8), r * 0.12, true)
		"pedra":
			_glow(r * 1.4, Color("#F97316"))
			_rock(r, Color("#B08968"))
		"P", "A", "S":
			_capsule(r, c, kind)
		"coracao":
			_glow(r * 1.5, col)
			var h := PackedVector2Array()
			for i in 40:
				var a := TAU * i / 40.0
				h.append(Vector2(16 * pow(sin(a), 3), -(13 * cos(a) - 5 * cos(2 * a) - 2 * cos(3 * a) - cos(4 * a))) * r / 17.0)
			_poly(h, c)
		"estrela":
			var s := PackedVector2Array()
			for i in 10:
				var a := -PI / 2.0 + i * PI / 5.0 + _t * 2.0
				s.append(Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
			_poly(s, c)


	if chief:
		var w := r * 0.5
		var top := Vector2(0, -r * 1.02)
		var crown := PackedVector2Array([top + Vector2(-w, 14), top + Vector2(-w, -22), top + Vector2(-w * 0.5, 0),
			top + Vector2(0, -34), top + Vector2(w * 0.5, 0), top + Vector2(w, -22), top + Vector2(w, 14)])
		_poly(crown, Color("#FACC15"))
		for sd in [-1.0, 1.0]:
			var e := Vector2(sd * r * 0.22, -r * 0.32)
			draw_line(e + Vector2(-r * 0.16, -sd * r * 0.06), e + Vector2(r * 0.16, sd * r * 0.06), INK, maxf(6.0, r * 0.07), true)


func _draw_painted(r: float) -> void:
	var cap := kind in ["P", "A", "S", "coracao"]
	_glow(r * (1.7 if cap else 1.4), col)
	var k := 1.0 + (0.08 * sin(_t * 6.0) if cap else 0.04 * sin(_t * 4.0))
	var side := size * (1.25 if cap else 1.35) * k
	var sz := Vector2(side, side * _tex.get_height() / float(_tex.get_width()))
	draw_set_transform(Vector2.ZERO, sin(_t * 2.0) * 0.08 if not cap else 0.0, Vector2.ONE)
	draw_texture_rect(_tex, Rect2(-sz / 2.0, sz), false, Color.WHITE.lerp(Color(3, 3, 3), flash * 0.7))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if chief:
		_crown(r)


func _crown(r: float) -> void:
	var w := r * 0.5
	var top := Vector2(0, -r * 1.02)
	var crown := PackedVector2Array([top + Vector2(-w, 14), top + Vector2(-w, -22), top + Vector2(-w * 0.5, 0),
		top + Vector2(0, -34), top + Vector2(w * 0.5, 0), top + Vector2(w, -22), top + Vector2(w, 14)])
	_poly(crown, Color("#FACC15"))


# ------------------------------------------------------------------ peças de desenho
func _glow(r: float, c: Color) -> void:
	draw_circle(Vector2.ZERO, r, Color(c, 0.12))
	draw_circle(Vector2.ZERO, r * 0.8, Color(c, 0.14))


func _blob(p: Vector2, r: float, c: Color) -> void:
	draw_circle(p, r + 4.0, INK)
	draw_circle(p, r, c)
	draw_circle(p + Vector2(-r * 0.3, -r * 0.35), r * 0.32, Color(1, 1, 1, 0.35))


func _poly(pts: PackedVector2Array, c: Color) -> void:
	var o := pts.duplicate()
	o.append(pts[0])
	draw_polyline(o, INK, 8.0, true)
	draw_colored_polygon(pts, c)
	draw_polyline(o, c.lightened(0.35), 2.0, true)


func _rock(r: float, c: Color) -> void:
	var pts := PackedVector2Array()
	for i in 9:
		var a := TAU * i / 9.0
		pts.append(Vector2.RIGHT.rotated(a) * r * (0.86 + 0.14 * sin(i * 2.7)))
	_poly(pts, c.darkened(0.3))
	draw_circle(Vector2(r * 0.4, r * 0.35), r * 0.15, c.darkened(0.5))


func _antenna(p: Vector2, lean: float, c: Color) -> void:
	var tip := p + Vector2(lean * 30.0 + sin(_t * 4.0) * 4.0, -size * 0.28)
	draw_line(p, tip, INK, 6.0, true)
	draw_circle(tip, size * 0.08 + 3.0, INK)
	draw_circle(tip, size * 0.08, c.lightened(0.4))


## Olhos: n = 1 (ciclope) ou 2; olham para a nave (look); piscam; felizes = arquinho ^ ^.
func _eyes(p: Vector2, er: float, gap: float, n: int) -> void:
	var cs: Array[Vector2] = [p]
	if n == 2:
		cs = [p + Vector2(-gap / 2.0, 0), p + Vector2(gap / 2.0, 0)]
	for e in cs:
		if happy:
			draw_arc(e + Vector2(0, er * 0.3), er * 0.8, PI * 1.15, PI * 1.85, 12, INK, maxf(4.0, er * 0.35), true)
			continue
		if _blink < 0.0:
			draw_line(e + Vector2(-er, 0), e + Vector2(er, 0), INK, maxf(4.0, er * 0.3), true)
			continue
		draw_circle(e, er + 3.0, INK)
		draw_circle(e, er, Color.WHITE)
		draw_circle(e + look.normalized() * er * 0.4, er * 0.5, INK)
		draw_circle(e + look.normalized() * er * 0.4 + Vector2(-er * 0.15, -er * 0.18), er * 0.16, Color.WHITE)


## Cápsula de item: P = canhão mais forte, A = ajudante, S = escudo. Gira devagar e pisca a letra.
func _capsule(r: float, c: Color, letter: String) -> void:
	var p := 1.0 + 0.08 * sin(_t * 6.0)
	draw_circle(Vector2.ZERO, r * 1.7 * p, Color(c, 0.18))
	draw_circle(Vector2.ZERO, r * 1.3 * p, Color(c, 0.22))
	draw_circle(Vector2.ZERO, r + 5.0, INK)
	draw_circle(Vector2.ZERO, r, c)
	draw_circle(Vector2.ZERO, r * 0.78, c.lightened(0.45))
	draw_circle(Vector2(-r * 0.35, -r * 0.4), r * 0.22, Color(1, 1, 1, 0.7))
	var w := maxf(6.0, r * 0.2)
	match letter:
		"P":
			draw_line(Vector2(-r * 0.25, -r * 0.5), Vector2(-r * 0.25, r * 0.5), INK, w, true)
			draw_arc(Vector2(-r * 0.05, -r * 0.2), r * 0.3, -PI / 2.0, PI / 2.0, 12, INK, w, true)
			draw_line(Vector2(-r * 0.25, -r * 0.5), Vector2(-r * 0.05, -r * 0.5), INK, w, true)
			draw_line(Vector2(-r * 0.25, r * 0.1), Vector2(-r * 0.05, r * 0.1), INK, w, true)
		"A":
			draw_line(Vector2(-r * 0.4, r * 0.5), Vector2(0, -r * 0.5), INK, w, true)
			draw_line(Vector2(r * 0.4, r * 0.5), Vector2(0, -r * 0.5), INK, w, true)
			draw_line(Vector2(-r * 0.22, r * 0.12), Vector2(r * 0.22, r * 0.12), INK, w, true)
		"S":
			draw_arc(Vector2(0, -r * 0.24), r * 0.26, -PI * 1.5, -PI * 0.15, 14, INK, w, true)
			draw_arc(Vector2(0, r * 0.24), r * 0.26, -PI * 0.5, PI * 0.85, 14, INK, w, true)
