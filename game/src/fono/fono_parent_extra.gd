class_name FonoParentExtra
extends RefCounted
## FALAR v2 na área dos pais (continuação de FonoParentPanel): dose do treino (figuras por bloco e repetições),
## pares mínimos (desligado por padrão), gráfico das palavras novas (sondas), diário para a fono e dicas de sessão
## curta. Tudo fica no aparelho; nada é enviado.


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


## Sessão curta (P12) e as dicas gerais para os pais.
static func tips(body: VBoxContainer) -> void:
	body.add_child(_txt("Sessões curtas: 10 a 15 minutos, uma vez por dia, uns 5 dias por semana (conta no tempo de " +
		"tela). Pode parar quando quiser: o bloco que ficou pela metade continua na próxima vez.", 20, Palette.TEXT_SOFT))
	for tip in FonoData.data().get("parent_tips", []):
		body.add_child(_txt("• " + str(tip), 18, Palette.TEXT_SOFT))


## "Fala 3 vezes" (P1): figuras por bloco e repetições por figura; e o liga/desliga dos pares mínimos (P5).
static func dose(body: VBoxContainer, refresh: Callable) -> void:
	body.add_child(_txt("Fala 3 vezes — figuras por bloco (palavras) e quantas vezes falar cada figura:", 24, Palette.TEAL))
	var h := _flow()
	for n in FonoPlan.BLOCKS:
		var b := UI.button("%d figuras" % n, Palette.TEAL if n == FonoPlan.block_size() else Palette.PANEL_LIGHT, "",
			Vector2(150, 56), false, 20)
		b.name = "FonoBlock_%d" % n
		b.tapped.connect(func():
			FonoPlan.set_block_size(n)
			refresh.call())
		h.add_child(b)
	for n in FonoPlan.REPS:
		var b := UI.button("%d× cada" % n, Palette.TEAL if n == FonoPlan.reps_per_picture() else Palette.PANEL_LIGHT, "",
			Vector2(140, 56), false, 20)
		b.name = "FonoRep_%d" % n
		b.tapped.connect(func():
			FonoPlan.set_reps_per_picture(n)
			refresh.call())
		h.add_child(b)
	body.add_child(h)
	body.add_child(_txt("Padrão da fono: 3× cada figura. 12 figuras × 3 = 36 falas por bloco; o adulto confirma uma vez " +
		"por figura. Passa de nível com 80% ou mais em 2 sessões seguidas, em dias diferentes.", 18, Palette.TEXT_SOFT))
	var on := FonoPlan.pairs_enabled()
	var p := UI.button("Pares mínimos (só se a fono concordar): %s" % ("LIGADO" if on else "desligado"),
		Palette.GREEN if on else Palette.PANEL_LIGHT, "", Vector2(560, 56), false, 20)
	p.name = "FonoPairs"
	p.tapped.connect(func():
		FonoPlan.set_pairs_enabled(not FonoPlan.pairs_enabled())
		refresh.call())
	body.add_child(p)


## Gráfico "% certo nas palavras novas" por data (sondas, P7), um por som; tela para fotografar e mostrar à fono.
static func probes(body: VBoxContainer) -> void:
	body.add_child(_txt("Palavras novas (sondas: a cada 5 sessões, 10 palavras nunca treinadas, sem ajuda):", 24, Palette.YELLOW))
	var any := false
	for id in FonoData.active_targets():
		var pts := FonoLog.probe_points(str(id))
		if pts.is_empty():
			continue
		any = true
		body.add_child(_txt("%s — %% certo nas palavras novas" % str(FonoData.target(str(id)).get("name", id)), 20))
		var c := Control.new()
		c.name = "FonoProbeChart_%s" % id
		c.custom_minimum_size = Vector2(0, 200)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.draw.connect(draw_chart.bind(c, pts))
		body.add_child(c)
	if not any:
		body.add_child(_txt("   ainda sem sondas (a primeira aparece quando ele chegar às palavras)", 18, Palette.TEXT_SOFT))


static func draw_chart(c: Control, pts: Array) -> void:
	var font := ThemeDB.fallback_font
	var h := c.size.y - 40.0
	var left := 60.0
	c.draw_line(Vector2(left, 6), Vector2(left, h + 6), Palette.TEXT_SOFT, 2.0)
	c.draw_line(Vector2(left, h + 6), Vector2(c.size.x - 10, h + 6), Palette.TEXT_SOFT, 2.0)
	for pct in [0, 50, 100]:
		var y: float = 6.0 + h * (1.0 - pct / 100.0)
		c.draw_string(font, Vector2(4, y + 6), "%d%%" % pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Palette.TEXT_SOFT)
	var shown := pts.slice(maxi(0, pts.size() - 12))
	var bw := minf(70.0, (c.size.x - left - 20.0) / maxf(1.0, shown.size()) - 12.0)
	for i in shown.size():
		var p: Dictionary = shown[i]
		var x := left + 12.0 + i * (bw + 12.0)
		var bh := h * int(p["pct"]) / 100.0
		c.draw_rect(Rect2(x, 6 + h - bh, bw, bh), Palette.TEAL)
		c.draw_string(font, Vector2(x, 6 + h - bh - 6), "%d%%" % int(p["pct"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Palette.WHITE)
		c.draw_string(font, Vector2(x, h + 30), str(p["d"]).substr(5), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Palette.TEXT_SOFT)


## Diário para a fono (P10): toques rápidos com a data de hoje; lista das últimas anotações.
static func diary(body: VBoxContainer, refresh: Callable) -> void:
	body.add_child(_txt("Diário para a fono (toque para anotar hoje; fica só neste aparelho):", 24, Palette.YELLOW))
	var h := _flow()
	var names := {}
	for k in FonoLog.diary_kinds():
		var kid := str(k["id"])
		names[kid] = str(k["name"])
		var b := UI.button(str(k["name"]), Palette.PANEL_LIGHT, "", Vector2(420, 56), false, 18)
		b.name = "FonoDiary_%s" % kid
		b.tapped.connect(func():
			FonoLog.add_note(kid)
			refresh.call())
		h.add_child(b)
	body.add_child(h)
	var notes := FonoLog.notes()
	if notes.is_empty():
		body.add_child(_txt("   nenhuma anotação ainda", 18, Palette.TEXT_SOFT))
	for n in notes.slice(maxi(0, notes.size() - 8)):
		body.add_child(_txt("   %s · %s" % [str(n.get("d", "")), str(names.get(str(n.get("k", "")), n.get("k", "")))], 18,
			Palette.TEXT_SOFT))
	body.add_child(_txt("Observação para levar à fono, não é diagnóstico.", 16, Palette.TEXT_SOFT))


## Jogos feitos (sacolas, chuva, trilha, pares): os últimos, com acertos.
static func activities(body: VBoxContainer) -> void:
	var acts := FonoLog.activities()
	if acts.is_empty():
		return
	var names := {"sacolas": "Sacolas do som", "chuva": "Chuva no guarda-chuva", "trilha": "Trilha de leitura",
		"pares": "Me faz pegar"}
	body.add_child(_txt("Jogos do FALAR (últimos):", 20, Palette.TEAL))
	for a in acts.slice(maxi(0, acts.size() - 6)):
		body.add_child(_txt("   %s · %s · %s · %d de %d" % [str(a.get("d", "")), str(names.get(str(a.get("a", "")), a.get("a", ""))),
			str(FonoData.target(str(a.get("t", ""))).get("letter", "")), int(a.get("ok", 0)), int(a.get("of", 0))], 18,
			Palette.TEXT_SOFT))
