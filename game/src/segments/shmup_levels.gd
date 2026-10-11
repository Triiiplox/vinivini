class_name ShmupLevels
extends RefCounted
## As 24 fases de nave (11/10, o Andro: "poucas fases" → escolheu 24). 6 planetas × 4 fases:
##   1 PATRULHA  ondas de robôs bagunceiros + mini-mestre no fim
##   2 DESAFIO   ondas + portal de conta no meio (canhão sobe) + mini-mestre
##   3 RESGATE   chuva de meteoros, estrelas para pegar e um primo para resgatar (vira ajudante) + mini-mestre
##   4 MESTRE    ondas curtas e o MESTRE do planeta (nome, cara, ataques próprios, 2 fases de raiva)
## Cada planeta traz um inimigo novo e o mestre dele; a dificuldade sobe devagar de 1 a 24.
## Progresso salvo em progress["fases24"] = {"<i>": estrelas}; a fase i abre quando a i-1 tem estrela.

const WORLDS := ["moon", "mars", "jupiter", "saturn", "uranus", "neptune"]
const WORLD_NAMES := ["Lua", "Marte", "Júpiter", "Saturno", "Urano", "Netuno"]
const KINDS := ["patrulha", "desafio", "resgate", "mestre"]
const KIND_NAMES := ["Patrulha", "Desafio", "Resgate", "Mestre"]
## Mestre de cada planeta (o tipo de desenho/ataques em ShmupBoss).
const BOSSES := ["cratera", "ferrugem", "tempestade", "aneis", "gelo", "polvo"]
const BOSS_NAMES := ["Rei Cratera", "Robô Ferrugem", "Olho da Tempestade", "Senhor dos Anéis", "Rainha de Gelo",
	"Polvo Cósmico"]
## Inimigo que cada planeta apresenta (somado aos dos planetas anteriores).
const NEW_FOE := ["bolinha", "seta", "olho", "giro", "casco", "mina"]
const COUNT := 24
const SAVE_KEY := "fases24"


static func world(i: int) -> int:
	return clampi(i, 0, COUNT - 1) / 4


static func kind(i: int) -> String:
	return KINDS[clampi(i, 0, COUNT - 1) % 4]


static func title(i: int) -> String:
	return "%s %d" % [WORLD_NAMES[world(i)], i % 4 + 1]


## Segundos de ondas antes do mini-mestre/mestre (mestre tem ondas curtas: o show é ele).
static func wave_time(i: int) -> float:
	return 26.0 if kind(i) == "mestre" else 42.0 + world(i) * 2.0


## Inimigos que podem aparecer na fase i (o novo do planeta aparece mais).
static func foe_pool(i: int) -> Array:
	var w := world(i)
	var pool: Array = []
	for k in w + 1:
		pool.append(NEW_FOE[k])
	pool.append(NEW_FOE[w])  # o do planeta vale dobrado
	return pool


## 0..1: velocidade, cadência de tiro inimigo e vida sobem com isso.
static func heat(i: int) -> float:
	return clampf(float(i) / float(COUNT - 1), 0.0, 1.0)


static func has_gate(i: int) -> bool:
	return kind(i) in ["desafio", "mestre"]


# ------------------------------------------------------------------ progresso
static func stars(i: int) -> int:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	var f: Variant = pd.get(SAVE_KEY, {})
	return int((f as Dictionary).get(str(i), 0)) if f is Dictionary else 0


static func is_open(i: int) -> bool:
	return i == 0 or stars(i - 1) > 0


static func save_stars(i: int, n: int) -> void:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	if not pd.get(SAVE_KEY) is Dictionary:
		pd[SAVE_KEY] = {}
	pd[SAVE_KEY][str(i)] = maxi(n, int(pd[SAVE_KEY].get(str(i), 0)))
	SaveService.progress.persist(SaveService.profile_id)


## Primeira fase aberta ainda sem estrela (a "próxima"); -1 se todas feitas.
static func current() -> int:
	for i in COUNT:
		if is_open(i) and stars(i) == 0:
			return i
	return -1


# ------------------------------------------------------------------ modo (escolha do Andro: "poder escolher")
## "facil": sem fim de jogo — escudo recarrega e o Astro conserta a nave (menos estrelas).
## "classico": 3 vidas; acabou, "Tente de novo".
static func mode() -> String:
	var m := str(SaveService.settings.get_value("nave_modo"))
	return m if m in ["facil", "classico"] else "facil"


static func set_mode(m: String) -> void:
	SaveService.settings.set_value("nave_modo", m)


# ------------------------------------------------------------------ falas (literais: o gen_voice acha e grava)
static func world_line(world_i: int) -> String:
	match world_i:
		0:
			return Lines.n("Planeta Lua!")
		1:
			return Lines.n("Planeta Marte!")
		2:
			return Lines.n("Planeta Júpiter!")
		3:
			return Lines.n("Planeta Saturno!")
		4:
			return Lines.n("Planeta Urano!")
	return Lines.n("Planeta Netuno!")


static func kind_line(kind: String) -> String:
	match kind:
		"patrulha":
			return Lines.n("Patrulha! Desligue os robôs bagunceiros!")
		"desafio":
			return Lines.n("Desafio! No meio tem uma conta para turbinar o canhão!")
		"resgate":
			return Lines.n("Resgate! Pegue a cápsula azul e seu primo vem ajudar!")
	return Lines.n("Hora do mestre! Seja corajoso!")


static func boss_line(world_i: int) -> String:
	match world_i:
		0:
			return Lines.n("Cuidado! É o Rei Cratera, o mestre da Lua!")
		1:
			return Lines.n("Cuidado! É o Robô Ferrugem, o mestre de Marte!")
		2:
			return Lines.n("Cuidado! É o Olho da Tempestade, o mestre de Júpiter!")
		3:
			return Lines.n("Cuidado! É o Senhor dos Anéis, o mestre de Saturno!")
		4:
			return Lines.n("Cuidado! É a Rainha de Gelo, a mestra de Urano!")
	return Lines.n("Cuidado! É o Polvo Cósmico, o mestre de Netuno!")
