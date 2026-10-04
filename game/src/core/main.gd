extends Control
## Cena raiz: fundo, host de telas, camada de celebração e fade.
## Também trata o botão voltar do Android e salva ao pausar/fechar.

var host: Control


func _ready() -> void:
	get_tree().root.theme = UITheme.build()
	var sky := SkyLayer.new()
	sky.name = "Sky"
	add_child(sky)
	Router.sky = sky
	# Raiz e host não podem "consumir" toques: as telas de jogo são transparentes ao toque e tratam o dedo em
	# _unhandled_input (mundo). Com STOP aqui, nenhum toque chegava ao mundo no celular.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	host = Control.new()
	host.name = "ScreenHost"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full(host)
	add_child(host)
	var fx := CelebrationLayer.new()
	fx.name = "Celebration"
	add_child(fx)
	Router.fx = fx
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 30
	add_child(fade_layer)
	var fader := ColorRect.new()
	fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var iris := ShaderMaterial.new()
	iris.shader = load("res://assets/shaders/iris.gdshader")
	fader.material = iris
	fader.resized.connect(func(): iris.set_shader_parameter("aspect", Vector2(fader.size.x / maxf(1.0, fader.size.y), 1.0)))
	UI.full(fader)
	fade_layer.add_child(fader)
	Router.register_host(host, fader)
	AudioService.play_music()
	GameLog.info("Boot", "pronto em %d ms" % Time.get_ticks_msec())
	if _start_debug_tool():
		return
	Router.reset_to("splash")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			Router.back()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_FOCUS_OUT:
			AppState.on_app_paused()
			AudioService.pause_all(true)
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			AppState.on_app_resumed()
			AudioService.pause_all(false)


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		Router.back()
		get_viewport().set_input_as_handled()


## Ferramentas de QA por linha de comando (-- --flag). Retorna true se alguma assumiu o controle.
func _start_debug_tool() -> bool:
	const TOOLS := {"--segpreview=": "seg_preview", "--rigpreview=": "rig_preview", "--spike=": "spike_fx",
		"--artpreview=": "art_preview", "--charpreview=": "char_preview", "--uigallery=": "ui_gallery", "--shots=": "screenshot_runner",
		"--smoke2": "smoke_v2", "--smoke": "smoke_runner", "--film": "intro_film", "--playcheck=": "play_check",
		"--touchcheck=": "touch_check", "--lessoncheck=": "lesson_check", "--uxcheck=": "ux_check"}
	var args := OS.get_cmdline_user_args()
	if args.has("--checkscripts"):
		_check_scripts()
		return true
	for a in args:
		for flag in TOOLS:
			if a == flag or (flag.ends_with("=") and a.begins_with(flag)):
				# Robôs de QA jogam como o Vini, sem a tela "quem vai jogar?" (as capturas ligam os convidados).
				Kids.guests_enabled = TOOLS[flag] == "seg_preview"
				add_child(load("res://src/debug/%s.gd" % TOOLS[flag]).new())
				return true
	return false


## Debug: carrega todos os .gd (com autoloads ativos) e sai com 1 se algum falhar no parse.
func _check_scripts() -> void:
	var bad := 0
	var dirs: Array[String] = ["res://src"]
	while not dirs.is_empty():
		var d: String = dirs.pop_back()
		for sub in DirAccess.get_directories_at(d):
			dirs.append(d.path_join(sub))
		for f in DirAccess.get_files_at(d):
			if f.ends_with(".gd"):
				var s: GDScript = load(d.path_join(f))
				if s == null or not s.can_instantiate():
					print("FAIL ", d.path_join(f))
					bad += 1
	print("checkscripts bad=", bad)
	get_tree().quit(1 if bad else 0)
