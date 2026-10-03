extends Node
## Preview do personagem com rig: --charpreview=/dir[:char]. Renderiza cada animação em 5 momentos + rostos.

var out := ""
var char_id := "vini"


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--charpreview="):
			var v := a.substr(14).split(":")
			out = v[0]
			if v.size() > 1:
				char_id = v[1]
	DirAccess.make_dir_recursive_absolute(out)
	if is_instance_valid(Router.sky):
		Router.sky.set_theme("ship")
	await _run()
	get_tree().quit(0)


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(n + ".png"))
	print("shot ", n)


func _run() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#2a3150")
	bg.size = Vector2(1280, 720)
	add_child(bg)
	var rigs: Array[CharacterRig2D] = []
	for i in 5:
		var r := CharacterRig2D.new(char_id, 300.0)
		r.position = Vector2(140 + i * 250, 650)
		add_child(r)
		rigs.append(r)
	await get_tree().process_frame
	await get_tree().process_frame
	for n in RigAnimations.NAMES:
		var length: float = rigs[0].anim.get_animation(n).length
		for i in rigs.size():
			rigs[i]._set_pose(n)
			rigs[i].anim.play(n)
			rigs[i].anim.seek(length * i / 4.0, true)
			rigs[i].anim.pause()
		await get_tree().process_frame
		await _shot("anim_" + n)
	var sets := [["happy", "big_smile", "surprised", "sad", "thinking"], ["angry", "curious", "proud", "calm", "scared"]]
	for k in sets.size():
		for i in rigs.size():
			rigs[i]._set_pose("")
			rigs[i].anim.play("idle")
			rigs[i].set_mood(sets[k][i])
			rigs[i].scale = Vector2(1.6, 1.6)
			rigs[i].position = Vector2(140 + i * 250, 1000)
		await get_tree().process_frame
		await _shot("faces" if k == 0 else "faces_%d" % k)
	if char_id == "vini":
		await outfits(rigs)


## Roupas: 5 combinações de traje, capacete e acessório (char "vini").
func outfits(rigs: Array[CharacterRig2D]) -> void:
	var looks := [
		{"suit": "suit_blue", "helmet": "helmet_classic", "accessory": "acc_jetpack"},
		{"suit": "suit_orange", "helmet": "helmet_antenna", "accessory": "acc_cape"},
		{"suit": "suit_green", "helmet": "helmet_cat", "accessory": "acc_heart_badge"},
		{"suit": "suit_galaxy", "helmet": "helmet_crown", "accessory": "acc_robot_pet"},
		{"suit": "suit_gold", "helmet": "helmet_gold", "accessory": "acc_planet_pet"},
	]
	for i in rigs.size():
		rigs[i].scale = Vector2.ONE
		rigs[i].position = Vector2(140 + i * 250, 650)
		rigs[i].set_mood("happy")
		rigs[i].dress_up(looks[i])
	await get_tree().process_frame
	await _shot("outfits")
