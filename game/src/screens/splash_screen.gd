extends BaseScreen
## Tela inicial: céu pintado, o Vini acenando, o Astro flutuando, título e um único botão JOGAR (design system).
## Toca a música-tema cantada.


var _started := false


func on_enter() -> void:
	if is_instance_valid(Router.sky):
		Router.sky.set_theme("space", 0.0)
	# Música-tema "Comandante das Estrelas" (cantada) só na tela inicial; nas telas com narração ficam as instrumentais.
	AudioService.play_music("theme", 0.8)
	var title := Label.new()
	title.text = "VINI"
	title.add_theme_font_override("font", DS.font("title", 900))
	title.add_theme_font_size_override("font_size", 120)
	title.add_theme_color_override("font_color", DS.STAR_GOLD)
	title.add_theme_color_override("font_outline_color", DS.SPACE_DARK)
	title.add_theme_constant_override("outline_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(340, 40)
	title.size = Vector2(600, 140)
	UI.child_ok(title)
	add_child(title)
	var sub := Label.new()
	sub.text = "COMANDANTE DAS ESTRELAS"
	sub.add_theme_font_override("font", DS.font("title", 700))
	sub.add_theme_font_size_override("font_size", 34)
	sub.add_theme_color_override("font_color", Color.WHITE)
	sub.add_theme_color_override("font_outline_color", DS.SPACE_DARK)
	sub.add_theme_constant_override("outline_size", 10)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(290, 170)
	sub.size = Vector2(700, 50)
	UI.child_ok(sub)
	add_child(sub)
	var stage := Node2D.new()
	add_child(stage)
	var vini := CharacterRig2D.new("vini", 400.0)
	vini.position = Vector2(330, 690)
	stage.add_child(vini)
	after(0.6, func(): vini.play("wave"))
	# Criança de 4 anos toca no personagem, não no botão: tocar no Vini também começa o jogo.
	var hit := Control.new()
	hit.name = "ViniTap"
	hit.position = Vector2(170, 280)
	hit.size = Vector2(320, 420)
	hit.gui_input.connect(_on_vini_input.bind(vini))
	add_child(hit)
	var astro := CosmoRig.new(170.0)
	astro.position = Vector2(1000, 360)
	stage.add_child(astro)
	var bob := astro.create_tween().set_loops()
	bob.tween_property(astro, "position:y", 340.0, 1.4).set_trans(Tween.TRANS_SINE)
	bob.tween_property(astro, "position:y", 360.0, 1.4).set_trans(Tween.TRANS_SINE)
	var play := DSButton.new("primary", "play", Vector2(260, 150))
	play.name = "PlayButton"
	play.position = Vector2(640 - 130, 430)
	play.pressed.connect(_on_play)
	add_child(play)
	var pulse := play.create_tween().set_loops()
	pulse.tween_property(play, "scale", Vector2.ONE * 1.06, 0.6).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(play, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)


func _on_vini_input(e: InputEvent, vini: CharacterRig2D) -> void:
	if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
		vini.play("jump")
		AudioService.play_sfx("boing")
		after(0.45, _on_play)


func _on_play() -> void:
	if _started:
		return
	_started = true
	AudioService.play_sfx("whoosh")
	if not bool(SaveService.settings.get_value("intro_video_seen")):
		Router.reset_to("intro_video", {"next": "opening"})
	elif not AppState.has_profile() or not bool(AppState.profile().get("intro_seen", false)):
		Router.reset_to("opening")
	elif str(SaveService.settings.get_value("hello_day")) != AppState.today():
		# Primeira vez no dia: "bom dia, comandante" (3 s) e segue para a nave.
		SaveService.settings.set_value("hello_day", AppState.today())
		Router.reset_to("intro_video", {"clip": "oi", "next": "home"})
	else:
		Router.reset_to("home")
