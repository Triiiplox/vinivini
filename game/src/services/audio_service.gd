extends Node
## Música, efeitos e narração (TTS do sistema, offline no Android).
## Toda instrução falada também aparece em texto: som nunca é a única via.

const SFX := ["tap", "count", "correct", "retry", "celebrate", "unlock", "levelup", "whoosh", "pad_0", "pad_1", "pad_2", "pad_3", "page"]
const MUSIC_DB := -14.0
const MUSIC_DUCK_DB := -24.0
const SFX_POOL := 5
const MAX_VOICE_TRIES := 8

var music_on := true
var sfx_on := true
var voice_on := true
var last_spoken := ""

var _streams: Dictionary = {}
var _music: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var _pool_i := 0
var _tts_available := false
var _voice_id := ""
var _speaking := 0
var _duck_tween: Tween
var _voice_tries := 0
var _next_voice_try_ms := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in SFX:
		var s: AudioStream = load("res://assets/audio/%s.wav" % n)
		if s:
			_streams[n] = s
		else:
			GameLog.warn("Audio", "SFX ausente: %s" % n)
	for i in SFX_POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_DB
	add_child(_music)
	var m: AudioStream = load("res://assets/audio/music_loop.wav")
	if m is AudioStreamWAV:
		var w := m as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(w.get_length() * w.mix_rate)
		_music.stream = w
	music_on = bool(SaveService.settings.get_value("music"))
	sfx_on = bool(SaveService.settings.get_value("sfx"))
	voice_on = bool(SaveService.settings.get_value("voice"))
	_init_tts()


func _init_tts() -> void:
	_tts_available = (
		DisplayServer.get_name() != "headless"
		and ProjectSettings.get_setting("audio/general/text_to_speech", false)
		and DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH)
	)
	if not _tts_available:
		GameLog.info("Audio", "TTS indisponível; instruções seguem em texto")
		return
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, _on_utterance_done)
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_CANCELED, _on_utterance_done)
	_pick_voice()


## No Android o motor de TTS inicializa de forma assíncrona: tentamos de novo ao falar.
func _pick_voice() -> void:
	if _voice_tries >= MAX_VOICE_TRIES or Time.get_ticks_msec() < _next_voice_try_ms:
		return
	_voice_tries += 1
	_next_voice_try_ms = Time.get_ticks_msec() + 1500
	if OS.get_name() == "Linux" and not FileAccess.file_exists("/usr/lib/x86_64-linux-gnu/libspeechd.so.2"):
		_voice_tries = MAX_VOICE_TRIES
		return
	var voices := DisplayServer.tts_get_voices()
	var fallback := ""
	for v in voices:
		var lang := str(v.get("language", "")).to_lower().replace("_", "-")
		if lang.begins_with("pt"):
			if lang.contains("br"):
				_voice_id = str(v.get("id", ""))
				return
			if fallback == "":
				fallback = str(v.get("id", ""))
	_voice_id = fallback
	if _voice_id != "":
		GameLog.info("Audio", "Voz TTS: %s" % _voice_id)


func has_voice() -> bool:
	return _tts_available and _voice_id != ""


func play_music() -> void:
	if music_on and _music.stream and not _music.playing:
		_music.play()


func stop_music() -> void:
	_music.stop()


func play_sfx(sfx_name: String, pitch: float = 1.0) -> void:
	if not sfx_on or not _streams.has(sfx_name):
		return
	var p := _pool[_pool_i]
	_pool_i = (_pool_i + 1) % _pool.size()
	p.stream = _streams[sfx_name]
	p.pitch_scale = pitch
	p.play()


## Fala o texto (interrompe a fala anterior para nunca sobrepor vozes).
func speak(text: String, interrupt: bool = true) -> void:
	last_spoken = text
	if not voice_on or not _tts_available or text.strip_edges() == "":
		return
	if _voice_id == "":
		_pick_voice()
	if _voice_id == "":
		return
	if interrupt:
		DisplayServer.tts_stop()
		_speaking = 0
	_speaking += 1
	_duck(true)
	DisplayServer.tts_speak(text, _voice_id, 100, 1.05, 0.95, 0, false)


func stop_speech() -> void:
	if _tts_available:
		DisplayServer.tts_stop()
	_speaking = 0
	_duck(false)


func _on_utterance_done(_id: int) -> void:
	_speaking = maxi(0, _speaking - 1)
	if _speaking == 0:
		_duck(false)


func _duck(on: bool) -> void:
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(_music, "volume_db", MUSIC_DUCK_DB if on else MUSIC_DB, 0.3)


func set_music_enabled(on: bool) -> void:
	music_on = on
	SaveService.settings.set_value("music", on)
	if on:
		play_music()
	else:
		stop_music()
	EventBus.settings_changed.emit("music", on)


func set_sfx_enabled(on: bool) -> void:
	sfx_on = on
	SaveService.settings.set_value("sfx", on)
	EventBus.settings_changed.emit("sfx", on)


func set_voice_enabled(on: bool) -> void:
	voice_on = on
	SaveService.settings.set_value("voice", on)
	if not on:
		stop_speech()
	EventBus.settings_changed.emit("voice", on)


func pause_all(paused: bool) -> void:
	_music.stream_paused = paused
	if paused:
		stop_speech()
