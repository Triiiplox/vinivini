extends BaseScreen
## Coleção: itens (toque para equipar), marcos e planetas criados.

var preview: AvatarView


func on_enter() -> void:
	build_frame("Troféus", "back", true, true)
	var pid := SaveService.profile_id
	var st := RewardService.stats()
	var h := UI.hbox(24)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(h)
	var left := UI.vbox(10)
	h.add_child(left)
	preview = AvatarView.new(AppState.avatar())
	preview.custom_minimum_size = Vector2(240, 340)
	left.add_child(preview)
	var medals := UI.vbox(6)
	left.add_child(medals)
	var total_missions := 0
	for a in st["missions_by_area"]:
		total_missions += int(st["missions_by_area"][a])
	for line in [
		["Missões", total_missions],
		["Desafios de Comandante", st["commander"]],
		["Finais de história", st["story_endings"]],
		["Planetas criados", st["creative"]]
	]:
		medals.add_child(UI.label("%s: %d" % [line[0], int(line[1])], 22, Palette.TEXT_SOFT))
	var right := UI.vbox(10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(right)
	var unlocked := SaveService.inventory.list_items(pid)
	right.add_child(UI.label("Itens: %d de %d" % [unlocked.size(), ContentService.repo.items.size()], 30, Palette.YELLOW, true))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 5
	scroll.add_child(grid)
	for it in ContentService.repo.items:
		if str(it["id"]).ends_with("_none"):
			continue
		var is_open := unlocked.has(it["id"])
		var b := Button.new()
		b.name = "Item_%s" % it["id"]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(150, 180)
		var equipped: bool = AppState.avatar().get(it["slot"], "") == it["id"]
		var sb := UITheme.rounded(Color(1, 1, 1, 0.12 if is_open else 0.05), 22, 5 if equipped else 0, Palette.YELLOW)
		for s in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(s, sb)
		var av := ProfileRepository.default_avatar()
		av[it["slot"]] = it["id"]
		var mv := AvatarView.new(av)
		mv.animate = false
		mv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mv.offset_bottom = -40
		if not is_open:
			mv.modulate = Color(1, 1, 1, 0.22)
		b.add_child(mv)
		var l := UI.label(str(it["name"]) if is_open else "???", 17, Palette.WHITE)
		l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		l.offset_top = -40
		l.offset_bottom = -4
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		l.add_theme_constant_override("line_spacing", -4)
		b.add_child(l)
		if not is_open:
			var lk := IconDraw.new("lock", Palette.YELLOW)
			lk.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
			lk.offset_left = -26
			lk.offset_top = -40
			lk.offset_right = 26
			lk.offset_bottom = 12
			b.add_child(lk)
		b.pressed.connect(_on_item.bind(it, is_open))
		grid.add_child(b)
	say("Sua coleção! Toque num item para usar.")


func _on_item(it: Dictionary, is_open: bool) -> void:
	if not is_open:
		AudioService.play_sfx("retry")
		var hint := RewardEngine.unlock_hint(it["unlock"])
		fx().toast(hint, Palette.PURPLE)
		say(hint + " para ganhar este item!")
		return
	AppState.equip(it)
	preview.set_avatar(AppState.avatar())
	AudioService.play_sfx("unlock")
	say("Você está usando: %s!" % it["name"])
	Router.replace("trophies", params)
