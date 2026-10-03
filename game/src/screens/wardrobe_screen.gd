extends GameScreen
## Quarto / guarda-roupa: o astronauta grande no espelho e as peças em cartões (cada cartão mostra
## o astronauta vestindo a peça). Toque = veste na hora. Peças trancadas mostram cadeado e a voz
## explica como ganhar. Sem texto.

const SLOTS := ["helmet", "suit", "accessory"]
const SLOT_ICON := {"helmet": "smile", "suit": "star", "accessory": "heart"}

var av: Dictionary
var big: AvatarRig
var slot := "helmet"
var cards: Array[Interactable] = []
var tabs: Array[Interactable] = []


func build() -> void:
	set_sky("space")
	AudioService.play_music("hub", 0.4)
	world.add_child(Scenery.new("ship"))
	av = AppState.avatar().duplicate(true)
	var mirror := Panel.new()
	mirror.add_theme_stylebox_override("panel", UITheme.rounded(Color("#BFE7FF", 0.25), 120, 10, Color("#FFD23F")))
	mirror.size = Vector2(300, 470)
	mirror.position = Vector2(60, 150)
	mirror.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(mirror)
	big = AvatarRig.new(av, 380.0)
	big.position = Vector2(210, 600)
	big.z_index = 5
	world.add_child(big)
	for i in SLOTS.size():
		var t := Interactable.new()
		t.radius = 50.0
		t.payload = SLOTS[i]
		var p := Panel.new()
		p.add_theme_stylebox_override("panel", UITheme.rounded([Palette.PINK, Palette.ORANGE, Palette.TEAL][i], 44, 6, Color("#22204A")))
		p.size = Vector2(88, 88)
		p.position = Vector2(-44, -44)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.add_child(p)
		var mini := AvatarRig.new(_with(SLOTS[i], {"helmet": "helmet_classic", "suit": "suit_blue",
			"accessory": "acc_star_badge"}[SLOTS[i]]), 74.0)
		mini.position = Vector2(0, 36)
		t.add_child(mini)
		t.position = Vector2(500 + i * 120, 140)
		world.add_child(t)
		t.tapped.connect(_on_tab)
		tabs.append(t)
	_show_slot("helmet")
	hint_fn = _hint


func begin() -> void:
	narrate(Lines.n("Seu quarto. Toque numa roupa para experimentar!"))


func _with(s: String, item_id: String) -> Dictionary:
	var a := av.duplicate()
	a[s] = item_id
	return a


func _on_tab(t: Interactable) -> void:
	AudioService.play_sfx("tap")
	_show_slot(str(t.payload))


func _show_slot(s: String) -> void:
	slot = s
	for t in tabs:
		t.scale = Vector2(1.15, 1.15) if t.payload == s else Vector2(0.9, 0.9)
	for c in cards:
		c.queue_free()
	cards.clear()
	var items: Array = ContentService.repo.items.filter(func(it): return str(it["slot"]) == s)
	var pid := SaveService.profile_id
	for i in items.size():
		var it: Dictionary = items[i]
		var open := SaveService.inventory.is_unlocked(pid, str(it["id"]))
		var c := Interactable.new()
		c.radius = 66.0
		c.payload = it
		var p := Panel.new()
		var worn := str(av.get(s, "")) == str(it["id"])
		p.add_theme_stylebox_override("panel", UITheme.rounded(Color("#2A2F5A") if open else Color("#1A1D3A"), 26, 6 if not worn else 9,
			Palette.YELLOW if worn else Color("#22204A")))
		p.size = Vector2(130, 150)
		p.position = Vector2(-65, -75)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(p)
		var mini := AvatarRig.new(_with(s, str(it["id"])), 128.0)
		mini.position = Vector2(0, 68)
		mini.modulate = Color.WHITE if open else Color(0.25, 0.25, 0.35)
		c.add_child(mini)
		if not open:
			var lock := IconDraw.new("lock", Color.WHITE)
			lock.size = Vector2(60, 60)
			lock.position = Vector2(-30, -30)
			c.add_child(lock)
		c.position = Vector2(520 + (i % 5) * 150, 320 + (i / 5) * 170)
		c.scale = Vector2.ZERO
		world.add_child(c)
		c.create_tween().tween_property(c, "scale", Vector2.ONE, 0.2).set_delay(i * 0.04)
		c.tapped.connect(_on_item.bind(open))
		cards.append(c)


func _on_item(c: Interactable, open: bool) -> void:
	var it: Dictionary = c.payload
	if not open:
		c.wiggle()
		AudioService.play_sfx("retry")
		narrate(Lines.n("Essa ainda está trancada. Complete missões e junte estrelas para ganhar!"))
		return
	av[slot] = it["id"]
	AppState.equip(it)
	big.set_avatar(av)
	big.play("jump")
	AudioService.play_sfx("pop")
	Fx.sparkle(world, big.position + Vector2(0, -200), 20, Palette.YELLOW)
	cosmo_say(RewardService.praise.pick("simple"))
	_show_slot(slot)


func _hint() -> void:
	if not cards.is_empty():
		hand.show_tap(cards[0].global_position)


func _on_home() -> void:
	Router.back()
