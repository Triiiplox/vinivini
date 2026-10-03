extends Node2D
## Pré-visualização das poses do rig: --rigpreview=/arquivo.png

func _ready() -> void:
	var out := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--rigpreview="):
			out = a.substr(13)
	var sky := ColorRect.new()
	sky.size = Vector2(1280, 720)
	var m := ShaderMaterial.new()
	m.shader = load("res://assets/shaders/space_sky.gdshader")
	sky.material = m
	add_child(sky)
	var poses := [["idle", ""], ["walk", ""], ["run", ""], ["point", ""], ["think", ""], ["dance", ""], ["carry", ""], ["idle", "jump"],
		["idle", "celebrate"], ["idle", "wave"]]
	var avs := [
		{"skin": "skin_3", "hair_style": "short", "hair_color": "hair_brown", "suit": "suit_orange", "helmet": "helmet_none",
			"accessory": "acc_none"},
		{"skin": "skin_5", "hair_style": "curly", "hair_color": "hair_black", "suit": "suit_blue", "helmet": "helmet_classic",
			"accessory": "acc_jetpack"},
	]
	var rigs: Array = []
	for i in poses.size():
		var r := AvatarRig.new(avs[i % 2], 230.0)
		r.position = Vector2(80 + (i % 5) * 270, 330 + (i / 5) * 350)
		r.state = poses[i][0]
		add_child(r)
		rigs.append([r, poses[i][1]])
	var c := CosmoRig.new(150.0)
	c.position = Vector2(1180, 120)
	c.state = "talk"
	add_child(c)
	await get_tree().create_timer(0.5).timeout
	for pair in rigs:
		if pair[1] != "":
			pair[0].play(pair[1])
	await get_tree().create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("rig preview ok")
	get_tree().quit()
