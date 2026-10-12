class_name FonoPhoto
extends Control
## Foto do Vini fazendo o exercício (pacote do Andro, 12/10: só os 29 que mostram a posição certa da boca). Repouso e
## pose ficam empilhados e a pose aparece e some no ritmo da contagem (sem rosto duplicado, sem tremida). As fotos
## são da família: ficam em assets/private (só no APK completo). Sem a foto do exercício, a tela usa o FonoFace.

const DIR := "res://assets/private/fono_fotos/%s_%d.png"
const SIZE := Vector2(283, 402)

var weight := 1.0  ## 0 = repouso, 1 = exercício
var _rest: TextureRect
var _pose: TextureRect


static func has(id: String) -> bool:
	return ResourceLoader.exists(DIR % [id, 0]) and ResourceLoader.exists(DIR % [id, 1])


func _ready() -> void:
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rest = _layer()
	_pose = _layer()


func _layer() -> TextureRect:
	var t := TextureRect.new()
	t.size = SIZE
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(t)
	return t


## Mostra o exercício; devolve false se não houver foto dele.
func show_pose(id: String) -> bool:
	if not has(id):
		visible = false
		return false
	_rest.texture = load(DIR % [id, 0])
	_pose.texture = load(DIR % [id, 1])
	weight = 1.0
	visible = true
	return true


func _process(_delta: float) -> void:
	if _pose:
		_pose.modulate.a = clampf(weight, 0.0, 1.0)
