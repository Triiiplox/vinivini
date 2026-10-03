extends GameScreen
## Diário espacial da criança (sem texto): o que ele já fez, em figuras. Missões (planetas com estrelas),
## adesivos (lições concluídas), palavras em inglês, criaturas, desenhos e peças da nave. O Astro conta os números.

var pages: Array[Node2D] = []
var page := 0


func build() -> void:
	set_sky("space")
	AudioService.play_music("hub", 0.4)
	world.add_child(Scenery.new("ship"))
	var album := DS.nine("panel_holo", "normal")
	DS.fit(album, Vector2(1000, 520))
	album.position += Vector2(140, 130)
	world.add_child(album)
	_page_missions()
	_page_stickers()
	_page_more()
	for i in pages.size():
		pages[i].visible = i == 0
	var nxt := DSButton.new("icon", "next", Vector2(100, 100))
	nxt.name = "NextPage"
	nxt.position = Vector2(1150, 610)
	nxt.pressed.connect(_next_page)
	hud.root.add_child(nxt)
	add_cosmo(Vector2(1180, 150), 100.0)
	hint_fn = func(): hand.show_tap(Vector2(1200, 660))


func _new_page() -> Node2D:
	var p := Node2D.new()
	world.add_child(p)
	pages.append(p)
	return p


func _page_missions() -> void:
	var p := _new_page()
	var done: Dictionary = SaveService.progress.data(SaveService.profile_id).get("missions_done", {})
	var i := 0
	for c in ContentService.repo.campaigns:
		for m in c["missions"]:
			var x := 230.0 + (i % 9) * 105.0
			var y := 220.0 + (i / 9) * 150.0
			var pl := ShaderPlanet.new(str(c["planet"]), 34.0)
			pl.position = Vector2(x, y)
			pl.modulate = Color.WHITE if done.has(m) else Color(0.3, 0.32, 0.45, 0.6)
			p.add_child(pl)
			for k in int(done.get(m, 0)):
				var s := ArtSprite.new("words", "estrela", 22.0)
				s.position = Vector2(x + (k - 1) * 24, y + 52)
				p.add_child(s)
			i += 1


func _page_stickers() -> void:
	var p := _new_page()
	var list := ShipProgress.stickers()
	for i in mini(list.size(), 24):
		var les: Dictionary = ContentService.repo.lessons[list[i]]
		var f := Figure.new(AcademyCover.cover(les), 92.0)
		f.position = Vector2(230 + (i % 8) * 115, 215 + (i / 8) * 125)
		f.rotation = randf_range(-0.12, 0.12)
		p.add_child(f)
	if list.is_empty():
		var ic := IconDraw.new("book", Color(1, 1, 1, 0.4))
		ic.size = Vector2(160, 160)
		ic.position = Vector2(560, 300)
		p.add_child(ic)


func _page_more() -> void:
	var p := _new_page()
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	var en := (Hello.state()["words"] as Dictionary).size()
	var row := [
		[{"t": "icon", "id": "voice", "c": "#60A5FA"}, en],
		[{"t": "icon", "id": "flask", "c": "#4ADE80"}, (pd.get("creatures", []) as Array).size()],
		[{"t": "icon", "id": "palette", "c": "#FACC15"}, (pd.get("drawings", []) as Array).size()],
	]
	for i in row.size():
		var f := Figure.new(row[i][0], 110.0)
		f.position = Vector2(330 + i * 300, 280)
		p.add_child(f)
		var n := Figure.new({"t": "text", "s": str(row[i][1])}, 110.0)
		n.position = Vector2(330 + i * 300, 410)
		p.add_child(n)
	var parts := ShipProgress.ship_parts()
	for i in parts.size():
		var a := ArtSprite.new("build", str(parts[i]), 80.0)
		a.position = Vector2(300 + i * 120, 560)
		p.add_child(a)


func begin() -> void:
	_say_page()


func _say_page() -> void:
	match page:
		0:
			var n := (SaveService.progress.data(SaveService.profile_id).get("missions_done", {}) as Dictionary).size()
			narrate_seq([Lines.n("Seu diário espacial! Você já completou"), Lines.number(mini(n, 20)), Lines.n("missões!")])
		1:
			var n2 := mini(ShipProgress.stickers().size(), 20)
			narrate_seq([Lines.n("Seus adesivos! Cada lição que você termina vira um adesivo."), Lines.number(n2), Lines.n("adesivos!")])
		2:
			narrate(Lines.n("Palavras em inglês, criaturas, desenhos e as peças que a sua nave ganhou!"))


func _next_page() -> void:
	page = (page + 1) % pages.size()
	for i in pages.size():
		pages[i].visible = i == page
	AudioService.play_sfx("page")
	_say_page()
