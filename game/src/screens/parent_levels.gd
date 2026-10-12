class_name ParentLevels
extends RefCounted
## Aba "Níveis" da área dos pais: por matéria, onde a trilha está e de onde começar ("começar em: números até
## 1000 / tabuada / dígrafos"). Trocar o ponto de partida não apaga nada: fases já feitas continuam com as
## estrelas; as antes do ponto ficam passadas; voltar para "Do começo" reabre as que nunca foram jogadas.

const AREAS := ["math", "reading", "logic"]


static func build(body: VBoxContainer, refresh: Callable) -> void:
	body.add_child(_txt("Cada matéria tem uma trilha de fases. A criança avança sozinha (acertou tudo de primeira, " +
		"pula a fase seguinte) e pode fazer o teste para pular. Aqui você escolhe o ponto de partida: o que vem antes " +
		"fica como já sabido, sem apagar nada do que foi feito.", 20, Palette.TEXT_SOFT))
	for area in AREAS:
		var ns := Stages.nodes(area)
		if ns.is_empty():
			continue
		var ni := Stages.next_index(area)
		var where := "matéria completa"
		if ni < ns.size():
			var les: Dictionary = ContentService.repo.lessons.get(str(ns[ni]["id"]), {})
			where = "fase %d de %d — %s" % [ni + 1, ns.size(), str(les.get("name", ""))]
		body.add_child(_txt("%s: %s" % [Areas.NAMES[area], where], 26, Palette.WHITE))
		var h := HFlowContainer.new()
		h.add_theme_constant_override("h_separation", 8)
		h.add_theme_constant_override("v_separation", 8)
		var cur := LevelPlan.start_id(area)
		h.add_child(UI.label("Começar em:", 22, Palette.TEXT_SOFT))
		for s in LevelPlan.starts(area):
			var sid := str(s[1])
			if sid != "" and not ContentService.repo.lessons.has(sid):
				continue
			var b := UI.button(str(s[0]), Palette.TEAL if sid == cur else Palette.PANEL_LIGHT, "", Vector2(250, 58), false, 19)
			b.name = "Start_%s_%s" % [area, sid if sid != "" else "inicio"]
			b.tapped.connect(func():
				LevelPlan.set_start(area, sid)
				refresh.call())
			h.add_child(b)
		body.add_child(h)
	body.add_child(_txt("Contas no voo e no treino: nível %d de %d." % [Stages.math_level(), EndlessGen.MAX], 22, Palette.TEXT_SOFT))


static func _txt(s: String, fs: int, c: Color) -> Label:
	var l := UI.label(s, fs, c)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l
