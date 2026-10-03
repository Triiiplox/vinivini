class_name ShipProgress
extends RefCounted
## Progressão visível da nave: salas que abrem com missões, peças da nave por campanha, tripulação que chega,
## adesivos (um por lição concluída) e o desafio surpresa do dia.

## Sala -> missão que abre a sala (as demais já começam abertas).
const STATION_REQ := {"hello": "m02", "robots": "m03", "kitchen": "m07", "library": "m08", "lab": "m09",
	"observatory": "m10"}
## Campanha concluída -> peça nova na nave (arte "build").
const SHIP_PARTS := {"nave": "antenna", "lua": "solar_panel", "marte": "thruster", "gigantes": "rocket_fin",
	"terra": "wheel", "escola": "rocket_nose"}
## Missão -> astronauta que passa a morar na nave (traje).
const CREW := {"m07": "suit_orange", "m13": "suit_green", "m16": "suit_galaxy"}


static func done(mission_id: String) -> bool:
	return MissionFlow.is_done(mission_id)


static func station_open(id: String) -> bool:
	return not STATION_REQ.has(id) or done(str(STATION_REQ[id]))


static func campaign_done(c: Dictionary) -> bool:
	for m in c.get("missions", []):
		if not done(str(m)):
			return false
	return true


static func ship_parts() -> Array:
	var out: Array = []
	for c in ContentService.repo.campaigns:
		if campaign_done(c) and SHIP_PARTS.has(str(c["id"])):
			out.append(SHIP_PARTS[str(c["id"])])
	return out


static func crew() -> Array:
	var out: Array = []
	for m in CREW:
		if done(m):
			out.append(CREW[m])
	return out


## Adesivos: cada lição concluída vira um adesivo com a figura da lição.
static func stickers() -> Array:
	var d: Dictionary = SaveService.progress.data(SaveService.profile_id).get("lessons_done", {})
	return d.keys().filter(func(k): return ContentService.repo.lessons.has(k))


## Desafio surpresa: no máximo um por dia, a partir do 2º dia de jogo (ou depois da 1ª missão).
static func surprise_available() -> bool:
	var pd: Dictionary = SaveService.progress.data(SaveService.profile_id)
	if str(pd.get("surprise_day", "")) == AppState.today():
		return false
	return done("m01")


static func mark_surprise() -> void:
	SaveService.progress.data(SaveService.profile_id)["surprise_day"] = AppState.today()
	SaveService.progress.persist(SaveService.profile_id)
