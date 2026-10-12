extends Node
## Capturas do módulo FALAR para revisão visual:
##   xvfb-run godot --path game --rendering-driver opengl3 --resolution 1280x720 -- --fonoshots=/caminho

var out_dir := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fonoshots="):
			out_dir = a.substr(12)
	DirAccess.make_dir_recursive_absolute(out_dir)
	Router.instant = true
	SaveService.configure(MemoryStorage.new())
	SaveService.reset_profile()
	RewardService.ensure_starter_items()
	await _run()
	get_tree().quit(0)


func shot(name: String, wait: float = 0.8) -> void:
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("FONOSHOT ", name)


func _run() -> void:
	Kids.guests_enabled = true
	Router.reset_to("who")
	await shot("00_quem_vai_jogar", 1.2)
	Kids.start()
	Router.reset_to("home")
	await shot("01_home", 1.2)
	FonoData.listened("ch")
	FonoData.record("ch", 1, 9, 10)
	Router.reset_to("fono", {})
	await shot("02_fono_inicio")
	Router.reset_to("fono_session", {"target": "ch", "lv": 0})
	await get_tree().create_timer(0.3).timeout
	var s: Node = Router.current_screen
	s.step = "rain"
	s.queue = FonoData.items("ch", 0).slice(0, 10)
	s.card.visible = false
	for i in 10:
		s._rain_next()
	await shot("03_chuva_de_palavras", 1.0)
	Router.reset_to("fono_session", {"target": "ch", "lv": 3})
	await get_tree().create_timer(0.3).timeout
	s = Router.current_screen
	s.det_queue = ["chave"]
	s._next_detective()
	s._buttons("detective")
	await shot("04_detetive")
	s.det_queue.clear()
	s.queue = ["chuva", "chapéu"]
	s._next_speak()
	s._buttons("mic")
	await shot("05_fala_comigo")
	s.step = "adult"
	s.meter.visible = true
	s._buttons("adult")
	await shot("06_adulto_confirma")
	s._end(9, 10, true)
	await shot("07_nivel_novo", 1.2)
	FonoData.set_gym_reps(10)
	Router.reset_to("fono_gym", {})
	await get_tree().create_timer(0.3).timeout
	var g: Node = Router.current_screen
	g._next()
	g.running = true
	for i in 4:
		g._process(1.6)
	await shot("08_academia")
	Router.reset_to("parent", {"tab": "speech"})
	await shot("09_area_dos_pais")
