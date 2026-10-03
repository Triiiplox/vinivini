class_name ProfileRepository
extends RefCounted
## Perfil infantil e avatar.

var _store: VersionedStore


func _init(store: VersionedStore) -> void:
	_store = store


static func key_for(profile_id: String) -> String:
	return "profile_%s" % profile_id


static func default_avatar() -> Dictionary:
	return {
		"skin": "skin_3",
		"hair_style": "short",
		"hair_color": "hair_brown",
		"suit": "suit_blue",
		"helmet": "helmet_none",
		"accessory": "acc_none",
		"pet": "pet_bip",
	}


static func default_profile(profile_id: String) -> Dictionary:
	return {
		"id": profile_id,
		"name": "Vini",
		"created": false,
		"created_at": 0,
		"intro_seen": false,
		"avatar": default_avatar(),
	}


func has_profile(profile_id: String) -> bool:
	return _store.has(key_for(profile_id)) and bool(load_profile(profile_id).get("created", false))


func load_profile(profile_id: String) -> Dictionary:
	return _store.load(key_for(profile_id), default_profile(profile_id))


func save_profile(profile: Dictionary) -> bool:
	var key := key_for(str(profile.get("id", "")))
	var live := _store.load(key, default_profile(str(profile.get("id", ""))))
	if live != profile:
		live.merge(profile, true)
	return _store.save(key)


func save_avatar(profile_id: String, avatar: Dictionary) -> bool:
	var p := load_profile(profile_id)
	p["avatar"] = avatar.duplicate(true)
	return _store.save(key_for(profile_id))
