class_name MinigameBase
extends Control
## Contrato dos minigames. O runner conecta `answered`:
## answered(false) = tentativa errada (rodada continua); answered(true) = rodada resolvida.

signal answered(correct: bool)
signal instruction_changed(text: String)

var activity: Dictionary = {}
var support := false
var locked := false
var rng := RandomNumberGenerator.new()


func setup(a: Dictionary, needs_support: bool) -> void:
	activity = a
	support = needs_support
	rng.randomize()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


func instruction() -> String:
	return str(activity.get("instruction", ""))


## Texto falado (pode diferir do exibido, ex.: sílaba em minúscula soa melhor).
func spoken_instruction() -> String:
	return instruction()


func show_hint() -> void:
	pass


## Simula resposta certa/errada pelo mesmo caminho do toque (testes e smoke).
func auto_answer(_correct: bool) -> void:
	pass


func _resolve(correct: bool) -> void:
	if correct:
		locked = true
		AudioService.play_sfx("correct")
	else:
		AudioService.play_sfx("retry")
	answered.emit(correct)


## Grade de botões de resposta numérica/texto.
func option_row(labels: Array, color: Color, min_size: Vector2, fs: int) -> HBoxContainer:
	var row := UI.hbox(28)
	for l in labels:
		var v: Variant = int(l) if (l is float and is_equal_approx(l, roundf(l))) else l
		var b := UI.button(str(v), color, "", min_size, false, fs)
		b.name = "Opt_%s" % str(v)
		b.set_meta("value", v)
		row.add_child(b)
	return row


## Posições espalhadas sem sobreposição dentro de `area` (ou em grade se `tidy`).
func scatter(n: int, area: Vector2, obj: float, tidy: bool) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if tidy:
		var per_row := 5
		var rows := ceili(n / float(per_row))
		var gap := obj * 1.12
		var start := (area - Vector2(mini(n, per_row) * gap, rows * gap)) / 2
		for i in n:
			out.append(start + Vector2((i % per_row) * gap, (i / per_row) * gap))
		return out
	var tries := 0
	while out.size() < n and tries < 4000:
		tries += 1
		var p := Vector2(rng.randf_range(0, maxf(1, area.x - obj)), rng.randf_range(0, maxf(1, area.y - obj)))
		var ok := true
		for q in out:
			if q.distance_to(p) < obj * 1.05:
				ok = false
				break
		if ok:
			out.append(p)
	while out.size() < n:
		out.append(Vector2(rng.randf_range(0, maxf(1, area.x - obj)), rng.randf_range(0, maxf(1, area.y - obj))))
	return out
