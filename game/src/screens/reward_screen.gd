extends GameScreen
## Recompensa: baú cai, abre com brilho, estrelas voam para o contador, itens novos aparecem no
## astronauta. Um botão de play grande continua (mapa da galáxia ou nave). Sem texto para ler.

var stars := 3
var chest: ArtSprite
var opened := false
var unlocked: Array = []
var avatar: CharacterRig2D
var cont: DSButton


func build() -> void:
	set_sky("space")
	AudioService.play_music("victory", 0.3)
	if params.has("mission"):
		stars = int(params.get("stars", 3))
		unlocked = params.get("reward", {}).get("unlocked", [])
	else:
		stars = clampi(int(params.get("result", {}).get("stars", 3)), 1, 3)
		RewardService.add_bonus_stars(stars)
	avatar = CharacterRig2D.new("vini", 330.0)
	avatar.position = Vector2(300, 640)
	avatar.z_index = 5
	world.add_child(avatar)
	add_cosmo(Vector2(1040, 260), 150.0)
	chest = ArtSprite.new("ui", "chest", 260.0)
	chest.position = Vector2(680, -200)
	chest.z_index = 6
	world.add_child(chest)
	var it := Interactable.new()
	it.radius = 150.0
	it.position = Vector2(680, 470)
	it.tapped.connect(func(_i): _open())
	world.add_child(it)
	cont = DSButton.new("primary", "play", Vector2(220, 130))
	cont.position = Vector2(1010, 520)
	cont.visible = false
	cont.pressed.connect(_continue)
	hud.stage.add_child(cont)
	if params.has("mission"):
		var bar := add_journey_bar()
		if bool(params.get("first_time", false)):
			bar.animate_from(int(JourneyBar.compute()["done"]) - 1)
	hint_fn = _hint


func begin() -> void:
	var tw := chest.create_tween()
	tw.tween_property(chest, "position:y", 470.0, 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	after(0.45, func():
		AudioService.play_sfx("land")
		shake_camera(8.0))
	var line := RewardService.praise.pick("mission_complete")
	after(0.8, func(): cosmo_say(line))
	after(0.8 + Voice.duration(line, "cosmo") + 0.4, _open)


func _open() -> void:
	if opened:
		return
	opened = true
	hand.hide_hint()
	AudioService.play_sfx("unlock")
	if ArtSprite.painted_tex("ui", "chest_open"):
		chest.set_item("chest_open")
	chest.bounce(0.4)
	Fx.sparkle(world, chest.position + Vector2(0, -60), 60, Palette.YELLOW, 420.0)
	avatar.play("celebrate")
	for i in stars:
		after(0.35 + i * 0.45, _fly_star.bind(i))
	var t_after := 0.35 + stars * 0.45 + 0.6
	if not unlocked.is_empty():
		after(t_after, _show_items)
		t_after += 2.8
	after(t_after, func():
		cont.visible = true
		cont.scale = Vector2.ZERO
		cont.create_tween().tween_property(cont, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		AudioService.play_sfx("pop"))


func _fly_star(i: int) -> void:
	var s := ArtSprite.new("props", "star_token", 110.0)
	s.position = chest.position + Vector2(0, -60)
	s.z_index = 20
	world.add_child(s)
	var dest := Vector2(560 + i * 120, 200)
	var tw := s.create_tween()
	tw.tween_property(s, "position", dest, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(s, "rotation", TAU, 0.5)
	AudioService.play_sfx("collect", 1.0 + i * 0.12)
	AudioService.haptic(30)
	Voice.say(Lines.number(i + 1))
	Fx.sparkle(world, dest, 16, Palette.YELLOW)


func _show_items() -> void:
	AudioService.play_sfx("fanfare")
	var av := AppState.avatar().duplicate()
	for id in unlocked:
		var item := ContentService.repo.get_item(str(id))
		if not item.is_empty():
			av[str(item["slot"])] = item["id"]
	# Veste o item novo na hora (a criança vê, não lê).
	AppState.save_avatar(av)
	avatar.dress_up(av)
	avatar.play("jump")
	Fx.sparkle(world, avatar.position + Vector2(0, -150), 40, Palette.PINK)
	cosmo_say(Lines.c("Olha só! Você ganhou um presente novo!"))


func _continue() -> void:
	AudioService.play_sfx("whoosh")
	if params.has("mission"):
		Router.reset_to("galaxy", {"focus": str(params["mission"].get("id", ""))})
	elif str((params.get("result", {}) as Dictionary).get("back", "")) != "":
		Router.reset_to(str(params["result"]["back"]))
	else:
		Router.home()


func _hint() -> void:
	if not opened:
		hand.show_tap(Vector2(680, 470))
	elif cont.visible:
		hand.show_tap(cont.position + cont.size / 2.0)


func _on_home() -> void:
	Router.home()
