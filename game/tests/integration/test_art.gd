extends TestCase
## Toda arte vetorial compõe um SVG válido e rasterizável (nenhum item/expressão quebrado).


func _ok(svg: String, vb_w: float, what: String) -> void:
	var img := Image.new()
	var err := img.load_svg_from_string(svg, 64.0 / vb_w)
	check(err == OK and img.get_width() > 0, "SVG inválido: %s" % what)
	check(not svg.contains("{") and not svg.contains("}"), "placeholder sem cor em %s" % what)


func test_every_avatar_option_and_item() -> void:
	var base := ProfileRepository.default_avatar()
	var repo := ContentService.repo
	for group in ["skin", "hair_style", "hair_color"]:
		for o in repo.avatar_options[group]:
			var av := base.duplicate()
			av[group] = o["id"]
			_ok(SvgArt.avatar_svg(av, "happy", false), 400, "%s=%s" % [group, o["id"]])
	for it in repo.items:
		var av := base.duplicate()
		av[it["slot"]] = it["id"]
		_ok(SvgArt.avatar_svg(av, "happy", false), 400, it["id"])
	for m in ["happy", "calm", "sad", "angry", "scared", "surprised"]:
		_ok(SvgArt.avatar_svg(base, m, false), 400, "avatar " + m)
	_ok(SvgArt.avatar_svg(base, "happy", true), 400, "avatar piscando")


func test_every_character_and_mood() -> void:
	for k in ["cosmo", "robot", "alien", "star", "bip"]:
		for m in ["happy", "calm", "sad", "angry", "scared", "surprised", "talk"]:
			_ok(SvgArt.character_svg(k, m, false), 300, "%s/%s" % [k, m])
		_ok(SvgArt.character_svg(k, "happy", true), 300, "%s piscando" % k)


func test_planets_objects_tokens_background() -> void:
	for id in PlanetView.PRESETS:
		_ok(SvgArt.planet_svg(PlanetView.PRESETS[id]), 240, id)
	for p in ContentService.repo.planets:
		_ok(SvgArt.planet_svg(p["visual"]), 240, p["id"])
	for st in ["plain", "stripes", "dots", "craters"]:
		_ok(SvgArt.planet_svg({"color": "#FF8C42", "color2": "#FFD23F", "style": st, "rings": true, "face": true}), 240, "lab " + st)
	for k in ["star", "crystal", "rocket", "moon"]:
		_ok(SvgArt.object_svg(k), 100, k)
	for shape in ContentValidator.SHAPES:
		for c in Palette.TOKEN_COLORS:
			_ok(SvgArt.token_svg(shape, Palette.TOKEN_COLORS[c]), 100, "%s_%s" % [shape, c])
	_ok(SvgArt.background_svg(), 1280, "fundo")
