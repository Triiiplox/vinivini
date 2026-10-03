extends Node
## Navegação entre telas com pilha de histórico e fade.
## Telas são scripts (BaseScreen) instanciados por id; params vão em setup().

signal screen_changed(screen_id: String)

const SCREENS := {
	"splash": "res://src/screens/splash_screen.gd",
	"creator": "res://src/screens/character_creator_screen.gd",
	"intro": "res://src/screens/intro_screen.gd",
	"hub": "res://src/screens/hub_screen.gd",
	"map": "res://src/screens/map_screen.gd",
	"planet": "res://src/screens/planet_screen.gd",
	"activity": "res://src/screens/activity_runner_screen.gd",
	"mission_complete": "res://src/screens/mission_complete_screen.gd",
	"library": "res://src/screens/library_screen.gd",
	"story": "res://src/screens/story_screen.gd",
	"lab": "res://src/screens/lab_screen.gd",
	"observatory": "res://src/screens/observatory_screen.gd",
	"trophies": "res://src/screens/trophy_screen.gd",
	"parent_gate": "res://src/screens/parent_gate_screen.gd",
	"parent": "res://src/screens/parent_dashboard_screen.gd",
}

## Testes ligam isto para trocar de tela sem animação.
var instant := false
## Camada de celebração registrada pelo Main.
var fx: CelebrationLayer = null
var current_screen: Control = null
var current_id := ""
var current_params: Dictionary = {}

var _host: Control = null
var _fader: ColorRect = null
var _stack: Array[Dictionary] = []
var _busy := false


func register_host(host: Control, fader: ColorRect) -> void:
	_host = host
	_fader = fader


func has_host() -> bool:
	return _host != null and is_instance_valid(_host)


## Abre a tela empilhando a atual (botão voltar retorna a ela).
func go(id: String, params: Dictionary = {}) -> void:
	if current_id != "":
		_stack.append({"id": current_id, "params": current_params})
	_show(id, params)


## Troca a tela atual sem empilhar (ex.: atividade -> resultado).
func replace(id: String, params: Dictionary = {}) -> void:
	_show(id, params)


## Limpa o histórico e vai para a nave.
func home() -> void:
	_stack.clear()
	_show("hub", {})


## Reseta a pilha deixando `id` como raiz.
func reset_to(id: String, params: Dictionary = {}) -> void:
	_stack.clear()
	_show(id, params)


func back() -> void:
	if _busy:
		return
	if current_screen and current_screen.has_method("on_back") and current_screen.on_back():
		return
	if _stack.is_empty():
		if current_id != "hub" and current_id != "splash" and current_id != "creator":
			_show("hub", {})
		return
	var prev: Dictionary = _stack.pop_back()
	_show(prev["id"], prev["params"])


func stack_depth() -> int:
	return _stack.size()


func _show(id: String, params: Dictionary) -> void:
	if not SCREENS.has(id):
		GameLog.error("Router", "Tela desconhecida: %s" % id)
		return
	if not has_host():
		GameLog.error("Router", "Host de telas não registrado")
		return
	if instant or _fader == null:
		_swap(id, params)
		return
	if _busy:
		return
	_busy = true
	_fader.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := create_tween()
	t.tween_property(_fader, "color:a", 1.0, 0.14)
	await t.finished
	_swap(id, params)
	var t2 := create_tween()
	t2.tween_property(_fader, "color:a", 0.0, 0.2)
	await t2.finished
	_fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func _swap(id: String, params: Dictionary) -> void:
	if current_screen and is_instance_valid(current_screen):
		if current_screen.has_method("on_exit"):
			current_screen.on_exit()
		current_screen.queue_free()
	if is_instance_valid(fx):
		fx.clear()
	var script: Script = load(SCREENS[id])
	var screen: Control = script.new()
	screen.name = "Screen_%s" % id
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if screen.has_method("setup"):
		screen.setup(params)
	current_screen = screen
	current_id = id
	current_params = params
	_host.add_child(screen)
	if screen.has_method("on_enter"):
		screen.on_enter()
	GameLog.info("Router", "-> %s" % id)
	screen_changed.emit(id)
