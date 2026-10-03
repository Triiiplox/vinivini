extends Control
## Cena raiz: fundo, host de telas, camada de celebração e fade.
## Também trata o botão voltar do Android e salva ao pausar/fechar.

var host: Control


func _ready() -> void:
	get_tree().root.theme = UITheme.build()
	var bg := Starfield.new()
	UI.full(bg)
	add_child(bg)
	host = Control.new()
	host.name = "ScreenHost"
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
	fader.color = Color(Palette.BG_BOTTOM, 0.0)
	fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full(fader)
	fade_layer.add_child(fader)
	Router.register_host(host, fader)
	AudioService.play_music()
	GameLog.info("Boot", "pronto em %d ms" % Time.get_ticks_msec())
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--artpreview="):
			add_child(load("res://src/debug/art_preview.gd").new())
			return
		if a.begins_with("--shots="):
			add_child(load("res://src/debug/screenshot_runner.gd").new())
			return
	if OS.get_cmdline_user_args().has("--smoke"):
		var smoke: Node = load("res://src/debug/smoke_runner.gd").new()
		add_child(smoke)
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
