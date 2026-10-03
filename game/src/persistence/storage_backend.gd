class_name StorageBackend
extends RefCounted
## Interface de armazenamento chave -> Dictionary.
## O jogo nunca fala com arquivo diretamente: só repositories conhecem esta interface.

## Descrição da última recuperação feita (backup usado, arquivo corrompido etc.).
var last_recovery := ""


## Retorna Dictionary ou null quando ausente/irrecuperável.
func read(_key: String) -> Variant:
	return null


func write(_key: String, _data: Dictionary) -> bool:
	return false


func remove(_key: String) -> void:
	pass


func has(_key: String) -> bool:
	return false
