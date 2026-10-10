class_name ArcadeCousin
extends Node2D
## Priminho no Voo Livre (pedido do Andro, 10/10): Vini, Manuzita, Enzo e Aylinha aparecem de vez em quando numa
## bolha numa faixa. Quem joga decide se vale ir buscar (às vezes tem pedra na frente). Resgatado, ele voa de ala
## ao lado da nave por alguns segundos e traz o poder dele. Só aparece quem tem foto no pacote (o APK público não
## tem as dos convidados) e nunca a própria criança que está jogando.

## Poder de cada um: Manuzita = escudo (segura 1 pedrada), Enzo = ímã, Aylinha = estrelas em dobro, Vini = turbo.
const POWER := {"manuzita": "shield", "enzo": "magnet", "aylinha": "double", "vini": "turbo"}
const WING_SECONDS := 10.0
const COLORS := {"vini": "#3B82F6", "manuzita": "#A78BFA", "enzo": "#F59E0B", "aylinha": "#22C55E"}

var kid := ""
var flying := false
var _t := 0.0


func _init(id: String) -> void:
	kid = id
	name = "Cousin_%s" % id
	set_meta("kind", "cousin")
	var col := Color(str(COLORS.get(id, "#3B82F6")))
	var bubble := Node2D.new()
	bubble.draw.connect(func():
		bubble.draw_circle(Vector2.ZERO, 62.0, Color(col, 0.28))
		bubble.draw_arc(Vector2.ZERO, 62.0, 0.0, TAU, 40, Color(col.lightened(0.4), 0.95), 6.0, true)
		bubble.draw_arc(Vector2.ZERO, 48.0, PI * 1.1, PI * 1.45, 10, Color(1, 1, 1, 0.6), 5.0, true))
	add_child(bubble)
	var face := Sprite2D.new()
	face.texture = load(Kids.head_path("big_smile", id))
	var k := 92.0 / face.texture.get_height()
	face.scale = Vector2(k, k)
	add_child(face)
	var nl := UI.label(Kids.name_of(id), 28, Color.WHITE, true)
	nl.size = Vector2(200, 40)
	nl.position = Vector2(-100, 62)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.add_theme_constant_override("outline_size", 8)
	nl.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.15))
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.child_ok(nl)  # nome do primo: ele lê
	add_child(nl)
	Fx.glow(self, Vector2.ZERO, 200, Color(col, 0.5), 1.0).z_index = -1


## Quem pode aparecer agora: tem foto no pacote e não é quem está jogando.
static func pool() -> Array:
	var out: Array = []
	for k in Kids.available():
		if str(k[0]) != SaveService.profile_id:
			out.append(str(k[0]))
	return out


## Fala do resgate (sem "Vini" no texto: a voz trocaria pelo nome de quem joga).
static func rescue_line(id: String) -> String:
	match id:
		"manuzita":
			return Lines.c("Resgatou a Manuzita! Ela protege a nave com um escudo!")
		"enzo":
			return Lines.c("Resgatou o Enzo! Ele puxa as estrelas com o ímã!")
		"aylinha":
			return Lines.c("Resgatou a Aylinha! Agora cada estrela vale duas!")
	return Lines.c("Resgatou o seu primo comandante! Turbo de família!")


## Depois do resgate: vira ala, voando acima e atrás da nave, balançando.
func start_wing() -> void:
	flying = true
	scale = Vector2.ONE * 0.75
	_t = 0.0


func follow(ship_pos: Vector2, delta: float) -> bool:
	_t += delta
	var goal := ship_pos + Vector2(-150, -110 if ship_pos.y > 300 else 110) + Vector2(0, sin(_t * 4.0) * 8.0)
	position = position.lerp(goal, minf(1.0, delta * 6.0))
	if _t >= WING_SECONDS:
		var tw := create_tween()
		tw.tween_property(self, "position", position + Vector2(-500, -260), 0.8).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(self, "modulate:a", 0.0, 0.8)
		tw.tween_callback(queue_free)
		return false
	return true
