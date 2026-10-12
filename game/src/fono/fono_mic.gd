class_name FonoMic
extends Node
## Microfone do módulo FALA (o Andro autorizou: "só no aparelho"). Grava a fala da criança SÓ NA MEMÓRIA (nunca vai
## para arquivo nem para a internet) e toca de volta para ela se ouvir — a automonitorização pedida no programa
## da fono. Mede ao vivo o "chiado" das fricativas: centroide espectral entre 1,5 e 11 kHz; CH/J (ʃ/ʒ) têm o ruído
## mais grave, S/Z (s/z) mais agudo (Zharkova, Hardcastle & Gibbon 2018: crianças separam /s/ e /ʃ/ pelo
## centroide). É PISTA, não nota: quem confirma o acerto é o adulto. Fronteira começa em 6 kHz (criança fala mais
## agudo que adulto) e se ajusta às falas que o adulto confirmou (FonoData.meter_samples).
## Permissão RECORD_AUDIO só é pedida ao entrar no módulo (Android pergunta uma vez). Vale também na TV (microfone do
## controle/TV): `peak` guarda o maior volume da última gravação, para avisar o adulto se o microfone não capta.
## VIBRAÇÃO (P8, J × CH): /ʒ/ e /ʃ/ têm o mesmo chiado; o J tem também energia grave (< 500 Hz) da voz. `voiced`
## liga quando há chiado E energia grave sem ser vogal (voicing_cue). É PISTA opcional ("mão no pescoço"), não nota.

signal permission_result(granted: bool)

const BUS := "FonoMic"
const DEFAULT_SPLIT := 6000.0
const BANDS_FROM := 1500.0
const BANDS_TO := 11000.0
const BAND := 500.0
const HISS_MIN := 0.004
const VOICE_MIN := 0.002

var granted := false
var level := 0.0  ## volume da voz agora (0..1)
var centroid := 0.0  ## Hz do chiado agora (0 = sem chiado)
var hiss := false  ## tem chiado agora (fricativa)
var voiced := false  ## chiado com a garganta vibrando agora (J, Z): pista
var peak := 0.0  ## maior volume (0..1) da gravação atual/última
var _player: AudioStreamPlayer
var _rec: AudioEffectRecord
var _spec: AudioEffectSpectrumAnalyzerInstance
var _bus := -1
var _samples: Array[float] = []
var _recording := false


func _ready() -> void:
	_setup_bus()
	granted = not OS.has_feature("android") or OS.get_granted_permissions().has("android.permission.RECORD_AUDIO")
	if OS.has_feature("android"):
		get_tree().on_request_permissions_result.connect(func(p: String, ok: bool):
			if p == "android.permission.RECORD_AUDIO":
				granted = ok
				if ok:
					_start_listen()
				permission_result.emit(ok))
	if granted:
		_start_listen()


## Pede a permissão (Android mostra o aviso uma vez). Devolve true se já tinha.
func ask() -> bool:
	if granted:
		return true
	OS.request_permission("android.permission.RECORD_AUDIO")
	return false


func _setup_bus() -> void:
	_bus = AudioServer.get_bus_index(BUS)
	if _bus == -1:
		AudioServer.add_bus()
		_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_bus, BUS)
		AudioServer.add_bus_effect(_bus, AudioEffectRecord.new())
		var sa := AudioEffectSpectrumAnalyzer.new()
		sa.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_1024
		AudioServer.add_bus_effect(_bus, sa)
		# A voz da criança não sai na caixa de som (senão realimenta): o bus fica mudo, os efeitos medem antes.
		AudioServer.set_bus_volume_db(_bus, -80.0)
	_rec = AudioServer.get_bus_effect(_bus, 0) as AudioEffectRecord
	_spec = AudioServer.get_bus_effect_instance(_bus, 1) as AudioEffectSpectrumAnalyzerInstance


func _start_listen() -> void:
	if _player != null:
		return
	_player = AudioStreamPlayer.new()
	_player.stream = AudioStreamMicrophone.new()
	_player.bus = BUS
	add_child(_player)
	_player.play()


func _exit_tree() -> void:
	if _rec and _rec.is_recording_active():
		_rec.set_recording_active(false)


func _process(_delta: float) -> void:
	if _spec == null or _player == null:
		return
	var low := _mag(80.0, 1200.0)
	var total := 0.0
	var wsum := 0.0
	var f := BANDS_FROM
	while f < BANDS_TO:
		var m := _mag(f, f + BAND)
		total += m
		wsum += m * (f + BAND / 2.0)
		f += BAND
	level = clampf(sqrt(low + total) * 6.0, 0.0, 1.0)
	# Fricativa: muita energia acima de 1,5 kHz e pouca voz grave (vogal); limiar baixo de propósito (criança).
	hiss = total > HISS_MIN and total > low * 1.2
	voiced = voicing_cue(_mag(80.0, 500.0), total)
	centroid = wsum / total if (hiss or voiced) and total > 0.0 else 0.0
	if _recording:
		peak = maxf(peak, level)
		if hiss or voiced:
			_samples.append(centroid)


func _mag(a: float, b: float) -> float:
	var v := _spec.get_magnitude_for_frequency_range(a, b)
	return (v.x + v.y) / 2.0


# ------------------------------------------------------------------ gravar e ouvir de volta
func start_recording() -> void:
	_samples.clear()
	peak = 0.0
	_recording = true
	if _rec:
		_rec.set_recording_active(true)


## Para a gravação; devolve a fala (em memória) ou null.
func stop_recording() -> AudioStreamWAV:
	_recording = false
	if _rec == null or not _rec.is_recording_active():
		return null
	_rec.set_recording_active(false)
	return _rec.get_recording()


## Centroide mediano do chiado na última gravação (0 se não teve chiado).
func last_centroid() -> float:
	if _samples.size() < 3:
		return 0.0
	var s := _samples.duplicate()
	s.sort()
	return s[s.size() / 2]


# ------------------------------------------------------------------ medidor
## "Garganta vibrando" (P8): chiado (energia acima de 1,5 kHz) junto com energia abaixo de 500 Hz, mas sem a
## energia grave dominar (aí é vogal, não fricativa). Pista para J × CH; precisa ser calibrada no aparelho.
static func voicing_cue(low500: float, high: float) -> bool:
	return high > HISS_MIN and low500 > VOICE_MIN and low500 < high * 3.0


## Fronteira entre o chiado "grosso" (CH/J) e o "fino" (S/Z): meio das médias confirmadas, ou o padrão.
static func split_hz() -> float:
	var m := FonoData.meter_samples()
	var a: Array = m.get("ʃ", [])
	var b: Array = m.get("s", [])
	if a.size() >= 3 and b.size() >= 3:
		return (_avg(a) + _avg(b)) / 2.0
	if a.size() >= 3:
		return _avg(a) + 1200.0
	if b.size() >= 3:
		return _avg(b) - 1200.0
	return DEFAULT_SPLIT


static func _avg(a: Array) -> float:
	var t := 0.0
	for x in a:
		t += float(x)
	return t / maxf(1.0, a.size())


## Para onde o chiado aponta: "ʃ" (CH/J), "s" (S/Z) ou "" (sem chiado).
static func classify(hz: float) -> String:
	if hz <= 0.0:
		return ""
	return "ʃ" if hz < split_hz() else "s"
