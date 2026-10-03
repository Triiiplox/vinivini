class_name Fx
extends RefCounted
## Efeitos de partículas (GPUParticles2D) e brilhos para o mundo de jogo.

static var _star: Texture2D
static var _dot: Texture2D


static func star_texture() -> Texture2D:
	if _star == null:
		_star = CelebrationLayer._star_texture()
	return _star


static func dot_texture() -> Texture2D:
	if _dot == null:
		var g := GradientTexture2D.new()
		g.fill = GradientTexture2D.FILL_RADIAL
		g.fill_from = Vector2(0.5, 0.5)
		g.fill_to = Vector2(1.0, 0.5)
		g.width = 32
		g.height = 32
		var gr := Gradient.new()
		gr.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
		g.gradient = gr
		_dot = g
	return _dot


static func _particles(parent: Node, pos: Vector2, amount: int, life: float, tex: Texture2D) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.amount = maxi(1, amount)
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 0.92
	p.texture = tex
	p.position = pos
	p.z_index = 500
	parent.add_child(p)
	var tw := p.create_tween()
	tw.tween_interval(life + 0.6)
	tw.tween_callback(p.queue_free)
	return p


## Estrelinhas coloridas saindo de um ponto (acerto, coleta).
static func sparkle(parent: Node, pos: Vector2, amount: int = 24, color: Color = Color.WHITE, speed: float = 320.0) -> void:
	if bool(SaveService.settings.get_value("reduced_effects")):
		amount = maxi(4, amount / 4)
	var p := _particles(parent, pos, amount, 0.9, star_texture())
	var m := ParticleProcessMaterial.new()
	m.direction = Vector3(0, -1, 0)
	m.spread = 180.0
	m.initial_velocity_min = speed * 0.5
	m.initial_velocity_max = speed
	m.gravity = Vector3(0, 380, 0)
	m.scale_min = 0.6
	m.scale_max = 1.5
	m.angular_velocity_min = -300
	m.angular_velocity_max = 300
	var g := Gradient.new()
	if color == Color.WHITE:
		g.colors = PackedColorArray([Palette.YELLOW, Palette.PINK, Palette.TEAL, Palette.PURPLE])
		g.offsets = PackedFloat32Array([0.0, 0.33, 0.66, 1.0])
	else:
		g.colors = PackedColorArray([color, color.lightened(0.5)])
	var gt := GradientTexture1D.new()
	gt.gradient = g
	m.color_initial_ramp = gt
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var ft := GradientTexture1D.new()
	ft.gradient = fade
	m.color_ramp = ft
	p.process_material = m
	p.emitting = true


## Poeira ao pisar/pousar.
static func dust(parent: Node, pos: Vector2, color: Color = Color(1, 1, 1, 0.7), amount: int = 14) -> void:
	var p := _particles(parent, pos, amount, 0.7, dot_texture())
	var m := ParticleProcessMaterial.new()
	m.direction = Vector3(0, -1, 0)
	m.spread = 70.0
	m.initial_velocity_min = 60
	m.initial_velocity_max = 160
	m.gravity = Vector3(0, 120, 0)
	m.scale_min = 0.4
	m.scale_max = 1.2
	m.color = color
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var ft := GradientTexture1D.new()
	ft.gradient = fade
	m.color_ramp = ft
	p.process_material = m
	p.emitting = true


## Rastro contínuo (propulsor). Retorna o nó para o chamador posicionar.
static func trail(parent: Node, color: Color = Color(1.0, 0.7, 0.3)) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.amount = 40
	p.lifetime = 0.5
	p.texture = dot_texture()
	parent.add_child(p)
	var m := ParticleProcessMaterial.new()
	m.direction = Vector3(-1, 0, 0)
	m.spread = 12.0
	m.initial_velocity_min = 180
	m.initial_velocity_max = 280
	m.scale_min = 0.6
	m.scale_max = 1.4
	m.color = color
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color.WHITE, Color(1, 0.5, 0.2, 0)])
	var ft := GradientTexture1D.new()
	ft.gradient = fade
	m.color_ramp = ft
	p.process_material = m
	return p


## Halo aditivo pulsante (portais, energia, item interativo).
static func glow(parent: Node, pos: Vector2, size: float, color: Color, pulse: float = 1.0) -> ColorRect:
	var r := ColorRect.new()
	r.size = Vector2(size, size)
	r.position = pos - r.size / 2
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load("res://assets/shaders/glow_sprite.gdshader")
	m.set_shader_parameter("glow_color", color)
	m.set_shader_parameter("pulse", pulse)
	r.material = m
	parent.add_child(r)
	return r
