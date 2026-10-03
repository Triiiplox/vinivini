extends BaseScreen
## Porta dos responsáveis: multiplicação simples que uma criança de 4 anos não resolve sozinha.

var a := 0
var b := 0
var typed := ""
var display: Label
var question: Label
var rng := RandomNumberGenerator.new()


func on_enter() -> void:
	rng.randomize()
	build_frame("Área dos responsáveis", "back", false, false)
	content.add_child(UI.label("Esta área é para adultos.", 28, Palette.TEXT_SOFT))
	question = UI.label("", 48, Palette.WHITE, true)
	content.add_child(question)
	var dp := UI.panel(Palette.WHITE, 20)
	dp.custom_minimum_size = Vector2(260, 80)
	dp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(dp)
	display = UI.label("", 48, Palette.TEXT_DARK, true)
	display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dp.add_child(display)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(grid)
	for d in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "<", "OK"]:
		var k := UI.button(d, Palette.GREEN if d == "OK" else Palette.PANEL_LIGHT, "", Vector2(110, 84), false, 38)
		k.name = "Key_%s" % d
		k.tapped.connect(_key.bind(d))
		grid.add_child(k)
	_new_question()


func _new_question() -> void:
	a = rng.randi_range(6, 9)
	b = rng.randi_range(6, 9)
	typed = ""
	question.text = "Quanto é %d × %d?" % [a, b]
	display.text = ""


func _key(d: String) -> void:
	match d:
		"<":
			typed = typed.substr(0, maxi(0, typed.length() - 1))
		"OK":
			if typed.is_valid_int() and int(typed) == a * b:
				Router.replace("parent")
				return
			fx().toast("Resposta incorreta", Palette.PURPLE)
			_new_question()
			return
		_:
			if typed.length() < 3:
				typed += d
	display.text = typed


func answer_for_tests() -> int:
	return a * b
