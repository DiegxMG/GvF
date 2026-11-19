class_name GameSettings
extends RefCounted
## Ajustes del jugador: idioma y volúmenes. Se guardan en user://settings.cfg.
## Todo son funciones estáticas (no hace falta Autoload), igual que ArcadeProgress.
##
## IMPORTANTE (audio): los volúmenes se aplican a dos buses de audio llamados
## "Music" y "SFX". Créalos en el panel Audio de Godot (abajo) y asigna tus
## reproductores de música al bus Music y los de efectos al bus SFX.
## Si tus buses se llaman distinto, cambia las dos constantes de abajo.

const SAVE_PATH := "user://settings.cfg"
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const LANGUAGES: Array[String] = ["es", "en"]

static var _loaded: bool = false
static var _language: String = "es"
static var _music: float = 0.8   # 0.0 a 1.0
static var _sfx: float = 0.8     # 0.0 a 1.0


## Llamar una vez al arrancar (MainMenu._ready lo hace). Es seguro llamarla varias veces.
static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		_language = str(cfg.get_value("general", "language", "es"))
		_music = clampf(float(cfg.get_value("audio", "music", 0.8)), 0.0, 1.0)
		_sfx = clampf(float(cfg.get_value("audio", "sfx", 0.8)), 0.0, 1.0)
	if not LANGUAGES.has(_language):
		_language = "es"
	apply_audio()


static func get_language() -> String:
	ensure_loaded()
	return _language


static func set_language(code: String) -> void:
	ensure_loaded()
	if LANGUAGES.has(code):
		_language = code


static func get_music() -> float:
	ensure_loaded()
	return _music


static func set_music(value: float) -> void:
	ensure_loaded()
	_music = clampf(value, 0.0, 1.0)
	_set_bus(MUSIC_BUS, _music)


static func get_sfx() -> float:
	ensure_loaded()
	return _sfx


static func set_sfx(value: float) -> void:
	ensure_loaded()
	_sfx = clampf(value, 0.0, 1.0)
	_set_bus(SFX_BUS, _sfx)


static func apply_audio() -> void:
	_set_bus(MUSIC_BUS, _music)
	_set_bus(SFX_BUS, _sfx)


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("general", "language", _language)
	cfg.set_value("audio", "music", _music)
	cfg.set_value("audio", "sfx", _sfx)
	cfg.save(SAVE_PATH)


static func _set_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		push_warning("GameSettings: no existe el bus de audio '%s'." % bus_name)
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(idx, linear <= 0.001)
