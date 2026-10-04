extends GameScreen
## Hora de descansar (limite diário definido pelos pais): o Vini dorme, o céu escurece. Sem castigo nem contagem.
## Só um adulto libera (segurar o cadeado → área dos pais → ajustar o limite).


func build() -> void:
	set_sky("space")
	AudioService.play_music("map", 0.3)
	world.add_child(Scenery.new("bedroom"))
	# Noite na nave: véu escuro cobrindo também as laterais das telas largas.
	var dim := Polygon2D.new()
	dim.polygon = PackedVector2Array([Vector2(-1000, -400), Vector2(2280, -400), Vector2(2280, 1200), Vector2(-1000, 1200)])
	dim.color = Color(0.02, 0.03, 0.1, 0.55)
	dim.z_index = 5
	world.add_child(dim)
	var vini := CharacterRig2D.new("vini", 330.0)
	vini.position = Vector2(640, 660)
	vini.z_index = 10
	world.add_child(vini)
	vini.set_mood("tired")
	var moon := ShaderPlanet.new("moon", 70.0)
	moon.position = Vector2(1040, 170)
	world.add_child(moon)
	hud.root.get_node("HomeButton").visible = false
	var lock := HoldButton.new("lock", 2.0)
	lock.position = Vector2(24, 24)
	lock.modulate.a = 0.55
	lock.held.connect(func(): Router.go("parent_gate"))
	hud.root.add_child(lock)


func begin() -> void:
	narrate(Lines.n("Hora de descansar, comandante! Amanhã tem mais aventura no espaço. Boa noite!"))


func _on_home() -> void:
	pass
