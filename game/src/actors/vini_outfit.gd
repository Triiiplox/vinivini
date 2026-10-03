class_name ViniOutfit
extends RefCounted
## Veste o Vini (CharacterRig2D) com o avatar salvo: cor do traje (shader), capacete de vidro pintado com
## variações e acessórios. Itens = content/rewards/items.json; ids sem visual próprio caem no padrão.

const SUITS := {
	"suit_blue": [], "suit_orange": ["#9A3412", "#FDBA74"], "suit_green": ["#166534", "#4ADE80"],
	"suit_moon": ["#4B5563", "#E5E7EB"], "suit_mars": ["#991B1B", "#FB923C"], "suit_saturn": ["#854D0E", "#FDE68A"],
	"suit_galaxy": ["#5B21B6", "#F472B6"], "suit_gold": ["#92400E", "#FACC15"],
}
const HELMETS := ["helmet_classic", "helmet_bubble", "helmet_antenna", "helmet_cat", "helmet_crown", "helmet_gold",
	"helmet_visor"]
## Partes do corpo que levam a cor do traje (a cabeça não).
const BODY := ["torso", "torso_think", "torso_point", "hand_think", "pad_r", "pad_l", "arm_r_up", "arm_r_lo",
	"arm_l_up", "arm_l_lo", "thigh_r", "thigh_l", "shin_r", "shin_l"]
## Capacete em coordenadas do osso da cabeça (medido na cabeça pintada: largura ~261, queixo em y≈6).
const HELMET_POS := Vector2(-4.6, -53.0)
const HELMET_SCALE := 1.75
const EXTRA_GROUP := "vini_outfit_extra"


static func apply(rig: CharacterRig2D, av: Dictionary) -> void:
	if rig == null or rig.sprites.is_empty():
		return
	for n in rig.get_tree().get_nodes_in_group(EXTRA_GROUP) if rig.is_inside_tree() else []:
		if rig.is_ancestor_of(n):
			n.queue_free()
	_suit(rig, str(av.get("suit", "suit_blue")))
	_helmet(rig, str(av.get("helmet", "helmet_none")), str(av.get("suit", "suit_blue")))
	_accessory(rig, str(av.get("accessory", "acc_none")))


static func _material(cols: Array) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://assets/shaders/suit_recolor.gdshader")
	m.set_shader_parameter("navy_to", Color(str(cols[0])))
	m.set_shader_parameter("glow_to", Color(str(cols[1])))
	m.set_shader_parameter("amount", 1.0)
	return m


static func _suit(rig: CharacterRig2D, id: String) -> void:
	var cols: Array = SUITS.get(id, [])
	var mat: ShaderMaterial = null if cols.is_empty() else _material(cols)
	for n in BODY:
		if rig.sprites.has(n):
			(rig.sprites[n] as Sprite2D).material = mat


static func _tag(n: Node) -> Node:
	n.add_to_group(EXTRA_GROUP)
	return n


static func _helmet(rig: CharacterRig2D, id: String, suit: String) -> void:
	if not HELMETS.has(id) or not rig.bones.has("head"):
		return
	var head: Bone2D = rig.bones["head"]
	var k := HELMET_SCALE * (1.08 if id == "helmet_bubble" else 1.0)
	var pos := HELMET_POS + (Vector2(0, -12) if id == "helmet_bubble" else Vector2.ZERO)
	# Vidro sem cor (o rosto aparece igual); só o colar leva a cor do traje (ou dourado).
	var h: Sprite2D = null
	for part in ["helmet_glass", "helmet_collar"]:
		var sp := Sprite2D.new()
		sp.texture = load("res://assets/characters/vini/acc/%s.png" % part)
		sp.scale = Vector2(k, k)
		sp.position = pos
		sp.z_index = 13
		sp.z_as_relative = false
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		if part == "helmet_collar":
			if id == "helmet_gold":
				sp.material = _material(["#92400E", "#FACC15"])
			elif SUITS.has(suit) and not (SUITS[suit] as Array).is_empty():
				sp.material = _material(SUITS[suit])
		else:
			h = sp
			if id == "helmet_visor":
				# Viseira dourada de verdade (camada de ouro que protege do Sol): esconde o rosto.
				sp.texture = load("res://assets/characters/vini/acc/helmet_visor.png")
		head.add_child(_tag(sp))
	var top := h.position.y - h.texture.get_height() * k / 2.0
	match id:
		"helmet_antenna":
			var ant := Line2D.new()
			ant.points = PackedVector2Array([Vector2(60, top + 30), Vector2(80, top - 50)])
			ant.width = 7.0
			ant.default_color = Color("#CBD5E1")
			ant.z_index = 14
			ant.z_as_relative = false
			head.add_child(_tag(ant))
			var ball := _disc(Vector2(80, top - 56), 16.0, Color("#F472B6"))
			head.add_child(_tag(ball))
		"helmet_cat":
			for sx in [-1.0, 1.0]:
				var ear := _shaded([Vector2(sx * 70, top + 46), Vector2(sx * 132, top - 26), Vector2(sx * 146, top + 76)],
					Color("#F8FAFC"), Color("#94A3B8"))
				head.add_child(_tag(ear))
				var inner := _shaded([Vector2(sx * 92, top + 50), Vector2(sx * 128, top + 4), Vector2(sx * 134, top + 62)],
					Color("#FBCFE8"), Color("#F472B6"))
				head.add_child(_tag(inner))
		"helmet_crown":
			var w := 110.0
			var cr := _shaded([Vector2(-w, top + 22), Vector2(-w, top - 40), Vector2(-w * 0.5, top - 4), Vector2(0, top - 62),
				Vector2(w * 0.5, top - 4), Vector2(w, top - 40), Vector2(w, top + 22)], Color("#FDE68A"), Color("#B45309"))
			head.add_child(_tag(cr))
			for jx in [-0.62, 0.0, 0.62]:
				head.add_child(_tag(_disc(Vector2(jx * w, top + 4), 10.0, Color("#EF4444") if jx == 0.0 else Color("#22D3EE"))))


## Polígono com degradê de cima para baixo e contorno escuro (leitura parecida com a arte pintada).
static func _shaded(pts: Array, top_col: Color, bottom_col: Color) -> Node2D:
	var root := Node2D.new()
	root.z_index = 14
	root.z_as_relative = false
	var poly := Polygon2D.new()
	var arr := PackedVector2Array(pts)
	poly.polygon = arr
	var ys: Array = pts.map(func(p): return p.y)
	var lo: float = ys.min()
	var hi: float = ys.max()
	var cols := PackedColorArray()
	for p in pts:
		cols.append(top_col.lerp(bottom_col, (p.y - lo) / maxf(1.0, hi - lo)))
	poly.vertex_colors = cols
	root.add_child(poly)
	var line := Line2D.new()
	line.points = arr + PackedVector2Array([arr[0]])
	line.width = 4.0
	line.default_color = Color(0.1, 0.12, 0.25, 0.8)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	root.add_child(line)
	return root


static func _disc(c: Vector2, r: float, col: Color) -> Polygon2D:
	var p := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 20:
		pts.append(c + Vector2.from_angle(TAU * i / 20.0) * r)
	p.polygon = pts
	p.color = col
	p.z_index = 14
	p.z_as_relative = false
	return p


static func _accessory(rig: CharacterRig2D, id: String) -> void:
	var torso: Bone2D = rig.bones.get("torso")
	if torso == null:
		return
	match id:
		"acc_jetpack":
			for sx in [-1.0, 1.0]:
				var bp := Sprite2D.new()
				bp.texture = load("res://assets/characters/vini/acc/backpack.png")
				bp.scale = Vector2(1.35, 1.35)
				bp.position = Vector2(sx * 178, -110)
				bp.flip_h = sx > 0
				bp.z_index = 3
				bp.z_as_relative = false
				torso.add_child(_tag(bp))
		"acc_cape":
			var cape := _shaded([Vector2(-150, -210), Vector2(150, -210), Vector2(215, 40), Vector2(0, 75), Vector2(-215, 40)],
				Color("#EF4444"), Color("#7F1D1D"))
			cape.z_index = 0
			torso.add_child(_tag(cape))
		"acc_heart_badge":
			var hb := Polygon2D.new()
			var pts := PackedVector2Array()
			for i in 36:
				var t := TAU * i / 36.0
				pts.append(Vector2(16.0 * pow(sin(t), 3), -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))) * 2.2)
			hb.polygon = pts
			hb.color = Color("#F43F5E")
			hb.position = Vector2(-62, -150)
			hb.z_index = 8
			hb.z_as_relative = false
			torso.add_child(_tag(hb))
		"acc_medal", "acc_telescope":
			var md := ArtSprite.new("ui", "medal", 70.0)
			md.position = Vector2(-62, -145)
			md.z_index = 8
			md.z_as_relative = false
			torso.add_child(_tag(md))
		"acc_robot_pet":
			var rb := NpcActor.new("robot", "happy", 120.0)
			rb.position = Vector2(-330, -420)
			rb.floating = true
			rig.get_node("Body").add_child(_tag(rb))
		"acc_planet_pet":
			var pl := ShaderPlanet.new("saturn", 40.0)
			pl.position = Vector2(300, -620)
			rig.get_node("Body").add_child(_tag(pl))
