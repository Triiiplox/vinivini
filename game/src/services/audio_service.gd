extends Node
## Mixagem: buses Music, Ambience, Narrator, Character, SFX, UI (todos -> Master).
## Música por contexto com crossfade; ambiente em loop; efeitos com pool; ducking durante a narração.
## A antiga API speak() delega para Voice (narração pré-gerada).

const BUSES := ["Music", "Ambience", "Narrator", "Character", "SFX", "UI"]
const MUSIC_DB := -9.0
const DUCK_DB := -19.0
const SFX_POOL := 8
## Música do "modo poderoso" no voo: arquivo particular da família (fica fora do git e do APK público).
const POWER_SONG := "res://assets/private/poder.ogg"

var music_on := true
var sfx_on := true
var voice_on := true

var current_music := ""
var last_spoken := ""

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _power: AudioStreamPlayer
var _power_tw: Tween
var _ambience: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var _pool_i := 0
var _streams: Dictionary = {}
var _duck_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for b in BUSES:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, b)
			AudioServer.set_bus_send(idx, "Master")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), MUSIC_DB)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambience"), -14.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("UI"), -6.0)
	apply_volumes.call_deferred()
	_music_a = _player("Music")
	_music_b = _player("Music")
	_ambience = _player("Ambience")
	for i in SFX_POOL:
		_pool.append(_player("SFX"))
	music_on = bool(SaveService.settings.get_value("music"))
	sfx_on = bool(SaveService.settings.get_value("sfx"))
	voice_on = bool(SaveService.settings.get_value("voice"))
	Voice.line_started.connect(func(_t, _w): _duck(true))
	Voice.line_finished.connect(func(): _duck(false))


func _player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func _stream(path: String) -> AudioStream:
	if not _streams.has(path):
		var s: AudioStream = load(path) if ResourceLoader.exists(path) else null
		if s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = path.contains("/music/") or path.contains("/ambience/")
		elif s is AudioStreamWAV and (path.contains("/music/") or path.contains("/ambience/")):
			var w := s as AudioStreamWAV
			w.loop_mode = AudioStreamWAV.LOOP_FORWARD
			w.loop_end = int(w.get_length() * w.mix_rate)
		_streams[path] = s
	return _streams[path]


## Música contextual com crossfade: hub, map, explore, flight, puzzle, kitchen, story, boss, title.
func play_music(name: String = "hub", fade: float = 1.2) -> void:
	if name == current_music and (_music_a.playing or _music_b.playing):
		return
	current_music = name
	if not music_on:
		return
	var s := _stream("res://assets/music/%s.ogg" % name)
	if s == null:
		return
	var old := _music_a if _music_a.playing else _music_b
	var nw := _music_b if old == _music_a else _music_a
	nw.stream = s
	nw.volume_db = -40.0
	nw.play()
	var t := create_tween().set_parallel()
	t.tween_property(nw, "volume_db", 0.0, fade)
	if old.playing:
		t.tween_property(old, "volume_db", -40.0, fade)
		t.chain().tween_callback(old.stop)


## Toca a música do modo poderoso por cima (a música do jogo abaixa) por sec segundos. false se não houver o arquivo.
func play_power(sec: float) -> bool:
	if not music_on or not ResourceLoader.exists(POWER_SONG):
		return false
	if _power == null:
		_power = _player("Music")
	if _power_tw:
		_power_tw.kill()
	_power.stream = _stream(POWER_SONG)
	_power.volume_db = 0.0
	_power.play()
	_music_a.volume_db = -40.0
	_music_b.volume_db = -40.0
	_power_tw = create_tween()
	_power_tw.tween_interval(sec)
	_power_tw.tween_callback(stop_power)
	return true


func stop_power() -> void:
	if _power == null or not _power.playing:
		return
	if _power_tw:
		_power_tw.kill()
	_power_tw = create_tween().set_parallel()
	_power_tw.tween_property(_power, "volume_db", -40.0, 1.0)
	_power_tw.tween_property(_music_a, "volume_db", 0.0, 1.0)
	_power_tw.tween_property(_music_b, "volume_db", 0.0, 1.0)
	_power_tw.chain().tween_callback(_power.stop)


func play_ambience(name: String) -> void:
	if name == "":
		_ambience.stop()
		return
	var s := _stream("res://assets/ambience/%s.ogg" % name)
	if s and _ambience.stream != s:
		_ambience.stream = s
		_ambience.play()


func stop_music() -> void:
	_music_a.stop()
	_music_b.stop()


func play_sfx(sfx_name: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not sfx_on:
		return
	var s := _stream("res://assets/sfx/%s.ogg" % sfx_name)
	if s == null:
		GameLog.warn("Audio", "sfx inexistente: %s" % sfx_name)
		return
	var p := _pool[_pool_i]
	_pool_i = (_pool_i + 1) % _pool.size()
	p.stream = s
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


## Compatibilidade: fala via narração pré-gerada.
func speak(text: String, interrupt: bool = true) -> void:
	last_spoken = text
	Voice.say(text, "narrator", interrupt)


func stop_speech() -> void:
	Voice.stop()


func has_voice() -> bool:
	return Voice.enabled


func _duck(on: bool) -> void:
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween().set_parallel()
	var mi := AudioServer.get_bus_index("Music")
	var ai := AudioServer.get_bus_index("Ambience")
	var vol := linear_to_db(maxf(float(SaveService.settings.get_value("vol_music")), 0.001))
	_duck_tween.tween_method(func(v): AudioServer.set_bus_volume_db(mi, v), AudioServer.get_bus_volume_db(mi),
		(DUCK_DB if on else MUSIC_DB) + vol, 0.35)
	_duck_tween.tween_method(func(v): AudioServer.set_bus_volume_db(ai, v), AudioServer.get_bus_volume_db(ai), -22.0 if on else -14.0, 0.35)


## Volumes da área dos pais (0–1): Música; Efeitos (SFX + UI); Voz (narrador + personagens).
func apply_volumes() -> void:
	var m := float(SaveService.settings.get_value("vol_music"))
	var f := float(SaveService.settings.get_value("vol_sfx"))
	var v := float(SaveService.settings.get_value("vol_voice"))
	for pair in [["Music", m, MUSIC_DB], ["SFX", f, 0.0], ["UI", f, -6.0], ["Narrator", v, 0.0], ["Character", v, 0.0]]:
		var idx := AudioServer.get_bus_index(str(pair[0]))
		if idx >= 0:
			AudioServer.set_bus_volume_db(idx, float(pair[2]) + linear_to_db(maxf(float(pair[1]), 0.001)))


func set_music_enabled(on: bool) -> void:
	music_on = on
	SaveService.settings.set_value("music", on)
	if on:
		var m := current_music
		current_music = ""
		play_music(m if m != "" else "hub")
	else:
		stop_music()
	EventBus.settings_changed.emit("music", on)


func set_sfx_enabled(on: bool) -> void:
	sfx_on = on
	SaveService.settings.set_value("sfx", on)
	EventBus.settings_changed.emit("sfx", on)


func set_voice_enabled(on: bool) -> void:
	voice_on = on
	Voice.set_enabled(on)
	EventBus.settings_changed.emit("voice", on)


func pause_all(paused: bool) -> void:
	_music_a.stream_paused = paused
	_music_b.stream_paused = paused
	_ambience.stream_paused = paused
	if paused:
		Voice.stop()


## Vibração leve (configurável). Requer permissão VIBRATE no Android.
func haptic(ms: int = 30) -> void:
	if bool(SaveService.settings.get_value("haptics")) and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms, 0.5)
