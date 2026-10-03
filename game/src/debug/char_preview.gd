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
			rigs[i].anim.play(n)
			rigs[i].anim.seek(length * i / 4.0, true)
			rigs[i].anim.pause()
		await get_tree().process_frame
		await _shot("anim_" + n)
	var moods := ["happy", "big_smile", "surprised", "sad", "thinking"]
	for i in rigs.size():
		rigs[i].anim.play("idle")
		rigs[i].set_mood(moods[i])
		rigs[i].scale = Vector2(1.6, 1.6)
		rigs[i].position = Vector2(140 + i * 250, 1000)
	await get_tree().process_frame
	await _shot("faces")
