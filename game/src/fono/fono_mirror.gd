class_name FonoMirror
extends Control
## Espelho da academia da boca e das pistas de "como fazer o som" (o Andro autorizou a câmera: "espelho ao vivo").
## Mostra a câmera da frente ao vivo, espelhada, num círculo com moldura. NADA é gravado nem salvo: a imagem só
## passa pela tela. Permissão CAMERA pedida só aqui. Sem câmera (ou sem permissão), vira um espelho de enfeite
## com o recado "Use um espelho de verdade!" — o exercício continua igual.
## Godot 4.5: CameraServer tem Android; o formato da câmera é escolhido com set_format(0) antes de ligar.

var feed: CameraFeed
var _tex: TextureRect
var _msg: Label
var _granted := false


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tex = TextureRect.new()
	_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_tex.flip_h = true
	_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tex)
	_msg = UI.label("", 26, Color.WHITE, true)
	_msg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	_msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(_msg)  # recado do espelho (para o adulto)
	add_child(_msg)
	_granted = not OS.has_feature("android") or OS.get_granted_permissions().has("android.permission.CAMERA")
	if OS.has_feature("android") and not _granted:
		get_tree().on_request_permissions_result.connect(func(p: String, ok: bool):
			if p == "android.permission.CAMERA" and ok:
				_granted = true
				_start())
		OS.request_permission("android.permission.CAMERA")
	_start()


func _start() -> void:
	if not _granted:
		_msg.text = "Use um espelho de verdade!"
		return
	CameraServer.monitoring_feeds = true
	await get_tree().process_frame
	if not is_inside_tree() or not CameraServer.monitoring_feeds:
		_msg.text = "Use um espelho de verdade!"
		return
	var best: CameraFeed = null
	for f in CameraServer.feeds():
		if best == null or f.get_position() == CameraFeed.FEED_FRONT:
			best = f
	if best == null:
		_msg.text = "Use um espelho de verdade!"
		return
	feed = best
	if feed.get_formats().size() > 0:
		feed.set_format(0, {})
	feed.feed_is_active = true
	var ct := CameraTexture.new()
	ct.camera_feed_id = feed.get_id()
	ct.which_feed = CameraServer.FEED_RGBA_IMAGE
	_tex.texture = ct
	_msg.text = ""


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.12, 0.3, 1.0), true)


func _exit_tree() -> void:
	if feed:
		feed.feed_is_active = false
	CameraServer.monitoring_feeds = false
