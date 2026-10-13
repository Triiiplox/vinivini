extends TestNodeCase
## Celular + controle (13/10): a TCL do Andro só tem OpenGL ES 2 (o Godot 4 não roda nela); o Vini joga no celular
## espelhado na TV com o DualSense pareado no celular. O modo controle liga sozinho com um botão do controle e a
## estrela some quando alguém toca na tela.


func test_phone_pad_turns_on_with_controller() -> void:
	var was := Pad.enabled
	Pad._set_enabled(false)
	check(not Pad.enabled, "celular sem controle: modo controle desligado")
	var b := InputEventJoypadButton.new()
	b.button_index = JOY_BUTTON_A
	b.pressed = false
	Pad._input(b)
	check(Pad.enabled, "botão do controle: modo controle liga sozinho")
	check(not Pad._touched, "estrela visível depois do controle")
	var t := InputEventScreenTouch.new()
	t.pressed = true
	Pad._input(t)
	check(Pad._touched, "tocou na tela: a estrela sai do caminho")
	Pad._process(0.016)
	check(not Pad._star.visible, "estrela escondida enquanto usa o dedo")
	Pad._input(b)
	check(not Pad._touched, "mexeu no controle de novo: estrela volta")
	Pad._set_enabled(was)
