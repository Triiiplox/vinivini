extends Node
## Estado da sessão: perfil atual, tempo jogado, lembrete de pausa.

const FLUSH_EVERY_SEC := 20.0

var session_seconds := 0.0
var break_reminder_shown := false
var _pending_seconds := 0.0
var _paused := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	RewardService.ensure_starter_items()
	RewardService.refresh_name()
	EventBus.session_started.emit()
	Telemetry.session_started.call_deferred()


func profile() -> Dictionary:
	return SaveService.profiles.load_profile(SaveService.profile_id)


func has_profile() -> bool:
	return SaveService.profiles.has_profile(SaveService.profile_id)


func child_name() -> String:
	var n := str(profile().get("name", "Vini")).strip_edges()
	return n if n != "" else "Vini"


func avatar() -> Dictionary:
	return profile().get("avatar", ProfileRepository.default_avatar())


func save_avatar(av: Dictionary) -> void:
	var p := profile()
	p["avatar"] = av.duplicate(true)
	if not bool(p.get("created", false)):
		p["created"] = true
		p["created_at"] = int(Time.get_unix_time_from_system())
	SaveService.profiles.save_profile(p)
	EventBus.avatar_changed.emit(p["avatar"])


func set_child_name(n: String) -> void:
	var p := profile()
	p["name"] = n.strip_edges().substr(0, 16)
	SaveService.profiles.save_profile(p)
	RewardService.refresh_name()


func equip(item: Dictionary) -> void:
	var av := avatar().duplicate(true)
	av[str(item["slot"])] = item["id"]
	save_avatar(av)
	SaveService.inventory.mark_seen(SaveService.profile_id, item["id"])


func today() -> String:
	return Time.get_date_string_from_system()


func played_today_seconds() -> float:
	return SaveService.progress.play_seconds(SaveService.profile_id, today()) + _pending_seconds


func parent_challenge() -> Dictionary:
	return SaveService.progress.get_parent_challenge(SaveService.profile_id)


func should_show_break_reminder() -> bool:
	var limit := int(SaveService.settings.get_value("break_reminder_min"))
	return limit > 0 and not break_reminder_shown and played_today_seconds() >= limit * 60


func _process(delta: float) -> void:
	if _paused:
		return
	session_seconds += delta
	_pending_seconds += delta
	if _pending_seconds >= FLUSH_EVERY_SEC:
		flush_time()


func flush_time() -> void:
	if _pending_seconds <= 0.0:
		return
	SaveService.progress.add_play_seconds(SaveService.profile_id, today(), _pending_seconds)
	SaveService.progress.persist(SaveService.profile_id)
	_pending_seconds = 0.0


func on_app_paused() -> void:
	flush_time()
	SaveService.flush()
	_paused = true
	EventBus.session_finished.emit()


func on_app_resumed() -> void:
	_paused = false
