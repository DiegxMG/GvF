extends Node
## Audio del juego. Se registra como Autoload con el nombre "AudioManager"
## (este archivo reemplaza el contenido de res://systems/AudioManager.gd).
##
## No hace falta tocar los demás scripts para que suenen las cosas: este
## gestor se engancha solo a los nodos del juego cuando aparecen en la escena
## (con node_added) y reacciona a sus señales.
##
##   Menú principal ........... música del menú (nodo llamado "MainMenu")
##   Partida .................. música del bosque (cuando entra el EnemyManager)
##   Fantasma golpeado ........ señal enemy_damaged de EnemyManager
##   Gato herido .............. señal damaged de PlayerHealth
##   Gato muere ............... señal died de PlayerHealth (corta la música y suena game_over)
##
## VOLUMEN: este gestor NO guarda ni cambia los volúmenes de los buses Music y SFX
## si ya existen (los controla GameSettings, de la pantalla de configuración).
## Solo los crea, con un volumen inicial, si no existen.
##
## DIAGNÓSTICO: al arrancar escribe en la pestaña Salida líneas que empiezan con
## "[Audio]" con el estado de los buses y de cada sonido. Ponlo en false cuando
## ya todo funcione.
const DEBUG_LOG := true

const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const SFX_POOL_SIZE := 12

## Efectos.
##   path          archivo del sonido
##   bus           por qué bus sale (SFX o Music)
##   volume_db     volumen propio de este sonido (negativo = más bajo)
##   pitch         rango aleatorio de tono (x = mínimo, y = máximo)
##   min_interval  segundos mínimos entre dos reproducciones (evita ráfagas)
const SOUNDS := {
	&"ghost_hit": {
		"path": "res://assets/audio/sfx/ghost_hit.ogg", "bus": &"SFX",
		"volume_db": -11.0, "pitch": Vector2(0.88, 1.15), "min_interval": 0.06,
	},
	&"player_hurt": {
		"path": "res://assets/audio/sfx/player_hurt.mp3", "bus": &"SFX",
		"volume_db": 8.0, "pitch": Vector2(0.97, 1.03), "min_interval": 0.15,
	},
	&"game_over": {
		"path": "res://assets/audio/music/game_over.ogg", "bus": &"Music",
		"volume_db": -3.0, "pitch": Vector2(1.0, 1.0), "min_interval": 0.0,
	},
}

## Músicas (se repiten en bucle).
const MUSIC := {
	&"forest": {"path": "res://assets/audio/music/music_forest.ogg", "volume_db": -10.0},
	&"menu": {"path": "res://assets/audio/music/music_menu.ogg", "volume_db": -4.0},
}

var _music_players: Array[AudioStreamPlayer] = []
var _music_active: int = 0
var _music_id: StringName = &""
var _music_tween: Tween

var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx: int = 0

var _streams: Dictionary = {} # clave -> AudioStream (o null si no existe)
var _last_played: Dictionary = {} # sonido -> milisegundos de la última vez
var _warned: Dictionary = {}
var _logged: Dictionary = {}


func _ready() -> void:
	# Debe seguir sonando con el juego en pausa (Game Over, menú de mejoras...).
	process_mode = Node.PROCESS_MODE_ALWAYS

	_ensure_bus(MUSIC_BUS, 0.6)
	_ensure_bus(SFX_BUS, 0.9)

	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = MUSIC_BUS
		add_child(player)
		_music_players.append(player)

	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_sfx_players.append(player)

	get_tree().node_added.connect(_on_node_added)

	_log("AudioManager activo.")
	_report_status.call_deferred()


# --- Enganche automático a los nodos del juego ----------------------------------------------

func _on_node_added(node: Node) -> void:
	if _is_main_menu(node):
		_log("Menú principal detectado.")
		play_music(&"menu")
	elif node is EnemyManager:
		node.connect(&"enemy_damaged", _on_enemy_damaged)
		# Entró una partida: suena la música del bosque.
		play_music(&"forest")
	elif node is PlayerHealth:
		node.connect(&"died", _on_player_died)
		if node.has_signal(&"damaged"):
			node.connect(&"damaged", _on_player_damaged)


# El menú principal es el nodo llamado "MainMenu" o cuyo script se llama MainMenu.
func _is_main_menu(node: Node) -> bool:
	if node.name == &"MainMenu":
		return true
	if node.scene_file_path.to_lower().contains("main_menu"):
		return true
	var script := node.get_script() as Script
	if script == null:
		return false
	if script.get_global_name() == &"MainMenu":
		return true
	return script.resource_path.get_file().to_lower() == "mainmenu.gd"
	
	




func _on_enemy_damaged(_position: Vector2, _amount: float) -> void:
	play_sfx(&"ghost_hit")


func _on_player_damaged() -> void:
	play_sfx(&"player_hurt")


func _on_player_died() -> void:
	stop_music(0.5)
	play_sfx(&"game_over")


# --- Efectos --------------------------------------------------------------------------------------

## Reproduce un efecto de la tabla SOUNDS. volume_offset_db lo sube o baja un poco.
func play_sfx(id: StringName, volume_offset_db: float = 0.0) -> void:
	var config: Dictionary = SOUNDS.get(id, {})
	if config.is_empty():
		return

	# Límite de repetición (el zarpazo golpea a varios fantasmas a la vez).
	var now := Time.get_ticks_msec()
	var min_interval_ms := int(float(config["min_interval"]) * 1000.0)
	if now - int(_last_played.get(id, -100000)) < min_interval_ms:
		return

	var stream := _get_stream(id, config["path"])
	if stream == null:
		return
	_last_played[id] = now

	# Reparte los sonidos entre los reproductores; si todos están ocupados, reutiliza el más antiguo.
	var player := _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx_players.size()

	var pitch_range: Vector2 = config["pitch"]
	player.stream = stream
	player.bus = config["bus"]
	player.volume_db = float(config["volume_db"]) + volume_offset_db
	player.pitch_scale = randf_range(pitch_range.x, pitch_range.y)
	player.play()

	if not _logged.has(id):
		_logged[id] = true
		_log("Primer sonido '%s' reproducido (bus %s, %.1f dB)." % [id, config["bus"], player.volume_db])


# --- Música ---------------------------------------------------------------------------------------

## Cambia a una música de la tabla MUSIC. Si ya suena, no hace nada.
## Si no había música, empieza de inmediato; si había, hace un fundido.
func play_music(id: StringName, fade: float = 1.2) -> void:
	if id == _music_id and _music_players[_music_active].playing:
		return

	var config: Dictionary = MUSIC.get(id, {})
	if config.is_empty():
		return

	var stream := _get_stream(StringName("music_%s" % id), config["path"])
	if stream == null:
		return
	# Los archivos vienen con el bucle apagado: se activa aquí.
	if "loop" in stream:
		stream.set("loop", true)

	var target_db := float(config["volume_db"])
	var old_player := _music_players[_music_active]
	_music_active = 1 - _music_active
	var new_player := _music_players[_music_active]
	_music_id = id

	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()

	new_player.stream = stream

	if not old_player.playing:
		# Sin música anterior: suena directamente al volumen final (sin fundido).
		old_player.stop()
		new_player.volume_db = target_db
		new_player.play()
	else:
		new_player.volume_db = -60.0
		new_player.play()
		_music_tween = create_tween().set_parallel(true)
		_music_tween.tween_property(new_player, "volume_db", target_db, fade)
		_music_tween.tween_property(old_player, "volume_db", -60.0, fade)
		_music_tween.chain().tween_callback(old_player.stop)

	_log("Música '%s' (bus %s, %.1f dB)." % [id, new_player.bus, target_db])


## Apaga la música con un fundido.
func stop_music(fade: float = 1.0) -> void:
	_music_id = &""
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()

	var any_playing := false
	for player in _music_players:
		if player.playing:
			any_playing = true
	if not any_playing:
		return

	_music_tween = create_tween().set_parallel(true)
	for player in _music_players:
		if player.playing:
			_music_tween.tween_property(player, "volume_db", -60.0, fade)
	_music_tween.chain().tween_callback(_stop_all_music)


func _stop_all_music() -> void:
	for player in _music_players:
		player.stop()


# --- Volumen (opcional) -------------------------------------------------------------------------

## Cambia el volumen de un bus de 0 a 1. Para la pantalla de configuración
## usa GameSettings; esto sirve para pruebas rápidas.
func set_bus_volume(bus_name: StringName, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	linear = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_mute(index, linear <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))


func get_bus_volume(bus_name: StringName) -> float:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0 or AudioServer.is_bus_mute(index):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(index))


# Crea el bus solo si no existe (así no hay que configurarlo a mano en el editor).
func _ensure_bus(bus_name: StringName, initial_linear: float) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, &"Master")
	AudioServer.set_bus_volume_db(index, linear_to_db(initial_linear))
	_log("Se creó el bus '%s'." % bus_name)


# --- Diagnóstico -------------------------------------------------------------------------------

# Escribe el estado de los buses y avisa si alguno está silenciado.
func _report_status() -> void:
	_log("Salida de audio: %s" % AudioServer.get_output_device())
	for bus_name in [&"Master", MUSIC_BUS, SFX_BUS]:
		var index := AudioServer.get_bus_index(bus_name)
		if index < 0:
			_log("Bus '%s': NO EXISTE" % bus_name)
			continue
		var volume := AudioServer.get_bus_volume_db(index)
		var muted := AudioServer.is_bus_mute(index)
		_log("Bus '%s': %.1f dB, silenciado=%s" % [bus_name, volume, muted])
		if muted or volume < -30.0:
			push_warning("AudioManager: el bus '%s' está silenciado o casi en cero (%.1f dB). Por eso no se oye." % [bus_name, volume])

	for id in SOUNDS:
		_check_file(SOUNDS[id]["path"])
	for id in MUSIC:
		_check_file(MUSIC[id]["path"])


func _check_file(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: NO existe el archivo %s" % path)


func _log(message: String) -> void:
	if DEBUG_LOG:
		print("[Audio] ", message)


# --- Utilidades -----------------------------------------------------------------------------------

func _get_stream(key: StringName, path: String) -> AudioStream:
	if _streams.has(key):
		return _streams[key]
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	if stream == null and not _warned.has(key):
		_warned[key] = true
		push_warning("AudioManager: no se encontró el sonido '%s' (%s)." % [key, path])
	_streams[key] = stream
	return stream


# Al pasar la app a segundo plano (Android) se pausa la música.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		for player in _music_players:
			player.stream_paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		for player in _music_players:
			player.stream_paused = false
