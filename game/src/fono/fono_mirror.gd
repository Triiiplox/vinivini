class_name FonoMirror
extends Control
## Espelho da academia da boca e das pistas de "como fazer o som" (o Andro autorizou a câmera: "espelho ao vivo").
## Um espelho de verdade no desenho: oval com moldura dourada e pedrinhas, vidro com reflexo e brilhinhos. O botão
## ABRIR CÂMERA (pedido do Andro, 12/10: "dê opção nesse espelho abrir a câmera") liga a câmera da frente e a imagem
## ao vivo aparece espelhada dentro do oval; FECHAR desliga. Sem câmera no aparelho (TV), o botão não aparece.
## NADA é gravado nem salvo: a imagem só passa pela tela. Permissão CAMERA pedida só ao tocar no botão. Sem câmera
## ou sem permissão, fica o vidro enfeitado e o recado "Faça olhando no espelho!" — o exercício continua igual.
## Godot 4.5: CameraServer tem Android; o formato da câmera é escolhido com set_format(0) antes de ligar.

const GOLD_DARK := Color("#7A4A0C")
const GOLD := Color("#F2B83B")
const GOLD_LIGHT := Color("#FFE7A0")
const GLASS_OUT := Color("#1E3A8A")
const GLASS_IN := Color("#BFE3FF")
const GEMS := [Color("#F472B6"), Color("#22D3EE"), Color("#A78BFA")]
## Recorta a câmera no oval (borda suave).
const OVAL_SHADER := """shader_type canvas_item;
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float d = length(p);
	COLOR = texture(TEXTURE, UV);
	COLOR.a *= 1.0 - smoothstep(0.96, 1.0, d);
}"""

var feed: CameraFeed
var live := false
var _tex: TextureRect
var _msg: Label
var _overlay: Control
var _granted := false
var _t := 0.0
var _btn: DSButton  ## ABRIR CÂMERA
var _close: DSButton  ## FECHAR


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tex = TextureRect.new()
	_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_tex.flip_h = true
	_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = OVAL_SHADER
	_tex.material = mat
	add_child(_tex)
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_frame)
	add_child(_overlay)
	_msg = UI.label("", 18, Color.WHITE, true)
	_msg.add_theme_constant_override("outline_size", 6)
	_msg.add_theme_color_override("font_outline_color", Color("#1E3A8A"))
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	_msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(_msg)  # recado do espelho (para o adulto)
	add_child(_msg)
	_btn = DSButton.new("primary", "camera", Vector2(64, 64), "normal", "" if size.y < 240.0 else "ABRIR CÂMERA")
	_btn.name = "MirrorCamera"
	_btn.pressed.connect(_toggle)
	add_child(_btn)
	_close = DSButton.new("secondary", "close", Vector2(64, 64), "normal", "" if size.y < 240.0 else "FECHAR")
	_close.name = "MirrorClose"
	_close.pressed.connect(_toggle)
	add_child(_close)
	resized.connect(_layout)
	_layout()
	_set_live(false)
	# TV e aparelhos sem câmera: sem botão (OS.has_feature("tv") vem do preset de TV).
	_btn.visible = not OS.has_feature("tv")
	_close.visible = false


## Abre (pede a permissão na primeira vez) ou fecha a câmera.
func _toggle() -> void:
	if live:
		_stop()
		return
	_granted = not OS.has_feature("android") or OS.get_granted_permissions().has("android.permission.CAMERA")
	if _granted:
		_start()
		return
	if not get_tree().on_request_permissions_result.is_connected(_on_perm):
		get_tree().on_request_permissions_result.connect(_on_perm)
	OS.request_permission("android.permission.CAMERA")


func _on_perm(p: String, ok: bool) -> void:
	if p == "android.permission.CAMERA" and ok:
		_granted = true
		_start()


func _stop() -> void:
	if feed:
		feed.feed_is_active = false
	feed = null
	CameraServer.monitoring_feeds = false
	_tex.texture = null
	_set_live(false)


func _layout() -> void:
	var inset := Vector2(14, 14)
	_tex.position = inset
	_tex.size = size - inset * 2.0
	_overlay.size = size
	_msg.position = Vector2(size.x * 0.16, size.y * 0.5)
	_msg.size = Vector2(size.x * 0.68, size.y * 0.2)
	# botão embaixo do espelho (no pequeno, só o ícone)
	var small := size.y < 240.0
	for b in [_btn, _close]:
		b.custom_minimum_size = Vector2(64, 64) if small else Vector2(230, 64)
		b.size = b.custom_minimum_size
		# grande: embaixo, no centro; pequeno: na lateral direita (embaixo fica a dica para o adulto)
		b.position = Vector2(size.x - 40.0, size.y / 2.0 - 32.0) if small else Vector2((size.x - b.size.x) / 2.0, size.y - 22.0)
	if _msg.text != "":
		_set_live(live)


func _start() -> void:
	if not _granted:
		return
	CameraServer.monitoring_feeds = true
	await get_tree().process_frame
	if not is_inside_tree() or not CameraServer.monitoring_feeds:
		return
	var best: CameraFeed = null
	for f in CameraServer.feeds():
		if best == null or f.get_position() == CameraFeed.FEED_FRONT:
			best = f
	if best == null:
		_msg.text = "Sem câmera neste aparelho"
		return
	feed = best
	if feed.get_formats().size() > 0:
		feed.set_format(0, {})
	feed.feed_is_active = true
	var ct := CameraTexture.new()
	ct.camera_feed_id = feed.get_id()
	ct.which_feed = CameraServer.FEED_RGBA_IMAGE
	_tex.texture = ct
	_set_live(true)


func _set_live(on: bool) -> void:
	live = on
	_tex.visible = on
	# Espelho pequeno (sessão de fala): só o vidro; o recado cabe no grande (academia).
	_msg.text = "" if on or size.y < 240.0 else "Faça olhando no espelho!"
	if _btn:
		_btn.visible = not on and not OS.has_feature("tv")
		_close.visible = on
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	_overlay.queue_redraw()


static func _oval(c: Vector2, rx: float, ry: float, n: int = 72) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## Fundo: sombra e o vidro (degradê do azul-escuro da borda ao azul-claro do centro), reflexos e brilhinhos.
func _draw() -> void:
	var c := size / 2.0
	var rx := size.x / 2.0 - 12.0
	var ry := size.y / 2.0 - 12.0
	draw_colored_polygon(_oval(c + Vector2(0, 8), rx + 10, ry + 10), Color(0, 0, 0, 0.35))
	if live:
		draw_colored_polygon(_oval(c, rx, ry), Color("#0B1030"))
		return
	for k in 14:
		var f := k / 13.0
		draw_colored_polygon(_oval(c + Vector2(-rx * 0.12, -ry * 0.12) * f, rx * (1.0 - 0.62 * f), ry * (1.0 - 0.62 * f)),
			GLASS_OUT.lerp(GLASS_IN, f))
	for i in 5:
		var p := c + Vector2(cos(i * 2.4 + 0.7) * rx * 0.55, sin(i * 1.7 + 0.3) * ry * 0.55)
		var s := 5.0 + 4.0 * (0.5 + 0.5 * sin(_t * 2.2 + i * 1.3))
		_star(p, s, Color(1, 1, 1, 0.85))


func _star(p: Vector2, s: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s * 2), p + Vector2(s * 0.45, -s * 0.45), p + Vector2(s * 2, 0),
		p + Vector2(s * 0.45, s * 0.45), p + Vector2(0, s * 2), p + Vector2(-s * 0.45, s * 0.45), p + Vector2(-s * 2, 0),
		p + Vector2(-s * 0.45, -s * 0.45)]), col)


## Por cima (também sobre a câmera): reflexo do vidro, moldura dourada em 3 tons e as pedrinhas.
func _draw_frame() -> void:
	var c := size / 2.0
	var rx := size.x / 2.0 - 12.0
	var ry := size.y / 2.0 - 12.0
	_overlay.draw_set_transform(c + Vector2(-rx * 0.38, -ry * 0.3), -0.7, Vector2.ONE)
	_overlay.draw_colored_polygon(_oval(Vector2.ZERO, rx * 0.09, ry * 0.42, 32), Color(1, 1, 1, 0.22))
	_overlay.draw_set_transform(c + Vector2(-rx * 0.18, -ry * 0.42), -0.7, Vector2.ONE)
	_overlay.draw_colored_polygon(_oval(Vector2.ZERO, rx * 0.04, ry * 0.22, 32), Color(1, 1, 1, 0.18))
	_overlay.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var ring := _oval(c, rx + 2, ry + 2)
	ring.append(ring[0])
	_overlay.draw_polyline(ring, GOLD_DARK, 20.0, true)
	_overlay.draw_polyline(ring, GOLD, 13.0, true)
	var hi := _oval(c + Vector2(-1.5, -2.5), rx + 2, ry + 2)
	hi.append(hi[0])
	_overlay.draw_polyline(hi, GOLD_LIGHT, 3.0, true)
	for i in 3:
		var a := -PI / 2.0 + (i - 1) * 0.42
		var g := c + Vector2(cos(a) * (rx + 2), sin(a) * (ry + 2))
		_overlay.draw_circle(g, 9.0 if i == 1 else 6.5, GOLD_DARK)
		_overlay.draw_circle(g, 7.0 if i == 1 else 5.0, GEMS[i])
		_overlay.draw_circle(g + Vector2(-2, -2), 2.0, Color(1, 1, 1, 0.8))
	var b := c + Vector2(0, ry + 2)
	_overlay.draw_circle(b, 8.0, GOLD_DARK)
	_overlay.draw_circle(b, 6.0, GEMS[1])


func _exit_tree() -> void:
	if feed:
		feed.feed_is_active = false
	CameraServer.monitoring_feeds = false
