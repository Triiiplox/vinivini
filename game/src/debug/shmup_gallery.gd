extends Node
## Galeria da arte desenhada das fases de nave: --shmupgallery=/dir → inimigos.png, mestres.png (normal, bravo, feliz).


func _ready() -> void:
	var out := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shmupgallery="):
			out = a.substr(15)
	DirAccess.make_dir_recursive_absolute(out)
	var root := Node2D.new()
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color("#2a1650")
	bg.size = Vector2(4000, 3000)
	root.add_child(bg)
	var kinds := ["bolinha", "seta", "giro", "olho", "cometa", "casco", "mina", "bala", "P", "A", "S", "coracao", "estrela"]
	for i in kinds.size():
		var s := ShmupSprite.new(kinds[i], 110.0 if kinds[i] != "bala" else 34.0)
		s.position = Vector2(110 + (i % 7) * 175, 200 + (i / 7) * 280)
		root.add_child(s)
	await _shot(out.path_join("inimigos.png"))
	for c in root.get_children():
		if c != bg:
			c.queue_free()
	var bosses := ["cratera", "ferrugem", "tempestade", "aneis", "gelo", "polvo"]
	for i in bosses.size():
		var b := ShmupBoss.new()
		b.kind = bosses[i]
		b.position = Vector2(230 + (i % 3) * 420, 190 + (i / 3) * 360)
		b.scale = Vector2.ONE * 0.62
		b.angry = i in [1, 4]
		b.happy = i == 5
		root.add_child(b)
	await _shot(out.path_join("mestres.png"))
	get_tree().quit(0)


func _shot(path: String) -> void:
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
