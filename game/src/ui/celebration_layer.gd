class_name CelebrationLayer
extends CanvasLayer
## Feedback visual por cima de tudo: toast de elogio, banner e confete calibrado.

static var _tex: Texture2D

var _toast: PanelContainer
var _toast_label: Label
var _toast_tween: Tween
var _banner: Label
var _root: Control


func _ready() -> void:
	layer = 20
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_toast = PanelContainer.new()
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.offset_top = 232
	_toast_label = Label.new()
	_toast_label.add_theme_font_size_override("font_size", 40)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_child(_toast_label)
	_toast.modulate.a = 0.0
	_root.add_child(_toast)
	_banner = Label.new()
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_override("font", UITheme.title_font())
	_banner.add_theme_font_size_override("font_size", 64)
	_banner.add_theme_color_override("font_color", Palette.YELLOW)
	_banner.add_theme_color_override("font_outline_color", Palette.BG_BOTTOM)
	_banner.add_theme_constant_override("outline_size", 18)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.modulate.a = 0.0
	_root.add_child(_banner)


## Mensagem curta no topo (elogio, "tente de novo"). Cor indica tom, nunca vermelho de erro.
func toast(text: String, color: Color = Palette.TEAL, seconds: float = 1.8) -> void:
	_toast_label.text = text
	_toast.add_theme_stylebox_override("panel", UITheme.rounded(color, 30, 4, Color(1, 1, 1, 0.6)))
	_toast_label.add_theme_color_override("font_color", Palette.TEXT_DARK if color.get_luminance() > 0.6 else Palette.WHITE)
	if _toast_tween:
		_toast_tween.kill()
	_toast.pivot_offset = _toast.size / 2
	_toast.scale = Vector2(0.7, 0.7)
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.12)
	_toast_tween.parallel().tween_property(_toast, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_toast_tween.tween_interval(seconds)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.3)


## Chamado a cada troca de tela: nada de mensagem "vazando" para a próxima.
func clear() -> void:
	hide_toast()
	_banner.modulate.a = 0.0


func hide_toast() -> void:
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 0.0


## tier: small | streak | big | epic
func celebrate(tier: String, banner_text: String = "") -> void:
	var amounts := {"small": 18, "streak": 40, "big": 90, "epic": 160}
	var amount: int = amounts.get(tier, 18)
	var vp := _root.get_viewport_rect().size
	match tier:
		"small":
			_burst(Vector2(vp.x / 2, vp.y * 0.45), amount, 0.7)
		"streak":
			_burst(Vector2(vp.x * 0.3, vp.y * 0.5), amount / 2, 0.9)
			_burst(Vector2(vp.x * 0.7, vp.y * 0.5), amount / 2, 0.9)
		_:
			_rain(amount, 2.2 if tier == "epic" else 1.6)
			if tier == "epic":
				for i in 3:
					get_tree().create_timer(0.35 * i).timeout.connect(_burst.bind(Vector2(vp.x * (0.25 + 0.25 * i), vp.y * 0.35), 30, 1.0))
	if tier == "big" or tier == "epic":
		AudioService.play_sfx("celebrate")
	if banner_text != "":
		show_banner(banner_text, Palette.GOLD if tier == "epic" else Palette.YELLOW)


func show_banner(text: String, color: Color = Palette.YELLOW, seconds: float = 1.8) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.pivot_offset = _banner.size / 2
	_banner.scale = Vector2(0.3, 0.3)
	var t := create_tween()
	t.tween_property(_banner, "modulate:a", 1.0, 0.1)
	t.parallel().tween_property(_banner, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	t.tween_interval(seconds)
	t.tween_property(_banner, "modulate:a", 0.0, 0.35)


func _make_particles(amount: int, life: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = maxi(1, amount)
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 0.9
	p.texture = _star_texture()
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	p.angular_velocity_min = -360
	p.angular_velocity_max = 360
	var g := Gradient.new()
	g.colors = PackedColorArray([Palette.YELLOW, Palette.PINK, Palette.TEAL, Palette.PURPLE, Palette.ORANGE])
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	p.color_initial_ramp = g
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	p.color_ramp = fade
	_root.add_child(p)
	get_tree().create_timer(life + 0.5).timeout.connect(p.queue_free)
	return p


func _burst(pos: Vector2, amount: int, life: float) -> void:
	var p := _make_particles(amount, life)
	p.position = pos
	p.direction = Vector2.UP
	p.spread = 180
	p.initial_velocity_min = 250
	p.initial_velocity_max = 520
	p.gravity = Vector2(0, 600)
	p.emitting = true


func _rain(amount: int, life: float) -> void:
	var vp := _root.get_viewport_rect().size
	var p := _make_particles(amount, life)
	p.explosiveness = 0.6
	p.position = Vector2(vp.x / 2, -20)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(vp.x / 2, 10)
	p.direction = Vector2.DOWN
	p.spread = 25
	p.initial_velocity_min = 200
	p.initial_velocity_max = 420
	p.gravity = Vector2(0, 300)
	p.emitting = true


static func _star_texture() -> Texture2D:
	if _tex:
		return _tex
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	var pts := IconDraw.star_points(Vector2(12, 12), 11.5, 5.0)
	for y in 24:
		for x in 24:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				img.set_pixel(x, y, Color.WHITE)
	_tex = ImageTexture.create_from_image(img)
	return _tex
