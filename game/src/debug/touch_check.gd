extends Node
## QA com tela (xvfb): toques REAIS (InputEventScreenTouch pelo Input), em tela larga como a dos celulares.
## Primeiro acesso (JOGAR → vídeo → tocar no Vini → missão), tela principal (Leitura → deslizar a trilha → lição)
## e mapa das fases (deslizar). --touchcheck=/dir
## Imprime TOUCH PASS/FAIL e sai com 1 se algum toque não funcionar.

var out := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--touchcheck="):
			out = a.substr(13)
	DirAccess.make_dir_recursive_absolute(out)
	SaveService.reset_profile()
	# Nivelamento já feito (estes testes olham a trilha; o nivelamento tem teste próprio).
	SaveService.progress.data(SaveService.profile_id)["placed"] = {"reading": true, "math": true, "logic": true,
		"astronomy": true, "science": true}
	SaveService.settings.set_value("intro_video_seen", false)
	Router.reset_to("splash")
	await _wait(1.5)
	print("viewport=", get_viewport().get_visible_rect().size, " window=", DisplayServer.window_get_size())
	await _tap_node(Router.current_screen.find_child("PlayButton", true, false), "JOGAR")
	await _wait(2.0)
	print("depois de JOGAR: ", Router.current_id)
	await _tap_at(Vector2(640, 360), "pular vídeo")
	await _wait(2.0)
	print("depois de tocar no vídeo: ", Router.current_id)
	var ok_vini := false
	for i in 8:
		await _wait(1.5)
		var its: Array = get_tree().get_nodes_in_group("interactable")
		var target: Node2D = null
		for it in its:
			if (it as Interactable).is_visible_in_tree() and (it as Interactable).enabled:
				target = it
		var lbl := Router.current_id
		if target:
			await _tap_node(target, "%s/%s" % [lbl, target.name])
		await _wait(0.8)
		print("passo %d: tela=%s" % [i, Router.current_id])
		await _shot("passo%d" % i)
		if Router.current_id != "opening":
			ok_vini = true
			break
	# Tela principal: tocar em Leitura abre a trilha; deslizar rola; tocar na lição que brilha abre a lição.
	await _wait(1.0)
	Router.reset_to("home")
	await _wait(1.5)
	print("home aberta: ", Router.current_id)
	await _wait(1.0)
	await _shot("home")
	await _tap_node(Router.current_screen.find_child("Tile_reading", true, false), "home/Leitura")
	await _until_not("home", 6.0)
	var ok_home := Router.current_id == "academy"
	print("home → ", Router.current_id)
	var ok_swipe := false
	var ok_lesson := false
	if ok_home:
		await _wait(1.0)
		await _shot("trilha")
		var scr := Router.current_screen as GameScreen
		var x0 := scr.camera.position.x
		await _swipe(Vector2(1200, 400), Vector2(300, 400))
		await _wait(0.8)
		var x1 := scr.camera.position.x
		print("trilha: câmera %.0f → %.0f" % [x0, x1])
		ok_swipe = absf(x1 - x0) > 100.0
		await _swipe(Vector2(300, 400), Vector2(1200, 400))
		await _wait(1.2)
		var next: Node = scr.call("next_tile")
		await _tap_node(next, "trilha/próxima lição")
		await _until_not("academy", 6.0)
		ok_lesson = Router.current_id == "seg_lesson"
		print("trilha → ", Router.current_id)
	# Mapa das fases: deslizar rola.
	await _wait(1.5)
	Router.reset_to("galaxy")
	await _wait(1.5)
	print("mapa aberto: ", Router.current_id)
	await _shot("mapa")
	var g := Router.current_screen as GameScreen
	var gx0 := g.camera.position.x
	await _swipe(Vector2(1200, 300), Vector2(300, 300))
	await _wait(0.8)
	var ok_map := absf(g.camera.position.x - gx0) > 100.0
	print("mapa: câmera %.0f → %.0f" % [gx0, g.camera.position.x])
	var ok := ok_vini and ok_home and ok_swipe and ok_lesson and ok_map
	print("TOUCH %s: vini=%s home=%s deslizar=%s licao=%s mapa=%s" % [
		"PASS" if ok else "FAIL", ok_vini, ok_home, ok_swipe, ok_lesson, ok_map])
	get_tree().quit(0 if ok else 1)


func _until_not(id: String, limit: float) -> void:
	var t := 0.0
	while Router.current_id == id and t < limit:
		await _wait(0.25)
		t += 0.25


## Arrasta o dedo de a até b (coordenadas do viewport), em passos, como um dedo real.
func _swipe(a: Vector2, b: Vector2) -> void:
	var st := get_viewport().get_screen_transform()
	var down := InputEventScreenTouch.new()
	down.position = st * a
	down.pressed = true
	Input.parse_input_event(down)
	await get_tree().process_frame
	var steps := 12
	for i in range(1, steps + 1):
		var d := InputEventScreenDrag.new()
		d.position = st * a.lerp(b, i / float(steps))
		d.relative = st.basis_xform((b - a) / steps)
		d.velocity = st.basis_xform((b - a) / steps) * 60.0
		Input.parse_input_event(d)
		await get_tree().process_frame
	var up := InputEventScreenTouch.new()
	up.position = st * b
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(n + ".png"))


func _tap_node(n: Node, label: String) -> void:
	if n == null:
		print("SEM ALVO para ", label)
		return
	var vp_pos: Vector2
	if n is Control:
		vp_pos = (n as Control).get_global_rect().get_center()
	else:
		vp_pos = (n as CanvasItem).get_global_transform_with_canvas().origin
	await _tap_at(vp_pos, label)


func _tap_at(vp_pos: Vector2, label: String) -> void:
	var win := get_viewport().get_screen_transform() * vp_pos
	print("toque em %s vp=%s janela=%s" % [label, vp_pos, win])
	for pressed in [true, false]:
		var t := InputEventScreenTouch.new()
		t.position = win
		t.pressed = pressed
		t.index = 0
		Input.parse_input_event(t)
		await get_tree().process_frame
		await get_tree().process_frame
		if pressed:
			var hc := get_viewport().gui_get_hovered_control()
			print("   controle sob o dedo: ", hc.get_path() if hc else "nenhum", " filtro=", hc.mouse_filter if hc else -1)
			if Router.current_screen is GameScreen:
				print("   mundo: dedo=", (Router.current_screen as GameScreen).world_pointer())
