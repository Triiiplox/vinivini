extends GameScreen
## Biblioteca da nave: as histórias em capas (sem texto). Tocar abre a história; depois dela, uma pergunta de
## interpretação e o recontar. O último livro é "Criar história" (o Vini monta a própria história).

var books: Array[Interactable] = []


func build() -> void:
	swipe_scroll = true
	set_sky("space")
	AudioService.play_music("story", 0.5)
	world.add_child(Scenery.new("library"))
	var shelf := Polygon2D.new()
	var ids: Array = ContentService.repo.story_order.duplicate()
	ids.append("__create")
	var right := maxf(1110.0, 320 + (ids.size() - 1) * 300 + 150.0)
	shelf.polygon = PackedVector2Array([Vector2(170, 470), Vector2(right, 470), Vector2(right, 500), Vector2(170, 500)])
	shelf.color = Color("#8B5A2B")
	world.add_child(shelf)
	camera.limit_left = 0
	camera.limit_right = int(maxf(1280.0, right + 170.0))
	var endings: Dictionary = SaveService.progress.data(SaveService.profile_id).get("story_endings", {})
	for i in ids.size():
		var b := Interactable.new()
		b.name = "Book_%s" % ids[i]
		b.radius = 110.0
		b.payload = ids[i]
		b.position = Vector2(320 + i * 300, 360)
		b.z_index = 5
		var bg := DS.nine("card", "selected" if ids[i] == "__create" else "normal")
		DS.fit(bg, Vector2(200, 230))
		bg.position += Vector2(-100, -115)
		b.add_child(bg)
		var cover: Dictionary = {"t": "icon", "id": "palette", "c": "#FACC15"}
		if ids[i] != "__create":
			var st: Dictionary = ContentService.repo.stories[ids[i]]
			var first: Dictionary = st["nodes"][st["start"]]
			var chars: Array = first.get("scene", {}).get("chars", [])
			var cid := str(chars[0]["id"]) if not chars.is_empty() else "robot"
			cover = {"t": "crew"} if cid == "crew" else {"t": "npc", "kind": cid, "mood": str(chars[0].get("mood", "happy"))}
			for k in mini((endings.get(ids[i], []) as Array).size(), 3):
				var s := ArtSprite.new("words", "estrela", 34.0)
				s.position = Vector2((k - 1) * 38, 130)
				b.add_child(s)
		b.add_child(Figure.new(cover, 160.0))
		b.tapped.connect(_open)
		world.add_child(b)
		books.append(b)
	add_cosmo(Vector2(1130, 200), 110.0)
	hint_fn = func(): hand.show_tap(books[0].global_position)


func begin() -> void:
	narrate(Lines.n("A biblioteca da nave! Toque num livro para ouvir a história, ou no último para criar a sua."))


func _open(b: Interactable) -> void:
	DS.press_feedback(b, "page")
	finished = true
	var id := str(b.payload)
	if id == "__create":
		Router.go("story_maker", {"back": "books"})
		return
	Router.go("seg_story", {"story": id, "back": "books", "quiz": true})
