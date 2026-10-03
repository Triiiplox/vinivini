extends Node
## Ponto único de acesso aos repositories. O backend físico é injetável
## (JsonFileStorage em produção, MemoryStorage nos testes).

const DEFAULT_PROFILE := "vini"

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
	store.erase(ProfileRepository.key_for(profile_id))
	store.erase(ProgressRepository.key_for(profile_id))
	store.erase(InventoryRepository.key_for(profile_id))
	GameLog.info("Save", "Progresso do perfil %s apagado" % profile_id)
