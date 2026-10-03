extends BaseScreen
## Vídeos curtos em momentos-chave (assets/video/<clip>.ogv). params.clip:
##   "abertura" (padrão, ~16 s): primeira vez que a criança toca em JOGAR; revisível na área dos pais.
##   "oi" (3 s): primeira abertura do dia ("bom dia, comandante").
##   "celebra" (4 s): campanha concluída pela primeira vez, antes do baú.
## Um toque (ou o voltar do Android) pula. params.next / next_params = rota seguinte (padrão "opening").
## Sem o arquivo, ou rodando sem tela (testes), segue direto.

var player: VideoStreamPlayer
var _done := false


func on_enter() -> void:
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full(bg)
	add_child(bg)
	var clip := str(params.get("clip", "abertura"))
	var path := "res://assets/video/%s.ogv" % clip
	if clip == "abertura":
		SaveService.settings.set_value("intro_video_seen", true)
	if DisplayServer.get_name() == "headless" or not ResourceLoader.exists(path):
		_finish.call_deferred()
		return
	AudioService.stop_music()
	player = VideoStreamPlayer.new()
	player.name = "IntroVideo"
	player.stream = load(path)
	player.expand = true
	player.bus = "Music"
	player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full(player)
	add_child(player)
	player.finished.connect(_finish)
	player.play()
	# Proteção: se o aparelho não tocar o vídeo (decodificação falhou), não deixa a tela preta parada.
	var limit := maxf(4.0, player.get_stream_length() + 2.0)
	get_tree().create_timer(1.5).timeout.connect(_watchdog)
	get_tree().create_timer(limit).timeout.connect(_finish)


func _watchdog() -> void:
	if not _done and is_instance_valid(player) and (not player.is_playing() or player.stream_position <= 0.0):
		GameLog.info("Video", "vídeo não começou; seguindo")
		_finish()


func _gui_input(e: InputEvent) -> void:
	if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
		accept_event()
		_finish()


func on_back() -> bool:
	_finish()
	return true


func _finish() -> void:
	if _done:
		return
	_done = true
	if player:
		player.stop()
	Router.reset_to(str(params.get("next", "opening")), params.get("next_params", {}))
