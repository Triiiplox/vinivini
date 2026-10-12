class_name FonoText
extends RefCounted
## Letra-alvo em vermelho (P6), como nas folhas da fono: ajuda a ligar letra e som (Rvachew 2004). Regra POR ALVO:
##   ch: CH sempre; X só quando soa /ʃ/ (começo de palavra, depois de ai/ei/oi/ou/en, "me-" no começo, ou palavra
##       conhecida). "táxi", "exame", "próximo", "trouxe" ficam sem destaque.
##   j:  J sempre; G só antes de e/i (gelo, girafa — não "gato", nem "guerra").
##   s:  S, SS, Ç, Z e C antes de e/i (cebola, cinema).
##   r:  R fraco: R sozinho entre vogais ou depois de consoante (cara, prato); não R inicial, RR, nem R no fim da sílaba.
##   ti: T/D antes de I, ou antes do E átono do fim (leite, verde): é onde vira "tchi/dji".
##   nd: N e D antes de vogal (menos os D que viram "dji").
##   lh: LH. encontros_r / encontros_l: a consoante + R/L do encontro (pr, bl). r_final: R que fecha a sílaba.

const RED := "#E11D48"
const VOWELS := "aeiouáéíóúâêôãõà"
const X_SH := ["lixo", "bruxa", "roxo", "puxar", "puxa", "coxa", "coxinha", "graxa", "faxina", "lagartixa", "bexiga",
	"abacaxi", "xixi", "rixa", "mexer", "enxada", "enxame", "enxergar", "caixote", "ameixa", "faixa", "baixo"]
const X_NOT := ["táxi", "taxi", "tóxico", "exame", "sexo", "boxe", "fixo", "próximo", "máximo", "texto", "extra",
	"exemplo", "exato", "êxito", "auxílio", "axila", "anexo", "reflexo", "complexo", "oxigênio", "tórax", "trouxe",
	"xérox", "fixar", "léxico", "sintaxe"]


## Texto em BBCode com as letras-alvo em vermelho (para RichTextLabel).
static func highlight(id: String, text: String) -> String:
	var m := mask(id, text)
	var out := ""
	var on := false
	for i in text.length():
		if m[i] and not on:
			out += "[color=%s]" % RED
			on = true
		elif not m[i] and on:
			out += "[/color]"
			on = false
		var ch := text[i]
		out += "[lb]" if ch == "[" else ch
	if on:
		out += "[/color]"
	return out


## Versão legível para testes: as letras-alvo entre < >. Ex.: ("ch", "chuva") → "<ch>uva".
static func marks(id: String, text: String) -> String:
	var m := mask(id, text)
	var out := ""
	for i in text.length():
		if m[i] and (i == 0 or not m[i - 1]):
			out += "<"
		out += text[i]
		if m[i] and (i == text.length() - 1 or not m[i + 1]):
			out += ">"
	return out


## true em cada letra-alvo do texto (frases: palavra por palavra).
static func mask(id: String, text: String) -> Array:
	var m: Array = []
	m.resize(text.length())
	m.fill(false)
	var start := -1
	for i in text.length() + 1:
		var letter := i < text.length() and _is_letter(text[i])
		if letter and start < 0:
			start = i
		elif not letter and start >= 0:
			var wm := _word_mask(id, text.substr(start, i - start).to_lower())
			for k in wm.size():
				m[start + k] = wm[k]
			start = -1
	return m


static func _is_letter(c: String) -> bool:
	return c.to_lower() != c.to_upper() or c == "ç"


static func _word_mask(id: String, w: String) -> Array:
	var m: Array = []
	m.resize(w.length())
	m.fill(false)
	var n := w.length()
	for i in n:
		var c := w[i]
		var nx := w[i + 1] if i + 1 < n else ""
		var pv := w[i - 1] if i > 0 else ""
		match id:
			"ch":
				if c == "c" and nx == "h":
					m[i] = true
					m[i + 1] = true
				elif c == "x" and x_is_sh(w, i):
					m[i] = true
			"j":
				if c == "j" or (c == "g" and nx != "" and "eéêií".contains(nx)):
					m[i] = true
			"s":
				if c in ["s", "ç", "z"] or (c == "c" and nx != "" and "eéêií".contains(nx)):
					m[i] = true
			"r":
				if c == "r" and i > 0 and pv != "r" and nx != "r" and nx != "" and VOWELS.contains(nx) and not pv in ["n", "l", "s"]:
					m[i] = true
			"ti":
				if c in ["t", "d"] and nx != "" and (nx in ["i", "í"] or (nx == "e" and (i + 2 == n or w.substr(i + 2) == "s"))):
					m[i] = true
					m[i + 1] = true
			"nd":
				if c == "n" and nx != "" and VOWELS.contains(nx):
					m[i] = true
				elif c == "d" and nx != "" and VOWELS.contains(nx) and not nx in ["i", "í"] and not (nx == "e" and i + 2 == n):
					m[i] = true
			"lh":
				if c == "l" and nx == "h":
					m[i] = true
					m[i + 1] = true
			"encontros_r", "encontros_l":
				var liq := "r" if id == "encontros_r" else "l"
				if c == liq and i > 0 and "bcdfgkptv".contains(pv) and nx != "" and VOWELS.contains(nx):
					m[i - 1] = true
					m[i] = true
			"r_final":
				if c == "r" and pv != "" and VOWELS.contains(pv) and (nx == "" or not VOWELS.contains(nx)) and nx != "r":
					m[i] = true
	return m


## O X desta palavra (na posição i) soa CH /ʃ/?
static func x_is_sh(w: String, i: int) -> bool:
	if X_NOT.has(w):
		return false
	if i == 0 or X_SH.has(w):
		return true
	if i >= 2 and w.substr(i - 2, 2) in ["ai", "ei", "oi", "ou", "en"]:
		return true
	if i == 2 and w.begins_with("me"):
		return true
	return _known_ch(w)


static func _known_ch(w: String) -> bool:
	var t := FonoData.target("ch")
	for k in ["inicio", "meio", "facil", "sondas"]:
		if (t.get(k, []) as Array).has(w):
			return true
	return false


## Rótulo pronto para a palavra com destaque (centralizado, fonte de alfabetização em negrito).
static func rich_label(font_size: int, color: Color) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.scroll_active = false
	r.fit_content = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	r.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_override("normal_font", DS.font("learning"))  # Andika: letra de alfabetização
	r.add_theme_font_size_override("normal_font_size", font_size)
	r.add_theme_color_override("default_color", color)
	UI.child_ok(r)  # a palavra (ele lê)
	return r
