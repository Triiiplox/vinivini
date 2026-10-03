extends Node
## Ponto único de acesso aos repositories. O backend físico é injetável
## (JsonFileStorage em produção, MemoryStorage nos testes).

const DEFAULT_PROFILE := "vini"
## Cópias de segurança: uma por dia (as últimas MAX_SNAPSHOTS) + "reset" (antes de apagar) + "undo" (antes de restaurar).
const SNAP_INDEX := "snapshots"
const MAX_SNAPSHOTS := 7

var profile_id := DEFAULT_PROFILE
var store: VersionedStore
var profiles: ProfileRepository
var progress: ProgressRepository
var inventory: InventoryRepository
var settings: SettingsRepository


func _ready() -> void:
	if store == null:
		configure(JsonFileStorage.new("user://save"))


func configure(backend: StorageBackend) -> void:
	store = VersionedStore.new(backend)
	profiles = ProfileRepository.new(store)
	progress = ProgressRepository.new(store)
	inventory = InventoryRepository.new(store)
	settings = SettingsRepository.new(store)


## Persiste tudo que está em cache (chamado ao pausar/fechar o app).
func flush() -> void:
	progress.persist(profile_id)
	store.save(ProfileRepository.key_for(profile_id))
	store.save(InventoryRepository.key_for(profile_id))
	store.save(SettingsRepository.KEY)


## Simula "fechar e abrir": descarta cache e relê do backend.
func reload_from_disk() -> void:
	store.clear_cache()


func reset_profile() -> void:
	snapshot("reset")
	store.erase(ProfileRepository.key_for(profile_id))
	store.erase(ProgressRepository.key_for(profile_id))
	store.erase(InventoryRepository.key_for(profile_id))
	GameLog.info("Save", "Progresso do perfil %s apagado" % profile_id)


func _save_keys() -> Array[String]:
	return [ProfileRepository.key_for(profile_id), ProgressRepository.key_for(profile_id),
		InventoryRepository.key_for(profile_id), SettingsRepository.KEY]


## Há algo que valha guardar? (perfil novo/vazio não sobrescreve cópias boas)
func has_progress() -> bool:
	var pd := progress.data(profile_id)
	return not (pd["attempts"] as Array).is_empty() or not (pd["missions_done"] as Dictionary).is_empty()


## Guarda o estado atual (como está no disco, depois do flush) em "snap_<tag>". Escrita atômica com .bak.
## Tags de data entram na rotação diária; "reset" e "undo" são fixas.
func snapshot(tag: String) -> bool:
	if not has_progress():
		return false
	flush()
	var pack := {}
	for k in _save_keys():
		var raw: Variant = store.backend.read(k)
		if raw is Dictionary:
			pack[k] = raw
	store.backend.last_recovery = ""
	if pack.is_empty() or not store.backend.write("snap_%s" % tag, {"t": int(Time.get_unix_time_from_system()), "keys": pack}):
		return false
	if tag in ["reset", "undo"]:
		return true
	var tags := snapshot_tags()
	tags.erase(tag)
	tags.append(tag)
	while tags.size() > MAX_SNAPSHOTS:
		store.backend.remove("snap_%s" % str(tags.pop_front()))
	store.backend.write(SNAP_INDEX, {"list": tags})
	return true


## Cópia do dia: feita ao abrir o app (guarda como estava antes de jogar hoje).
func snapshot_daily(today: String) -> bool:
	if snapshot_tags().has(today):
		return false
	return snapshot(today)


## Datas das cópias diárias, da mais antiga para a mais nova.
func snapshot_tags() -> Array:
	var idx: Variant = store.backend.read(SNAP_INDEX)
	store.backend.last_recovery = ""
	if idx is Dictionary and idx.get("list") is Array:
		return (idx["list"] as Array).duplicate()
	return []


func has_snapshot(tag: String) -> bool:
	return store.backend.has("snap_%s" % tag)


func snapshot_time(tag: String) -> int:
	var raw: Variant = store.backend.read("snap_%s" % tag)
	store.backend.last_recovery = ""
	return int(raw.get("t", 0)) if raw is Dictionary else 0


## Volta tudo para a cópia `tag`. Antes, guarda o estado atual em "undo" (dá para desfazer).
func restore_snapshot(tag: String) -> bool:
	var raw: Variant = store.backend.read("snap_%s" % tag)
	store.backend.last_recovery = ""
	if not raw is Dictionary or not raw.get("keys") is Dictionary or (raw["keys"] as Dictionary).is_empty():
		return false
	if tag != "undo":
		snapshot("undo")
	var keys: Dictionary = raw["keys"]
	for k in keys:
		if keys[k] is Dictionary:
			store.backend.write(str(k), keys[k])
	store.clear_cache()
	GameLog.info("Save", "Progresso restaurado da cópia %s" % tag)
	return true
