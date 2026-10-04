extends Node
## QA com tela (xvfb): toques REAIS (InputEventScreenTouch pelo Input), em tela larga como a dos celulares.
## Primeiro acesso (JOGAR → vídeo → tocar no Vini → missão) e nave (tocar na cabine → mapa). --touchcheck=/dir
## Imprime TOUCH PASS/FAIL e sai com 1 se algum toque não funcionar.

var out := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--touchcheck="):
			out = a.substr(13)
	DirAccess.make_dir_recursive_absolute(out)
	SaveService.reset_profile()
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
	# Nave: tocar na cabine leva ao mapa da galáxia.
	Router.reset_to("ship", {"quiet": true})
	await _wait(1.5)
	var st: Interactable = Router.current_screen.stations.get("academy")
	print("   escola no mundo: ", st.global_position, " raio=", st.radius * absf(st.global_scale.x))
	await _tap_node(st, "nave/escola")
	var t := 0.0
	while Router.current_id == "ship" and t < 15.0:
		await _wait(0.5)
		t += 0.5
	var ok_ship := Router.current_id == "academy"
	print("nave → ", Router.current_id)
	var ok := ok_vini and ok_ship
	print("TOUCH %s: vini=%s nave=%s" % ["PASS" if ok else "FAIL", ok_vini, ok_ship])
	get_tree().quit(0 if ok else 1)


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
