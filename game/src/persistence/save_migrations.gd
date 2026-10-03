class_name SaveMigrations
extends RefCounted
## Versionamento de save.
## v1: dicionário cru, sem envelope (formato legado/protótipo).
## v2: envelope {"schema_version": 2, "saved_at": unix, "data": {...}}.
## Toda migração é pura e testada; nunca apaga dados desconhecidos.

const CURRENT_VERSION := 2


static func version_of(raw: Dictionary) -> int:
	if raw.has("schema_version"):
		return int(raw["schema_version"])
	return 1


## Recebe o conteúdo bruto lido do storage e devolve o `data` na versão atual.
static func migrate(raw: Dictionary) -> Dictionary:
	var version := version_of(raw)
	var data: Dictionary
	if version == 1:
		data = raw.duplicate(true)
		version = 2
	else:
		var d: Variant = raw.get("data", {})
		data = (d as Dictionary).duplicate(true) if d is Dictionary else {}
	# Futuras migrações: if version == 2: data = _v2_to_v3(data); version = 3
	return data


static func wrap(data: Dictionary, now: int) -> Dictionary:
	return {"schema_version": CURRENT_VERSION, "saved_at": now, "data": data}


## Completa chaves ausentes com os padrões, recursivamente, sem sobrescrever.
static func merge_defaults(data: Dictionary, defaults: Dictionary) -> Dictionary:
	var out := data.duplicate(true)
	for k in defaults:
		if not out.has(k):
			out[k] = defaults[k].duplicate(true) if (defaults[k] is Dictionary or defaults[k] is Array) else defaults[k]
		elif out[k] is Dictionary and defaults[k] is Dictionary:
			out[k] = merge_defaults(out[k], defaults[k])
		elif typeof(out[k]) != typeof(defaults[k]) and not _numeric_pair(out[k], defaults[k]):
			# Tipo inválido (save adulterado/corrompido): volta ao padrão.
			out[k] = defaults[k].duplicate(true) if (defaults[k] is Dictionary or defaults[k] is Array) else defaults[k]
	return out


static func _numeric_pair(a: Variant, b: Variant) -> bool:
	var ta := typeof(a)
	var tb := typeof(b)
	return (ta == TYPE_INT or ta == TYPE_FLOAT) and (tb == TYPE_INT or tb == TYPE_FLOAT)
