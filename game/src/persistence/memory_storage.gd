class_name MemoryStorage
extends StorageBackend
## Backend em memória para testes (e fallback se o disco falhar).

var data: Dictionary = {}


func read(key: String) -> Variant:
	if not data.has(key):
		return null
	return (data[key] as Dictionary).duplicate(true)


func write(key: String, value: Dictionary) -> bool:
	# Simula o round-trip JSON (números viram float) para os testes pegarem bugs de tipo.
	data[key] = JSON.parse_string(JSON.stringify(value))
	return true


func remove(key: String) -> void:
	data.erase(key)


func has(key: String) -> bool:
	return data.has(key)
