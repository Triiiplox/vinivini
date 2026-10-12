class_name FonoTargetScreen
extends GameScreen
## FALAR v2: a "casa" de um som (params.target). À esquerda, o TREINO (continua do nível aberto, com a trilha de 8
## níveis); à direita, os jogos do som: SACOLAS DO SOM (P4), CHUVA NO GUARDA-CHUVA (P3), TRILHA DE LEITURA (P6) e
## ME FAZ PEGAR (P5, só se os pais ligarem na área dos pais). Som sem jogos vai direto para o treino.

const ACTS := {
	"sacolas_do_som": {"screen": "fono_bags", "icon": "bags", "color": "#0EA5E9"},
	"chuva_guarda_chuva": {"screen": "fono_rain", "icon": "cloud", "color": "#6366F1"},
	"trilha_de_leitura": {"screen": "fono_read", "icon": "rocket", "color": "#F59E0B"},
	"me_faz_pegar": {"screen": "fono_pairs", "icon": "hands", "color": "#10B981"},
}

var target := "ch"
var tiles: Array[Interactable] = []
var train: Interactable
var _picked := false


## Jogos disponíveis para o som: [{"id", "name", "say", "screen", ...}] na ordem de ACTS.
static func activities_for(id: String) -> Array:
	var out: Array = []
	var t := FonoData.target(id)
	for a in FonoData.data().get("activities", []):
		var aid := str(a.get("id", ""))
		if not ACTS.has(aid) or not (a.get("targets", []) as Array).has(id):
			continue
		if aid == "sacolas_do_som" and FonoPlan.bag_pairs(id).is_empty():
			continue
		if aid == "me_faz_pegar" and (not FonoPlan.pairs_enabled() or (t.get("pares", []) as Array).is_empty()):
			continue
		var d: Dictionary = (a as Dictionary).duplicate()
		d.merge(ACTS[aid])
		out.append(d)
	return out


func build() -> void:
	target = str(params.get("target", "ch"))
	FonoPlan.mark_session()
	set_sky("space")
	AudioService.play_music("hub", 0.5)
	var t := FonoData.target(target)
	var title := UI.label(str(t.get("letter", target.to_upper())), 52, Color.WHITE, true)
	title.size = Vector2(400, 70)
	title.position = Vector2(440, 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(title)  # a letra do som
	hud.stage.add_child(title)
	_train_card(Vector2(370, 380))
	var acts := activities_for(target)
	for i in acts.size():
		_tile(acts[i], Vector2(830 + (i % 2) * 250, 250 + (i / 2) * 250))
	hint_fn = func(): hand.show_tap(train.global_position)


func begin() -> void:
	narrate(Lines.n("O que vamos fazer?"))


func _train_card(pos: Vector2) -> void:
	var sz := Vector2(440, 430)
	var col := Color(str(FonoPanels.COLORS.get(target, "#475569")))
	train = Interactable.new()
	train.name = "FonoTrain"
	train.hit_rect = Rect2(-sz / 2.0, sz)
	train.position = pos
	var p := Panel.new()
	var sb := UITheme.rounded(col, 44, 6, col.lightened(0.5))
	sb.shadow_color = Color(col, 0.5)
	sb.shadow_size = 16
	p.add_theme_stylebox_override("panel", sb)
	p.size = sz
	p.position = -sz / 2.0
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	train.add_child(p)
	var face := FonoFace.new()
	face.scale = Vector2.ONE * 0.62
	face.position = Vector2(0, -70)
	face.set_pose(target)
	train.add_child(face)
	var lv := FonoData.level_open(target)
	var n := FonoData.levels().size()
	var step := 44.0
	for k in n:
		var dot := ColorRect.new()
		dot.size = Vector2(32, 32)
		dot.position = Vector2(-step * (n - 1) / 2.0 - 16 + k * step, 120)
		dot.color = DS.STAR_GOLD if k < lv else (Color.WHITE if k == lv else Color(1, 1, 1, 0.22))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		train.add_child(dot)
	var lvn := UI.label(str(FonoData.levels()[lv]["name"]), 34, Color.WHITE, true)
	lvn.position = Vector2(-sz.x / 2.0, 158)
	lvn.size = Vector2(sz.x, 50)
	lvn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(lvn)  # nome do nível
	train.add_child(lvn)
	train.tapped.connect(func(_i): _go("fono_session", {"target": target, "lv": FonoData.level_open(target)}))
	world.add_child(train)


func _tile(a: Dictionary, pos: Vector2) -> void:
	var sz := Vector2(230, 220)
	var col := Color(str(a.get("color", "#475569")))
	var it := Interactable.new()
	it.name = "Act_" + str(a["id"])
	it.payload = a
	it.hit_rect = Rect2(-sz / 2.0, sz)
	it.position = pos
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", UITheme.rounded(col, 36, 5, col.lightened(0.5)))
	p.size = sz
	p.position = -sz / 2.0
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	it.add_child(p)
	if str(a["icon"]) == "bags":
		var pairs := FonoPlan.bag_pairs(target)
		var letters := [str(FonoData.target(target).get("letter", ""))]
		if not pairs.is_empty():
			letters.append(str(pairs[0].get("letra", "")))
		for k in 2:
			var bag := Panel.new()
			bag.add_theme_stylebox_override("panel", UITheme.rounded(Color("#FDE68A"), 18, 4, Color("#92400E")))
			bag.size = Vector2(84, 96)
			bag.position = Vector2(-92 + k * 100, -86)
			bag.mouse_filter = Control.MOUSE_FILTER_IGNORE
			it.add_child(bag)
			var l := UI.label(str(letters[k]) if k < letters.size() else "?", 36, Color("#92400E"), true)
			l.size = bag.size
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			UI.child_ok(l)  # letra do som na sacola
			bag.add_child(l)
	else:
		var ic := IconDraw.new(str(a["icon"]), Color.WHITE)
		ic.size = Vector2(110, 110)
		ic.position = Vector2(-55, -92)
		it.add_child(ic)
	var name_l := UI.wrap_label(str(a.get("name", "")), 24, Color.WHITE)
	name_l.position = Vector2(-sz.x / 2.0 + 8, 30)
	name_l.size = Vector2(sz.x - 16, 70)
	name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(name_l)  # nome do jogo (a narradora fala ao tocar)
	it.add_child(name_l)
	it.tapped.connect(func(i: Interactable):
		var d: Dictionary = i.payload
		var dur := narrate(str(d.get("name", "")))
		_go(str(d["screen"]), {"target": target}, maxf(0.25, dur)))
	world.add_child(it)
	tiles.append(it)


func _go(screen: String, p: Dictionary, wait: float = 0.25) -> void:
	if _picked:
		return
	_picked = true
	AudioService.play_sfx("whoosh")
	after(wait, Router.go.bind(screen, p))
