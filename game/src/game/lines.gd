class_name Lines
extends RefCounted
## Marca textos narrados para o gerador de voz (tools/gen_voice.py varre Lines.n("...") e Lines.c("...")).
## n = narradora, c = Cosmo. Também guarda o vocabulário falado dinâmico (números, sílabas).

const NUMBERS := ["zero", "um", "dois", "três", "quatro", "cinco", "seis", "sete", "oito", "nove", "dez",
	"onze", "doze", "treze", "catorze", "quinze", "dezesseis", "dezessete", "dezoito", "dezenove", "vinte"]
const NUMBERS_F := ["zero", "uma", "duas", "três", "quatro", "cinco", "seis", "sete", "oito", "nove", "dez",
	"onze", "doze", "treze", "catorze", "quinze", "dezesseis", "dezessete", "dezoito", "dezenove", "vinte"]


static func n(text: String) -> String:
	return text


static func c(text: String) -> String:
	return text


static func number(v: int) -> String:
	return NUMBERS[clampi(v, 0, 20)]


## Fala de uma sílaba (vogal aberta acentuada para a voz pronunciar isolada).
static func syllable_say(syl: String) -> String:
	var bank: Dictionary = ContentService.repo.banks.get("syllables", {})
	return str(bank.get("say", {}).get(syl, syl.to_lower()))


## Nome falado de uma figura do banco "words" (ex.: "robo" → "robô").
static func word_say(pic: String) -> String:
	for w in ContentService.repo.banks.get("words", {}).get("words", []):
		if str(w.get("pic", "")) == pic:
			return str(w.get("say", w.get("word", pic)))
	return pic


static func word_entry(pic: String) -> Dictionary:
	for w in ContentService.repo.banks.get("words", {}).get("words", []):
		if str(w.get("pic", "")) == pic:
			return w
	return {}
