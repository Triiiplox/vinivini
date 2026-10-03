extends GameScreen
## Ateliê de criação: desenhar, inventar planeta, montar nave, montar cenário, criar bichinho e criar história.

const TOOLS := [
	["draw", {"t": "icon", "id": "palette", "c": "#FACC15"}, "draw", {}, "Desenhar!"],
	["planet", {"t": "planet", "id": "saturn"}, "maker", {"mode": "planet"}, "Inventar um planeta!"],
	["ship", {"t": "art", "set": "words", "id": "foguete"}, "maker", {"mode": "ship"}, "Montar a sua nave!"],
	["scene", {"t": "comet"}, "maker", {"mode": "scene"}, "Montar um cenário espacial!"],
	["creature", {"t": "icon", "id": "flask", "c": "#4ADE80"}, "seg_creature", {}, "Inventar um bichinho!"],
	["story", {"t": "icon", "id": "book", "c": "#60A5FA"}, "story_maker", {}, "Criar uma história!"],
]

var tiles: Array[Interactable] = []


func build() -> void:
	set_sky("space")
	AudioService.play_music("hub", 0.4)
	world.add_child(Scenery.new("ship"))
	for i in TOOLS.size():
		var t: Array = TOOLS[i]
		var it := Interactable.new()
		it.name = "Tool_%s" % t[0]
		it.radius = 95.0
		it.payload = i
		it.position = Vector2(300 + (i % 3) * 300, 230 + (i / 3) * 250)
		var bg := DS.nine("card", "normal")
		DS.fit(bg, Vector2(190, 190))
		bg.position += Vector2(-95, -95)
		it.add_child(bg)
		it.add_child(Figure.new(t[1], 140.0))
		it.tapped.connect(_open)
		world.add_child(it)
		tiles.append(it)
	add_cosmo(Vector2(1150, 170), 100.0)
	hint_fn = func(): hand.show_tap(tiles[0].global_position)


func begin() -> void:
	narrate(Lines.n("O ateliê de criação! O que você quer inventar hoje?"))


func _open(it: Interactable) -> void:
	var t: Array = TOOLS[int(it.payload)]
	DS.press_feedback(it, "pop")
	finished = true
	var p: Dictionary = (t[3] as Dictionary).duplicate()
	p["back"] = "studio"
	var d := narrate(str(t[4]))
	after(minf(d, 1.2), Router.go.bind(str(t[2]), p))
