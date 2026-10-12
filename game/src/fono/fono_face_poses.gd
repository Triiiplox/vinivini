extends RefCounted
## O que cada exercício/som faz no rosto: a expressão (olhar que acompanha a língua, sobrancelhas, apertar os olhos,
## bochechas cheias ou chupadas, gotinha de esforço) e a boca (fono_face_tongue.gd / fono_face_lips.gd).
## `ph` é a fase 0..1 da repetição (o `beat` da academia, ou um relógio próprio); `t` é o tempo corrido (tremidas).
## Id desconhecido = rosto neutro, sem erro.

const Mouth := preload("res://src/fono/fono_face_mouth.gd")
const Tongue := preload("res://src/fono/fono_face_tongue.gd")
const Lips := preload("res://src/fono/fono_face_lips.gd")


static func look(pose: String, ph: float, t: float) -> Dictionary:
	var o := {"gaze": Vector2.ZERO, "squint": 0.0, "brow_up": 0.0, "brow_tilt": 0.0, "puff_l": 0.0, "puff_r": 0.0,
		"effort": 0.0}
	match pose:
		"lingua_cima", "lamber_labio_cima":
			o.gaze = Vector2(sin(TAU * ph) * 0.5 if pose != "lingua_cima" else 0.0, -1)
			o.brow_up = 0.6
		"lingua_baixo", "lingua_larga", "lingua_fina", "lingua_dentro_fora", "lamber_labio_baixo", "vibrar_lingua":
			o.gaze = Vector2(sin(TAU * ph) * 0.5 if pose == "lamber_labio_baixo" else 0.0, 1)
			o.brow_up = 0.3
			o.squint = 0.3 if pose == "vibrar_lingua" else 0.0
		"lingua_larga_segura", "lingua_fina_segura", "bico_segura", "sorriso_segura":
			o.gaze = Vector2(0, 0.6 if pose.begins_with("lingua") else 0.0)
			o.brow_tilt = -0.7
			o.squint = 0.3
			o.effort = 1.0
		"lingua_direita", "lingua_esquerda":
			o.gaze = Vector2(1 if pose == "lingua_direita" else -1, 0.5) * Mouth.hold(ph)
			o.brow_tilt = 0.4
		"cantinhos", "limpar_dentes_cima", "limpar_dentes_baixo":
			var x := -cos(TAU * ph) if pose == "cantinhos" else sin(TAU * ph)
			o.gaze = Vector2(x, 0.4)
			o.brow_tilt = 0.3
		"lamber_labios":
			var a := TAU * ph - PI / 2.0
			o.gaze = Vector2(cos(a), sin(a) * 0.6 + 0.5)
		"bochecha_dentro", "bochecha_alterna":
			var sk := Lips.cheek_side(ph, pose == "bochecha_alterna")
			o.gaze = Vector2(sk.x, 0.4) * 0.8
			o.brow_tilt = 0.5
			if pose == "bochecha_alterna":
				o.puff_r = 0.25 * sk.y if sk.x > 0 else 0.0
				o.puff_l = 0.25 * sk.y if sk.x < 0 else 0.0
		"inflar":
			o.puff_l = 0.85 + 0.15 * Mouth.swing(ph)
			o.puff_r = o.puff_l
			o.squint = 0.3
			o.brow_up = 0.8
		"inflar_alterna":
			var a := smoothstep(0.08, 0.42, ph) - smoothstep(0.58, 0.92, ph)
			o.puff_l = a
			o.puff_r = 1.0 - a
			o.gaze = Vector2(o.puff_r - o.puff_l, 0) * 0.7
			o.squint = 0.25
			o.brow_up = 0.6
		"chupar_bochechas":
			o.puff_l = -0.55 - 0.1 * Mouth.swing(ph)
			o.puff_r = o.puff_l
			o.brow_up = 0.9
		"vibrar_labios":
			o.puff_l = 0.3
			o.puff_r = 0.3
			o.squint = 0.4
			o.brow_up = 0.4 + 0.1 * sin(t * 30.0)
		"bico", "ch", "j", "bico_aberto", "bico_dentes_travados", "boca_de_a":
			o.brow_up = 1.0 if pose == "boca_de_a" else 0.7
		"sorriso_fechado", "sorriso_dentes", "s":
			o.squint = 0.4
			o.brow_up = 0.3
		"bico_sorriso":
			var a := Lips.pucker_smile(ph)
			o.squint = 0.4 * a
			o.brow_up = 0.7 * (1.0 - a)
		"apertar_labios":
			o.brow_tilt = -0.5 * Mouth.hold(ph)
			o.squint = 0.3 * Mouth.hold(ph)
		"morder_labio", "morder_labio_cima", "estalo", "ceu_boca", "varrer", "nd", "r", "ti", "ponta_ceu_soltar", \
				"ponta_chao_soltar":
			o.brow_tilt = 0.35
			o.gaze = Vector2(0, 0.3)
	return o


## Desenha a boca da pose (ampliada em volta do centro da boca).
static func draw(ci: CanvasItem, pose: String, ph: float, t: float) -> void:
	ci.draw_set_transform(Mouth.M * (1.0 - Mouth.MS), 0.0, Vector2.ONE * Mouth.MS)
	if not Tongue.draw(ci, pose, ph, t):
		Lips.draw(ci, pose, ph, t)
	ci.draw_set_transform(Vector2.ZERO)
