class_name LevelPlan
extends RefCounted
## Dificuldade gerenciada (v4.4), por cima das fases da trilha (Stages):
##   - ponto de partida por matéria (área dos pais: "começar em"; padrão do perfil do Vini). Não apaga nem inventa
##     estrelas: as fases antes do ponto ficam passadas, e voltar o ponto as reabre com as estrelas que já tinham;
##   - teste rápido na entrada dos blocos marcados (sons das palavras, letras parecidas, sons parecidos, letras
##     com dois sons): acertou, pula o bloco; errou, começa nele;
##   - subida automática: acertou tudo de primeira numa fase de matemática/lógica, a fase seguinte da lição é pulada;
##   - migração: perfil antigo do Vini ganha o ponto de partida uma vez (levels_v), sem perder nada do que fez.

const VERSION := 1


static func data() -> Dictionary:
	return ContentService.repo.banks.get("levels", {})


static func _pd() -> Dictionary:
	return SaveService.progress.data(SaveService.profile_id)


## Marcos de partida da matéria: [[nome, id da lição], ...] ("" = do começo).
static func starts(area: String) -> Array:
	return (data().get("starts", {}) as Dictionary).get(area, [])


static func start_id(area: String) -> String:
	var v: Variant = _pd().get("start_at", {})
	return str((v as Dictionary).get(area, "")) if v is Dictionary else ""


static func set_start(area: String, lesson_id: String) -> void:
	var pd := _pd()
	if not pd.get("start_at") is Dictionary:
		pd["start_at"] = {}
	if lesson_id == "":
		(pd["start_at"] as Dictionary).erase(area)
	else:
		pd["start_at"][area] = lesson_id
		if not pd.get("placed") is Dictionary:
			pd["placed"] = {}
		pd["placed"][area] = true  # quem escolheu o ponto de partida não precisa do nivelamento
	SaveService.progress.persist(SaveService.profile_id)


## Padrão do perfil (levels.json "defaults"), aplicado uma vez por perfil. Convidados não têm padrão: começam do
## básico. Também é a migração dos saves antigos: só acrescenta (ponto de partida e nível de contas mínimo).
static func apply_defaults() -> void:
	var pd := _pd()
	if int(pd.get("levels_v", 0)) >= VERSION:
		return
	pd["levels_v"] = VERSION
	var d: Dictionary = (data().get("defaults", {}) as Dictionary).get(SaveService.profile_id, {})
	for area in d.get("start", {}):
		if start_id(str(area)) == "":
			set_start(str(area), str(d["start"][area]))
	if d.has("endless_math"):
		var cur := Stages.math_level()
		Stages.set_math_level(maxi(cur, int(d["endless_math"])))
	SaveService.progress.persist(SaveService.profile_id)


## Subida automática: devolve a chave da próxima fase a pular ("" = nenhuma).
static func autoskip(les: Dictionary, stage: int, first_ok: int, asked: int) -> String:
	if not bool(les.get("autoskip", false)) or asked <= 0 or first_ok < asked or stage >= Stages.lesson_levels(les):
		return ""
	var k := Stages.key(str(les.get("id", "")), stage + 1)
	return "" if Stages.is_done(k) else k


static func block_of(lesson_id: String) -> String:
	return str(ContentService.repo.lessons.get(lesson_id, {}).get("block", ""))


## Índice da primeira fase do bloco na trilha (-1 se não existe).
static func block_start(area: String, block: String) -> int:
	var ns := Stages.nodes(area)
	for i in ns.size():
		if block_of(str(ns[i]["id"])) == block:
			return i
	return -1


## Teste rápido a fazer agora: a próxima fase é a entrada de um bloco com teste ainda não feito.
## Devolve {block, samples} ou {}.
static func block_test(area: String) -> Dictionary:
	var ns := Stages.nodes(area)
	var ni := Stages.next_index(area)
	if ni >= ns.size():
		return {}
	var b := block_of(str(ns[ni]["id"]))
	var info: Dictionary = (data().get("blocks", {}) as Dictionary).get(b, {})
	var done: Variant = _pd().get("block_tests", {})
	if b == "" or not bool(info.get("test", false)) or (done is Dictionary and (done as Dictionary).has(b)):
		return {}
	if block_start(area, b) != ni:
		return {}
	var samples := block_samples(area, b)
	return {} if samples.is_empty() else {"block": b, "samples": samples}


## Até 6 fases espalhadas pelo bloco, só as que têm pergunta de resposta certa.
static func block_samples(area: String, block: String) -> Array:
	var ok: Array = []
	for nd in Stages.nodes(area):
		if block_of(str(nd["id"])) != block:
			continue
		var les: Dictionary = ContentService.repo.lessons[str(nd["id"])]
		for q in les.get("ask", []):
			if int(q.get("lvl", 1)) == int(nd["stage"]) and str(q.get("k", "")) in ["pick", "num", "order"]:
				ok.append(nd)
				break
	var out: Array = []
	var m := mini(6, ok.size())
	for i in m:
		var nd: Dictionary = ok[int(round(i * (ok.size() - 1) / maxf(1.0, m - 1.0)))]
		if not out.has(nd):
			out.append(nd)
	return out


## Nome do ponto de partida atual (para a área dos pais).
static func start_name(area: String) -> String:
	var sid := start_id(area)
	for s in starts(area):
		if str(s[1]) == sid:
			return str(s[0])
	return "Do começo"
