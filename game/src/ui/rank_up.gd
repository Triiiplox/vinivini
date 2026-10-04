class_name RankUp
extends Control
## Promoção de patente (ADR-036): tela escurece, a insígnia nova cresce no meio com estrelas, o Astro anuncia.
## Ligada a fases concluídas (mestria), nunca a tempo de jogo ou compra. Toque fecha antes da hora.


## Mostra sobre `parent` e devolve quanto tempo a cena dura.
static func present(parent: Control, idx: int) -> float:
	var ru := RankUp.new()
	ru.name = "RankUp"
	ru.set_anchors_preset(Control.PRESET_FULL_RECT)
	ru.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(ru)
	return ru._play(idx)


func _play(idx: int) -> float:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.1, 0.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	create_tween().tween_property(dim, "color:a", 0.78, 0.3)
	var badge := RankBadge.new(idx)
	badge.size = Vector2(300, 300)
	badge.pivot_offset = badge.size / 2.0
	var vp := get_viewport_rect().size
	badge.position = Vector2(vp.x / 2.0, vp.y * 0.44) - badge.size / 2.0
	badge.scale = Vector2.ZERO
	add_child(badge)
	var tw := create_tween()
	tw.tween_interval(0.25)
	tw.tween_property(badge, "scale", Vector2.ONE * 1.15, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(badge, "scale", Vector2.ONE, 0.2)
	var lbl := UI.label(Stages.rank_name(idx), 54, Palette.YELLOW)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = Vector2(vp.x, 80)
	lbl.position = Vector2(0, vp.y * 0.72)
	UI.child_ok(lbl)
	lbl.modulate.a = 0.0
	add_child(lbl)
	create_tween().tween_property(lbl, "modulate:a", 1.0, 0.4).set_delay(0.6)
	AudioService.play_sfx("fanfare")
	if is_instance_valid(Router.fx):
		Router.fx.celebrate("epic")
	var d := Voice.cosmo(_line(idx))
	var total := maxf(3.2, d + 1.2)
	get_tree().create_timer(total).timeout.connect(_close)
	return total


func _gui_input(e: InputEvent) -> void:
	if (e is InputEventScreenTouch or e is InputEventMouseButton) and e.pressed:
		_close()


func _close() -> void:
	if is_queued_for_deletion():
		return
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)


## Uma fala por patente (literais: o gerador de voz colhe cada uma).
static func _line(idx: int) -> String:
	match idx:
		1:
			return Lines.c("Promoção! Agora você é Aprendiz de Piloto!")
		2:
			return Lines.c("Promoção! Agora você é Piloto!")
		3:
			return Lines.c("Promoção! Agora você é Navegador! Você sabe achar o caminho!")
		4:
			return Lines.c("Promoção! Agora você é Tenente!")
		5:
			return Lines.c("Promoção! Agora você é Capitão da nave!")
		6:
			return Lines.c("Promoção! Agora você é Comandante!")
		7:
			return Lines.c("Promoção! Agora você é Almirante! Que jornada!")
		8:
			return Lines.c("Promoção máxima! Você é o Comandante das Estrelas!")
	return Lines.c("Promoção! Você subiu de patente!")
