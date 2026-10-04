extends Node
## QA com tela (xvfb): joga as lições "mão na massa" com toques e arrastos REAIS, em tela larga, e salva quadros.
## Traçar (arrasta pelos traços), contar (toca em cada um), juntar/tirar (arrasta para a cesta/fora), montar palavra.
## --lessoncheck=/dir · imprime LESSON PASS/FAIL e sai com 1 se alguma não fechar.

var out := ""
var results := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lessoncheck="):
			out = a.substr(14)
	DirAccess.make_dir_recursive_absolute(out)
	SaveService.configure(JsonFileStorage.new("user://lessoncheck_save"))
	SaveService.reset_profile()
	RewardService.ensure_starter_items()
	for id in ["tracar_vogais", "contar_tocando", "juntar", "tirar_objetos", "montar_palavras"]:
		results[id] = await _play(id)
	var ok := not results.values().has(false)
	print("LESSON %s: %s" % ["PASS" if ok else "FAIL", results])
	get_tree().quit(0 if ok else 1)


func _play(id: String) -> bool:
	Router.reset_to("seg_lesson", {"lesson": id, "n": 2})
	await _wait(1.0)
	var s: Node = Router.current_screen
	var t := 0.0
	# Pula as explicações (botão play), como a criança faria.
	while str(s.rd.get("k", "")) in ["", "teach"] and t < 40.0:
		if s.next_btn.visible:
			await _tap(s.next_btn.get_global_rect().get_center())
		await _wait(0.5)
		t += 0.5
	var k := str(s.rd.get("k", ""))
	await _wait(2.5)
	await _shot("%s_inicio" % id)
	var step := int(s.step_i)
	match k:
		"trace":
			for st in s._strokes(str(s.rd["letter"])):
				var pts: Array = []
				for u in st:
					pts.append(_vp(s, s._tp(u)))
				await _drag_path(pts)
				await _wait(0.2)
		"count":
			for c in s.cards.duplicate():
				if is_instance_valid(c) and c.name.begins_with("Cnt_"):
					await _tap(_vp(s, c.global_position))
					await _wait(0.35)
		"join", "take":
			var want := "out" if k == "join" else "in"
			var dest: Node2D = s.basket if k == "join" else s.outside
			for i in int(s.rd.get("b", 1)):
				for c in s.cards:
					if is_instance_valid(c) and c.draggable and str(c.payload) == want:
						await _drag_path([_vp(s, c.global_position), _vp(s, dest.global_position)])
						await _wait(0.4)
						break
		"build":
			var parts: Array = s.rd.get("parts", [])
			for i in parts.size():
				for c in s.cards:
					if is_instance_valid(c) and c.draggable and str(c.payload) == str(parts[i]):
						await _drag_path([_vp(s, c.global_position), _vp(s, s.zones[i].global_position)])
						await _wait(0.5)
						break
	await _wait(0.6)
	await _shot("%s_feito" % id)
	var ok: bool = s.busy or int(s.step_i) > step
	print("%s (%s): %s" % [id, k, "ok" if ok else "NÃO FECHOU"])
	return ok


func _vp(s: Node, world_pos: Vector2) -> Vector2:
	return (s as GameScreen).world.get_canvas_transform() * world_pos


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(n + ".png"))


func _tap(vp: Vector2) -> void:
	var st := get_viewport().get_screen_transform()
	for pressed in [true, false]:
		var t := InputEventScreenTouch.new()
		t.position = st * vp
		t.pressed = pressed
		Input.parse_input_event(t)
		await get_tree().process_frame
		await get_tree().process_frame


## Arrasta o dedo passando por todos os pontos (coordenadas do viewport), em passos curtos.
func _drag_path(pts: Array) -> void:
	var st := get_viewport().get_screen_transform()
	var down := InputEventScreenTouch.new()
	down.position = st * (pts[0] as Vector2)
	down.pressed = true
	Input.parse_input_event(down)
	await get_tree().process_frame
	for i in range(1, pts.size()):
		var a: Vector2 = pts[i - 1]
		var b: Vector2 = pts[i]
		var n := maxi(2, int(a.distance_to(b) / 12.0))
		for j in range(1, n + 1):
			var d := InputEventScreenDrag.new()
			d.position = st * a.lerp(b, j / float(n))
			d.relative = st.basis_xform((b - a) / n)
			Input.parse_input_event(d)
			await get_tree().process_frame
	var up := InputEventScreenTouch.new()
	up.position = st * (pts[pts.size() - 1] as Vector2)
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame
