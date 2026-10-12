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
	# Academia com a foto do Vini (só existe no APK da família: assets/private/fono_fotos)
	FonoData.set_gym_list(["bico", "lingua_larga_segura"])
	Router.reset_to("fono_gym", {})
	await get_tree().create_timer(0.3).timeout
	g = Router.current_screen
	g._next()
	await shot("08b_academia_foto_repouso", 0.3)
	g.running = true
	g._beat_t = 0.75
	g._process(0.01)
	await shot("08c_academia_foto_pose", 0.1)
	Router.reset_to("parent", {"tab": "speech"})
	await shot("09_area_dos_pais")
	await _v2()


## Telas da v2 (P1–P12).
func _v2() -> void:
	FonoPlan.set_pairs_enabled(true)
	Router.reset_to("fono_target", {"target": "ch"})
	await shot("10_casa_do_som")
	FonoData._entry("ch")["lv"] = 4
	FonoData._entry("ch")["probes"] = [{"d": "2026-09-01", "ok": 4, "of": 10}]
	Router.reset_to("fono_session", {"target": "ch", "lv": 4})
	await get_tree().create_timer(0.3).timeout
	var s: Node = Router.current_screen
	s.queue = ["chuva", "peixe", "chulé"]
	s._next_speak()
	s.reps_done = 2
	s.dots.queue_redraw()
	s._buttons("mic")
	s.level_bar.visible = true
	s.mic.level = 0.35
	s.mic.peak = 0.5
	await shot("11_fala_3_vezes")
	s.level_bar.visible = false
	s.use_mic = false
	s._next_speak()
	s.reps_done = 1
	s.dots.queue_redraw()
	s._buttons("rep")
	s._mic_gone()
	await shot("12_sem_microfone_falou", 0.5)
	s.queue.clear()
	s._next_speak()
	await shot("13_pausa_entre_blocos")
	Router.reset_to("fono_session", {"target": "ch", "lv": 4})
	await get_tree().create_timer(0.3).timeout
	s = Router.current_screen
	s.probe_queue = ["chicote"]
	s._next_probe()
	await shot("14_sonda_palavra_nova")
	s._short_session_notice()
	await shot("15_aviso_sessao_curta")
	Router.reset_to("fono_bags", {"target": "ch", "vs": "s"})
	await get_tree().create_timer(0.3).timeout
	s = Router.current_screen
	s._next()
	await shot("16_sacolas_do_som")
	Router.reset_to("fono_rain", {"target": "ch"})
	await get_tree().create_timer(0.3).timeout
	s = Router.current_screen
	s._next_cloud()
	s.push(1.4)
	await shot("17_chuva_gota")
	s.idx = 1
	s.progress = 1.0
	s._show_part(2)
	s._rain_t = 0.3
	s.ok_btn.visible = true
	s.again_btn.visible = true
	await shot("18_chuva_silaba")
	Router.reset_to("fono_read", {"target": "j"})
	await get_tree().create_timer(0.3).timeout
	s = Router.current_screen
	s._next()
	s._mark(true)
	s._next()
	s._mark(false)
	s._next()
	await shot("19_trilha_de_leitura")
	Router.reset_to("fono_pairs", {"target": "ch"})
	await get_tree().create_timer(0.3).timeout
	s = Router.current_screen
	s._next()
	await shot("20_me_faz_pegar")
	FonoData._entry("ch")["lv"] = 6
	Router.reset_to("fono_session", {"target": "ch", "lv": 6})
	await get_tree().create_timer(0.3).timeout
	s = Router.current_screen
	s._conversa(false)
	await shot("21_conversa_com_figura")
	FonoData.set_gym_list(["bico_segura", "limpar_dentes_cima"])
	Router.reset_to("fono_gym", {})
	await get_tree().create_timer(0.3).timeout
	var g: Node = Router.current_screen
	g._next()
	g.running = true
	for i in 2:
		g._process(1.3)
	await shot("22_academia_segura")
	Router.reset_to("fono", {})
	await shot("23_fono_inicio_8_niveis")
	FonoLog.record_probe("ch", 3, 10, "2026-09-01")
	FonoLog.record_probe("ch", 5, 10, "2026-09-08")
	FonoLog.record_probe("ch", 7, 10, "2026-09-15")
	FonoLog.add_note("cansado")
	FonoLog.add_note("espontaneo")
	Router.reset_to("parent", {"tab": "speech"})
	await shot("24_pais_topo", 1.0)
	var sc := _scroll(Router.current_screen)
	for k in 6:
		if sc:
			sc.scroll_vertical = 500 * (k + 1)
		await shot("25_pais_rolar_%d" % (k + 1), 0.5)


func _scroll(n: Node) -> ScrollContainer:
	if n is ScrollContainer:
		return n
	for c in n.get_children():
		var r := _scroll(c)
		if r:
			return r
	return null
