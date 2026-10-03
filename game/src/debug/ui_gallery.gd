extends Node
## Galeria do design system: --uigallery=/dir. Renderiza todos os componentes e estados (STEP 22B).

var out := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--uigallery="):
			out = a.substr(12)
	DirAccess.make_dir_recursive_absolute(out)
	if is_instance_valid(Router.sky):
		Router.sky.set_theme("space")
	var root := Control.new()
	root.size = Vector2(1280, 720)
	add_child(root)
	var x := 40.0
	for t in ["normal", "success", "warning", "rare", "focused"]:
		var b := DSButton.new("primary", "play", Vector2(210, 92), t, "JOGAR")
		b.position = Vector2(x, 40)
		root.add_child(b)
		x += 240
	var dis := DSButton.new("primary", "play", Vector2(210, 92), "normal", "JOGAR")
	dis.position = Vector2(40, 160)
	root.add_child(dis)
	dis.disabled = true
	var sec := DSButton.new("secondary", "map", Vector2(220, 84), "normal", "EXPLORAR")
	sec.position = Vector2(290, 164)
	root.add_child(sec)
	x = 560.0
	for t in ["normal", "gold", "purple", "disabled"]:
		var ib := DSButton.new("icon", ["home", "star", "rocket", "lock"][["normal", "gold", "purple", "disabled"].find(t)], Vector2(96, 96), t)
		ib.position = Vector2(x, 160)
		root.add_child(ib)
		x += 130
	var p := DSWidgets.panel(Vector2(420, 250))
	p.position = Vector2(40, 300)
	root.add_child(p)
	var pt := Label.new()
	pt.text = "PAINEL HOLOGRÁFICO"
	pt.add_theme_font_override("font", DS.font("title", 800))
	pt.add_theme_font_size_override("font_size", 26)
	pt.position = Vector2(30, 24)
	p.add_child(pt)
	var bar := DSWidgets.bar(Vector2(360, 30), "cyan")
	bar.position = Vector2(30, 90)
	p.add_child(bar)
	DSWidgets.set_bar_value(bar, 0.6, false)
	var bar2 := DSWidgets.bar(Vector2(360, 30), "gold")
	bar2.position = Vector2(30, 150)
	p.add_child(bar2)
	DSWidgets.set_bar_value(bar2, 0.75, false)
	var chip := DSWidgets.chip(load("res://assets/ui/button_icon/gold.png"), "1.250", "gold")
	chip.position = Vector2(520, 320)
	root.add_child(chip)
	var chip2 := DSWidgets.chip(load("res://assets/ui/button_icon/purple.png"), "3", "cyan")
	chip2.position = Vector2(720, 320)
	root.add_child(chip2)
	for i in 2:
		var card := Control.new()
		card.size = Vector2(200, 200)
		card.position = Vector2(520 + i * 240, 420)
		var n := DS.nine("card", ["normal", "selected"][i])
		card.add_child(n)
		DS.fit(n, card.size)
		root.add_child(card)
	var h := Label.new()
	h.text = "Vini — Comandante das Estrelas"
	h.add_theme_font_override("font", DS.font("title", 900))
	h.add_theme_font_size_override("font_size", 34)
	h.add_theme_color_override("font_color", DS.STAR_GOLD)
	h.position = Vector2(40, 600)
	root.add_child(h)
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join("ui_gallery.png"))
	print("shot ui_gallery")
	get_tree().quit(0)
