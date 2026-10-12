extends RefCounted
## O que cada exercício/som faz no rosto: a expressão (olhar que acompanha a língua, sobrancelhas, apertar os olhos,
## bochechas cheias ou chupadas, gotinha de esforço, luzinhas da gola contando o "segura") e a boca
## (fono_face_tongue.gd / fono_face_lips.gd). `ph` é a fase 0..1 do ciclo (o `beat` da academia, ou um relógio
## próprio). Tudo depende só de `ph`, então o ciclo fecha sem emenda. Id desconhecido = rosto neutro, sem erro.

const Mouth := preload("res://src/fono/fono_face_mouth.gd")
const Tongue := preload("res://src/fono/fono_face_tongue.gd")
const Lips := preload("res://src/fono/fono_face_lips.gd")


## Duração do ciclo próprio (quando ninguém controla o beat).
static func cycle(pose: String) -> float:
	return 3.5 if pose.ends_with("_segura") else 1.6


static func look(pose: String, ph: float) -> Dictionary:
	var o := {"gaze": Vector2.ZERO, "squint": 0.0, "brow_up": 0.0, "brow_tilt": 0.0, "puff_l": 0.0, "puff_r": 0.0,
		"effort": 0.0, "dots": -1.0}
	var g := Mouth.hold(ph)
	var e := Mouth.ext(ph)
	match pose:
		"lingua_cima":
			o.gaze = Vector2(0, -1) * e
			o.brow_up = 0.6 * e
		"lamber_labio_cima":
			o.gaze = Vector2(sin(TAU * smoothstep(0.15, 0.85, ph)) * 0.5, -0.8) * g
			o.brow_up = 0.5 * g
		"lingua_baixo", "lingua_larga", "lingua_fina", "lingua_dentro_fora", "vibrar_lingua":
			o.gaze = Vector2(0, 1) * e
			o.brow_up = 0.3 * e
			o.squint = 0.3 * e if pose == "vibrar_lingua" else 0.0
		"lamber_labio_baixo":
			o.gaze = Vector2(sin(TAU * smoothstep(0.15, 0.85, ph)) * 0.5, 1) * g
		"lingua_larga_segura", "lingua_fina_segura", "bico_segura", "sorriso_segura":
			var k := Tongue.hold_firm(ph)
			o.gaze = Vector2(0, 0.6 if pose.begins_with("lingua") else 0.0) * k
			o.brow_tilt = -0.7 * k
			o.squint = 0.3 * k
			o.effort = smoothstep(0.3, 0.6, ph) * (1.0 - smoothstep(0.8, 0.9, ph))
			o.dots = clampf((ph - Tongue.SEGURA_IN) / (1.0 - 2.0 * Tongue.SEGURA_IN), 0.0, 1.0) * 3.0 * k
		"lingua_direita", "lingua_esquerda":
			o.gaze = Vector2(1 if pose == "lingua_direita" else -1, 0.5) * e
			o.brow_tilt = 0.4 * e
		"cantinhos", "limpar_dentes_cima", "limpar_dentes_baixo":
			o.gaze = Vector2(sin(TAU * smoothstep(0.1, 0.9, ph)), 0.4)
			o.brow_tilt = 0.3 * g
		"lamber_labios":
			var a := TAU * smoothstep(0.12, 0.88, ph) - PI / 2.0
			o.gaze = Vector2(cos(a), sin(a) * 0.6 + 0.5) * g
		"bochecha_dentro", "bochecha_alterna":
			var sk := Lips.cheek_side(ph, pose == "bochecha_alterna")
			o.gaze = Vector2(sk.x, 0.4) * 0.8 * sk.y
			o.brow_tilt = 0.5 * sk.y
			if pose == "bochecha_alterna":
				o.puff_r = 0.25 * sk.y if sk.x > 0 else 0.0
				o.puff_l = 0.25 * sk.y if sk.x < 0 else 0.0
		"inflar", "inflar_alterna":
			var p := Lips.puffs(pose, ph)
			o.puff_l = p.x
			o.puff_r = p.y
			o.gaze = Vector2(p.y - p.x, 0) * 0.7 if pose == "inflar_alterna" else Vector2.ZERO
			o.squint = 0.3 * maxf(p.x, p.y)
			o.brow_up = 0.8 * maxf(p.x, p.y)
		"chupar_bochechas":
			o.puff_l = -0.62 * g
			o.puff_r = o.puff_l
			o.brow_up = 0.9 * g
		"vibrar_labios":
			o.puff_l = 0.3 * g
			o.puff_r = 0.3 * g
			o.squint = 0.4 * g
			o.brow_up = (0.4 + 0.1 * sin(TAU * ph * 10.0)) * g
		"bico", "ch", "j", "bico_aberto", "bico_dentes_travados", "boca_de_a":
			o.brow_up = (1.0 if pose == "boca_de_a" else 0.7) * g
		"sorriso_fechado", "sorriso_dentes", "s":
			o.squint = 0.4 * g
			o.brow_up = 0.3 * g
		"bico_sorriso":
			var a := Lips.pucker_smile(ph)
			o.squint = 0.4 * a.y
			o.brow_up = 0.7 * a.x
		"apertar_labios", "labios_fechados":
			o.brow_tilt = -0.5 * g
			o.squint = 0.3 * g
		"morder_labio", "morder_labio_cima", "estalo", "ceu_boca", "varrer", "nd", "r", "ti", "ponta_ceu_soltar", \
				"ponta_chao_soltar":
			o.brow_tilt = 0.35 * g
			o.gaze = Vector2(0, 0.3) * g
	return o


## Desenha a boca da pose (ampliada em volta do centro da boca).
static func draw(ci: CanvasItem, pose: String, ph: float) -> void:
	ci.draw_set_transform(Mouth.M * (1.0 - Mouth.MS), 0.0, Vector2.ONE * Mouth.MS)
	if not Tongue.draw(ci, pose, ph):
		Lips.draw(ci, pose, ph)
	ci.draw_set_transform(Vector2.ZERO)
