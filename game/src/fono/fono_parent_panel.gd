class_name FonoParentPanel
extends RefCounted
## Parte do módulo FALAR na área dos pais (aba Fala): quais sons treinar e em que ordem, a academia da boca
## (exercícios e repetições, como a fono passou) e o histórico para mostrar à fono. Nada sai do aparelho.
## As escolhas ficam nos ajustes (fono_targets, fono_gym, fono_reps, fono_gym_reps); o progresso no perfil (FonoData).
## v2: dose do treino, pares mínimos, sondas, diário e dicas ficam em FonoParentExtra.

const REPS := [10, 15, 20]


static func build(body: VBoxContainer, refresh: Callable) -> void:
	body.add_child(_txt("FALAR — treino de fala em casa", 30, Palette.YELLOW))
	body.add_child(_txt("Siga o que a fonoaudióloga pediu. O adulto confirma cada fala (botões CERTO / QUASE); o " +
		"microfone e a câmera só funcionam na hora, nada é gravado em arquivo nem enviado.", 20, Palette.TEXT_SOFT))
	FonoParentExtra.tips(body)
	_targets(body, refresh)
	FonoParentExtra.dose(body, refresh)
	_gym(body, refresh)
	_report(body)
	FonoParentExtra.probes(body)
	FonoParentExtra.activities(body)
	FonoParentExtra.diary(body, refresh)


static func _txt(s: String, fs: int = 24, c: Color = Palette.WHITE) -> Label:
	var l := UI.label(s, fs, c)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func _flow() -> HFlowContainer:
	var h := HFlowContainer.new()
	h.add_theme_constant_override("h_separation", 8)
	h.add_theme_constant_override("v_separation", 8)
	return h


static func _targets(body: VBoxContainer, refresh: Callable) -> void:
	body.add_child(_txt("Sons em treino (toque para ligar/desligar; a ordem é a de ligar):", 24, Palette.TEAL))
	var active := FonoData.active_targets()
	var h := _flow()
	for tid in FonoData.data().get("targets", {}):
		var id := str(tid)
		var t := FonoData.target(id)
		var pos := active.find(id)
		var label := str(t.get("name", id)) if pos < 0 else "%d. %s" % [pos + 1, str(t.get("name", id))]
		var b := UI.button(label, Palette.GREEN if pos >= 0 else Palette.PANEL_LIGHT, "", Vector2(230, 60), false, 20)
		b.name = "FonoTarget_%s" % id
		b.tapped.connect(func():
			var now := FonoData.active_targets().duplicate()
			if now.has(id):
				if now.size() > 1:
					now.erase(id)
			else:
				now.append(id)
			FonoData.set_active_targets(now)
			refresh.call())
		h.add_child(b)
	body.add_child(h)


## Lista do dia da academia, igual à folha da fono: cada toque num exercício passa por 10 → 15 → 20 → fora.
static func cycle_gym(id: String) -> void:
	var now := FonoData.gym_list().duplicate()
	if not now.has(id):
		now.append(id)
		FonoData.set_gym_list(now)
		FonoData.set_gym_reps_for(id, 10)
		return
	var r := FonoData.gym_reps_for(id)
	if r < 15:
		FonoData.set_gym_reps_for(id, 15)
	elif r < 20:
		FonoData.set_gym_reps_for(id, 20)
	elif now.size() > 1:
		now.erase(id)
		FonoData.set_gym_list(now)


static func _gym(body: VBoxContainer, refresh: Callable) -> void:
	var day := FonoData.gym_date()
	body.add_child(_txt("Academia da boca — lista do dia (como a folha da fono)%s:" % (
		" · montada em " + day if day != "" else ""), 24, Palette.TEAL))
	body.add_child(_txt("Repetições para todos:", 20, Palette.TEXT_SOFT))
	var hr := _flow()
	for n in REPS:
		var b := UI.button(str(n), Palette.TEAL if n == FonoData.gym_reps() else Palette.PANEL_LIGHT, "", Vector2(90, 60), false, 22)
		b.name = "FonoReps_%d" % n
		b.tapped.connect(func():
			FonoData.set_gym_reps(n)
			refresh.call())
		hr.add_child(b)
	body.add_child(hr)
	body.add_child(_txt("Exercícios (cada toque: 10 → 15 → 20 → fora; os com \"segura\" contam um, dois, três):", 22,
		Palette.TEXT_SOFT))
	var on := FonoData.gym_list()
	var h := _flow()
	for g in FonoData.gym():
		var id := str(g["id"])
		var label := str(g["name"]) + (" · %d" % FonoData.gym_reps_for(id) if on.has(id) else "")
		var b := UI.button(label, Palette.GREEN if on.has(id) else Palette.PANEL_LIGHT, "", Vector2(250, 56), false, 18)
		b.name = "FonoGym_%s" % id
		b.tapped.connect(func():
			cycle_gym(id)
			refresh.call())
		h.add_child(b)
	body.add_child(h)


## Para mostrar à fono: nível de cada som e as últimas sessões (data, nível, acertos confirmados).
static func _report(body: VBoxContainer) -> void:
	body.add_child(_txt("Para mostrar à fono:", 24, Palette.YELLOW))
	var levels := FonoData.levels()
	for id in FonoData.active_targets():
		var t := FonoData.target(str(id))
		var lv := FonoData.level_open(str(id))
		body.add_child(_txt("%s — nível %d de %d (%s)" % [str(t.get("name", id)), lv + 1, levels.size(),
			str(levels[lv]["name"])], 22, Palette.WHITE))
		var hist := FonoData.history(str(id))
		if hist.is_empty():
			body.add_child(_txt("   ainda sem sessões", 18, Palette.TEXT_SOFT))
		for e in hist.slice(maxi(0, hist.size() - 5)):
			var lname := str(levels[clampi(int(e.get("lv", 0)), 0, levels.size() - 1)]["name"])
			body.add_child(_txt("   %s · %s · %d de %d" % [str(e.get("d", "")), lname, int(e.get("ok", 0)), int(e.get("of", 0))],
				18, Palette.TEXT_SOFT))
	var gl := FonoData.gym_log()
	var dates: Array = []
	for e in gl.slice(maxi(0, gl.size() - 7)):
		dates.append(str(e.get("d", "")))
	body.add_child(_txt("Academia da boca feita em: %s" % (", ".join(dates) if not dates.is_empty() else "ainda não"), 20))
	var m := FonoData.meter_samples()
	body.add_child(_txt("Medidor de chiado (pista, não nota): %d falas de CH/J e %d de S confirmadas; fronteira em %d Hz." % [
		(m.get("ʃ", []) as Array).size(), (m.get("s", []) as Array).size(), int(FonoMic.split_hz())], 18, Palette.TEXT_SOFT))
