extends Node2D
## Filme de abertura (~10 s) feito com a arte oficial do jogo: na Lua (céu preto, Terra no alto), o Vini entra
## andando, finca a bandeira, acena e comemora. Gravar: --write-movie out.avi --fixed-fps 30 -- --film

var cam: Camera2D
var flag: PaintedProp
var vini: CharacterRig2D
var fade: ColorRect


func _ready() -> void:
	# Céu da Lua de verdade: preto, estrelas e só a Terra (sem nebulosa nem Saturno).
	var sky := ColorRect.new()
	sky.color = Color("#04050c")
	sky.size = Vector2(1600, 1000)
	sky.position = Vector2(-160, -140)
	sky.z_index = -100
	add_child(sky)
	var stars := Node2D.new()
	stars.z_index = -99
	stars.draw.connect(_draw_stars.bind(stars))
	add_child(stars)
	var earth := ShaderPlanet.new("earth", 80.0)
	earth.position = Vector2(330, 235)
	earth.z_index = -98
	add_child(earth)
	add_child(Scenery.new("moon"))
	cam = Camera2D.new()
	cam.position = Vector2(640, 360)
	add_child(cam)
	cam.make_current()
	flag = PaintedProp.new("flag", 150.0, true)
	flag.position = Vector2(860, Scenery.GROUND_Y + 40)
	flag.z_index = 10
	flag.visible = false
	add_child(flag)
	vini = CharacterRig2D.new("vini", 330.0)
	vini.position = Vector2(-150, Scenery.GROUND_Y + 30)
	vini.z_index = 20
	vini.dress = false
	add_child(vini)
	# Na Lua não tem ar: capacete de vidro (o rosto continua visível).
	vini.dress_up({"suit": "suit_blue", "helmet": "helmet_classic", "accessory": "acc_none"})
	var cl := CanvasLayer.new()
	cl.layer = 40
	add_child(cl)
	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.size = Vector2(1280, 720)
	cl.add_child(fade)
	_run()


func _draw_stars(n: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 260:
		var p := Vector2(rng.randf_range(-160, 1440), rng.randf_range(-140, 470))
		n.draw_circle(p, rng.randf_range(0.6, 2.0), Color(1, 1, 1, rng.randf_range(0.35, 1.0)))


func _run() -> void:
	create_tween().tween_property(fade, "color:a", 0.0, 0.8)
	# Câmera desce do céu (Terra) até o chão enquanto o Vini entra andando.
	cam.position = Vector2(640, 250)
	create_tween().tween_property(cam, "position", Vector2(640, 360), 2.5).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.6).timeout
	await vini.walk_to(760, 260.0).finished
	# Finca a bandeira (como os astronautas da Apollo).
	vini.play("point")
	await get_tree().create_timer(0.4).timeout
	flag.visible = true
	flag.scale.y = 0.01
	var k := flag.scale.x
	create_tween().tween_property(flag, "scale:y", k, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioService.play_sfx("snap")
	Fx.sparkle(self, flag.position, 24, Color(0.85, 0.85, 0.9), 200.0)
	await get_tree().create_timer(0.9).timeout
	vini.walk_to(640, 200.0)
	await get_tree().create_timer(0.7).timeout
	vini.face(1)
	vini.set_mood("happy")
	vini.play("wave")
	var z := create_tween()
	z.tween_property(cam, "zoom", Vector2(1.3, 1.3), 3.2).set_trans(Tween.TRANS_SINE)
	z.parallel().tween_property(cam, "position", Vector2(640, 410), 3.2).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(1.7).timeout
	vini.play("celebrate")
	Fx.sparkle(self, vini.position + Vector2(0, -260), 40, DS.STAR_GOLD, 360.0)
	await get_tree().create_timer(1.7).timeout
	create_tween().tween_property(fade, "color:a", 1.0, 0.7)
	await get_tree().create_timer(0.8).timeout
	get_tree().quit(0)
