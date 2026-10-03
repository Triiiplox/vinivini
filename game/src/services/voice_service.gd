extends Node
## Narração natural pré-gerada (Kokoro, offline) — sem TTS do sistema.
## Cada fala é identificada por md5(quem|texto-modelo). O texto-modelo pode conter {name}.
## tools/gen_voice.py varre código e conteúdo e gera assets/voice/*.ogg + manifest.json.

signal line_started(text: String, who: String)
signal line_finished

const MANIFEST_PATH := "res://assets/voice/manifest.json"
const VOICE_DIR := "res://assets/voice/"

var enabled := true
var missing: Array[String] = []
var current_text := ""
var current_who := ""
var _current_entry: Dictionary = {}
var _manifest: Dictionary = {}
var _player: AudioStreamPlayer
var _queue: Array = []
var _speaking := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.bus = "Narrator"
	add_child(_player)
	_player.finished.connect(_on_finished)
	var f := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if f:
		var d: Variant = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			_manifest = d
	enabled = bool(SaveService.settings.get_value("voice"))


static func key_for(text: String, who: String = "narrator") -> String:
	return ("%s|%s" % [who, normalize(text)]).md5_text().substr(0, 12)


## O áudio é gerado com o modelo "{name}"; textos já personalizados voltam ao modelo.
static func normalize(text: String) -> String:
	var t := text.strip_edges()
	var n := AppState.child_name() if Engine.get_main_loop() and AppState else "Vini"
	if n != "" and t.contains(n):
		t = t.replace(n, "{name}")
	return t


func has_line(text: String, who: String = "narrator") -> bool:
	return _manifest.has(key_for(text, who))


## Duração (s) da fala, ou estimativa se não houver áudio.
func duration(text: String, who: String = "narrator") -> float:
	var e: Dictionary = _manifest.get(key_for(text, who), {})
	return float(e.get("d", 0.4 + text.length() * 0.065))


## Fala um texto-modelo. Interrompe a fala anterior por padrão (nunca sobrepõe vozes).
func say(text: String, who: String = "narrator", interrupt: bool = true) -> float:
	if text.strip_edges() == "":
		return 0.0
	if interrupt:
		_queue.clear()
		_player.stop()
	elif _speaking:
		_queue.append([text, who])
		return duration(text, who)
	return _play(text, who)


func cosmo(text: String, interrupt: bool = true) -> float:
	return say(text, "cosmo", interrupt)


## Fila de falas: [[texto, quem], ...] ou [texto, ...].
func say_sequence(lines: Array) -> float:
	_queue.clear()
	_player.stop()
	var total := 0.0
	for l in lines:
		var pair: Array = l if l is Array else [str(l), "narrator"]
		_queue.append(pair)
		total += duration(pair[0], pair[1]) + 0.08
	_next()
	return total


func stop() -> void:
	_queue.clear()
	_player.stop()
	if _speaking:
		_speaking = false
		line_finished.emit()


func is_speaking() -> bool:
	return _speaking


func _play(text: String, who: String) -> float:
	current_text = text
	current_who = who
	var e: Dictionary = _manifest.get(key_for(text, who), {})
	_current_entry = e
	line_started.emit(text, who)
	if not enabled or e.is_empty():
		if e.is_empty() and not missing.has(text):
			missing.append(text)
			GameLog.warn("Voice", "sem áudio: [%s] %s" % [who, text])
		_speaking = false
		if not _queue.is_empty():
			_next.call_deferred()
		return 0.0
	var stream: AudioStream = load(VOICE_DIR + str(e["f"]))
	if stream == null:
		return 0.0
	_player.stream = stream
	_player.play()
	_speaking = true
	return float(e.get("d", 1.0))


func _next() -> void:
	if _queue.is_empty():
		return
	var pair: Array = _queue.pop_front()
	_play(pair[0], pair[1])


func _on_finished() -> void:
	_speaking = false
	line_finished.emit()
	if not _queue.is_empty():
		get_tree().create_timer(0.08).timeout.connect(_next)


func set_enabled(on: bool) -> void:
	enabled = on
	SaveService.settings.set_value("voice", on)
	if not on:
		stop()


## Visema atual (A, E, O, MBP, REST) da fala tocando, pelos markers gerados no build (lip-sync).
func viseme_now() -> String:
	if not _speaking or _current_entry.is_empty():
		return "REST"
	var marks: Array = _current_entry.get("v", [])
	if marks.is_empty():
		return "A" if fmod(_player.get_playback_position(), 0.3) < 0.15 else "REST"
	var t := _player.get_playback_position()
	var cur := "REST"
	for m in marks:
		if float(m[0]) > t:
			break
		cur = str(m[1])
	return cur
