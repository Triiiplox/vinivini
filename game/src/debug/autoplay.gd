class_name Autoplay
extends RefCounted
## "Robô jogador" de QA: resolve cada segmento/tela v2 usando o estado interno (como uma criança
## que acerta tudo — ou erra de propósito com mistake=true). Usado pelo smoke v2 e previews.
## step(screen) é chamado várias vezes por segundo; cada chamada faz no máximo uma ação.

static var mistakes := false
static var _t := {}


static func step(id: String, s: Node) -> void:
	if s == null or not is_instance_valid(s):
		return
	if id == "seg_lesson" and s.get("finished"):
		# Fim de fase no meio da lição: segue para a próxima fase (o baú vem ao fechar a lição).
		var nb := s.find_child("NextStage", true, false) as DSButton
		if nb and not nb.has_meta("pressed"):
			nb.set_meta("pressed", true)
			nb.pressed.emit()
		return
	if s.get("finished"):
		return
	if mistakes and randf() < 0.3 and _mistake(id, s):
		return
	match id:
		"seg_cutscene":
			s.on_world_tap(Vector2(640, 400))
		"seg_build":
			for it in s.tray:
				var part := str(it.payload)
				if s.placed[part] < int(s.need[part]):
					s._on_drop(it, s.zone)
					return
		"seg_flight":
			_flight(s)
		"seg_explore":
			_explore(s)
		"seg_cook":
			_cook(s)
		"seg_monster":
			if s.busy or s.cards.is_empty():
				return
			for c in s.cards:
				if str(c.payload) == s.target:
					s._on_drop(c, s.mouth)
					return
		"seg_word":
			if s.word.is_empty() or s.filled >= s.word["syllables"].size():
				return
			for c in s.cards:
				if str(c.payload) == str(s.word["syllables"][s.filled]):
					s._on_drop(c, s.slot_zones[s.filled])
					return
		"seg_robot":
			if s.running or s.palette_cards.is_empty():
				return
			if s.program.is_empty():
				for d in s.solution:
					for pc in s.palette_cards:
						if pc.dir == d:
							s._add_step(pc)
							break
			s._run()
		"seg_memory":
			if s.listening and s.pos_i < s.seq.size():
				s._on_tap(s.hits[s.seq[s.pos_i]])
		"seg_pattern":
			if s.gap_zones.is_empty():
				return
			var z: DropZone = s.gap_zones[0]
			for o in s.options:
				if str(o.payload) == str(s.row[int(z.key)]):
					s._on_drop(o, z)
					return
		"seg_story":
			if not s.choice_cards.is_empty():
				var c: Interactable = s.choice_cards[0]
				s._on_choice(c)
				s._on_choice(c)
		"seg_planetarium":
			if s.exploring:
				s._on_tap(s.nodes[["earth", "mars", "saturn", "sun"][s.taps % 4]])
			elif s.target != "":
				s._on_tap(s.nodes[s.target])
		"seg_creature":
			match str(s.step):
				"color":
					s._on_color(s.choosers[0])
				"shape":
					s._on_shape(s.choosers[1])
				"eyes", "legs", "antennae":
					if not s.pile.is_empty() and s.placed < s.need:
						var p: Interactable = s.pile[0]
						p.global_position = s.creature.global_position + Vector2(randf_range(-50, 50), -40)
						s._on_piece(p, s.zone)
		"seg_lesson":
			_lesson(s, false)
		"books":
			if not s.finished and not s.books.is_empty():
				s._open(s.books[0])
		"story_maker":
			if not s.cards.is_empty() and not s.busy and s.step < s.STEPS.size():
				s._on_pick(s.cards[randi() % s.cards.size()])
		"maker":
			if s.mode == "planet":
				s._on_tile(s.palette[0])
			elif not s.palette.is_empty() and s.placed.size() < 3:
				var it: Interactable = s.palette[s.placed.size() % s.palette.size()]
				it.position = Vector2(600, 300)
				s._on_drop(it, s.canvas_zone)
			if s.placed.size() >= 3 or s.mode == "planet":
				s._save()
		"academy":
			if not s.tiles.is_empty() and not s.finished:
				s._on_lesson(s.tiles[0])
		"seg_english":
			_english(s, false)
		"hello":
			if s.next_id != "":
				s._on_unit(s.nodes[s.next_id])
		"reward":
			if s.cont.visible:
				s._continue()
		"opening":
			if s.step == "tap_vini":
				s._tap_vini()


## Uma ação errada plausível (a criança erra). Retorna true se errou.
static func _mistake(id: String, s: Node) -> bool:
	match id:
		"seg_build":
			for it in s.tray:
				var part := str(it.payload)
				if s.placed[part] >= int(s.need[part]):
					s._on_drop(it, s.zone)
					return true
		"seg_monster":
			if not s.busy:
				for c in s.cards:
					if str(c.payload) != s.target:
						s._on_drop(c, s.mouth)
						return true
		"seg_word":
			if not s.word.is_empty() and s.filled < s.word["syllables"].size():
				for c in s.cards:
					if str(c.payload) != str(s.word["syllables"][s.filled]):
						s._on_drop(c, s.slot_zones[s.filled])
						return true
		"seg_pattern":
			if not s.gap_zones.is_empty():
				var z: DropZone = s.gap_zones[0]
				for o in s.options:
					if str(o.payload) != str(s.row[int(z.key)]):
						s._on_drop(o, z)
						return true
		"seg_memory":
			if s.listening and s.pos_i < s.seq.size():
				s._on_tap(s.hits[(s.seq[s.pos_i] + 1) % s.hits.size()])
				return true
		"seg_robot":
			if not s.running and s.program.is_empty() and not s.palette_cards.is_empty():
				s._add_step(s.palette_cards[0])
				s._run()
				return true
			if not s.running and not s.program.is_empty():
				# Tira o comando errado (como a criança faria) antes de tentar de novo.
				s._remove_step(s.program_cards[s.program_cards.size() - 1])
				return true
		"seg_cook":
			if not s.order.is_empty() and s.in_bowl.is_empty():
				s._serve(null)
				return true
		"seg_flight":
			if not s.portal_set.is_empty():
				for p in s.portal_set:
					if str(p.get_meta("label")) != s.portal_target:
						s.target_y = p.position.y
						return true
		"seg_planetarium":
			if s.target != "":
				for k in s.nodes:
					if k != s.target:
						s._on_tap(s.nodes[k])
						return true
		"seg_lesson":
			return _lesson(s, true)
		"seg_english":
			return _english(s, true)
		"seg_creature":
			if str(s.step) in ["eyes", "legs", "antennae"] and s.placed >= s.need and not s.pile.is_empty():
				s._on_piece(s.pile[0], s.zone)
				return true
	return false


## Sala de Inglês: conhecer (toca a figura), achar (toca a certa; com mistake, uma errada), corpo (toca o Vini).
static func _english(s: Node, wrong: bool) -> bool:
	if s.busy or s.step.is_empty() or s.cards.is_empty():
		return false
	match str(s.step["k"]):
		"meet":
			if not wrong:
				s._on_card(s.cards[0])
		"find":
			for c in s.cards:
				if is_instance_valid(c) and (str(c.payload) != s.target) == wrong:
					s._on_card(c)
					return true
		"tpr":
			if not wrong:
				s._tpr_tap(s.step["c"])
	return false


## Lição: explicação → play; escolher → certa (ou errada com mistake); ordenar → próxima; classificar → solta no grupo.
static func _lesson(s: Node, wrong: bool) -> bool:
	if s.busy or s.rd.is_empty() or s.finished:
		return false
	match str(s.rd.get("k", "")):
		"teach":
			if s.next_btn.visible and not wrong:
				s._advance()
		"pick":
			for c in s.cards:
				if is_instance_valid(c) and c.name.begins_with("Opt_") and (int(c.payload) != int(s.rd["ok"])) == wrong:
					s._on_pick(c)
					return true
		"order":
			for c in s.cards:
				if is_instance_valid(c) and c.enabled and c.name.begins_with("Ord_") \
						and (int(c.payload) != s.order_next) == wrong:
					s._on_order(c)
					return true
		"sort":
			for c in s.cards:
				if is_instance_valid(c) and c.draggable and c.name.begins_with("Sort_"):
					var b := int(c.payload)
					if wrong:
						b = (b + 1) % s.zones.size()
					s._on_drop(c, s.zones[b])
					return true
		"trace":
			# Robô "traça": passa por todos os pontos de controle (ou só metade, quando erra de propósito).
			var pts: Array = s._trace_pts
			for i in pts.size():
				if not wrong or i % 2 == 0:
					pts[i]["hit"] = true
			s._trace_check(true)
			return true
		"count":
			for c in s.cards:
				if is_instance_valid(c) and c.name.begins_with("Cnt_"):
					if int(c.payload) == 0 or wrong:
						s._on_count(c)
						return true
		"join", "take":
			var want := "out" if str(s.rd["k"]) == "join" else "in"
			for c in s.cards:
				if is_instance_valid(c) and c.draggable and str(c.payload) == want:
					s._on_basket_drop(c, s.outside if wrong == (want == "out") else s.basket)
					return true
		"num":
			var key: Interactable = s._key_card("OK")
			if key:
				s.typed = str(int(s.rd.get("ans", 0)) + (1 if wrong else 0))
				s._on_key(key)
				return true
		"build":
			var parts: Array = s.rd.get("parts", [])
			if s.placed < parts.size():
				for c in s.cards:
					if is_instance_valid(c) and c.draggable and (str(c.payload) == str(parts[s.placed])) != wrong:
						s._on_syllable_drop(c, s.zones[s.placed])
						return true
	return false


static func _flight(s: Node) -> void:
	var y := 360.0
	if not s.portal_set.is_empty():
		for p in s.portal_set:
			if str(p.get_meta("label")) == s.portal_target:
				y = p.position.y
	else:
		var best := INF
		for o in s.objects:
			if is_instance_valid(o) and str(o.get_meta("kind", "")) == "crystal" and o.position.x > s.SHIP_X and o.position.x < best:
				best = o.position.x
				y = o.position.y
	s.target_y = y


static func _explore(s: Node) -> void:
	if s.door and not s.door_open:
		if not s.bag.is_empty() or s.door_put > 0:
			if s.door_put < s.door_need and not s.bag.is_empty():
				var z: DropZone = null
				for n in s.get_tree().get_nodes_in_group("dropzone"):
					if n is DropZone and n.key == "door":
						z = n
				s._on_bag_drop(s.bag[0], z)
			elif s.door_put == s.door_need:
				s._on_door_confirm(null)
			return
		if not s.collectibles.is_empty() and s.collectibles[0].position.x < s.door_x:
			s._on_item_tapped(s.collectibles[0])
		else:
			s.on_world_tap(Vector2(s.door_x - 100, 600))
		return
	if not s.collectibles.is_empty():
		s._on_item_tapped(s.collectibles[0])
	elif not s.signs.is_empty():
		s._on_sign_tapped(s.signs[0])
	else:
		s.on_world_tap(Vector2(minf(s.vini.position.x + 900, s.width - 100), 600))


static func _cook(s: Node) -> void:
	if s.order.is_empty() or s.customer == null:
		return
	var have: Dictionary = s._counts()
	for f in s.order:
		var want: int = int(s.order[f]) * s.plates
		if int(have.get(f, 0)) < want:
			for n in s.world.get_children():
				if n is Interactable and n.has_meta("crate") and str(n.payload) == f and not s.in_bowl.has(n):
					s._on_drop(n, s.bowl_zone)
					return
	s._serve(null)


static func describe(id: String, s: Node) -> String:
	if s == null:
		return ""
	match id:
		"seg_explore":
			return "vini=%d door=%s open=%s put=%d/%d bag=%d col=%d signs=%d rescue=%s width=%d fin=%s" % [
				s.vini.position.x, s.door != null, s.door_open, s.door_put, s.door_need, s.bag.size(), s.collectibles.size(),
				s.signs.size(), s.rescue_npc != null, s.width, s.finished]
		"seg_cook":
			return "order=%s served=%d bowl=%d" % [str(s.order), s.served, s.in_bowl.size()]
		"seg_flight":
			return "progress=%d/%d portals=%d target=%s" % [s.progress, s.goal, s.portal_set.size(), s.portal_target]
	return ""
