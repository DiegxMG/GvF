class_name GameText
extends RefCounted
## Textos DENTRO de la partida (HUD, menú de mejoras al subir de nivel, Game Over)
## en español e inglés. Los menús de la compañera usan Loc; esto cubre lo demás.
##
## IDIOMA: se lee del archivo user://settings.cfg, donde GameSettings guarda el
## idioma elegido en Configuración (busca una clave que contenga "lang", "idioma"
## o "locale"). Si no la encuentra, usa el idioma del sistema (TranslationServer).
## Para forzar un idioma en una prueba: GameText.language_override = "en".
##
## Uso:
##   GameText.t(&"day")                          -> "DÍA" o "DAY"
##   GameText.t(&"level_up_title") % 5           -> "¡NIVEL 5!" o "LEVEL 5!"
##   GameText.is_english()
## Para agregar un texto: añade una línea en TEXTS con "es" y "en".

const SETTINGS_PATH := "user://settings.cfg"

const TEXTS := {
	# HUD
	&"level_short": {"es": "NV.", "en": "LV."},
	&"day": {"es": "DÍA", "en": "DAY"},
	&"night": {"es": "NOCHE", "en": "NIGHT"},
	&"phase_line": {"es": "%s %d  ·  %s en %d:%02d", "en": "%s %d  ·  %s in %d:%02d"},
	# Menú de mejoras al subir de nivel
	&"level_up_title": {"es": "¡NIVEL %d!", "en": "LEVEL %d!"},
	&"pick_upgrade": {"es": "Elige una mejora", "en": "Choose an upgrade"},
	&"pick_upgrade_full": {
		"es": "Elige una mejora (modificadores completos)",
		"en": "Choose an upgrade (modifier slots full)"},
	&"reward_level": {
		"es": "¡Nivel de recompensa! Más probabilidad de mejoras raras",
		"en": "Reward level! Better odds for rare upgrades"},
	# Game Over
	&"game_over": {"es": "GAME OVER", "en": "GAME OVER"},
	&"game_over_stats": {
		"es": "Sobreviviste %02d:%02d\nNivel alcanzado: %d\nEnemigos eliminados: %d\nMonedas ganadas: %d",
		"en": "You survived %02d:%02d\nLevel reached: %d\nEnemies defeated: %d\nCoins earned: %d"},
	&"play_again": {"es": "JUGAR DE NUEVO", "en": "PLAY AGAIN"},
	&"upgrades": {"es": "MEJORAS", "en": "UPGRADES"},
	&"exit": {"es": "SALIR", "en": "EXIT"},
	# Rarezas
	&"rarity_0": {"es": "Común", "en": "Common"},
	&"rarity_1": {"es": "Poco común", "en": "Uncommon"},
	&"rarity_2": {"es": "Especial", "en": "Special"},
	&"rarity_3": {"es": "Épico", "en": "Epic"},
	&"rarity_4": {"es": "Legendario", "en": "Legendary"},
}

## Pon "es" o "en" para forzar un idioma (sirve para probar). Vacío = el de la configuración.
static var language_override: String = ""

static var _cached: String = "es"
static var _next_check_ms: int = 0


## "es" o "en".
static func language() -> String:
	if language_override != "":
		return language_override
	var now := Time.get_ticks_msec()
	# Se vuelve a leer el archivo como máximo cada medio segundo.
	if now >= _next_check_ms:
		_next_check_ms = now + 500
		_cached = _detect()
	return _cached


static func is_english() -> bool:
	return language() == "en"


## Texto traducido. Si la clave no existe, devuelve la clave (así se nota el olvido).
static func t(key: StringName) -> String:
	var entry: Dictionary = TEXTS.get(key, {})
	if entry.is_empty():
		return String(key)
	return entry.get(language(), entry.get("es", String(key)))


static func rarity_name(rarity: int) -> String:
	return t(StringName("rarity_%d" % rarity))


# --- Detección del idioma ------------------------------------------------------------------

static func _detect() -> String:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		for section in config.get_sections():
			for key in config.get_section_keys(section):
				var key_name := String(key).to_lower()
				if key_name.contains("lang") or key_name.contains("idioma") or key_name.contains("locale"):
					return _normalize(config.get_value(section, key))
	return _normalize(TranslationServer.get_locale())


# Convierte lo que haya guardado ("en", "English", "Español", 0, 1...) en "es" o "en".
static func _normalize(value: Variant) -> String:
	if value is int:
		return "en" if int(value) == 1 else "es"
	var text := str(value).to_lower()
	if text.begins_with("en") or text.contains("engl") or text.contains("ingl"):
		return "en"
	return "es"
