extends Node
## Auditoria de sobreposição (--overlapcheck=pasta): abre as telas do roteador e procura
##   (a) dois alvos tocáveis que se cruzam (botão cortando o outro);
##   (b) texto coberto por um alvo ou por outro texto, cortado (reticências/clip) ou saindo da tela;
##   (c) alvo fora da área visível (ou fora da área segura do celular).
## Também: botão/selo da HUD cobrindo parte de outro botão ou cartão do jogo (erro) e botão da HUD por cima de
## um desenho solto (Cosmo, personagem; aviso). Ignora filhos do mesmo botão e o painel/cartão que contém o
## botão. Salva captura de cada tela em pasta/<tela>.png (problemas marcados: vermelho = erro, laranja = aviso)
## e o relatório em pasta/overlap.txt. Sai com 1 se houver ERRO (alvos se cruzando, um cortando o outro, fora
## da tela). Desenho feito em código (_draw) não tem retângulo: revise as capturas também.
##   xvfb-run -a -s "-screen 0 2340x1080x24" godot --path . --rendering-driver opengl3 --resolution 2340x1080 \
##     -- --overlapcheck=/dir        (TV: --resolution 1920x1080 -- --tv --overlapcheck=/dir)
## Filtro opcional: --overlapcheck=/dir:home só abre as telas cujo nome contém "home".

## Cruzamento mínimo (px do viewport) nas duas direções: bordas encostando não contam.
const MIN_HIT := 6.0
## Alvo maior que isto (fração da tela) é "toque em qualquer lugar" (fundo), não botão.
const HUGE := 0.45
## Jogos de ação: objetos do mundo se mexem e se cruzam de propósito; só a HUD é auditada.
const ACTION := ["seg_fases", "seg_arcade", "seg_flight", "seg_explore", "seg_creature", "seg_planetarium"]
## Pintura/painel maior que isto (fração da tela) é fundo/cenário, não "desenho por cima do texto".
const COVER_MAX := 0.2

var out := ""
var only := ""
var hard := 0
var soft := 0
var lines: Array[String] = []
var _items: Array[Dictionary] = []
var _issues: Array[Dictionary] = []
var _screen: Node = null
var _order := 0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--overlapcheck="):
			var v := a.substr(15).split(":")
			out = v[0]
			only = v[1] if v.size() > 1 else ""
	DirAccess.make_dir_recursive_absolute(out)
	# Convidados ligados: o botão "quem está jogando / trocar" e a tela "quem vai jogar?" aparecem.
	Kids.guests_enabled = true
	Router.instant = true
	SaveService.configure(MemoryStorage.new())
	SaveService.reset_profile()
	SaveService.progress.data(SaveService.profile_id)["placed"] = {"reading": true, "math": true, "logic": true,
		"astronomy": true, "science": true}
	SaveService.progress.data(SaveService.profile_id)["arcade"] = {"best": 42, "far": 2}
	SaveService.settings.set_value("intro_video_seen", true)
	SaveService.settings.set_value("knows_basics", true)
	RewardService.ensure_starter_items()
	_seed_numbers()
	await get_tree().create_timer(0.5).timeout
	await _run()
	var head := "OVERLAP %s %s: %d problema(s) graves (alvos se cruzando/fora da tela), %d aviso(s) (texto/desenho)" % [
		"PASS" if hard == 0 else "FAIL", _res_tag(), hard, soft]
	lines.push_front(head)
	var f := FileAccess.open(out.path_join("overlap.txt"), FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	print(head)
	get_tree().quit(0 if hard == 0 else 1)


## Contadores com 3-4 dígitos (estrelas de quem já jogou muito): o número tem que caber sem encostar em nada.
func _seed_numbers() -> void:
	SaveService.inventory.add_stars(SaveService.profile_id, 1250)
	var done: Dictionary = SaveService.progress.data(SaveService.profile_id)["missions_done"]
	var n := 0
	for c in ContentService.repo.campaigns:
		for mid in c["missions"]:
			n += 1
			if n <= 40:
				done[str(mid)] = 3


func _res_tag() -> String:
	var vs := get_viewport().get_visible_rect().size
	var ws := DisplayServer.window_get_size()
	return "%dx%d (viewport %dx%d%s)" % [ws.x, ws.y, int(vs.x), int(vs.y), ", TV" if Pad.enabled else ""]


# ------------------------------------------------------------------ telas
func _cases() -> Array:
	var c: Array = [
		["home", "home", {}],
		["home_enzo", "home", {}, func(): Kids.select("enzo"), 1.6, func(): Kids.select("vini")],
		["who", "who", {}],
		["fono", "fono", {}],
		["fono_sessao_chuva", "fono_session", {"target": "ch", "lv": 0}],
		["fono_sessao_detetive", "fono_session", {"target": "ch", "lv": 3}, null, 0.4, _fono_detective],
		["fono_sessao_fala", "fono_session", {"target": "ch", "lv": 3}, null, 0.4, _fono_speak],
		["fono_sessao_adulto", "fono_session", {"target": "ch", "lv": 3}, null, 0.4, _fono_adult],
		["fono_academia", "fono_gym", {}],
	]
	for t in ["summary", "skills", "levels", "history", "diary", "speech", "english", "challenge", "settings"]:
		c.append(["pais_" + t, "parent", {"tab": t}])
	c.append_array([
		["parent_gate", "parent_gate", {}],
		["fly_menu", "fly_menu", {}],
		["galaxy", "galaxy", {}],
		["map", "map", {}],
		["ship", "ship", {"quiet": true}],
		["journey", "journey", {}],
		["academy_reading", "academy", {"area": "reading"}],
		["academy_math", "academy", {"area": "math"}],
		["academy_emotion", "academy", {"area": "emotion"}],
		["licao_somar", "seg_lesson", {"lesson": "somar", "stage": 3, "back": "academy"}, null, 3.0],
		["licao_tracar", "seg_lesson", {"lesson": "tracar_letras", "n": 2}, null, 3.0],
		["licao_juntar", "seg_lesson", {"lesson": "juntar", "n": 2}, null, 3.0],
		["licao_frases", "seg_lesson", {"lesson": "frases_posicao", "stage": 2, "back": "academy"}, null, 3.0],
		["licao_planetas", "seg_lesson", {"lesson": "planetas", "stage": 2, "back": "academy"}, null, 3.0],
		["licao_textos", "seg_lesson", {"lesson": "textos_curtos", "n": 2}, null, 7.0],
		["licao_infinita", "seg_lesson", {"lesson": "somar", "endless": "math", "back": "academy"}, null, 3.0],
		["atividade_silabas", "activity", _act("reading.simple_syllables")],
		["atividade_contar", "activity", _act("math.counting")],
		["atividade_padrao", "activity", _act("logic.patterns")],
		["atividade_emocao", "activity", _act("emotion.recognition")],
		["mission_complete", "mission_complete", {"result": {"stars": 3}, "reward": {"stars": 3}}],
		["reward", "reward", {"mission": ContentService.repo.missions["m03"], "stars": 3, "reward": {}}],
		["wardrobe", "wardrobe", {}],
		["gallery", "gallery", {}],
		["draw", "draw", {}],
		["studio", "studio", {}],
		["hello", "hello", {}],
		["books", "books", {}],
		["diary", "diary", {}],
		["story_maker", "story_maker", {}],
		["maker", "maker", {"mode": "planet"}],
		["rest", "rest", {}],
		["hub", "hub", {}],
		["planet_mars", "planet", {"id": "mars"}],
		["library", "library", {}],
		["story", "story", {"id": "story_robot_lost_001"}],
		["lab", "lab", {}],
		["observatory", "observatory", {}],
		["trophies", "trophies", {}],
		["creator_new", "creator", {"mode": "new"}],
		["creator_edit", "creator", {"mode": "edit"}],
		["splash", "splash", {}],
		["opening", "opening", {}],
		["seg_fases", "seg_fases", {"fase": 3}, null, 2.5],
		["seg_arcade", "seg_arcade", {}, null, 2.5],
		["seg_flight", "seg_flight", {"theme": "space", "play": "portals", "goal": 4, "portal_skill": "numbers"}, null, 2.5],
		["seg_explore", "seg_explore", {}, null, 2.0],
		["seg_build", "seg_build", {"blueprint": "rocket"}, null, 2.0],
		["seg_build_rover", "seg_build", {"blueprint": "rover", "count": 4}, null, 2.0],
		["seg_cook", "seg_cook", {"customers": 2}, null, 2.6],
		["seg_monster", "seg_monster", {"rounds": 3}, null, 2.0],
		["seg_word", "seg_word", {"rounds": 2}, null, 2.0],
		["seg_robot", "seg_robot", {"rounds": 2}, null, 2.0],
		["seg_memory", "seg_memory", {"rounds": 2}, null, 2.0],
		["seg_pattern", "seg_pattern", {"rounds": 2}, null, 2.0],
		["seg_story", "seg_story", {"story": "story_robot_lost_001"}, null, 2.0],
		["seg_planetarium", "seg_planetarium", {}, null, 2.0],
		["seg_creature", "seg_creature", {}, null, 2.0],
		["seg_english", "seg_english", {"unit": "colors"}, null, 2.0],
		["seg_cutscene", "seg_cutscene", ContentService.repo.missions["m07"]["segments"][0], null, 1.5],
	])
	return c


func _act(skill: String) -> Dictionary:
	return {"mode": "single", "skills": [skill], "rounds": 4, "forced_difficulty": 2, "title": "Teste"}


func _fono_detective() -> void:
	var s: Node = Router.current_screen
	s.det_queue = ["chave"]
	s._next_detective()
	s._buttons("detective")


func _fono_speak() -> void:
	var s: Node = Router.current_screen
	s.det_queue.clear()
	s.queue = ["chuva", "chapéu"]
	s._next_speak()
	s._buttons("mic")


func _fono_adult() -> void:
	_fono_speak()
	var s: Node = Router.current_screen
	s.step = "adult"
	s.meter.visible = true
	s._buttons("adult")


func _run() -> void:
	lines.append("Resolução: " + _res_tag())
	for cs in _cases():
		var nm := str(cs[0])
		if only != "" and not nm.contains(only):
			continue
		var pre: Variant = cs[3] if cs.size() > 3 else null
		if pre is Callable:
			(pre as Callable).call()
		Router.reset_to(str(cs[1]), cs[2])
		var wait: float = cs[4] if cs.size() > 4 else 1.6
		await get_tree().create_timer(wait).timeout
		var post: Variant = cs[5] if cs.size() > 5 else null
		if post is Callable and Router.current_id == str(cs[1]):
			(post as Callable).call()
			await get_tree().create_timer(0.8).timeout
		await _audit(nm, str(cs[1]))
		if nm == "home_enzo":
			Kids.select("vini")


# ------------------------------------------------------------------ auditoria de uma tela
func _audit(nm: String, id: String) -> void:
	_screen = Router.current_screen
	_items.clear()
	_issues.clear()
	_order = 0
	var vp := get_viewport().get_visible_rect()
	var world_off := ACTION.has(id) or _scrolls(_screen)
	_walk(_screen, {"clip": vp, "owner": null, "hud_only": ACTION.has(id), "z": 0, "layer": 0,
		"box": Rect2()})
	var targets := _items.filter(func(it: Dictionary): return it["k"] == "alvo")
	var texts := _items.filter(func(it: Dictionary): return it["k"] == "texto")
	var covers := _items.filter(func(it: Dictionary): return it["k"] == "desenho")
	for i in targets.size():
		for j in range(i + 1, targets.size()):
			_pair_targets(targets[i], targets[j])
		for d in covers:
			_pair_target_cover(targets[i], d)
	for d in covers:
		for e in covers:
			_pair_hud_cover(d, e)
	for t in texts:
		for a in targets:
			_pair_text_target(t, a)
		for d in covers:
			_pair_text_cover(t, d)
	for i in texts.size():
		for j in range(i + 1, texts.size()):
			_pair_texts(texts[i], texts[j])
	_check_bounds(vp, targets, texts, world_off)
	var head := "[%s] %s  (%d alvos, %d textos)%s" % [nm, "OK" if _issues.is_empty() else "%d problema(s)" % _issues.size(),
		targets.size(), texts.size(), "" if Router.current_id == id else " (abriu %s)" % Router.current_id]
	lines.append(head)
	print("OVERLAP ", head)
	for it in _issues:
		var l := "   %s %s" % ["ERRO " if it["hard"] else "aviso", it["msg"]]
		lines.append(l)
		print("OVERLAP ", l)
	await _shot(nm)


## (c) alvo fora da tela/área segura e texto saindo da tela.
func _check_bounds(vp: Rect2, targets: Array, texts: Array, world_off: bool) -> void:
	var safe := vp
	var inset := GameHud.safe_x(get_viewport())
	safe.position.x += inset.x
	safe.size.x -= inset.x + inset.y
	for a in targets:
		if a["clipped"] or (world_off and a["world"]):
			continue
		var r: Rect2 = a["full"]
		if r.intersects(vp) and not safe.grow(2.0).encloses(r):
			_issue(true, "fora da tela: %s %s (tela %s)" % [a["n"], _rs(r), _rs(safe)], [r])
	for t in texts:
		if t["clipped"] or (world_off and t["world"]):
			continue
		var r: Rect2 = t["full"]
		if r.intersects(vp) and not vp.grow(2.0).encloses(r):
			_issue(false, "texto saindo da tela: \"%s\" %s" % [t["txt"], _rs(r)], [r])


## Mundo que rola (deslizar ou câmera com limites maiores que a tela): o que está fora da tela é de propósito.
func _scrolls(s: Node) -> bool:
	if not s is GameScreen:
		return false
	var g := s as GameScreen
	if g.swipe_scroll:
		return true
	var span := g.camera.limit_right - g.camera.limit_left
	return span < 1000000 and span > get_viewport().get_visible_rect().size.x + 8.0


func _issue(is_hard: bool, msg: String, rects: Array) -> void:
	for it in _issues:
		if it["msg"] == msg:
			return
	_issues.append({"hard": is_hard, "msg": msg, "rects": rects})
	if is_hard:
		hard += 1
	else:
		soft += 1


func _hit(a: Rect2, b: Rect2) -> bool:
	var x := a.intersection(b)
	return x.size.x > MIN_HIT and x.size.y > MIN_HIT


func _pair_targets(a: Dictionary, b: Dictionary) -> void:
	if _related(a["node"], b["node"]) or _plain_hold(a["node"]) or _plain_hold(b["node"]):
		return
	if a["drag"] and b["drag"]:
		return  # peças de arrastar empilhadas (montar, cozinha): é o jogo
	if _hit(a["r"], b["r"]):
		_issue(true, "alvos se cruzam: %s %s × %s %s" % [a["n"], _rs(a["r"]), b["n"], _rs(b["r"])], [a["r"], b["r"]])


func _pair_text_target(t: Dictionary, a: Dictionary) -> void:
	if t["owner"] == a["node"] or _related(t["node"], a["node"]) or _plain_hold(a["node"]):
		return
	if t["owner"] != null and a["drag"] and t["owner_drag"]:
		return
	if _hit(t["r"], a["r"]):
		_issue(false, "texto \"%s\" (%s) coberto por %s %s" % [t["txt"], t["n"], a["n"], _rs(a["r"])], [t["r"], a["r"]])


## Botão por cima de um pedaço (pintura, painel, selo) de OUTRO botão: um corta o outro.
func _pair_target_cover(a: Dictionary, d: Dictionary) -> void:
	var o: Node = d["owner"]
	if o == null:
		# Botão da HUD por cima de um desenho solto do mundo (Cosmo, personagem): aviso.
		if not a["world"] and d["world"] and _hit(a["r"], d["r"]):
			_issue(false, "%s %s por cima do desenho %s %s" % [a["n"], _rs(a["r"]), d["n"], _rs(d["r"])], [a["r"], d["r"]])
		return
	if o == a["node"] or _related(a["node"], o) or _plain_hold(a["node"]):
		return
	if a["drag"] or (o is Interactable and (o as Interactable).draggable):
		return
	if _hit(a["r"], d["r"]):
		_issue(true, "%s %s cobre parte de %s (%s)" % [a["n"], _rs(a["r"]), _short(o), d["n"]], [a["r"], d["r"]])


## Selo/placar da HUD (sem toque) por cima de um cartão/botão do jogo (ex.: o placar 0/5 cortando o cartão da frase).
func _pair_hud_cover(d: Dictionary, e: Dictionary) -> void:
	if d["world"] or d["owner"] != null or not e["world"] or e["owner"] == null:
		return
	if (e["owner"] is Interactable) and (e["owner"] as Interactable).draggable:
		return
	if _hit(d["r"], e["r"]):
		_issue(true, "%s %s (HUD) cobre parte de %s (%s)" % [d["n"], _rs(d["r"]), _short(e["owner"]), e["n"]], [d["r"], e["r"]])


## Desenho (pintura, painel) de OUTRO objeto pintado por cima do texto.
func _pair_text_cover(t: Dictionary, d: Dictionary) -> void:
	if t["owner"] != null and t["owner"] == d["owner"]:
		return
	if _related(t["node"], d["node"]) or (d["owner"] != null and _related(t["node"], d["owner"])):
		return
	if not _above(d, t) or not _hit(t["r"], d["r"]):
		return
	_issue(false, "texto \"%s\" (%s) coberto pelo desenho %s %s" % [t["txt"], t["n"], d["n"], _rs(d["r"])], [t["r"], d["r"]])


func _pair_texts(t: Dictionary, u: Dictionary) -> void:
	if _related(t["node"], u["node"]):
		return
	if t["owner"] != null and t["owner"] == u["owner"] and t["owner_drag"]:
		return
	if _hit(t["r"], u["r"]):
		_issue(false, "textos se cruzam: \"%s\" × \"%s\"" % [t["txt"], u["txt"]], [t["r"], u["r"]])


## a é pintado por cima de b? (camada, z efetivo, ordem na árvore)
func _above(a: Dictionary, b: Dictionary) -> bool:
	if a["layer"] != b["layer"]:
		return a["layer"] > b["layer"]
	if a["z"] != b["z"]:
		return a["z"] > b["z"]
	return a["o"] > b["o"]


func _related(a: Node, b: Node) -> bool:
	return a == b or a.is_ancestor_of(b) or b.is_ancestor_of(a)


func _plain_hold(n: Node) -> bool:
	return n is HoldButton and (n as HoldButton).plain


func _rs(r: Rect2) -> String:
	return "[%d,%d %dx%d]" % [int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y)]


# ------------------------------------------------------------------ coleta
## ctx: clip (área visível herdada de ScrollContainer/clip_contents), owner (alvo que contém este nó),
## hud_only, z (z efetivo) e layer (CanvasLayer).
func _walk(n: Node, ctx: Dictionary) -> void:
	if n is CanvasLayer:
		if not (n as CanvasLayer).visible:
			return
		ctx = ctx.duplicate()
		ctx["layer"] = (n as CanvasLayer).layer
		ctx["z"] = 0
	if n is CanvasItem:
		var ci := n as CanvasItem
		if not ci.is_visible_in_tree() or _alpha(ci) < 0.1:
			return
		ctx = ctx.duplicate()
		ctx["z"] = (int(ctx["z"]) if ci.z_as_relative else 0) + ci.z_index
	_order += 1
	var in_world := _in_world(n)
	if ctx["hud_only"] and in_world:
		return
	if n is Interactable:
		ctx = _collect_interactable(n as Interactable, ctx, in_world)
	elif n is Sprite2D:
		_collect_sprite(n as Sprite2D, ctx, in_world)
	elif n is Control:
		ctx = _collect_control(n as Control, ctx, in_world)
	for ch in n.get_children():
		_walk(ch, ctx)


func _collect_interactable(it: Interactable, ctx: Dictionary, in_world: bool) -> Dictionary:
	if ctx["owner"] != null:
		return ctx
	var r := _inter_rect(it)
	if r.get_area() <= 16.0:
		return ctx
	# Objeto sem toque (ex.: cartão da frase na lição) não é alvo, mas o desenho dele é "dele" (agrupa os filhos).
	if it.enabled and (it.tappable or it.draggable):
		_add("alvo", it, r, ctx, in_world, it.draggable)
	var out := ctx.duplicate()
	out["owner"] = it
	out["box"] = r if it.hit_rect.has_area() else Rect2()
	return out


func _collect_sprite(sp: Sprite2D, ctx: Dictionary, in_world: bool) -> void:
	if sp.texture == null:
		return
	# Pinturas têm borda transparente: conta só o miolo.
	var lr := sp.get_rect()
	var m := lr.size * 0.12
	var r := sp.get_global_transform_with_canvas() * lr.grow_individual(-m.x, -m.y, -m.x, -m.y)
	if r.get_area() < get_viewport().get_visible_rect().get_area() * COVER_MAX:
		_add("desenho", sp, r, ctx, in_world, false)


func _collect_control(c: Control, ctx: Dictionary, in_world: bool) -> Dictionary:
	var vp := get_viewport().get_visible_rect()
	var full := c.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, c.size)
	var out := ctx
	if ctx["owner"] == null and _is_target(c, full, vp):
		_add("alvo", c, full, ctx, in_world, false)
		out = ctx.duplicate()
		out["owner"] = c
	if _draws_box(c):
		out = out.duplicate()
		out["box"] = full
	if c is Label:
		_add_label(c as Label, out, in_world)
	elif (c is Panel or c is PanelContainer or c is NinePatchRect) and full.get_area() < vp.get_area() * COVER_MAX:
		if out["owner"] != c:
			_add("desenho", c, _visible_part(c, full), ctx, in_world, false)
	if c.clip_contents or c is ScrollContainer:
		out = out.duplicate()
		out["clip"] = (out["clip"] as Rect2).intersection(full)
	return out


## NinePatch do design system tem brilho pré-renderizado na borda (transparente): conta só o miolo.
func _visible_part(c: Control, full: Rect2) -> Rect2:
	if not c is NinePatchRect:
		return full
	var pad := float(c.get_meta("pad", 0)) * full.size.x / maxf(1.0, c.size.x)  # ver DS.nine / DS.fit
	return full.grow(-pad)


## Controle que desenha uma caixa visível (cartão, botão com fundo): o texto dentro dele não pode vazar da borda.
func _draws_box(c: Control) -> bool:
	if c is DSButton:
		return true
	var sb: StyleBox = null
	if c is Panel or c is PanelContainer:
		sb = c.get_theme_stylebox("panel")
	elif c is BaseButton and not (c is Button and (c as Button).flat):
		sb = c.get_theme_stylebox("normal")
	if sb == null or sb is StyleBoxEmpty:
		return false
	if sb is StyleBoxFlat:
		var f := sb as StyleBoxFlat
		return f.bg_color.a > 0.15 or (f.border_color.a > 0.15 and f.border_width_bottom > 0)
	return true


func _add(kind: String, n: Node, full: Rect2, ctx: Dictionary, in_world: bool, drag: bool) -> void:
	var vp := get_viewport().get_visible_rect()
	var clip: Rect2 = ctx["clip"]
	var r := full.intersection(clip)
	if r.get_area() < 16.0:
		return
	_items.append({"k": kind, "node": n, "n": _short(n), "r": r, "full": full, "clipped": clip != vp,
		"world": in_world, "drag": drag, "owner": ctx["owner"], "owner_drag": false, "txt": "",
		"o": _order, "z": ctx["z"], "layer": ctx["layer"]})


func _add_label(l: Label, ctx: Dictionary, in_world: bool) -> void:
	var txt := l.text.strip_edges()
	if txt == "" or l.visible_ratio == 0.0 or l.visible_characters == 0:
		return
	var tr := _text_local(l)
	var local: Rect2 = tr["r"]
	if l.clip_text:
		local = local.intersection(Rect2(Vector2.ZERO, l.size))
	var xf := l.get_global_transform_with_canvas()
	var full := xf * local
	var clip: Rect2 = ctx["clip"]
	if bool(tr["cut"]) and clip.encloses(xf * Rect2(Vector2.ZERO, l.size)):
		_issue(false, "texto cortado: \"%s\" (%s)" % [txt.left(40), _short(l)], [full])
	var box: Rect2 = ctx["box"]
	if box.has_area() and clip.encloses(box) and not box.grow(3.0).encloses(full):
		_issue(false, "texto vaza da caixa/botão: \"%s\" (%s) %s fora de %s" % [txt.left(40), _short(l), _rs(full), _rs(box)],
			[full, box])
	var before := _items.size()
	_add("texto", l, full, ctx, in_world, false)
	if _items.size() > before:
		var owner: Node = ctx["owner"]
		_items[-1]["txt"] = txt.left(40).replace("\n", " ")
		_items[-1]["owner_drag"] = owner is Interactable and (owner as Interactable).draggable


## Retângulo (local) que as letras ocupam de fato, conforme alinhamento; "cut" = o texto não cabe e é cortado.
## A altura da linha da fonte tem folga em cima e embaixo (acentos, descendentes): conta só o miolo.
func _text_local(l: Label) -> Dictionary:
	var font := l.get_theme_font("font")
	var fs := l.get_theme_font_size("font_size")
	var txt := l.text.to_upper() if l.uppercase else l.text
	var w := 0.0
	var cut := false
	for part in txt.split("\n"):
		w = maxf(w, font.get_string_size(part, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	if l.autowrap_mode != TextServer.AUTOWRAP_OFF:
		w = minf(w, l.size.x)
	elif w > l.size.x + 2.0 and (l.clip_text or l.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING):
		cut = true
		w = l.size.x
	var n_lines := maxi(1, l.get_line_count())
	if l.max_lines_visible > 0 and n_lines > l.max_lines_visible:
		cut = true
		n_lines = l.max_lines_visible
	var lh := font.get_height(fs)
	var h := n_lines * lh + (n_lines - 1) * l.get_theme_constant("line_spacing")
	var ax := {HORIZONTAL_ALIGNMENT_CENTER: 0.5, HORIZONTAL_ALIGNMENT_RIGHT: 1.0}.get(l.horizontal_alignment, 0.0) as float
	var ay := {VERTICAL_ALIGNMENT_CENTER: 0.5, VERTICAL_ALIGNMENT_BOTTOM: 1.0}.get(l.vertical_alignment, 0.0) as float
	var sb := l.get_theme_stylebox("normal")
	var off := Vector2(sb.get_margin(SIDE_LEFT), sb.get_margin(SIDE_TOP)) if sb else Vector2.ZERO
	var inner := l.size - (sb.get_minimum_size() if sb else Vector2.ZERO)
	var pos := off + Vector2((inner.x - w) * ax, (inner.y - h) * ay)
	return {"r": Rect2(pos, Vector2(w, h)).grow_individual(0, -lh * 0.16, 0, -lh * 0.14), "cut": cut}


func _is_target(c: Control, full: Rect2, vp: Rect2) -> bool:
	if c.mouse_filter == Control.MOUSE_FILTER_IGNORE or full.get_area() < 16.0:
		return false
	if full.get_area() > vp.get_area() * HUGE:
		return false
	if c is BaseButton or c is DSButton or c is HoldButton or c is ArtButton or c is Slider or c is LineEdit:
		return true
	if not c.gui_input.get_connections().is_empty():
		return true
	var s: Script = c.get_script()
	if s:
		for m in s.get_script_method_list():
			if str(m["name"]) == "_gui_input":
				return true
	return false


func _inter_rect(it: Interactable) -> Rect2:
	var xf := it.get_global_transform_with_canvas()
	if it.hit_rect.has_area():
		return xf * it.hit_rect
	# Círculo de toque: o quadrado inscrito (o círculo é generoso de propósito, maior que o desenho).
	var h := it.radius * 0.7
	return xf * Rect2(-h, -h, h * 2.0, h * 2.0)


func _alpha(ci: CanvasItem) -> float:
	var a := 1.0
	var n: Node = ci
	while n != null and n != _screen.get_parent():
		if n is CanvasItem:
			a *= (n as CanvasItem).modulate.a
		n = n.get_parent()
	return a * ci.self_modulate.a


func _in_world(n: Node) -> bool:
	var p := n
	while p != null and p != _screen:
		if p is CanvasLayer:
			return false
		if p.name == "World":
			return true
		p = p.get_parent()
	return false


func _short(n: Node) -> String:
	var path := str(_screen.get_path_to(n)) if _screen.is_ancestor_of(n) else str(n.name)
	var parts := path.split("/")
	var keep := parts.slice(maxi(0, parts.size() - 3))
	return "/".join(keep).replace("@", "")


# ------------------------------------------------------------------ captura
func _shot(nm: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 120
	var ov := Control.new()
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var issues := _issues.duplicate()
	ov.draw.connect(func():
		var font := ThemeDB.fallback_font
		var k := 0
		for it in issues:
			k += 1
			var col := Color.RED if it["hard"] else Color(1.0, 0.55, 0.0)
			for r in it["rects"]:
				ov.draw_rect(r, col, false, 4.0)
				ov.draw_string_outline(font, (r as Rect2).position + Vector2(4, 22), str(k), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 6,
					Color.BLACK)
				ov.draw_string(font, (r as Rect2).position + Vector2(4, 22), str(k), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, col))
	layer.add_child(ov)
	add_child(layer)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(nm + ".png"))
	layer.queue_free()
