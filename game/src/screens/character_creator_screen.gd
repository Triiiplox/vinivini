extends BaseScreen
## Criador/Oficina de personagem: pele, cabelo, cor do cabelo, traje, capacete, acessório.
## mode "new" (primeira vez) ou "edit" (Oficina, com itens desbloqueados).

const CATEGORIES := [
	{"id": "skin", "name": "Pele", "icon": "smile", "color": "#F6C9A0"},
	{"id": "hair_style", "name": "Cabelo", "icon": "cloud", "color": "#8E7DFF"},
	{"id": "hair_color", "name": "Cor", "icon": "palette", "color": "#FF70A6"},
	{"id": "suit", "name": "Traje", "icon": "star", "color": "#FF8C42"},
	{"id": "helmet", "name": "Capacete", "icon": "rocket", "color": "#3A86FF"},
	{"id": "accessory", "name": "Extra", "icon": "heart", "color": "#2EC4B6"},
]

var avatar: Dictionary = {}
var preview: AvatarView
var options_grid: GridContainer
var category := "skin"
var _cat_buttons: Dictionary = {}


func on_enter() -> void:
	var is_new := str(params.get("mode", "new")) == "new"
	avatar = AppState.avatar().duplicate(true)
	build_frame("Crie seu astronauta!" if is_new else "Oficina", "back", true, not is_new)
	var h := UI.hbox(24)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(h)
	var left := UI.vbox(8)
	h.add_child(left)
	var pp := UI.panel(Color(1, 1, 1, 0.08), 40)
	left.add_child(pp)
	preview = AvatarView.new(avatar)
	preview.custom_minimum_size = Vector2(300, 420)
	pp.add_child(preview)
	var right := UI.vbox(14, BoxContainer.ALIGNMENT_BEGIN)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(right)
	var cats := UI.hbox(10)
	right.add_child(cats)
	for c in CATEGORIES:
		var b := UI.button(c["name"], Color(c["color"]), c["icon"], Vector2(118, 100), true, 22)
		b.name = "Cat_%s" % c["id"]
		b.speak_on_press = c["name"]
		b.tapped.connect(_select_category.bind(c["id"]))
		cats.add_child(b)
		_cat_buttons[c["id"]] = b
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	options_grid = GridContainer.new()
	options_grid.columns = 5
	options_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(options_grid)
	var done := UI.button("PRONTO!", Palette.GREEN, "check", Vector2(300, 96), false, 40)
	done.name = "DoneButton"
	done.tapped.connect(_on_done)
	right.add_child(done)
	done.size_flags_horizontal = Control.SIZE_SHRINK_END
	_select_category("skin")
	say("Escolha como o seu astronauta vai ser!" if is_new else "Bem-vindo à Oficina! Experimente roupas novas.")


func _select_category(cat: String) -> void:
	category = cat
	for id in _cat_buttons:
		(_cat_buttons[id] as KidButton).modulate = Color.WHITE if id == cat else Color(1, 1, 1, 0.55)
	UI.clear(options_grid)
	for opt in _options_for(cat):
		options_grid.add_child(_make_cell(opt))


## Lista de opções {id, name, color?, locked, hint, new}.
func _options_for(cat: String) -> Array:
	var out: Array = []
	var pid := SaveService.profile_id
	if cat in ["skin", "hair_style", "hair_color"]:
		for o in ContentService.repo.avatar_options.get(cat, []):
			out.append({"id": o["id"], "name": str(o.get("name", "")), "color": str(o.get("color", "")), "locked": false})
		return out
	var unseen := SaveService.inventory.unseen_items(pid)
	for it in ContentService.repo.items:
		if it["slot"] != cat:
			continue
		var unlocked := SaveService.inventory.is_unlocked(pid, it["id"])
		out.append(
			{
				"id": it["id"],
				"name": it["name"],
				"locked": not unlocked,
				"hint": RewardEngine.unlock_hint(it["unlock"]),
				"new": unseen.has(it["id"])
			}
		)
	return out


func _make_cell(opt: Dictionary) -> Control:
	var b := Button.new()
	b.name = "Opt_%s" % opt["id"]
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(150, 170)
	var selected: bool = avatar.get(category, "") == opt["id"]
	var bg := UITheme.rounded(Color(1, 1, 1, 0.12), 24, 6 if selected else 0, Palette.YELLOW)
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, bg)
	if opt.get("color", "") != "":
		var sw := ColorRect.new()
		sw.color = Color(opt["color"])
		sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sw.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		sw.offset_left = 28
		sw.offset_top = 34
		sw.offset_right = -28
		sw.offset_bottom = -34
		b.add_child(sw)
	else:
		var av := avatar.duplicate(true)
		av[category] = opt["id"]
		var mini := AvatarView.new(av)
		mini.animate = false
		mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mini.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mini.offset_top = 6
		mini.offset_bottom = -6
		if opt.get("locked", false):
			mini.modulate = Color(1, 1, 1, 0.22)
		b.add_child(mini)
	if opt.get("locked", false):
		var lock := IconDraw.new("lock", Palette.YELLOW)
		lock.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		lock.custom_minimum_size = Vector2(60, 60)
		lock.offset_left = -30
		lock.offset_top = -30
		lock.offset_right = 30
		lock.offset_bottom = 30
		b.add_child(lock)
	if opt.get("new", false):
		var tag := UI.label("NOVO!", 22, Palette.TEXT_DARK)
		var tp := UI.panel(Palette.YELLOW, 12)
		tp.add_child(tag)
		tp.position = Vector2(4, 126)
		tp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(tp)
	b.pressed.connect(_on_option.bind(opt))
	return b


func _on_option(opt: Dictionary) -> void:
	if opt.get("locked", false):
		AudioService.play_sfx("retry")
		fx().toast(str(opt.get("hint", "Ainda trancado")), Palette.PURPLE)
		say("%s. %s para ganhar!" % [opt.get("name", ""), opt.get("hint", "")])
		return
	AudioService.play_sfx("tap")
	avatar[category] = opt["id"]
	preview.set_avatar(avatar)
	if opt.get("name", "") != "":
		AudioService.speak(str(opt["name"]))
	if opt.get("new", false):
		SaveService.inventory.mark_seen(SaveService.profile_id, opt["id"])
	_select_category(category)


func _on_done() -> void:
	var is_new := str(params.get("mode", "new")) == "new"
	AppState.save_avatar(avatar)
	AudioService.play_sfx("correct")
	if is_new:
		say("Que astronauta incrível!")
		Router.reset_to("intro")
	else:
		fx().toast("Visual salvo!", Palette.GREEN)
		Router.back()
