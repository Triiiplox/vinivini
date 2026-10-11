extends Node
## QA da versão de TV com controle (xvfb): só eventos de CONTROLE (setas, analógico, A, B) — nada de toque.
##   godot --path game -- --tv --padcheck=/dir
## Controle de PS5 (DualSense): no Godot ✕ = A, ○ = B, □ = X, △ = Y, OPTIONS = START, CREATE = BACK.
## Ajuda na 1ª vez (fecha com △) → setas até o VOAR → ○ → FASES → fase 1 (✕) → seta repetida como tecla pelo Android
## não anda duas vezes → trocar faixa (setas e analógico) → OPTIONS segurado volta para o começo → lição de arrastar
## (✕ segurado + analógico) → traçar letra pelo analógico → turbo do voo livre (□ e um botão de número desconhecido).
## Imprime PAD PASS/FAIL e sai com 1 se algo falhar.

var out := ""
var results := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--padcheck="):
			out = a.substr(11)
	DirAccess.make_dir_recursive_absolute(out)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://tv.cfg"))
	SaveService.reset_profile()
	SaveService.progress.data(SaveService.profile_id)["placed"] = {"reading": true, "math": true, "logic": true,
		"astronomy": true, "science": true}
	results["pad_ligado"] = Pad.enabled
	await _home_to_phase()
	await _lanes_and_back()
	await _drag_lesson()
	await _trace_lesson()
	await _arcade_turbo()
	var ok := not results.values().has(false)
	print("PAD %s: %s" % ["PASS" if ok else "FAIL", results])
	get_tree().quit(0 if ok else 1)


# ------------------------------------------------------------------ passos
func _home_to_phase() -> void:
	Router.reset_to("home", {})
	await _wait(1.6)
	results["ajuda_aparece"] = Pad.get_node_or_null("PadHelp") != null
	await _shot("pad_ajuda")
	await _btn(JOY_BUTTON_Y)
	await _wait(0.4)
	results["ajuda_fecha_com_triangulo"] = Pad.get_node_or_null("PadHelp") == null
	var fly: Node2D = Router.current_screen.find_child("Tile_fly", true, false)
	results["setas_chegam_no_voar"] = await _dpad_to(fly.get_global_transform_with_canvas().origin)
	await _shot("pad_home_voar")
	await _btn(JOY_BUTTON_B)
	await _wait(1.4)
	results["bola_abre_menu_voar"] = Router.current_id == "fly_menu"
	var f1: Node2D = Router.current_screen.find_child("Fase_1", true, false)
	results["setas_chegam_na_fase1"] = await _dpad_to(f1.get_global_transform_with_canvas().origin)
	await _echo_check()
	await _dpad_to(f1.get_global_transform_with_canvas().origin)
	await _btn(JOY_BUTTON_A)
	await _wait(1.4)
	results["xis_abre_fase"] = Router.current_id == "seg_fases"


func _lanes_and_back() -> void:
	var s: Node = Router.current_screen
	await _wait(0.5)
	results["nave_em_modo_faixa"] = Pad.pad_lanes_now()
	var y0: float = s.target_y
	await _btn(JOY_BUTTON_DPAD_DOWN)
	results["seta_baixo_troca_faixa"] = s.target_y > y0
	await _axis(JOY_AXIS_LEFT_Y, -1.0, 0.3)
	await _axis(JOY_AXIS_LEFT_Y, 0.0, 0.1)
	await _axis(JOY_AXIS_LEFT_Y, -1.0, 0.3)
	await _axis(JOY_AXIS_LEFT_Y, 0.0, 0.1)
	results["analogico_sobe_duas_faixas"] = is_equal_approx(s.target_y, 200.0)
	await _shot("pad_fase")
	await _btn(JOY_BUTTON_B)
	await _btn(JOY_BUTTON_Y)
	results["botoes_da_frente_nao_saem"] = Router.current_id == "seg_fases"
	_send_btn(JOY_BUTTON_START, true)
	await _wait(0.4)
	await _shot("pad_options_segurando")
	results["options_rapido_nao_sai"] = Router.current_id == "seg_fases"
	await _wait(0.8)
	_send_btn(JOY_BUTTON_START, false)
	await _wait(1.2)
	results["options_segurado_volta_ao_comeco"] = Router.current_id == "home"


func _drag_lesson() -> void:
	Router.reset_to("seg_lesson", {"lesson": "juntar", "n": 2})
	await _wait(1.2)
	var s: Node = Router.current_screen
	var t := 0.0
	while str(s.rd.get("k", "")) in ["", "teach"] and t < 40.0:
		if s.next_btn.visible:
			await _dpad_to(s.next_btn.get_global_transform_with_canvas() * (s.next_btn.size / 2.0))
			await _btn(JOY_BUTTON_A)
		await _wait(0.5)
		t += 0.5
	await _wait(2.5)
	var step := int(s.step_i)
	var dest: Node2D = s.basket
	for i in int(s.rd.get("b", 1)):
		for c in s.cards:
			if is_instance_valid(c) and c.draggable and str(c.payload) == "out":
				await _stick_to(c.get_global_transform_with_canvas().origin)
				_send_btn(JOY_BUTTON_A, true)
				await _wait(0.15)
				await _stick_to(dest.get_global_transform_with_canvas().origin)
				_send_btn(JOY_BUTTON_A, false)
				await _wait(0.5)
				break
	await _wait(0.6)
	await _shot("pad_arrastar")
	results["arrastar_com_xis_e_analogico"] = s.busy or int(s.step_i) > step


func _trace_lesson() -> void:
	Router.reset_to("seg_lesson", {"lesson": "tracar_letras", "n": 2})
	await _wait(1.2)
	var s: Node = Router.current_screen
	var t := 0.0
	while str(s.rd.get("k", "")) in ["", "teach"] and t < 40.0:
		if s.next_btn.visible:
			await _dpad_to(s.next_btn.get_global_transform_with_canvas() * (s.next_btn.size / 2.0))
			await _btn(JOY_BUTTON_A)
		await _wait(0.5)
		t += 0.5
	await _wait(2.5)
	var step := int(s.step_i)
	var ct: Transform2D = (s as GameScreen).world.get_canvas_transform()
	for st in s._strokes(str(s.rd["letter"])):
		await _stick_to(ct * s._tp(st[0]))
		_send_btn(JOY_BUTTON_A, true)
		await _wait(0.1)
		for u in st:
			await _stick_to(ct * s._tp(u), 14.0)
		_send_btn(JOY_BUTTON_A, false)
		await _wait(0.3)
	await _wait(0.6)
	await _shot("pad_tracar")
	results["tracar_letra_%s_pelo_analogico" % s.rd["letter"]] = s.busy or int(s.step_i) > step


func _arcade_turbo() -> void:
	Router.reset_to("seg_arcade", {})
	await _wait(1.5)
	var s: Node = Router.current_screen
	await _btn(JOY_BUTTON_X)
	results["quadrado_e_turbo_no_voo_livre"] = s.turbo_t > 0.0
	await _wait(3.0)
	s.turbo_t = 0.0
	s.turbo_cd = 0.0
	await _btn(40)  # DualSense sem driver (Android antigo): botão com número fora do padrão
	results["botao_desconhecido_tambem_vale"] = s.turbo_t > 0.0


## Android repete a seta do controle como tecla (direcional "sintético"): a estrela não pode andar duas vezes.
## Tecla sozinha (controle remoto da TV) continua andando.
func _echo_check() -> void:
	var c0: Vector2 = Pad.cursor
	_send_btn(JOY_BUTTON_DPAD_LEFT, true)
	_send_key(KEY_LEFT, true)
	await _wait(0.05)
	_send_btn(JOY_BUTTON_DPAD_LEFT, false)
	_send_key(KEY_LEFT, false)
	var c1: Vector2 = Pad.cursor
	var once: Vector2 = c0
	Pad.cursor = c0
	Pad.snap(Vector2.LEFT)
	once = Pad.cursor
	Pad.move_to(c1)
	results["seta_repetida_do_android_ignorada"] = c1 != c0 and c1.distance_to(once) < 1.0
	await _wait(0.3)
	_send_key(KEY_RIGHT, true)
	await _wait(0.05)
	_send_key(KEY_RIGHT, false)
	await _wait(0.05)
	var c2: Vector2 = Pad.cursor
	results["controle_remoto_da_tv_anda"] = c2 != c1
	await _wait(0.2)


func _send_key(k: int, down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.pressed = down
	Input.parse_input_event(e)


# ------------------------------------------------------------------ controle simulado
func _send_btn(b: int, down: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	e.pressed = down
	Input.parse_input_event(e)


func _btn(b: int) -> void:
	_send_btn(b, true)
	await _wait(0.08)
	_send_btn(b, false)
	await _wait(0.12)


func _axis(axis: int, v: float, sec: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = v
	Input.parse_input_event(e)
	await _wait(sec)


## Setas até o alvo (como uma criança apertando para os lados): no máximo 12 apertos.
func _dpad_to(p: Vector2) -> bool:
	for i in 12:
		var cur: Vector2 = Pad.cursor
		var d: Vector2 = p - cur
		if d.length() < 40.0:
			return true
		var b := (JOY_BUTTON_DPAD_RIGHT if d.x > 0 else JOY_BUTTON_DPAD_LEFT) if absf(d.x) > absf(d.y) \
			else (JOY_BUTTON_DPAD_DOWN if d.y > 0 else JOY_BUTTON_DPAD_UP)
		await _btn(b)
	var last: Vector2 = Pad.cursor
	return last.distance_to(p) < 40.0


## Analógico até o ponto (inclina na direção, solta perto).
func _stick_to(p: Vector2, tol: float = 24.0) -> void:
	for i in 240:
		var cur: Vector2 = Pad.cursor
		var d: Vector2 = p - cur
		if d.length() < tol:
			break
		var v: Vector2 = d.normalized() * clampf(d.length() / 140.0, 0.55, 1.0)
		var ex := InputEventJoypadMotion.new()
		ex.axis = JOY_AXIS_LEFT_X
		ex.axis_value = v.x
		Input.parse_input_event(ex)
		var ey := InputEventJoypadMotion.new()
		ey.axis = JOY_AXIS_LEFT_Y
		ey.axis_value = v.y
		Input.parse_input_event(ey)
		await get_tree().process_frame
	for ax in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		var z := InputEventJoypadMotion.new()
		z.axis = ax
		z.axis_value = 0.0
		Input.parse_input_event(z)
	await get_tree().process_frame


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(n + ".png"))
