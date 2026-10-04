extends Node
## Auditoria de usabilidade (--uxcheck=pasta): faz o caminho de uma criança rápida (tela principal → matéria →
## fase → responde certo assim que as opções aparecem → recompensa → volta) e mede tempo, toques e esperas,
## salvando uma captura em cada momento. Uso: xvfb-run ... godot --path . -- --uxcheck=/tmp/ux

var out := "/tmp/ux"
var t0 := 0.0
var taps := 0
var log_lines: Array = []


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--uxcheck="):
			out = a.substr(10)
	DirAccess.make_dir_recursive_absolute(out)
	SaveService.configure(JsonFileStorage.new("user://ux_save"))
	SaveService.reset_profile()
	SaveService.progress.data(SaveService.profile_id)["placed"] = {"math": true}
	SaveService.settings.set_value("intro_video_seen", true)
	var p := AppState.profile()
	p["intro_seen"] = true
	p["created"] = true
	SaveService.profiles.save_profile(p)
	await get_tree().create_timer(1.0).timeout
	_run.call_deferred()


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0 - t0


func note(s: String) -> void:
	var line := "%6.1fs  toques=%2d  %s" % [_now(), taps, s]
	log_lines.append(line)
	print("UX ", line)


func shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(n + ".png"))


func wait_until(f: Callable, limit: float) -> bool:
	var t := 0.0
	while t < limit:
		if f.call():
			return true
		await get_tree().create_timer(0.1).timeout
		t += 0.1
	return false


func _run() -> void:
	Router.reset_to("home", {})
	t0 = Time.get_ticks_msec() / 1000.0
	await get_tree().create_timer(0.3).timeout
	note("tela principal aberta")
	await shot("01_home")
	await get_tree().create_timer(2.0).timeout
	var tile: Interactable = Router.current_screen.find_child("Tile_math", true, false)
	taps += 1
	tile.tapped.emit(tile)
	note("toque em Matemática")
	await wait_until(func(): return Router.current_id == "academy", 5.0)
	note("trilha aberta")
	await get_tree().create_timer(1.0).timeout
	await shot("02_trilha")
	for phase in 3:
		if Router.current_id == "academy":
			var scr: Node = Router.current_screen
			var nt: Interactable = scr.call("next_tile")
			taps += 1
			nt.tapped.emit(nt)
			note("toque na fase %d" % (phase + 1))
		await wait_until(func(): return Router.current_id == "seg_lesson", 5.0)
		var les: Node = Router.current_screen
		var first_q := true
		var guard := 0
		while Router.current_id == "seg_lesson" and guard < 1500 and not les.finished:
			guard += 1
			var k := str(les.rd.get("k", ""))
			if k == "teach" and les.next_btn.visible:
				taps += 1
				les._advance()
				note("  explicação: toque em continuar")
				continue
			if k == "pick" and not les.busy:
				var ok := int(les.rd.get("ok", 0))
				var target: Interactable = null
				for c in les.cards:
					if is_instance_valid(c) and c.name == "Opt_%d" % ok:
						target = c
				if target and target.scale.x > 0.95:
					if first_q:
						note("  primeira pergunta na tela")
						await shot("03_fase%d_pergunta" % (phase + 1))
						first_q = false
					taps += 1
					les._on_pick(target)
					note("  respondeu certo")
					await wait_until(func(): return les.busy == false or Router.current_id != "seg_lesson", 8.0)
					note("  pronta a próxima")
					continue
			if k != "pick" and k != "teach" and k != "" and not les.busy:
				# cesta, contar, traçar, montar: o robô de testes faz o gesto (conta como 1 toque por passo)
				taps += 1
				Autoplay.step("seg_lesson", les)
				await get_tree().create_timer(0.4).timeout
				continue
			await get_tree().create_timer(0.1).timeout
		await wait_until(func(): return Router.current_id != "seg_lesson" or les.find_child("NextStage", true, false) != null, 10.0)
		note("fim da fase → %s" % Router.current_id)
		await shot("04_fase%d_fim" % (phase + 1))
		var nb := les.find_child("NextStage", true, false) as DSButton
		if nb and phase < 2:
			taps += 1
			nb.pressed.emit()
			note("toque em Próxima fase")
			await wait_until(func(): return Router.current_screen != les, 5.0)
			continue
		if Router.current_id == "reward":
			await get_tree().create_timer(0.5).timeout
			await wait_until(func(): return Router.current_screen.has_method("_continue"), 3.0)
			await get_tree().create_timer(2.0).timeout
			taps += 1
			Router.current_screen._continue()
			note("toque em continuar na recompensa")
		await wait_until(func(): return Router.current_id == "academy", 8.0)
		note("de volta à trilha")
		await get_tree().create_timer(0.8).timeout
	var f := FileAccess.open(out.path_join("ux_log.txt"), FileAccess.WRITE)
	f.store_string("\n".join(log_lines))
	print("UX FIM")
	get_tree().quit(0)
