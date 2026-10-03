class_name VersionedStore
extends RefCounted
## Camada entre repositories e StorageBackend: envelope, migração, padrões e cache.

var backend: StorageBackend
var recoveries: Array[String] = []
var _cache: Dictionary = {}


func _init(b: StorageBackend) -> void:
	backend = b


func has(key: String) -> bool:
	return _cache.has(key) or backend.has(key)


## Retorna referência viva (cacheada). Quem altera deve chamar save(key).
func load(key: String, defaults: Dictionary) -> Dictionary:
	if _cache.has(key):
		return _cache[key]
	var raw: Variant = backend.read(key)
	if backend.last_recovery != "":
		recoveries.append(backend.last_recovery)
		backend.last_recovery = ""
	var data: Dictionary = {}
	if raw is Dictionary:
		data = SaveMigrations.migrate(raw)
	data = SaveMigrations.merge_defaults(data, defaults)
	_cache[key] = data
	return data


func save(key: String) -> bool:
	if not _cache.has(key):
		return false
	var env := SaveMigrations.wrap(_cache[key], int(Time.get_unix_time_from_system()))
	return backend.write(key, env)


func erase(key: String) -> void:
	_cache.erase(key)
	backend.remove(key)


func clear_cache() -> void:
	_cache.clear()
