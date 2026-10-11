class_name ShmupBoss
extends Node2D
## Os 6 MESTRES das fases de nave (11/10, o Andro: "o mestre deveria ser algo legal"). Cada planeta tem o seu,
## desenhado em código com rosto que reage (olha para a nave, fica bravo na metade da vida, sorri quando vence),
## partes animadas e ataques próprios. Todo ataque forte AVISA antes (faixa piscando ~1 s): dá para uma criança
## de 4 anos desviar. Não morre: quando a vida acaba ele "acalma", fica feliz, vira amigo e vai embora.
## A tela que o usa (ShmupSegment) dá: enemy_bullet(), danger_band(), spawn_foe(), ship_pos(), vr().

const R := 150.0
const INK := Color("#1A1033")
const ATTACKS := {"cratera": ["leque", "olhar", "chuva", "filhotes"], "ferrugem": ["leque", "garra", "filhotes", "espiral"],
	"tempestade": ["espiral", "raios", "leque", "raios"], "aneis": ["anel", "parede", "leque", "anel"],
	"gelo": ["leque", "espinhos", "espiral", "filhotes"], "polvo": ["bolhas", "tentaculo", "espiral", "filhotes", "raios"]}
const BODY := {"cratera": Color("#A5A3C9"), "ferrugem": Color("#E8743B"), "tempestade": Color("#5EC8E5"),
	"aneis": Color("#F2C879"), "gelo": Color("#9BE7FF"), "polvo": Color("#B07CF0")}

var kind := "cratera"
var max_hp := 60.0
var hp := 60.0
var heat := 0.0
var angry := false
var happy := false
var calm := false
var flash := 0.0
var seg: Node
var _t := 0.0
var _cd := 2.0
var _next := 0
var _home := Vector2.ZERO
var _blink := 2.0


func setup(k: String, life: float, h: float, s: Node) -> void:
	kind = k
	max_hp = life
	hp = life
	heat = h
	seg = s
	z_index = 30


## Dano; devolve true quando a vida acaba (ele acalma).
func hurt(dmg: float) -> bool:
	if calm:
		return false
	hp = maxf(0.0, hp - dmg)
	flash = 1.0
	if not angry and hp <= max_hp * 0.5:
		angry = true
		_cd = minf(_cd, 0.8)
		AudioService.play_sfx("bump", 0.6, 0.0)
	if hp <= 0.0:
		calm = true
		happy = true
		return true
	return false


func radius() -> float:
	return R * 0.92


## Animação (rosto, piscar, partes) roda sempre — inclusive depois de vencido, para o sorriso aparecer (antes ela
## só rodava na luta e o mestre ia embora congelado com a cara brava).
func _process(delta: float) -> void:
	_t += delta
	_blink -= delta
	if _blink < -0.12:
		_blink = randf_range(1.5, 3.5)
	flash = maxf(0.0, flash - delta * 5.0)
	queue_redraw()


## Inteligência de luta (a tela chama só enquanto a luta está valendo).
func tick(delta: float) -> void:
	if calm or seg == null:
		return
	var vr: Rect2 = seg.vr()
	_home = Vector2(vr.end.x - R - 170.0, lerpf(380.0, seg.ship_pos().y, 0.35))
	position = position.lerp(_home + Vector2(sin(_t * 0.9) * 30.0, sin(_t * 1.7) * 60.0), minf(1.0, delta * 1.6))
	_cd -= delta
	if _cd <= 0.0 and seg.can_attack():
		var list: Array = ATTACKS[kind]
		_attack(str(list[_next % list.size()]))
		_next += 1
		_cd = lerpf(3.0, 1.9, heat) * (0.72 if angry else 1.0)


# ------------------------------------------------------------------ ataques
func _attack(a: String) -> void:
	var sp := 250.0 + 110.0 * heat
	var mouth := position + Vector2(-R * 0.6, R * 0.2)
	var aim: Vector2 = (seg.ship_pos() - mouth).normalized()
	var vr: Rect2 = seg.vr()
	match a:
		"leque":
			var n := 7 if angry else 5
			for i in n:
				seg.enemy_bullet(mouth, aim.rotated(deg_to_rad(-40.0 + 80.0 * i / float(n - 1))) * sp)
			AudioService.play_sfx("tap", 0.6, -4.0)
		"espiral":
			for b in (4 if angry else 3):
				seg.after(b * 0.35, func():
					if calm:
						return
					for i in 8:
						seg.enemy_bullet(position, Vector2.LEFT.rotated(i * TAU / 8.0 + b * 0.35) * sp * 0.8))
		"chuva":
			for i in (5 if angry else 4):
				var x := lerpf(vr.position.x + 300.0, position.x - 100.0, i / 4.0)
				seg.enemy_bullet(Vector2(x, 40), Vector2(-90, sp * 0.8), 56.0, "pedra")
		"olhar", "garra", "tentaculo":
			var y: float = seg.ship_pos().y
			var style := {"olhar": "raio", "garra": "garra", "tentaculo": "tentaculo"}[a] as String
			seg.danger_band(Rect2(vr.position.x, y - 60.0, position.x - vr.position.x, 120.0), 1.1, 0.6, BODY[kind], style)
		"raios":
			for i in (3 if angry else 2):
				var x := randf_range(vr.position.x + 120.0, position.x - 260.0)
				seg.danger_band(Rect2(x - 55.0, 0, 110.0, 720.0), 1.1, 0.5, Color("#FDE047"), "raio")
		"espinhos":
			var top := randf() < 0.5
			seg.danger_band(Rect2(vr.position.x, 0.0 if top else 500.0, position.x - vr.position.x, 220.0), 1.1, 0.5,
				BODY[kind], "gelo")
		"anel":
			seg.enemy_bullet(position + Vector2(-R, 0), (seg.ship_pos() - position).normalized() * sp * 0.75, 120.0, "anel")
		"parede":
			var gap := int(clampf((seg.ship_pos().y - 80.0) / 90.0, 0.0, 6.0))
			for i in 8:
				if i == gap or i == gap + 1:
					continue
				seg.enemy_bullet(Vector2(position.x - R, 60.0 + i * 90.0), Vector2(-sp * 0.75, 0))
		"bolhas":
			for i in (8 if angry else 6):
				seg.enemy_bullet(mouth, Vector2(-sp * 0.7, 0).rotated(randf_range(-0.5, 0.5)), 40.0, "onda")
		"filhotes":
			for i in 3:
				seg.spawn_foe(seg.world_foe(), position + Vector2(-R, -120 + i * 120))


# ------------------------------------------------------------------ desenho
func _draw() -> void:
	var c: Color = (BODY[kind] as Color).lerp(Color.WHITE, flash * 0.8)
	var bob := sin(_t * 2.2) * 6.0
	draw_circle(Vector2.ZERO, R * 1.55, Color(c, 0.10))
	draw_circle(Vector2.ZERO, R * 1.25, Color(c, 0.12))
	match kind:
		"cratera":
			for i in 3:
				var a := _t * 1.4 + i * TAU / 3.0
				_ball(Vector2.RIGHT.rotated(a) * R * 1.2, R * 0.2, c.darkened(0.25))
			_ball(Vector2(0, bob), R, c)
			for p in [Vector2(-0.45, -0.5), Vector2(0.5, 0.45), Vector2(0.55, -0.2), Vector2(-0.55, 0.5)]:
				draw_circle(Vector2(p.x * R, p.y * R + bob), R * 0.13, c.darkened(0.3))
			_crown(Vector2(0, -R * 0.95 + bob), Color("#FACC15"))
			_face(Vector2(0, R * 0.05 + bob), R)
		"ferrugem":
			var claw := 0.5 + 0.5 * sin(_t * 3.0)
			for sd in [-1.0, 1.0]:
				var base := Vector2(-R * 0.75, sd * R * 0.62 + bob)
				var elbow := base + Vector2(-R * 0.45, sd * 26.0)
				var hand := elbow + Vector2(-R * 0.3, 0)
				draw_line(base, elbow, INK, 34.0, true)
				draw_line(base, elbow, c.darkened(0.25), 22.0, true)
				draw_circle(elbow, 22.0, INK)
				draw_circle(elbow, 15.0, c.lightened(0.15))
				for k in [-1.0, 1.0]:
					var tip := hand + Vector2(-34, k * (14.0 + 26.0 * claw))
					draw_line(elbow, tip, INK, 26.0, true)
					draw_line(elbow, tip, Color("#94A3B8"), 15.0, true)
			var rect := Rect2(-R, -R * 0.85 + bob, R * 2.0, R * 1.7)
			draw_rect(rect.grow(6.0), INK)
			draw_rect(rect, c)
			draw_rect(Rect2(rect.position + Vector2(10, 10), Vector2(rect.size.x - 20, 26)), c.lightened(0.25))
			for p in [Vector2(-0.85, -0.7), Vector2(0.85, -0.7), Vector2(-0.85, 0.7), Vector2(0.85, 0.7)]:
				draw_circle(Vector2(p.x * R, p.y * R + bob), 9.0, c.darkened(0.4))
			draw_line(Vector2(0, -R * 0.85 + bob), Vector2(0, -R * 1.25 + bob), INK, 8.0)
			draw_circle(Vector2(0, -R * 1.28 + bob), 16.0, Color("#F43F5E") if fmod(_t, 0.8) < 0.4 else Color("#FDE68A"))
			_face(Vector2(0, R * 0.05 + bob), R)
		"tempestade":
			for i in 7:
				var a := -_t * 1.6 + i * TAU / 7.0
				draw_arc(Vector2(0, bob), R * (0.75 + 0.1 * (i % 3)), a, a + 1.6, 18, Color(c.lightened(0.2), 0.85), 22.0, true)
			_ball(Vector2(0, bob), R * 0.72, c)
			if fmod(_t, 1.3) < 0.15:
				var z := PackedVector2Array([Vector2(R * 0.8, -R), Vector2(R * 0.55, -R * 0.4), Vector2(R * 0.85, -R * 0.35),
					Vector2(R * 0.5, R * 0.3)])
				draw_polyline(z, Color("#FDE047"), 10.0, true)
			_face(Vector2(0, bob), R * 0.75)
		"aneis":
			_ring(Vector2(0, bob), c, true)
			_ball(Vector2(0, bob), R * 0.8, c)
			for k in 3:
				draw_arc(Vector2(0, bob), R * (0.35 + k * 0.15), PI * 1.1, PI * 1.9, 16, Color(c.darkened(0.2), 0.6), 8.0, true)
			_ring(Vector2(0, bob), c, false)
			_face(Vector2(0, R * 0.05 + bob), R * 0.8)
		"gelo":
			for i in 7:
				var a := -PI / 2.0 + (i - 3) * 0.42
				var tip := Vector2.RIGHT.rotated(a) * R * (1.25 + 0.1 * sin(_t * 3.0 + i))
				_shard(Vector2(0, bob), tip + Vector2(0, bob), R * 0.22, c.lightened(0.1 * (i % 2)))
			_gem(Vector2(0, bob), R * 0.85, c)
			_face(Vector2(0, R * 0.1 + bob), R * 0.8)
		"polvo":
			for i in 6:
				var base := Vector2(-R * 0.55 + i * R * 0.2, R * 0.45 + bob)
				var pts := PackedVector2Array()
				for k in 14:
					var u := k / 13.0
					var dir := Vector2(-0.55 - i * 0.05, 1.0).normalized()
					pts.append(base + dir * u * R * 1.15 + dir.orthogonal() * sin(_t * 3.5 + i * 0.9 + u * 4.0) * 30.0 * u)
				for k in 13:
					var w := lerpf(46.0, 14.0, k / 12.0)
					draw_line(pts[k], pts[k + 1], INK, w + 8.0, true)
				for k in 13:
					var w := lerpf(46.0, 14.0, k / 12.0)
					draw_line(pts[k], pts[k + 1], c.darkened(0.08), w, true)
				for k in [3, 6, 9]:
					draw_circle(pts[k] + Vector2(6, 0), lerpf(9.0, 4.0, k / 12.0), c.lightened(0.4))
			_ball(Vector2(0, bob - R * 0.1), R * 0.9, c)
			for p in [Vector2(0.4, -0.55), Vector2(0.6, -0.15), Vector2(-0.5, -0.6)]:
				draw_circle(Vector2(p.x * R, p.y * R + bob), R * 0.09, c.lightened(0.35))
			_face(Vector2(0, bob), R * 0.85)


func _ball(p: Vector2, r: float, c: Color) -> void:
	draw_circle(p, r + 7.0, INK)
	draw_circle(p, r, c)
	draw_circle(p + Vector2(r * 0.15, r * 0.2), r * 0.82, c.darkened(0.12))
	draw_circle(p + Vector2(-r * 0.32, -r * 0.38), r * 0.22, Color(1, 1, 1, 0.35))


func _crown(p: Vector2, c: Color) -> void:
	var w := R * 0.55
	var pts := PackedVector2Array([p + Vector2(-w, 20), p + Vector2(-w, -30), p + Vector2(-w * 0.5, 0), p + Vector2(0, -45),
		p + Vector2(w * 0.5, 0), p + Vector2(w, -30), p + Vector2(w, 20)])
	var o := pts.duplicate()
	o.append(pts[0])
	draw_colored_polygon(pts, c)
	draw_polyline(o, INK, 6.0, true)
	for x in [-w * 0.6, 0.0, w * 0.6]:
		draw_circle(p + Vector2(x, 6), 8.0, Color("#F43F5E"))


func _ring(p: Vector2, c: Color, back: bool) -> void:
	var pts := PackedVector2Array()
	for i in 33:
		var a := (PI if back else 0.0) + PI * i / 32.0
		pts.append(p + Vector2(cos(a) * R * 1.6, sin(a) * R * 0.38).rotated(-0.25))
	var rc := Color.from_hsv(fmod(_t * 0.15, 1.0), 0.45, 1.0) if angry else c.lightened(0.3)
	draw_polyline(pts, INK, 30.0, true)
	draw_polyline(pts, rc, 20.0, true)


func _shard(base: Vector2, tip: Vector2, w: float, c: Color) -> void:
	var n := (tip - base).orthogonal().normalized() * w
	var pts := PackedVector2Array([base + n, tip, base - n])
	var o := pts.duplicate()
	o.append(pts[0])
	draw_colored_polygon(pts, c)
	draw_polyline(o, INK, 6.0, true)


func _gem(p: Vector2, r: float, c: Color) -> void:
	var pts := PackedVector2Array()
	for i in 6:
		pts.append(p + Vector2.RIGHT.rotated(PI / 6.0 + i * TAU / 6.0) * r)
	var o := pts.duplicate()
	o.append(pts[0])
	draw_colored_polygon(pts, c)
	draw_polyline(o, INK, 8.0, true)
	draw_colored_polygon(PackedVector2Array([p, pts[4], pts[5]]), c.lightened(0.35))
	draw_colored_polygon(PackedVector2Array([p, pts[1], pts[2]]), c.darkened(0.15))


## Rosto: olhos que seguem a nave, sobrancelha brava na metade da vida, sorriso quando acalma.
func _face(p: Vector2, s: float) -> void:
	var look := Vector2.LEFT
	if seg != null:
		look = (seg.ship_pos() - (position + p)).normalized()
	var er := s * 0.2
	for side in [-1.0, 1.0]:
		var e := p + Vector2(side * s * 0.32, -s * 0.12)
		if happy:
			draw_arc(e + Vector2(0, er * 0.3), er * 0.85, PI * 1.15, PI * 1.85, 14, INK, er * 0.35, true)
			continue
		if _blink < 0.0:
			draw_line(e + Vector2(-er, 0), e + Vector2(er, 0), INK, er * 0.3, true)
		else:
			draw_circle(e, er + 5.0, INK)
			draw_circle(e, er, Color.WHITE)
			draw_circle(e + look * er * 0.42, er * 0.5, Color("#7F1D1D") if angry else INK)
			draw_circle(e + look * er * 0.42 + Vector2(-er * 0.15, -er * 0.2), er * 0.16, Color.WHITE)
		var tilt := 0.5 if angry else 0.25
		draw_line(e + Vector2(-er * 1.1, -er * (1.3 - side * tilt)), e + Vector2(er * 1.1, -er * (1.3 + side * tilt)), INK,
			er * 0.4, true)
	var m := p + Vector2(0, s * 0.38)
	if happy:
		draw_arc(m + Vector2(0, -s * 0.08), s * 0.3, 0.15, PI - 0.15, 18, INK, s * 0.07, true)
		draw_circle(m + Vector2(-s * 0.48, -s * 0.12), s * 0.1, Color(1, 0.45, 0.6, 0.6))
		draw_circle(m + Vector2(s * 0.48, -s * 0.12), s * 0.1, Color(1, 0.45, 0.6, 0.6))
	elif angry:
		draw_rect(Rect2(m + Vector2(-s * 0.3, -s * 0.07), Vector2(s * 0.6, s * 0.16)), INK)
		for k in 4:
			draw_rect(Rect2(m + Vector2(-s * 0.26 + k * s * 0.14, -s * 0.05), Vector2(s * 0.1, s * 0.07)), Color.WHITE)
		for sd in [-1.0, 1.0]:
			draw_circle(p + Vector2(sd * s * 0.55, s * 0.2), s * 0.11, Color(1, 0.25, 0.25, 0.55))
			var puff := fmod(_t * 1.5 + (0.5 if sd > 0 else 0.0), 1.0)
			draw_circle(p + Vector2(sd * s * (0.75 + puff * 0.25), -s * (0.75 + puff * 0.5)), s * (0.08 + puff * 0.08),
				Color(1, 1, 1, 0.6 * (1.0 - puff)))
	else:
		# sorriso maroto (de vilão de desenho): torto, com um dentinho
		draw_arc(m + Vector2(s * 0.04, -s * 0.12), s * 0.26, 0.35, PI - 0.6, 16, INK, s * 0.07, true)
		draw_rect(Rect2(m + Vector2(-s * 0.02, s * 0.1), Vector2(s * 0.09, s * 0.08)), Color.WHITE)
