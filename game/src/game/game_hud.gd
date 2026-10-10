class_name GameHud
extends CanvasLayer
## HUD sem texto: casa (sair), alto-falante (repetir instrução), contador e progresso da missão.

signal home_pressed
signal speak_pressed

const EDGE := 24.0
## Botões redondos do HUD (casa, alto-falante): maiores para dedo de criança (antes 92).
const BTN := 116.0

var counter_icon := ""
var root: Control
## Caixa 1280×720 centrada na tela: o que foi desenhado nas coordenadas do jogo (1280 de largura) fica no
## centro também em celular largo (2340×1080 vira 1560 de largura). Use para tudo que não é canto de tela.
var stage: Control
var _counter_label: Label
var _counter_box: Control
var _pips: HBoxContainer


func _ready() -> void:
	layer = 5
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	stage = Control.new()
	stage.name = "Stage"
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.set_anchors_preset(Control.PRESET_CENTER)
	stage.offset_left = -640
	stage.offset_right = 640
	stage.offset_top = -360
	stage.offset_bottom = 360
	root.add_child(stage)
	var home := DSButton.new("icon", "home", Vector2(BTN, BTN))
	home.name = "HomeButton"
	var inset := safe_x(get_viewport())
	home.position = Vector2(EDGE + inset.x, 16)
	home.pressed.connect(func(): home_pressed.emit())
	root.add_child(home)
	var spk := DSButton.new("icon", "speaker", Vector2(BTN, BTN), "purple")
	spk.name = "SpeakButton"
	spk.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	spk.position = Vector2(-BTN - EDGE - inset.y, 16)
	spk.pressed.connect(func(): speak_pressed.emit())
	root.add_child(spk)
	_pips = HBoxContainer.new()
	_pips.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_pips.position = Vector2(-150, 26)
	_pips.size = Vector2(300, 40)
	_pips.alignment = BoxContainer.ALIGNMENT_CENTER
	_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_pips)
	_counter_box = HBoxContainer.new()
	_counter_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_counter_box.position = Vector2(-BTN - EDGE - inset.y - 18 - 240, 28)
	_counter_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_counter_box.visible = false
	root.add_child(_counter_box)


func set_progress(step: int, total: int) -> void:
	UI.clear(_pips)
	if total <= 1:
		return
	for i in total:
		var d := IconDraw.new("star", Palette.YELLOW if i < step else (Color.WHITE if i == step else Color(1, 1, 1, 0.3)))
		d.custom_minimum_size = Vector2(38, 38)
		_pips.add_child(d)


## Contador grande (ex.: cristais 3/5) com ícone ilustrado.
func set_counter(icon_group: String, icon: String, value: int, target: int = -1) -> void:
	_counter_box.visible = true
	if _counter_box.get_child_count() == 0:
		# Chip do design system: fundo 9-slice + ícone ilustrado + numeral.
		var chip := Control.new()
		chip.custom_minimum_size = Vector2(240, 92)
		chip.size = chip.custom_minimum_size
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bgc := DS.nine("chip", "gold")
		chip.add_child(bgc)
		DS.fit(bgc, chip.size)
		var ic := ArtSprite.new(icon_group, icon, 74.0)
		ic.position = Vector2(48, 46)
		chip.add_child(ic)
		_counter_label = Label.new()
		_counter_label.add_theme_font_override("font", DS.font("body", 900))
		_counter_label.add_theme_font_size_override("font_size", 52)
		_counter_label.add_theme_color_override("font_color", DS.STAR_GOLD)
		_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_counter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_counter_label.position = Vector2(88, 0)
		_counter_label.size = Vector2(146, 92)
		UI.child_ok(_counter_label)
		chip.add_child(_counter_label)
		_counter_box.add_child(chip)
	_counter_label.text = str(value) if target < 0 else "%d/%d" % [value, target]
	var tw := _counter_label.create_tween()
	_counter_label.pivot_offset = _counter_label.size / 2
	tw.tween_property(_counter_label, "scale", Vector2(1.3, 1.3), 0.08)
	tw.tween_property(_counter_label, "scale", Vector2.ONE, 0.15)


## Recorte da câmera/cantos do celular (em unidades do viewport): [esquerda, direita]. Zero no PC.
static func safe_x(vp: Viewport) -> Vector2:
	var ss := DisplayServer.screen_get_size()
	var sa := DisplayServer.get_display_safe_area()
	if vp == null or ss.x <= 0 or sa.size.x <= 0:
		return Vector2.ZERO
	var k := vp.get_visible_rect().size.x / float(ss.x)
	return Vector2(maxf(sa.position.x, 0.0) * k, maxf(ss.x - sa.end.x, 0.0) * k)


## Centro do ícone do contador (tela): para a estrela "voar" até ele.
func counter_point() -> Vector2:
	return _counter_box.get_global_rect().position + Vector2(48, 46)


## Pulinho no contador quando chega ponto.
func bump_counter() -> void:
	_counter_box.pivot_offset = _counter_box.size / 2.0
	var tw := _counter_box.create_tween()
	tw.tween_property(_counter_box, "scale", Vector2.ONE * 1.18, 0.08)
	tw.tween_property(_counter_box, "scale", Vector2.ONE, 0.14)
