extends Node
## QA com tela (xvfb): primeiro acesso → toca JOGAR → registra as telas por 22 s e salva quadros. --playcheck=/dir

var out := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--playcheck="):
			out = a.substr(12)
	DirAccess.make_dir_recursive_absolute(out)
	SaveService.settings.set_value("intro_video_seen", false)
	Router.reset_to("splash")
	await get_tree().create_timer(1.5).timeout
	var play: Node = Router.current_screen.find_child("PlayButton", true, false)
	print("play button: ", play)
	play.emit_signal("pressed")
	var t := 0.0
	while t < 22.0:
		await get_tree().create_timer(0.5).timeout
		t += 0.5
		var v: Node = Router.current_screen.find_child("IntroVideo", true, false) if is_instance_valid(Router.current_screen) else null
		var vs := ""
		if v:
			vs = " video playing=%s pos=%.1f" % [v.is_playing(), v.stream_position]
		print("t=%.1f tela=%s%s" % [t, Router.current_id, vs])
		if int(t * 2) % 6 == 0:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(out.path_join("t%04.1f.png" % t))
	get_tree().quit(0)
