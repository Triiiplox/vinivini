extends BaseScreen
## Abertura em vídeo (apresentação, ~16 s): toca na primeira vez que a criança toca em JOGAR e pode ser revista
## pela área dos pais. Um toque (ou o voltar do Android) pula. params.next = rota seguinte (padrão "opening").
## Sem o arquivo de vídeo, ou rodando sem tela (testes), segue direto.

const PATH := "res://assets/video/abertura.ogv"

var player: VideoStreamPlayer
var _done := false


func on_enter() -> void:
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full(bg)
	add_child(bg)
	SaveService.settings.set_value("intro_video_seen", true)
	if DisplayServer.get_name() == "headless" or not ResourceLoader.exists(PATH):
		_finish.call_deferred()
		return
	AudioService.stop_music()
	player = VideoStreamPlayer.new()
	player.name = "IntroVideo"
	player.stream = load(PATH)
	player.expand = true
	player.bus = "Music"
	player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full(player)
	add_child(player)
	player.finished.connect(_finish)
	player.play()


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
