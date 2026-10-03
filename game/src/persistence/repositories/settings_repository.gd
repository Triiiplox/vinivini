class_name SettingsRepository
extends RefCounted
## Preferências do dispositivo (áudio, voz, lembrete de pausa).

const KEY := "settings"

var _store: VersionedStore


func _init(store: VersionedStore) -> void:
	_store = store


static func defaults() -> Dictionary:
	return {"music": true, "sfx": true, "voice": true, "break_reminder_min": 0}


func get_value(key: String) -> Variant:
	return _store.load(KEY, defaults()).get(key, defaults().get(key))


func set_value(key: String, value: Variant) -> void:
	_store.load(KEY, defaults())[key] = value
	_store.save(KEY)


func all() -> Dictionary:
	return _store.load(KEY, defaults())
