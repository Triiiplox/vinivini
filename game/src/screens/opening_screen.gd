extends GameScreen
## Abertura (primeiro minuto): nave chega, Cosmo se apresenta pelo nome do Vini, o Vini (arte oficial)
## entra, a criança toca nele para dar oi, e já parte para a primeira missão (ligar o motor da nave).
## A customização do astronauta volta quando existirem skins da arte nova (v3/arte/RIG_GODOT.md).

var vini: CharacterRig2D
var av: Dictionary
var ship: Node2D
var step := ""
var options: Array[Interactable] = []


func build() -> void:
	set_sky("space")
	AudioService.play_music("title", 0.5)
	av = AppState.avatar().duplicate(true)
	if not AppState.has_profile():
		AppState.save_avatar(av)
		AppState.set_child_name("Vini")
	ship = Node2D.new()
	ship.position = Vector2(-300, 300)
	var art := ArtSprite.new("props", "ship_side", 320.0)
	ship.add_child(art)
	var tr := Fx.trail(ship)
	tr.position = Vector2(-140, 6)
	tr.emitting = true
	world.add_child(ship)
	hud.root.get_node("HomeButton").visible = false


func begin() -> void:
	AudioService.play_sfx("whoosh")
	var tw := ship.create_tween()
	tw.tween_property(ship, "position", Vector2(640, 330), 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ship, "position:x", 1700.0, 1.2).set_delay(1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	after(2.6, func():
		add_cosmo(Vector2(-100, 200), 170.0)
		var t2 := cosmo.create_tween()
		t2.tween_property(cosmo, "position", Vector2(980, 250), 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		AudioService.play_sfx("beep"))
	after(3.8, func():
		var d := cosmo_say(Lines.c("Olá, {name}! Eu sou o Cosmo, o robô da sua nave."))
		after(d + 0.3, _show_avatar))


func _show_avatar() -> void:
	# Vini (arte oficial, rig Godot) entra andando, acena e espera um toque.
	vini = CharacterRig2D.new("vini", 380.0)
	vini.position = Vector2(-150, 660)
	vini.z_index = 5
	world.add_child(vini)
	var tw := vini.walk_to(520.0, 300.0)
	tw.tween_callback(func(): vini.play("wave"))
	step = "tap_vini"
	var d := cosmo_say(Lines.c("Esse é você, comandante! Toque no Vini para dar oi!"))
	var it := Interactable.new()
	it.name = "ViniTap"
	it.radius = 170.0
	it.position = Vector2(520, 470)
	it.tapped.connect(func(_i): _tap_vini())
	world.add_child(it)
	options.append(it)
	hint_fn = _hint
	after(d + 4.0, _hint)


func _tap_vini() -> void:
	if step != "tap_vini":
		return
	step = "done"
	_finish_avatar()


func _hint() -> void:
	if step == "tap_vini":
		hand.show_tap(Vector2(520, 470))


func _finish_avatar() -> void:
	for o in options:
		o.queue_free()
	options.clear()
	vini.play("celebrate")
	Fx.sparkle(world, vini.position + Vector2(0, -200), 50, Palette.YELLOW)
	AudioService.play_sfx("fanfare")
	var p := AppState.profile()
	p["intro_seen"] = true
	SaveService.profiles.save_profile(p)
	var d := cosmo_say(Lines.c("Que astronauta incrível! Agora, a primeira missão!"))
	after(d + 0.4, func(): MissionFlow.start("m01"))


func _on_home() -> void:
	pass
