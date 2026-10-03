class_name SvgArt
extends RefCounted
## Ilustrações vetoriais (assets/art/art.json, gerado por tools/gen_art.py) montadas em camadas,
## com cores resolvidas em runtime e rasterizadas na resolução real da tela.
## Cache LRU + orçamento de rasterizações por frame (telas cheias carregam progressivamente).

const ART_PATH := "res://assets/art/art.json"
const MAX_CACHE := 200
const BUDGET_PER_FRAME := 4

const ART2_PATH := "res://assets/art/art2.json"
static var _art2: Dictionary = {}
static var _art: Dictionary = {}
static var _cache: Dictionary = {}
static var _order: Array[String] = []
static var _frame := -1
static var _spent := 0


static func art() -> Dictionary:
	if _art.is_empty():
		var f := FileAccess.open(ART_PATH, FileAccess.READ)
		if f:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_art = d
	return _art


static func hex(c: Color) -> String:
	return "#" + c.to_html(false)


## Cores base/escura/clara para gradientes: {name}, {name_d}, {name_l}.
static func add_shades(colors: Dictionary, name: String, c: Color, dark: float = 0.28, light: float = 0.32) -> void:
	colors[name] = hex(c)
	colors[name + "_d"] = hex(c.darkened(dark))
	colors[name + "_l"] = hex(c.lightened(light))


static func document(viewbox: Array, defs: String, body: String) -> String:
	return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="%s %s %s %s"><defs>%s</defs>%s</svg>' % [
		viewbox[0], viewbox[1], viewbox[2], viewbox[3], defs, body]


## Escala de tela efetiva (stretch + transformações) para rasterizar nítido.
static func screen_scale(ci: CanvasItem) -> float:
	if not ci.is_inside_tree():
		return 1.0
	var s := ci.get_global_transform_with_canvas().get_scale().x
	return absf(s * ci.get_viewport().get_final_transform().get_scale().x)


static func bucket(px: float) -> int:
	return clampi(int(ceil(px / 64.0)) * 64, 64, 2048)


## Retorna textura pronta ou null (se estourou o orçamento deste frame: o chamador redesenha depois).
static func get_texture(key: String, px_width: float, vb_width: float, builder: Callable) -> Texture2D:
	var w := bucket(px_width)
	var k := "%s@%d" % [key, w]
	if _cache.has(k):
		_order.erase(k)
		_order.append(k)
		return _cache[k]
	var frame := Engine.get_process_frames()
	if frame != _frame:
		_frame = frame
		_spent = 0
	if _spent >= BUDGET_PER_FRAME:
		return null
	_spent += 1
	var img := Image.new()
	if img.load_svg_from_string(builder.call(), float(w) / vb_width) != OK:
		push_warning("SvgArt: falha ao rasterizar %s" % key)
		return null
	var tex := ImageTexture.create_from_image(img)
	_cache[k] = tex
	_order.append(k)
	while _order.size() > MAX_CACHE:
		_cache.erase(_order.pop_front())
	return tex


## Desenha a arte encaixada em `rect` (mantém proporção). Retorna false se ainda não está pronta.
static func draw_in(ci: CanvasItem, rect: Rect2, key: String, vb: Array, builder: Callable, modulate: Color = Color.WHITE) -> bool:
	var px := rect.size.x * screen_scale(ci)
	var tex := get_texture(key, px, float(vb[2]), builder)
	if tex == null:
		# Orçamento do frame esgotado: redesenha no próximo frame (conexão some se o nó for liberado).
		var tree := ci.get_tree()
		if tree and not tree.process_frame.is_connected(ci.queue_redraw):
			tree.process_frame.connect(ci.queue_redraw, CONNECT_ONE_SHOT)
		return false
	# O nó guarda referência às texturas que desenhou: o LRU pode descartar do cache sem
	# liberar uma textura que ainda está nos comandos de desenho de um nó que não redesenha.
	var refs: Dictionary = ci.get_meta("svg_refs", {})
	refs.erase(key)
	refs[key] = tex
	while refs.size() > 24:
		refs.erase(refs.keys()[0])
	ci.set_meta("svg_refs", refs)
	ci.draw_texture_rect(tex, rect, false, modulate)
	return true


static func clear_cache() -> void:
	_cache.clear()
	_order.clear()


# ---------------------------------------------------------------- composições

static func avatar_svg(av: Dictionary, mood: String, blink: bool) -> String:
	var a: Dictionary = art()["avatar"]
	var lay: Dictionary = a["layers"]
	var repo := ContentService.repo
	var colors := {}
	add_shades(colors, "skin", _opt_color(repo, "skin", str(av.get("skin", "skin_3")), "#E3A877"), 0.2, 0.25)
	add_shades(colors, "hair", _opt_color(repo, "hair_color", str(av.get("hair_color", "hair_brown")), "#6B4226"), 0.3, 0.35)
	var suit_item := repo.get_item(str(av.get("suit", "suit_orange")))
	add_shades(colors, "suit", Color(str(suit_item.get("color", "#FF8C42"))))
	var helmet := str(repo.get_item(str(av.get("helmet", "helmet_none"))).get("style", "none"))
	var acc := str(repo.get_item(str(av.get("accessory", "acc_none"))).get("style", "none"))
	var hair := str(av.get("hair_style", "short"))
	var dome := helmet in ["classic", "bubble", "antenna", "cat", "gold"]
	if dome and hair == "puff":
		hair = "curly"
	var defs := str(a["defs"])
	var parts: Array[String] = []
	if acc == "cape" or acc == "jetpack":
		parts.append(lay["back_" + acc])
	if lay.has("hair_back_" + hair):
		parts.append(lay["hair_back_" + hair])
	parts.append(lay["legs"])
	parts.append(lay["arms"])
	parts.append(lay["body"])
	if str(suit_item.get("pattern", "")) == "stars":
		parts.append(lay["pattern_stars"])
	parts.append(lay["collar"])
	parts.append(lay["hands"])
	parts.append(lay["head"])
	var face_key := "face_blink" if blink and mood == "happy" else "face_" + (mood if lay.has("face_" + mood) else "happy")
	parts.append(lay[face_key])
	parts.append(lay.get("hair_front_" + hair, ""))
	if lay.has("helmet_" + helmet):
		parts.append(lay["helmet_" + helmet])
	if lay.has("front_" + acc):
		parts.append(lay["front_" + acc])
	if acc == "robot_pet":
		var co: Dictionary = art()["characters"]["kinds"]["cosmo"]
		defs += str(co["defs"])
		parts.append('<g transform="translate(300 -36) scale(0.34)">%s%s</g>' % [co["body"], co["faces"]["happy"]])
	if acc == "planet_pet":
		var pspec := {"color": "#9B5DE5", "color2": "#F15BB5", "style": "dots", "rings": true, "face": true}
		var pc := planet_colors(pspec)
		colors.merge(pc)
		defs += str(art()["planet"]["defs"])
		parts.append('<g transform="translate(300 -26) scale(0.38)">%s</g>' % planet_body(pspec))
	return document(a["viewbox"], defs.format(colors), "".join(parts).format(colors))


static func _opt_color(repo: ContentRepository, group: String, id: String, fallback: String) -> Color:
	for o in repo.avatar_options.get(group, []):
		if o.get("id") == id:
			return Color(str(o.get("color", fallback)))
	return Color(fallback)


static func character_svg(kind: String, mood: String, blink: bool) -> String:
	var chars: Dictionary = art()["characters"]
	var k: Dictionary = chars["kinds"].get(kind, chars["kinds"]["cosmo"])
	var face: String = k["blink"] if blink and mood == "happy" else k["faces"].get(mood, k["faces"]["happy"])
	return document(chars["viewbox"], k["defs"], str(k["body"]) + face)


static func planet_colors(spec: Dictionary) -> Dictionary:
	var c := Color(str(spec.get("color", "#8E7DFF")))
	var c2 := Color(str(spec.get("color2", "#5A4FCF")))
	var colors := {"c": hex(c), "cd": hex(c.darkened(0.35)), "cl": hex(c.lightened(0.4)), "c2": hex(c2),
		"rc": hex(c2.lightened(0.3))}
	var tilt := float(spec.get("ring_tilt", 0.25))
	colors["tilt"] = str(-14.0 if tilt < 1.0 else rad_to_deg(tilt) - 10.0)
	return colors


static func planet_body(spec: Dictionary) -> String:
	var pp: Dictionary = art()["planet"]["parts"]
	var style := str(spec.get("style", "plain"))
	var parts: Array[String] = []
	if style == "nebula":
		return '<defs>%s</defs>%s' % [pp["nebula_defs"], pp["nebula"]]
	if style == "sun":
		parts.append(pp["glow"])
		parts.append(pp["rays"])
	var rings := bool(spec.get("rings", false))
	if rings:
		parts.append(pp["ring_back"])
	parts.append(pp["body"])
	parts.append('<g clip-path="url(#plClip)">%s</g>' % pp.get(style, ""))
	if style != "sun":
		parts.append(pp["shade"])
	parts.append(pp["highlight"])
	parts.append(pp["outline"])
	if bool(spec.get("face", false)) or style == "sun":
		parts.append(pp["face"])
	if rings:
		parts.append(pp["ring_front"])
	return "".join(parts)


static func planet_svg(spec: Dictionary) -> String:
	var p: Dictionary = art()["planet"]
	var colors := planet_colors(spec)
	return document(p["viewbox"], str(p["defs"]).format(colors), planet_body(spec).format(colors))


static func object_svg(kind: String) -> String:
	var o: Dictionary = art()["objects"]
	return document(o["viewbox"], "", str(o["svg"].get(kind, o["svg"]["star"])))


static func token_svg(shape: String, color: Color) -> String:
	var t: Dictionary = art()["tokens"]
	var colors := {"c": hex(color), "cd": hex(color.darkened(0.35)), "cl": hex(color.lightened(0.45))}
	return document(t["viewbox"], "", str(t["svg"].get(shape, t["svg"]["circle"])).format(colors))


static func background_svg() -> String:
	var b: Dictionary = art()["background"]
	return document(b["viewbox"], b["defs"], b["body"])


# ---------------------------------------------------------------- arte v2 (art2.json: rigs, objetos, comidas...)



static func art2() -> Dictionary:
	if _art2.is_empty():
		var f := FileAccess.open(ART2_PATH, FileAccess.READ)
		if f:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_art2 = d
	return _art2


## Item simples de um grupo (props, foods, build, words, npcs, pets). colors resolve {c},{cd},{cl}.
static func item_svg(group: String, name: String, colors: Dictionary = {}) -> String:
	var it: Dictionary = art2().get(group, {}).get(name, {})
	if it.is_empty():
		return ""
	var c := colors.duplicate()
	if not c.has("c"):
		c.merge({"c": "#8E7DFF", "cd": "#5A4FCF", "cl": "#C9C2FF"})
	return document(it["vb"], str(it.get("defs", "")).format(c), str(it["svg"]).format(c))


static func item_vb(group: String, name: String) -> Array:
	return art2().get(group, {}).get(name, {}).get("vb", [0, 0, 100, 100])


static func tint_colors(c: Color) -> Dictionary:
	return {"c": hex(c), "cd": hex(c.darkened(0.35)), "cl": hex(c.lightened(0.4))}


## Cores do avatar (pele, cabelo, traje) para os placeholders.
static func avatar_colors(av: Dictionary) -> Dictionary:
	var repo := ContentService.repo
	var colors := {}
	add_shades(colors, "skin", _opt_color(repo, "skin", str(av.get("skin", "skin_3")), "#E3A877"), 0.2, 0.25)
	add_shades(colors, "hair", _opt_color(repo, "hair_color", str(av.get("hair_color", "hair_brown")), "#6B4226"), 0.3, 0.35)
	var suit_item := repo.get_item(str(av.get("suit", "suit_orange")))
	add_shades(colors, "suit", Color(str(suit_item.get("color", "#FF8C42"))))
	return colors


## Peça do rig do avatar: head | torso | back | leg | arm.
static func avatar_part_svg(part: String, av: Dictionary, mood: String = "happy", blink: bool = false) -> String:
	var rig: Dictionary = art2()["avatar_rig"]
	var spec: Dictionary = rig["parts"][part]
	var base: Dictionary = art()["avatar"]["layers"]
	var extra: Dictionary = rig["layers"]
	var repo := ContentService.repo
	var helmet := str(repo.get_item(str(av.get("helmet", "helmet_none"))).get("style", "none"))
	var acc := str(repo.get_item(str(av.get("accessory", "acc_none"))).get("style", "none"))
	var hair := str(av.get("hair_style", "short"))
	if helmet in ["classic", "bubble", "antenna", "cat", "gold"] and hair == "puff":
		hair = "curly"
	var suit_item := repo.get_item(str(av.get("suit", "suit_orange")))
	var vars := {"hair": hair, "helmet": helmet, "acc": acc, "pattern": str(suit_item.get("pattern", "none")),
		"mood": "blink" if blink and mood == "happy" else mood}
	var parts: Array[String] = []
	for l in spec["layers"]:
		var lname := str(l).format(vars)
		if base.has(lname):
			parts.append(base[lname])
		elif extra.has(lname):
			parts.append(extra[lname])
	var colors := avatar_colors(av)
	return document(spec["vb"], str(art()["avatar"]["defs"]).format(colors), "".join(parts).format(colors))


static func cosmo_part_svg(part: String, mood: String = "happy") -> String:
	var r: Dictionary = art2()["cosmo_rig"]
	var p: Dictionary = r[part]
	var body := str(p["svg"])
	if part == "head":
		body += str(r["faces"].get(mood, r["faces"]["happy"]))
	return document(p["vb"], r["defs"], body)


## Cliente alienígena (cor + humor) para o Restaurante de Marte.
static func customer_svg(color: Color, mood: String) -> String:
	var n: Dictionary = art2()["npcs"]
	var body: Dictionary = n["customer"]
	var c := tint_colors(color)
	var face: String = n["customer_faces"].get(mood, n["customer_faces"]["happy"])
	return document(body["vb"], str(body["defs"]).format(c), str(body["svg"]).format(c) + face)
