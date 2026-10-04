class_name PetActor
extends Node2D
## Mascote que segue o Vini. Com a arte pintada: o cachorrinho Bip e o gato andam no chão ao lado dele
## (de perfil andando, parado olhando para a frente); o Robô Ajudante é um Astro pequeno amarelo, como o
## Honey, um dos três Astrobee (robôs que voam dentro da Estação Espacial). Sem a pintura, os desenhos antigos.
## Origem = centro do corpo.

const PAINTED := "res://assets/art/painted/chars/"
## pet -> [pasta, parado, andando, pulo]
const GROUND := {"pet_bip": ["bip", "three_q", "side", "front"], "pet_cat": ["cat", "sit", "walk", "jump"]}

var height_px := 110.0
var follow: Node2D
var offset := Vector2(-150, -170)
var t := 0.0
var kind := "pet_bip"
var _body: Node2D
var _flip := 1
var _ground := false
var _tex: Dictionary = {}
var _sprite: Sprite2D
var _moving := false
var _trick := false


func _init(h: float = 110.0, k: String = "pet_bip") -> void:
	height_px = h
	kind = k
	var g: Array = GROUND.get(kind, [])
	if not g.is_empty() and ResourceLoader.exists(PAINTED + "%s/%s.png" % [g[0], g[1]]):
		offset = Vector2(-175, -height_px / 2.0)  # no chão, ao lado do Vini


func _ready() -> void:
	var g: Array = GROUND.get(kind, [])
	if not g.is_empty() and ResourceLoader.exists(PAINTED + "%s/%s.png" % [g[0], g[1]]):
		_build_ground(g)
		return
	match kind:
		"pet_robot":
			if ResourceLoader.exists(CosmoRig.PAINTED_DIR + "rig_body.png"):
				var a := CosmoRig.new(height_px * 1.1)
				a.modulate = Color(1.0, 0.9, 0.55)
				_body = a
			else:
				var r := NpcActor.new("robot", "happy", height_px * 1.1)
				r.floating = true
				_body = r
		"pet_cat":
			_body = ArtSprite.new("words", "gato", height_px * 1.1)
		_:
			var b := NpcActor.new("bip", "happy", height_px)
			b.floating = true
			_body = b
	add_child(_body)


func _build_ground(g: Array) -> void:
	_ground = true
	for i in [1, 2, 3]:
		_tex[i] = load(PAINTED + "%s/%s.png" % [g[0], g[i]])
	_body = Node2D.new()
	add_child(_body)
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_body.add_child(_sprite)
	_set_pose(1)


## Pose pelo índice (1 parado, 2 andando, 3 pulo), com a altura fixa em height_px e os pés no mesmo lugar.
func _set_pose(i: int) -> void:
	var tex: Texture2D = _tex[i]
	_sprite.texture = tex
	var k := height_px / float(tex.get_height())
	if i == 2:
		k *= 0.92  # de perfil o corpo é mais comprido; um pouco menor para ocupar o mesmo espaço
	_sprite.scale = Vector2(k, k)
	_sprite.position.y = height_px / 2.0 - tex.get_height() * k / 2.0


func _process(delta: float) -> void:
	t += delta
	if not _ground:
		_body.position.y = sin(t * 3.0) * 6.0
	if follow and is_instance_valid(follow):
		var face := 1
		if "facing" in follow:
			face = int(follow.facing)
		var target := follow.position + Vector2(offset.x * face, offset.y)
		position = position.lerp(target, minf(1.0, delta * 2.5))
		var dir := 1 if target.x >= position.x - 4 else -1
		if dir != _flip and absf(target.x - position.x) > 20:
			_flip = dir
		if _ground:
			_walk_anim(absf(target.x - position.x) > 14.0)
		scale.x = absf(scale.x) * _flip


func _walk_anim(moving: bool) -> void:
	if _trick:
		return
	if moving != _moving:
		_moving = moving
		_set_pose(2 if moving else 1)
	# andando: passinhos (sobe e desce); parado: respira
	_body.position.y = -absf(sin(t * 11.0)) * 7.0 if moving else 0.0
	_body.scale.y = 1.0 if moving else 1.0 + 0.015 * sin(t * 2.2)


func flip_trick() -> void:
	if _ground:
		if _trick:
			return
		_trick = true
		_set_pose(3)
		var tw := create_tween()
		tw.tween_property(_body, "position:y", -height_px * 0.6, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(_body, "rotation", -0.25 * _flip, 0.22)
		tw.tween_property(_body, "position:y", 0.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(_body, "rotation", 0.0, 0.24)
		tw.tween_callback(func():
			_trick = false
			_moving = false
			_set_pose(1))
		return
	var tw2 := create_tween()
	tw2.tween_property(self, "rotation", TAU * _flip, 0.6).set_trans(Tween.TRANS_QUAD)
	tw2.tween_callback(func(): rotation = 0.0)
