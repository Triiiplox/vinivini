class_name InventoryRepository
extends RefCounted
## Estrelas (não monetárias, nunca gastas), itens desbloqueados e equipados.

var _store: VersionedStore


func _init(store: VersionedStore) -> void:
	_store = store


static func key_for(profile_id: String) -> String:
	return "inventory_%s" % profile_id


static func defaults() -> Dictionary:
	return {"stars": 0, "unlocked": [], "unseen": []}


func data(profile_id: String) -> Dictionary:
	return _store.load(key_for(profile_id), defaults())


## Retorna true se o item era novo.
func unlock_item(profile_id: String, item_id: String, mark_unseen: bool = true) -> bool:
	var d := data(profile_id)
	var unlocked: Array = d["unlocked"]
	if unlocked.has(item_id):
		return false
	unlocked.append(item_id)
	if mark_unseen:
		(d["unseen"] as Array).append(item_id)
	_store.save(key_for(profile_id))
	return true


func is_unlocked(profile_id: String, item_id: String) -> bool:
	return (data(profile_id)["unlocked"] as Array).has(item_id)


func list_items(profile_id: String) -> Array:
	return (data(profile_id)["unlocked"] as Array).duplicate()


func mark_seen(profile_id: String, item_id: String) -> void:
	var unseen: Array = data(profile_id)["unseen"]
	if unseen.has(item_id):
		unseen.erase(item_id)
		_store.save(key_for(profile_id))


func unseen_items(profile_id: String) -> Array:
	return (data(profile_id)["unseen"] as Array).duplicate()


func add_stars(profile_id: String, amount: int) -> int:
	var d := data(profile_id)
	d["stars"] = int(d["stars"]) + maxi(0, amount)
	_store.save(key_for(profile_id))
	return int(d["stars"])


func get_stars(profile_id: String) -> int:
	return int(data(profile_id)["stars"])
