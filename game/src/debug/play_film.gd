extends Node
## Robô que joga como uma criança de 4 anos e filma (11/10, o Andro: "tem muitos bugs nos jogos", e a bateria
## automática não pegava). Toques de verdade (eventos de mouse na janela), sem chamar funções internas do jogo.
##   godot --path game --resolution 2340x1080 -- --playfilm=/dir:modo[:segundos]
##   modos: fase1..fase6 (fases de nave até o fim), voar (voo livre), licao_<id> (amassa a tela numa lição);
##   "+deus" no fim do modo (fase3+deus) = não perde coração, para filmar o chefão e o poder.
## Salva um quadro a cada 0,5 s (640 px de largura) e um log por segundo: estado do jogo, FPS, nós na cena.
## No fim imprime FILM <modo>: resumo + avisos (FPS baixo, nós crescendo = vazamento, tela parada = travou).

var out := ""
var mode := ""
var limit := 150.0
var log_lines: PackedStringArray = []
var warns: PackedStringArray = []
var _frame := 0
var _t := 0.0
var _nodes0 := 0
var _god := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--playfilm="):
			var v := a.substr(11).split(":")
			out = v[0]
			mode = v[1] if v.size() > 1 else "fase1"
			if v.size() > 2 and v[2].is_valid_float():
				limit = float(v[2])
	_god = mode.ends_with("+deus")
	mode = mode.trim_suffix("+deus")
	DirAccess.make_dir_recursive_absolute(out)
	SaveService.reset_profile()
	SaveService.progress.data(SaveService.profile_id)["placed"] = {"reading": true, "math": true, "logic": true,
		"astronomy": true, "science": true}
	RewardService.ensure_starter_items()
	_capture_loop()
	if mode.begins_with("fase"):
		await _play_phase(int(mode.substr(4)) - 1)
	elif mode == "voar":
		await _play_arcade()
	elif mode.begins_with("licao"):
		await _mash_lesson(mode.trim_prefix("licao_"))
	FileAccess.open(out.path_join("log.txt"), FileAccess.WRITE).store_string("\n".join(log_lines))
	print("FILM %s: %d quadros, %.0f s | avisos: %s" % [mode, _frame, _t, warns if not warns.is_empty() else "nenhum"])
	get_tree().quit(0)


# ------------------------------------------------------------------ filmagem e log
func _capture_loop() -> void:
	_nodes0 = get_tree().get_node_count()
	var low_fps := 0
	var last_sig := ""
	var same := 0
	while true:
		await get_tree().create_timer(0.5).timeout
		_t += 0.5
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.resize(640, int(640.0 * img.get_height() / img.get_width()), Image.INTERPOLATE_BILINEAR)
		img.save_jpg(out.path_join("f%04d.jpg" % _frame), 0.8)
		_frame += 1
		if fmod(_t, 1.0) == 0.0:
			var fps := Engine.get_frames_per_second()
			var n := get_tree().get_node_count()
			var st := _state()
			log_lines.append("%5.0fs fps=%3d nos=%5d tela=%s %s" % [_t, fps, n, Router.current_id, st])
			if fps < 40 and _t > 3.0:
				low_fps += 1
				if low_fps == 3:
					warns.append("FPS baixo (%d) aos %.0fs" % [fps, _t])
			if n > _nodes0 + 1500 and not warns.has("nós crescendo"):
				warns.append("nós crescendo (%d → %d) aos %.0fs" % [_nodes0, n, _t])
			var sig := Router.current_id + st
			same = same + 1 if sig == last_sig else 0
			last_sig = sig
			if same == 12:
				warns.append("tela parada 12 s aos %.0fs (%s)" % [_t, sig])


func _state() -> String:
	var s: Node = Router.current_screen
	if s == null:
		return ""
	var bits: PackedStringArray = []
	for k in ["state", "t", "hearts", "pips", "lives", "repairs", "gun", "shield", "score", "power_t", "over", "step_i",
			"turbo_t", "stars"]:
		if k in s:
			var v: Variant = s.get(k)
			bits.append("%s=%s" % [k, ("%.1f" % v) if v is float else str(v)])
	if "boss" in s and s.get("boss") != null:
		bits.append("mestre=%.0f/%.0f" % [s.boss.hp, s.boss.max_hp])
	return " ".join(bits)


# ------------------------------------------------------------------ toques de criança
func _tap(p: Vector2, hold: float = 0.08) -> void:
	_mouse(p, true)
	await get_tree().create_timer(hold).timeout
	_mouse(p, false)


func _mouse(p: Vector2, down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.position = get_viewport().get_screen_transform() * p
	e.global_position = e.position
	Input.parse_input_event(e)


func _vis() -> Rect2:
	return get_viewport().get_visible_rect()


# ------------------------------------------------------------------ fases de nave
func _play_phase(i: int) -> void:
	Router.reset_to("seg_fases", {"fase": i})
	await get_tree().create_timer(2.0).timeout
	var s: Node = Router.current_screen
	var ct: Transform2D = s.world.get_canvas_transform()
	while _t < limit and is_instance_valid(s) and Router.current_screen == s and not s.over:
		if _god:
			s.pips = s.max_pips
		# Decide para onde a nave vai (como uma criança: às vezes certo, às vezes não).
		var want: Vector2 = s.ship.position + Vector2(randf_range(-120, 120), randf_range(-220, 220))
		if not s.gate.is_empty() and randf() < 0.65:
			for p in s.gate:
				if str(p.get_meta("label")) == s.gate_answer:
					want = Vector2(s.ship.position.x, p.position.y)
		elif not s.pickups.is_empty() and randf() < 0.6:
			want = s.pickups[0].position
		elif randf() < 0.5:
			for b in s.ebullets:
				if is_instance_valid(b) and b.position.distance_to(s.ship.position) < 220.0:
					want = s.ship.position + Vector2(0, -200 if b.position.y > s.ship.position.y else 200)
		# Arrasta o dedo de um ponto qualquer (dedo não precisa estar em cima da nave).
		var anchor: Vector2 = s.ship.position + Vector2(randf_range(120, 260), randf_range(-60, 60))
		var from: Vector2 = s.target
		_mouse(ct * anchor, true)
		var goal := anchor + (want - from) / 1.25
		for k in 8:
			var m := InputEventMouseMotion.new()
			m.position = get_viewport().get_screen_transform() * (ct * anchor.lerp(goal, (k + 1) / 8.0))
			m.global_position = m.position
			m.button_mask = MOUSE_BUTTON_MASK_LEFT
			Input.parse_input_event(m)
			await get_tree().create_timer(0.03).timeout
		await get_tree().create_timer(randf_range(0.2, 0.9)).timeout
		_mouse(ct * goal, false)
		await get_tree().create_timer(randf_range(0.1, 0.5)).timeout
	await get_tree().create_timer(4.0).timeout
	log_lines.append("FIM: tela=%s %s" % [Router.current_id, _state()])
	# Toca no botão grande de seguir (onde a criança tocaria: no meio-baixo do painel).
	var r := _vis()
	await _tap(r.get_center() + Vector2(110, 140))
	await get_tree().create_timer(3.0).timeout
	log_lines.append("DEPOIS DO TOQUE: tela=%s" % Router.current_id)


# ------------------------------------------------------------------ voo livre
func _play_arcade() -> void:
	Router.reset_to("seg_arcade", {})
	await get_tree().create_timer(2.0).timeout
	var s: Node = Router.current_screen
	while _t < limit and is_instance_valid(s) and Router.current_screen == s:
		await get_tree().create_timer(randf_range(0.3, 1.2)).timeout
		var r := _vis()
		await _tap(Vector2(r.size.x * randf_range(0.2, 0.9), r.size.y * randf_range(0.15, 0.95)), randf_range(0.05, 0.5))
	await get_tree().create_timer(3.0).timeout
	log_lines.append("FIM: tela=%s %s" % [Router.current_id, _state()])


# ------------------------------------------------------------------ lição amassada (toques em qualquer lugar)
func _mash_lesson(id: String) -> void:
	Router.reset_to("seg_lesson", {"lesson": id, "n": 2})
	await get_tree().create_timer(2.0).timeout
	while _t < limit:
		await get_tree().create_timer(randf_range(0.25, 1.0)).timeout
		var r := _vis()
		var p := Vector2(r.size.x * randf_range(0.05, 0.95), r.size.y * randf_range(0.1, 0.95))
		if randf() < 0.3:
			# arrasta um pouco (dedo escorregando)
			_mouse(p, true)
			for k in 8:
				var m := InputEventMouseMotion.new()
				p += Vector2(randf_range(-40, 40), randf_range(-40, 40))
				m.position = get_viewport().get_screen_transform() * p
				m.global_position = m.position
				m.button_mask = MOUSE_BUTTON_MASK_LEFT
				Input.parse_input_event(m)
				await get_tree().process_frame
			_mouse(p, false)
		else:
			await _tap(p)
	log_lines.append("FIM: tela=%s %s" % [Router.current_id, _state()])
