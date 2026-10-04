extends GameScreen
## Cozinha da Estação Espacial: um astronauta da tripulação pede por voz e com figuras ("Eu quero três morangos").
## (Na Estação Espacial Internacional a comida vem em pacotes e é montada em bandejas; frutas frescas chegam nas naves de carga.)
## Arraste da caixa para a tigela; toque num item da tigela para tirar; toque no sino para servir.
## Nível 1: um ingrediente (1–5). Nível 2: dois ingredientes (soma até 10). Nível 3: dois pratos iguais
## (multiplicação intuitiva: "dois pratos com três cogumelos").
## params: customers (n), foods (lista opcional)

const FOODS := {
	"strawberry": ["morango", "morangos", "m"], "mushroom": ["cogumelo", "cogumelos", "m"], "cheese": ["queijo", "queijos", "m"],
	"carrot": ["cenoura", "cenouras", "f"], "apple": ["maçã", "maçãs", "f"], "egg": ["ovo", "ovos", "m"],
	"tomato": ["tomate", "tomates", "m"], "banana": ["banana", "bananas", "f"], "bread": ["pão", "pães", "m"],
}
const CREW_SUITS := ["suit_orange", "chef", "suit_blue", "suit_green", "chef", "suit_saturn"]

var foods: Array = []
var customers_total := 3
var served := 0
var order: Dictionary = {}
var plates := 1
var in_bowl: Array[Interactable] = []
var customer: CrewActor
var bubble: Node2D
var bowl_zone: DropZone
var tries := 0
var t0 := 0.0
var _lvl := 1


static func food_phrase(n: int, food: String) -> String:
	var f: Array = FOODS[food]
	var num: String = Lines.NUMBERS_F[n] if f[2] == "f" else Lines.NUMBERS[n]
	return "%s %s" % [num, f[0] if n == 1 else f[1]]


func build() -> void:
	customers_total = int(params.get("customers", 3))
	foods = params.get("foods", ["strawberry", "mushroom", "cheese", "carrot", "apple", "egg"])
	set_sky("space")
	AudioService.play_music("kitchen")
	world.add_child(Scenery.new("kitchen"))
	var counter := Panel.new()
	# Balcão nas cores da cozinha pintada (azul-marinho com filete ciano), da largura de qualquer tela.
	counter.add_theme_stylebox_override("panel", UITheme.rounded(Color("#1F3F8F"), 26, 6, Color("#5CE1FF")))
	counter.position = Vector2(-400, 470)
	counter.size = Vector2(2080, 300)
	counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counter.z_index = 2
	world.add_child(counter)
	var top := Panel.new()
	top.add_theme_stylebox_override("panel", UITheme.rounded(Color("#EEF1F7"), 18, 4, Color("#B8C2D8")))
	top.position = Vector2(-400, 450)
	top.size = Vector2(2080, 48)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.z_index = 3
	world.add_child(top)
	var bowl := ArtSprite.new("props", "bowl", 260.0)
	bowl.position = Vector2(700, 470)
	bowl.z_index = 8
	world.add_child(bowl)
	bowl_zone = DropZone.new()
	bowl_zone.radius = 170.0
	bowl_zone.position = Vector2(700, 430)
	world.add_child(bowl_zone)
	var bell := Interactable.new()
	bell.radius = 70.0
	bell.position = Vector2(1060, 420)
	bell.z_index = 9
	bell.name = "Bell"
	bell.add_child(ArtSprite.new("ui", "check", 110.0))
	bell.tapped.connect(_serve)
	world.add_child(bell)
	add_cosmo(Vector2(1180, 170), 120.0)
	_lvl = difficulty("math.addition.concrete")
	hint_fn = _hint


func begin() -> void:
	narrate(Lines.n("Bem-vindo à cozinha da estação espacial! Os astronautas estão com fome."))
	after(2.5, _next_customer)


func _next_customer() -> void:
	if served >= customers_total:
		cosmo_say(Lines.c("A tripulação toda comeu! Você é um ótimo cozinheiro espacial!"))
		after(2.4, func(): finish({"stars": 3, "skills": ["math.addition.concrete"]}))
		return
	_clear_bowl(false)
	customer = CrewActor.new(CREW_SUITS[served % CREW_SUITS.size()], 260.0)
	customer.position = Vector2(-200, 450)
	customer.z_index = 1
	world.add_child(customer)
	var tw := customer.create_tween()
	tw.tween_property(customer, "position:x", 300.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_place_order)
	_crates()


func _crates() -> void:
	for n in world.get_children():
		if n is Interactable and n.has_meta("crate"):
			n.queue_free()


func _make_crate(food: String, i: int, total: int) -> void:
	var it := Interactable.new()
	it.draggable = true
	it.tappable = true
	it.radius = 62.0
	it.payload = food
	it.set_meta("crate", true)
	it.add_child(ArtSprite.new("foods", food, 92.0))
	var x := 640.0 - (total - 1) * 75.0 + i * 150.0
	it.position = Vector2(x, 620)
	it.z_index = 20
	world.add_child(it)
	it.dropped.connect(_on_drop)
	it.tapped.connect(func(i2): Voice.say(str(FOODS[str(i2.payload)][0])))


func _place_order() -> void:
	tries = 0
	t0 = Time.get_ticks_msec() / 1000.0
	var pool := foods.duplicate()
	pool.shuffle()
	order = {}
	plates = 1
	match _lvl:
		1:
			order[pool[0]] = randi_range(1, 5)
		2:
			var a := randi_range(1, 5)
			order[pool[0]] = a
			order[pool[1]] = randi_range(1, mini(5, 10 - a))
		_:
			plates = 2
			order[pool[0]] = randi_range(2, 4)
	var shown: Array = order.keys()
	var crate_foods: Array = shown.duplicate()
	for f in pool:
		if crate_foods.size() >= 3:
			break
		if not crate_foods.has(f):
			crate_foods.append(f)
	crate_foods.shuffle()
	for i in crate_foods.size():
		_make_crate(crate_foods[i], i, crate_foods.size())
	_show_bubble()
	_say_order()


func _show_bubble() -> void:
	if bubble:
		bubble.queue_free()
	bubble = Node2D.new()
	bubble.position = customer.position + Vector2(0, -330)
	bubble.z_index = 30
	world.add_child(bubble)
	var w := 150.0 * order.size() + 60.0
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", UITheme.rounded(Color.WHITE, 40, 6, Color("#22204A")))
	p.size = Vector2(w, 150 if plates == 1 else 170)
	p.position = Vector2(-w / 2, -75)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_child(p)
	var i := 0
	for f in order:
		var a := ArtSprite.new("foods", f, 80.0)
		a.position = Vector2(-w / 2 + 70 + i * 150, -10)
		bubble.add_child(a)
		var num := UI.label(("%d×" % plates if plates > 1 else "") + str(order[f]), 48, Palette.TEXT_DARK, true)
		UI.child_ok(num)
		num.position = Vector2(-w / 2 + 110 + i * 150, -20)
		bubble.add_child(num)
		if _lvl == 1:
			for k in int(order[f]):
				var d := ArtSprite.new("props", "star_token", 20.0)
				d.position = Vector2(-w / 2 + 40 + i * 150 + k * 22, 52)
				bubble.add_child(d)
		i += 1
	bubble.scale = Vector2(0.2, 0.2)
	bubble.create_tween().tween_property(bubble, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _say_order() -> void:
	var parts: Array = [Lines.n("Eu quero")]
	if plates > 1:
		parts = [Lines.n("Eu quero dois pratos. Cada prato com")]
	var keys: Array = order.keys()
	for i in keys.size():
		if i > 0:
			parts.append(Lines.n("e"))
		parts.append(food_phrase(int(order[keys[i]]), keys[i]))
	narrate_seq(parts)


func _on_drop(it: Interactable, z: DropZone) -> void:
	if z != bowl_zone:
		if in_bowl.has(it):
			in_bowl.erase(it)
			it.queue_free()
			_update_count()
		else:
			it.return_home()
		return
	if in_bowl.has(it):
		it.return_home()
		return
	# A caixa é infinita: o item arrastado vai para a tigela e nasce outro igual na caixa.
	var food := str(it.payload)
	var copy := Interactable.new()
	copy.draggable = true
	copy.radius = 62.0
	copy.payload = food
	copy.set_meta("crate", true)
	copy.add_child(ArtSprite.new("foods", food, 92.0))
	copy.position = it.home_pos
	copy.z_index = 20
	world.add_child(copy)
	copy.dropped.connect(_on_drop)
	copy.tapped.connect(func(i2): Voice.say(str(FOODS[str(i2.payload)][0])))
	it.remove_meta("crate")
	var k := in_bowl.size()
	it.snap_to(Vector2(640 + (k % 5) * 30 - 30, 400 - (k / 5) * 26 - (k % 2) * 12), true, Vector2(0.75, 0.75))
	it.tapped.connect(_remove_from_bowl)
	in_bowl.append(it)
	_update_count()


func _remove_from_bowl(it: Interactable) -> void:
	if in_bowl.has(it):
		in_bowl.erase(it)
		AudioService.play_sfx("pop")
		var tw := it.create_tween()
		tw.tween_property(it, "scale", Vector2.ZERO, 0.15)
		tw.tween_callback(it.queue_free)
		_update_count()


func _update_count() -> void:
	Voice.say(Lines.number(in_bowl.size()))


func _counts() -> Dictionary:
	var c := {}
	for it in in_bowl:
		c[it.payload] = int(c.get(it.payload, 0)) + 1
	return c


func _serve(_b: Interactable) -> void:
	if order.is_empty():
		return
	tries += 1
	var have := _counts()
	var ok := have.size() == order.size()
	for f in order:
		if int(have.get(f, 0)) != int(order[f]) * plates:
			ok = false
	if ok:
		_happy()
	else:
		AudioService.play_sfx("retry")
		customer.set_mood("surprised")
		after(1.2, _calm_customer)
		var f: String = order.keys()[0]
		var want := int(order[f]) * plates
		var got := int(have.get(f, 0))
		if got < want:
			narrate_seq([Lines.n("Hmm, ainda falta."), Lines.n("Eu quero"), food_phrase(want, f)])
		elif got > want:
			narrate_seq([Lines.n("Opa, é demais!"), Lines.n("Eu quero"), food_phrase(want, f), Lines.n("Toque para tirar.")])
		else:
			_say_order()


func _calm_customer() -> void:
	if is_instance_valid(customer):
		customer.set_mood("happy")


func _happy() -> void:
	var rt := Time.get_ticks_msec() / 1000.0 - t0
	var skill := "math.addition.concrete" if order.size() > 1 or plates > 1 else "math.counting"
	record(skill, "cook_%s" % str(order), tries == 1, tries, minf(rt, 15.0))
	order = {}
	AudioService.play_sfx("chew")
	customer.set_mood("happy")
	for it in in_bowl:
		var tw := it.create_tween()
		tw.tween_property(it, "position", customer.position + Vector2(0, -140), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(it, "scale", Vector2(0.2, 0.2), 0.4)
		tw.tween_callback(it.queue_free)
	in_bowl.clear()
	after(0.5, func():
		AudioService.play_sfx("yum")
		customer.hop(3)
		Fx.sparkle(world, customer.position + Vector2(0, -200), 30, Palette.PINK)
		praise({"tries": tries, "area": "math"}))
	served += 1
	if bubble:
		bubble.queue_free()
		bubble = null
	after(2.6, _leave)


func _leave() -> void:
	var c := customer
	var tw := c.create_tween()
	tw.tween_property(c, "position:x", -300.0, 0.8)
	tw.tween_callback(c.queue_free)
	_next_customer()


func _clear_bowl(_animate: bool) -> void:
	for it in in_bowl:
		it.queue_free()
	in_bowl.clear()


func _hint() -> void:
	if order.is_empty():
		return
	var have := _counts()
	for f in order:
		if int(have.get(f, 0)) < int(order[f]) * plates:
			for n in world.get_children():
				if n is Interactable and n.has_meta("crate") and str(n.payload) == f:
					hand.show_drag(n.global_position, bowl_zone.global_position)
					return
	hand.show_tap(Vector2(1060, 420))
