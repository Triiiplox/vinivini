extends Node
## Galerias da arte vetorial para revisão: godot --headless --path game -- --artpreview=/dir

var out_dir := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--artpreview="):
			out_dir = a.substr(13)
	DirAccess.make_dir_recursive_absolute(out_dir)
	SvgArt.clear_cache()
	var t0 := Time.get_ticks_msec()
	_gallery("avatars", _avatars(), 400, 600, 260)
	_gallery("characters", _characters(), 300, 300, 200)
	_gallery("planets", _planets(), 240, 240, 220)
	_gallery("objects", _objects(), 100, 100, 140)
	print("art preview em %d ms" % (Time.get_ticks_msec() - t0))
	get_tree().quit(0)


func _raster(svg: String, vb_w: float, px: int) -> Image:
	var img := Image.new()
	var err := img.load_svg_from_string(svg, px / vb_w)
	if err != OK:
		push_error("svg inválido")
	img.convert(Image.FORMAT_RGBA8)
	return img


func _gallery(name: String, svgs: Array, vb_w: float, vb_h: float, cell: int) -> void:
	var cols := 6
	var ch := int(cell * vb_h / vb_w)
	var rows := ceili(svgs.size() / float(cols))
	var canvas := Image.create(cols * cell, rows * ch, false, Image.FORMAT_RGBA8)
	canvas.fill(Color("#1B2A6B"))
	for i in svgs.size():
		var img := _raster(svgs[i], vb_w, cell)
		canvas.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i((i % cols) * cell, (i / cols) * ch))
	canvas.save_png(out_dir.path_join(name + ".png"))


func _avatars() -> Array:
	var out := []
	var combos := [
		{
			"skin": "skin_3",
			"hair_style": "short",
			"hair_color": "hair_brown",
			"suit": "suit_orange",
			"helmet": "helmet_none",
			"accessory": "acc_none"
		},
		{
			"skin": "skin_5",
			"hair_style": "curly",
			"hair_color": "hair_black",
			"suit": "suit_blue",
			"helmet": "helmet_classic",
			"accessory": "acc_star_badge"
		},
		{
			"skin": "skin_1",
			"hair_style": "long",
			"hair_color": "hair_blonde",
			"suit": "suit_green",
			"helmet": "helmet_cat",
			"accessory": "acc_cape"
		},
		{
			"skin": "skin_6",
			"hair_style": "puff",
			"hair_color": "hair_black",
			"suit": "suit_galaxy",
			"helmet": "helmet_none",
			"accessory": "acc_robot_pet"
		},
		{
			"skin": "skin_2",
			"hair_style": "spiky",
			"hair_color": "hair_red",
			"suit": "suit_gold",
			"helmet": "helmet_gold",
			"accessory": "acc_jetpack"
		},
		{
			"skin": "skin_4",
			"hair_style": "bald",
			"hair_color": "hair_blue",
			"suit": "suit_mars",
			"helmet": "helmet_crown",
			"accessory": "acc_planet_pet"
		},
		{
			"skin": "skin_3",
			"hair_style": "short",
			"hair_color": "hair_pink",
			"suit": "suit_moon",
			"helmet": "helmet_antenna",
			"accessory": "acc_medal"
		},
		{
			"skin": "skin_5",
			"hair_style": "long",
			"hair_color": "hair_brown",
			"suit": "suit_saturn",
			"helmet": "helmet_bubble",
			"accessory": "acc_telescope"
		},
		{
			"skin": "skin_2",
			"hair_style": "curly",
			"hair_color": "hair_blonde",
			"suit": "suit_blue",
			"helmet": "helmet_none",
			"accessory": "acc_heart_badge"
		},
	]
	for av in combos:
		out.append(SvgArt.avatar_svg(av, "happy", false))
	for m in ["calm", "sad", "surprised"]:
		out.append(SvgArt.avatar_svg(combos[0], m, false))
	return out


func _characters() -> Array:
	var out := []
	for k in ["cosmo", "robot", "alien", "star", "bip"]:
		for m in ["happy", "sad", "angry", "scared", "surprised", "calm"]:
			out.append(SvgArt.character_svg(k, m, false))
	return out


func _planets() -> Array:
	var out := []
	for id in PlanetView.PRESETS:
		var s: Dictionary = PlanetView.PRESETS[id].duplicate()
		s["face"] = id in ["moon", "mars", "saturn", "sun"]
		out.append(SvgArt.planet_svg(s))
	out.append(SvgArt.planet_svg({"color": "#C77DFF", "color2": "#FF7EB6", "style": "nebula"}))
	out.append(SvgArt.planet_svg({"color": "#9B5DE5", "color2": "#F15BB5", "style": "dots", "rings": true, "face": true}))
	return out


func _objects() -> Array:
	var out := []
	for k in ["star", "crystal", "rocket", "moon"]:
		out.append(SvgArt.object_svg(k))
	for sh in ["circle", "square", "triangle", "star", "heart", "diamond"]:
		out.append(
			SvgArt.token_svg(
				sh,
				Palette.TOKEN_COLORS[["red", "blue", "yellow", "green", "purple", "orange"][
					["circle", "square", "triangle", "star", "heart", "diamond"].find(sh)
				]]
			)
		)
	return out
