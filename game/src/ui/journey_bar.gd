class_name JourneyBar
extends Control
## Barra da jornada (para a criança, sem texto para ler): uma trilha com o planeta de cada campanha e o foguete
## na posição das missões já feitas. O planeta acende quando a campanha termina. À direita, as estrelas ganhas.
## animate_from(done_antes) faz o foguete avançar (tela de recompensa de missão nova).

signal tapped

const W := 600.0
const H := 76.0
const PAD := 46.0

var stats: Dictionary = {}
var shown := 0.0
var _rocket: Node2D
var _planets: Array[Node2D] = []


## {done, total, stars, marks: [{f, planet, done}]} — f = fração da trilha onde a campanha termina.
static func compute() -> Dictionary:
	var repo := ContentService.repo
	var done_map: Dictionary = SaveService.progress.data(SaveService.profile_id)["missions_done"]
	var total := 0
	var done := 0
	var stars := 0
	var ends: Array = []
	for c in repo.campaigns:
		var all_done := true
		for mid in c["missions"]:
			if not repo.missions.has(mid):
				continue
			total += 1
			if done_map.has(mid):
				done += 1
				stars += int(done_map[mid])
			else:
				all_done = false
		ends.append({"n": total, "planet": str(c.get("planet", "earth")), "done": all_done})
	var marks: Array = []
	for e in ends:
		marks.append({"f": float(e["n"]) / maxf(1.0, float(total)), "planet": e["planet"], "done": e["done"]})
	return {"done": done, "total": total, "stars": stars, "marks": marks}


func _init() -> void:
	name = "JourneyBar"
	custom_minimum_size = Vector2(W, H)
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	stats = compute()
	shown = _fraction(int(stats["done"]))
	for m in stats["marks"]:
		var p := ShaderPlanet.new(str(m["planet"]), 17.0)
		p.position = Vector2(_x(float(m["f"])), H * 0.5)
		p.modulate = Color.WHITE if bool(m["done"]) else Color(0.45, 0.45, 0.6, 0.85)
		add_child(p)
		_planets.append(p)
	_rocket = Node2D.new()
	var art := ArtSprite.new("props", "ship_side", 64.0)
	art.idle = "float"
	_rocket.add_child(art)
	_rocket.position = Vector2(_x(shown), H * 0.5 - 4)
	add_child(_rocket)
	var star := ArtSprite.new("props", "star_token", 40.0)
	star.position = Vector2(W + 34, H * 0.5)
	add_child(star)
	var lbl := UI.label(str(int(stats["stars"])), 30, DS.STAR_GOLD)
	lbl.name = "StarCount"
	lbl.set_meta("child_text_ok", true)  # só número (contador), como o placar da HUD
	lbl.position = Vector2(W + 58, H * 0.5 - 22)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)


func _fraction(done: int) -> float:
	return clampf(float(done) / maxf(1.0, float(stats.get("total", 1))), 0.0, 1.0)


func _x(f: float) -> float:
	return PAD + f * (W - PAD * 2.0)


## Mostra o foguete saindo de done_before e indo até o progresso atual.
func animate_from(done_before: int) -> void:
	if not is_node_ready():
		ready.connect(animate_from.bind(done_before), CONNECT_ONE_SHOT)
		return
	var target := shown
	shown = _fraction(done_before)
	_rocket.position.x = _x(shown)
	queue_redraw()
	var tw := create_tween()
	tw.tween_interval(0.6)
	tw.tween_method(_set_shown, shown, target, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func(): AudioService.play_sfx("unlock"))


func _set_shown(f: float) -> void:
	shown = f
	_rocket.position.x = _x(f)
	queue_redraw()


func _draw() -> void:
	draw_style_box(UITheme.rounded(Color(DS.SPACE_DARK, 0.72), int(H * 0.5), 3, Color(DS.STAR_GOLD, 0.55)), Rect2(Vector2.ZERO, size))
	var y := H * 0.5
	draw_line(Vector2(_x(0.0), y), Vector2(_x(1.0), y), Color(1, 1, 1, 0.22), 10.0, true)
	if shown > 0.0:
		draw_line(Vector2(_x(0.0), y), Vector2(_x(shown), y), DS.STAR_GOLD, 10.0, true)
	draw_circle(Vector2(_x(0.0), y), 9.0, DS.STAR_GOLD)


func _gui_input(e: InputEvent) -> void:
	var press: bool = (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed)
	if not press:
		return
	accept_event()
	var tw := _rocket.create_tween()
	tw.tween_property(_rocket, "position:y", H * 0.5 - 26, 0.15).set_ease(Tween.EASE_OUT)
	tw.tween_property(_rocket, "position:y", H * 0.5 - 4, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	AudioService.play_sfx("tap")
	tapped.emit()
