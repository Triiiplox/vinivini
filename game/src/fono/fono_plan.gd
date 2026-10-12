class_name FonoPlan
extends RefCounted
## FALAR v2: o "plano" de cada rodada, em funções puras (testáveis sem tela). Base (docs/FONO.md):
##   - DOSE (P1): "Fala 3 vezes" — cada figura falada reps_per_picture vezes (padrão 3, como as pranchas da fono),
##     o adulto julga uma vez por figura; bloco de 6/9/12 figuras (Williams 2012; Allen 2013: 50–100 produções).
##   - CONTEXTO FACILITADOR (P2): sílabas começam por chu/cho/chi; nas palavras, as fáceis vêm primeiro
##     (Bonini & Keske-Soares 2018).
##   - SACOLAS DO SOM (P4), CHUVA NO GUARDA-CHUVA (P3), TRILHA DE LEITURA (P6), ME FAZ PEGAR (P5).
##   - MICROFONE MUDO: 2 gravações seguidas sem som (ou permissão negada) → só os botões do adulto naquela sessão.
##   - SESSÃO CURTA (P12): aviso para o adulto depois de ~12 min (nunca para a criança, nunca é placar).
## Escolhas dos pais ficam nos ajustes do aparelho: fono_block (6/9/12), fono_rep (1/3/5), fono_pairs (bool).

const BLOCKS := [6, 9, 12]
const REPS := [1, 3, 5]
const REP_LEVELS := ["facil", "inicio", "meio"]
const SHORT_SESSION_MIN := 12.0

## Começo da sessão de FALAR de hoje (ms do relógio do jogo), para o aviso de sessão curta.
static var session_start_ms := -1
static var _warned := false


# ------------------------------------------------------------------ escolhas dos pais (P1, P5)
static func block_size() -> int:
	var n := int(_setting("fono_block", 12))
	return n if BLOCKS.has(n) else 12


static func set_block_size(n: int) -> void:
	SaveService.settings.set_value("fono_block", n if BLOCKS.has(n) else 12)


static func reps_per_picture() -> int:
	var n := int(_setting("fono_rep", 3))
	return n if REPS.has(n) else 3


static func set_reps_per_picture(n: int) -> void:
	SaveService.settings.set_value("fono_rep", n if REPS.has(n) else 3)


## "Me faz pegar!" (pares mínimos) só aparece se os pais ligarem (combinar com a fono antes).
static func pairs_enabled() -> bool:
	return bool(_setting("fono_pairs", false))


static func set_pairs_enabled(on: bool) -> void:
	SaveService.settings.set_value("fono_pairs", on)


static func _setting(key: String, def: Variant) -> Variant:
	var v: Variant = SaveService.settings.get_value(key)
	return def if v == null else v


## Quantas vezes falar cada figura neste nível (só nos níveis de palavra; som, sílaba, frase e história: 1).
static func reps_for(level_id: String) -> int:
	return reps_per_picture() if REP_LEVELS.has(level_id) else 1


# ------------------------------------------------------------------ itens da sessão (P1 + P2)
## Figuras de um bloco do nível. Sílabas na ordem do contexto facilitador (chu, chô, chi...); palavras: as fáceis
## primeiro (embaralhadas entre si), depois as outras. `rng_seed` ≠ 0 deixa o sorteio repetível (testes).
static func production_items(id: String, lv: int, rng_seed: int = 0) -> Array:
	var level_id := str(FonoData.levels()[lv]["id"])
	var src: Array = FonoData.items(id, lv).duplicate()
	var n := 10
	match level_id:
		"historia":
			n = 1
		"isolado":
			n = 6
		"facil", "inicio", "meio":
			n = block_size()
	var rng := RandomNumberGenerator.new()
	if rng_seed != 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	var ordered: Array = []
	if level_id == "silabas":
		ordered = src
	else:
		var easy: Array = src.filter(func(w): return FonoData.is_easy(id, str(w)))
		var rest: Array = src.filter(func(w): return not FonoData.is_easy(id, str(w)))
		ordered = _shuffled(easy, rng) + _shuffled(rest, rng)
	var out: Array = []
	while out.size() < n and not ordered.is_empty():
		out.append(ordered[out.size() % ordered.size()])
	return out


static func _shuffled(a: Array, rng: RandomNumberGenerator) -> Array:
	var b := a.duplicate()
	for i in range(b.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = b[i]
		b[i] = b[j]
		b[j] = tmp
	return b


## Fala da narradora entre as repetições da mesma figura (1 → "de novo!", 2 → "mais uma!").
static func rep_cue(done: int) -> String:
	return Lines.n("De novo!") if done == 1 else Lines.n("Mais uma!")


# ------------------------------------------------------------------ sacolas do som (P4)
## Os pares de sacola do alvo: [{"vs": "s", "erro": ["ʃ", "s"], "letra": "S", "pose": "s"}, ...].
static func bag_pairs(id: String) -> Array:
	return FonoData.target(id).get("bolsas", [])


## 10 itens (metade dita certa, metade com a troca), palavras com o som no começo; as que têm figura primeiro.
## Cada item: {"w": palavra, "err": bool, "bag": "alvo" ou o id do outro som}.
static func bag_items(id: String, vs: String, n: int = 10, rng_seed: int = 0) -> Array:
	var t := FonoData.target(id)
	var rng := RandomNumberGenerator.new()
	if rng_seed != 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	var words: Array = (t.get("inicio", []) as Array).duplicate()
	var pics: Array = _shuffled(words.filter(func(w): return FonoData.picture(str(w)) != null), rng)
	var rest: Array = _shuffled(words.filter(func(w): return FonoData.picture(str(w)) == null), rng)
	var pool: Array = pics + rest
	var errs: Array = []
	for i in n:
		errs.append(i % 2 == 1)
	errs = _shuffled(errs, rng)
	var out: Array = []
	for i in mini(n, pool.size()):
		out.append({"w": str(pool[i]), "err": errs[i], "bag": vs if errs[i] else id})
	return out


## A figura foi para a sacola certa? (a do som que a criança OUVIU no começo da palavra)
static func bag_right(it: Dictionary, bag: String) -> bool:
	return str(it.get("bag", "")) == bag


## Texto para o Voice: palavra certa (narradora) ou com a troca (fonoerr "de|para|palavra").
static func bag_voice(id: String, vs: String, it: Dictionary) -> Array:
	if not bool(it.get("err", false)):
		return [str(it["w"]), "narrator"]
	for b in bag_pairs(id):
		if str(b.get("vs", "")) == vs:
			var e: Array = b["erro"]
			return ["%s|%s|%s" % [e[0], e[1], str(it["w"])], "fonoerr"]
	return [str(it["w"]), "narrator"]


# ------------------------------------------------------------------ chuva no guarda-chuva (P3)
## 5 nuvens = 5 vogais na ordem facilitadora (u, o, i, a, e): a sílaba de cada uma (chu, chô, chi, chá, ché).
static func rain_syllables(id: String) -> Array:
	var vowels: Array = ["u", "o", "i", "a", "e"]
	for a in FonoData.data().get("activities", []):
		if str(a.get("id", "")) == "chuva_guarda_chuva":
			vowels = a.get("vowels_order", vowels)
	var sil: Array = FonoData.target(id).get("silabas", [])
	var out: Array = []
	for v in vowels:
		for s in sil:
			if _vowel_of(str(s)) == str(v):
				out.append({"v": str(v), "s": str(s)})
				break
	return out


static func _vowel_of(s: String) -> String:
	var last := s.right(1)
	return {"á": "a", "é": "e", "ê": "e", "í": "i", "ó": "o", "ô": "o", "ú": "u"}.get(last, last)


## A gota anda neste quadro? Com o chiado do som (centroide do lado CH/J) ou com o adulto segurando o botão.
## Sem tempo-limite: se o som para, a gota espera.
static func drop_moves(hiss: bool, centroid: float, adult_holding: bool) -> bool:
	if adult_holding:
		return true
	return hiss and FonoMic.classify(centroid) == "ʃ"


# ------------------------------------------------------------------ trilha de leitura (P6)
## 12 palavras para ler (início e meio, as fáceis primeiro), sem relógio.
static func read_items(id: String, n: int = 12, rng_seed: int = 0) -> Array:
	var t := FonoData.target(id)
	var rng := RandomNumberGenerator.new()
	if rng_seed != 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	var all: Array = (t.get("inicio", []) as Array) + (t.get("meio", []) as Array)
	var easy: Array = all.filter(func(w): return FonoData.is_easy(id, str(w)))
	var rest: Array = all.filter(func(w): return not FonoData.is_easy(id, str(w)))
	return (_shuffled(easy, rng) + _shuffled(rest, rng)).slice(0, n)


# ------------------------------------------------------------------ me faz pegar (P5)
## 10 rodadas de pares: {"want": palavra que a criança pede, "other": a do par}. Alterna os dois lados do par.
static func pair_items(id: String, n: int = 10) -> Array:
	var pares: Array = FonoData.target(id).get("pares", [])
	var out: Array = []
	if pares.is_empty():
		return out
	for i in n:
		var p: Dictionary = pares[i % pares.size()]
		var first := (i / pares.size()) % 2 == 0
		out.append({"want": str(p["a"]) if first else str(p["b"]), "other": str(p["b"]) if first else str(p["a"])})
	return out


# ------------------------------------------------------------------ sessão curta (P12)
## Marca o começo da sessão de hoje (ao abrir o FALAR). Mais de 1 h parado conta como sessão nova.
static func mark_session(now_ms: int = -1) -> void:
	var now := now_ms if now_ms >= 0 else Time.get_ticks_msec()
	if session_start_ms < 0 or now - session_start_ms > 3600000:
		session_start_ms = now
		_warned = false


static func session_minutes(now_ms: int = -1) -> float:
	if session_start_ms < 0:
		return 0.0
	var now := now_ms if now_ms >= 0 else Time.get_ticks_msec()
	return float(now - session_start_ms) / 60000.0


## Mostrar o aviso para o adulto agora? (uma vez por sessão, depois de ~12 min)
static func should_warn(now_ms: int = -1) -> bool:
	if _warned or session_minutes(now_ms) < SHORT_SESSION_MIN:
		return false
	_warned = true
	return true


static func reset_session() -> void:
	session_start_ms = -1
	_warned = false
