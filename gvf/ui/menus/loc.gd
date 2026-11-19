
class_name Loc
extends RefCounted
## Textos en español e inglés. Uso:  Loc.t("clave")   o   Loc.t("clave", [valor1, valor2])
## Los textos con argumentos usan %d / %s, y %% para un símbolo %.
##
## Para agregar un texto nuevo: ponlo en AMBOS idiomas con la misma clave.
## Los botones con imagen cambian de carpeta según el idioma:
##   res://assets/menu/es/Boton_X.png   y   res://assets/menu/en/Boton_X.png

const TEXTS := {
	"es": {
		# --- general
		"mode_title": "MODOS DE JUEGO",
		"coming_soon": "¡Próximamente!",
		"coins": "Monedas: %d",

		# --- configuración
		"settings_title": "CONFIGURACIÓN",
		"language": "Idioma",
		"lang_es": "ESPAÑOL",
		"lang_en": "ENGLISH",
		"music": "Música",
		"sfx": "Efectos",

		# --- menú Arcade
		"arcade_title": "ARCADE",
		"tab_characters": "PERSONAJES",
		"tab_weapons": "ARMAS",
		"tab_items": "OBJETOS",
		"locked_name": "???",
		"locked_desc": "Todavía está bloqueado.",
		"pick_hint": "Toca un elemento para ver sus detalles.",
		"char_cat_name": "Gato",
		"char_cat_desc": "El valiente gato que defiende el bosque de los fantasmas.",
		"weapon_claws_name": "Garras",
		"weapon_claws_desc": "Zarpazos que dañan a los fantasmas cercanos.",
		"item_xp_name": "Orbe de experiencia",
		"item_xp_desc": "Sirve para llenar la barra de experiencia y subir de nivel, así puedes mejorar a tu gato durante la partida.",
		"item_coin_name": "Moneda",
		"item_coin_desc": "Cuando termina la partida se guardan y sirven para mejorar a tu gato de forma permanente o conseguir skins.",
		"item_mouse_name": "Ratón",
		"item_mouse_desc": "Al comértelo recuperas un poco de salud.",
		"hint_characters": "Elige el aspecto de tu gato",
		"hint_weapons": "Las armas con las que cuentas",
		"hint_items": "Lo que te encontrarás en la partida (solo informativo)",
		"skin_classic_name": "Gato",
		"skin_classic_desc": "El gato original, valiente y listo para defender el bosque de los fantasmas.",
		"skin_cat3d_name": "Gato3D",
		"skin_cat3d_desc": "Un nuevo aspecto para tu gato, con animaciones en 8 direcciones. Solo cambia el aspecto, no las estadísticas.",
		"skin_price": "%d monedas",
		"skin_equipped": "EQUIPADO",
		"skin_equip": "EQUIPAR",
		"skin_buy": "COMPRAR (%d monedas)",
		"skin_not_enough": "No te alcanzan las monedas",

		# --- mejoras permanentes
		"upg_title": "MEJORAS PERMANENTES",
		"upg_level": "Nivel %d / %d",
		"upg_buy": "COMPRAR",
		"upg_max": "MÁXIMO",
		"upg_debug": "+100 monedas (solo pruebas)",
		"up_damage_name": "Garras de acero",
		"up_damage_text": "+%d%% de daño en todas las partidas, por nivel",
		"up_attack_speed_name": "Zarpazos rápidos",
		"up_attack_speed_text": "+%d%% de velocidad de ataque, por nivel",
		"up_health_name": "Cuerpo resistente",
		"up_health_text": "+%d de vida máxima, por nivel",
		"up_defense_name": "Pelaje de acero",
		"up_defense_text": "Los fantasmas hacen %d%% menos de daño, por nivel",
		"up_move_speed_name": "Patas de relámpago",
		"up_move_speed_text": "+%d%% de velocidad de movimiento, por nivel",
		"up_xp_gain_name": "Mente brillante",
		"up_xp_gain_text": "+%d%% de experiencia obtenida, por nivel",
		"up_coin_chance_name": "Nariz de oro",
		"up_coin_chance_text": "+%d%% de probabilidad de monedas, por nivel",
		"up_coin_value_name": "Monedas pesadas",
		"up_coin_value_text": "Las monedas valen +%d%%, por nivel",

		# --- tutorial
		"tuto_1_title": "Muévete",
		"tuto_1_a": "Usa el joystick de la pantalla para mover a tu gato.",
		"tuto_1_b": "No te quedes quieto: los fantasmas te persiguen.",
		"tuto_2_title": "Pelea",
		"tuto_2_a": "Tus garras dañan a los fantasmas que estén cerca.",
		"tuto_2_b": "Cada fantasma derrotado suelta orbes de experiencia.",
		"tuto_3_title": "Sube de nivel",
		"tuto_3_a": "Recoge los orbes de experiencia para subir de nivel.",
		"tuto_3_b": "Al subir de nivel eliges una mejora para esa partida.",
		"tuto_4_title": "Monedas y mejoras",
		"tuto_4_a": "Las monedas de tu partida se guardan cuando termina.",
		"tuto_4_b": "Gástalas en Mejoras (modo Arcade) para ser más fuerte en todas tus partidas.",

		# --- créditos originales
		"cr_game_1": "GATOS VS",
		"cr_game_2": "FANTASMAS",
		"cr_author": "AUTOR Y DUEÑO DE LA IDEA",
		"cr_design": "DISEÑO DEL JUEGO",
		"cr_dev": "PROGRAMACIÓN",
		"cr_direction": "DIRECCIÓN CREATIVA",
		"cr_name": "Diego Mendieta Gonzalez",
		"cr_owner": "La idea original, el concepto, el diseño y todo el contenido de este juego pertenecen a Diego Mendieta Gonzalez.",
		"cr_rights": "© 2026 Diego Mendieta Gonzalez. Todos los derechos reservados.",
		"cr_thanks": "¡Gracias por jugar!",

		# --- créditos adicionales
		"cr_title": "CRÉDITOS",
		"cr_game_name": "GATOS VS FANTASMAS",
		"cr_team": "EQUIPO DE DESARROLLO",
		"cr_direction_dev": "DIRECCIÓN Y DESARROLLO",
		"cr_game_design": "DISEÑO Y CONCEPTO DEL JUEGO",
		"cr_visual_design": "DISEÑO VISUAL",
		"cr_ui_design": "DISEÑO DE MENÚS E INTERFAZ",
		"cr_character_concept": "DISEÑO CONCEPTUAL DE PERSONAJES",
		"cr_sprites": "CREACIÓN DE SPRITES E ILUSTRACIONES",
		"cr_animation": "ANIMACIÓN DE PERSONAJES",
		"cr_external_assets": "RECURSOS DE TERCEROS",
		"cr_map_assets": "RECURSOS GRÁFICOS DEL MAPA",
		"cr_audio": "MÚSICA Y EFECTOS DE SONIDO",
		"cr_sound_creator": "AUTOR DEL RECURSO DE AUDIO",
		"cr_thanks_title": "AGRADECIMIENTOS",
		"cr_thanks_message": "Gracias a todas las personas que contribuyeron a hacer realidad este proyecto.",
		"cr_final_message": "¡GRACIAS POR JUGAR!",
	},

	"en": {
		# --- general
		"mode_title": "GAME MODES",
		"coming_soon": "Coming soon!",
		"coins": "Coins: %d",

		# --- settings
		"settings_title": "SETTINGS",
		"language": "Language",
		"lang_es": "ESPAÑOL",
		"lang_en": "ENGLISH",
		"music": "Music",
		"sfx": "Sound effects",

		# --- Arcade menu
		"arcade_title": "ARCADE",
		"tab_characters": "CHARACTERS",
		"tab_weapons": "WEAPONS",
		"tab_items": "ITEMS",
		"locked_name": "???",
		"locked_desc": "Still locked.",
		"pick_hint": "Tap an item to see its details.",
		"char_cat_name": "Cat",
		"char_cat_desc": "The brave cat who defends the forest from ghosts.",
		"weapon_claws_name": "Claws",
		"weapon_claws_desc": "Swipes that damage nearby ghosts.",
		"item_xp_name": "Experience orb",
		"item_xp_desc": "Fills the experience bar so you can level up and upgrade your cat during the run.",
		"item_coin_name": "Coin",
		"item_coin_desc": "When the run ends they are saved and used to permanently upgrade your cat or unlock skins.",
		"item_mouse_name": "Mouse",
		"item_mouse_desc": "Eating it restores a bit of health.",
		"hint_characters": "Choose your cat's look",
		"hint_weapons": "The weapons you have",
		"hint_items": "What you will find during a run (info only)",
		"skin_classic_name": "Cat",
		"skin_classic_desc": "The original cat, brave and ready to defend the forest from ghosts.",
		"skin_cat3d_name": "Gato3D",
		"skin_cat3d_desc": "A new look for your cat, with animations in 8 directions. It only changes the look, not the stats.",
		"skin_price": "%d coins",
		"skin_equipped": "EQUIPPED",
		"skin_equip": "EQUIP",
		"skin_buy": "BUY (%d coins)",
		"skin_not_enough": "Not enough coins",

		# --- permanent upgrades
		"upg_title": "PERMANENT UPGRADES",
		"upg_level": "Level %d / %d",
		"upg_buy": "BUY",
		"upg_max": "MAX",
		"upg_debug": "+100 coins (testing only)",
		"up_damage_name": "Steel Claws",
		"up_damage_text": "+%d%% damage in every run, per level",
		"up_attack_speed_name": "Quick Swipes",
		"up_attack_speed_text": "+%d%% attack speed, per level",
		"up_health_name": "Sturdy Body",
		"up_health_text": "+%d max health, per level",
		"up_defense_name": "Steel Fur",
		"up_defense_text": "Ghosts deal %d%% less damage, per level",
		"up_move_speed_name": "Lightning Paws",
		"up_move_speed_text": "+%d%% movement speed, per level",
		"up_xp_gain_name": "Bright Mind",
		"up_xp_gain_text": "+%d%% experience gained, per level",
		"up_coin_chance_name": "Golden Nose",
		"up_coin_chance_text": "+%d%% coin drop chance, per level",
		"up_coin_value_name": "Heavy Coins",
		"up_coin_value_text": "Coins are worth +%d%%, per level",

		# --- tutorial
		"tuto_1_title": "Move",
		"tuto_1_a": "Use the on-screen joystick to move your cat.",
		"tuto_1_b": "Keep moving: the ghosts are chasing you.",
		"tuto_2_title": "Fight",
		"tuto_2_a": "Your claws damage the ghosts that are close to you.",
		"tuto_2_b": "Every defeated ghost drops experience orbs.",
		"tuto_3_title": "Level up",
		"tuto_3_a": "Collect experience orbs to level up.",
		"tuto_3_b": "When you level up, you pick an upgrade for that run.",
		"tuto_4_title": "Coins and upgrades",
		"tuto_4_a": "The coins from your run are saved when it ends.",
		"tuto_4_b": "Spend them on Upgrades (Arcade mode) to get stronger in every run.",

		# --- original credits
		"cr_game_1": "CATS VS",
		"cr_game_2": "GHOSTS",
		"cr_author": "AUTHOR AND IDEA OWNER",
		"cr_design": "GAME DESIGN",
		"cr_dev": "PROGRAMMING",
		"cr_direction": "CREATIVE DIRECTION",
		"cr_name": "Diego Mendieta Gonzalez",
		"cr_owner": "The original idea, concept, design and all the content of this game belong to Diego Mendieta Gonzalez.",
		"cr_rights": "© 2026 Diego Mendieta Gonzalez. All rights reserved.",
		"cr_thanks": "Thanks for playing!",

		# --- additional credits
		"cr_title": "CREDITS",
		"cr_game_name": "CATS VS GHOSTS",
		"cr_team": "DEVELOPMENT TEAM",
		"cr_direction_dev": "DIRECTION AND DEVELOPMENT",
		"cr_game_design": "GAME DESIGN AND CONCEPT",
		"cr_visual_design": "VISUAL DESIGN",
		"cr_ui_design": "MENU AND INTERFACE DESIGN",
		"cr_character_concept": "CHARACTER CONCEPT DESIGN",
		"cr_sprites": "SPRITE AND ILLUSTRATION CREATION",
		"cr_animation": "CHARACTER ANIMATION",
		"cr_external_assets": "THIRD-PARTY ASSETS",
		"cr_map_assets": "MAP GRAPHICS",
		"cr_audio": "MUSIC AND SOUND EFFECTS",
		"cr_sound_creator": "AUDIO ASSET CREATOR",
		"cr_thanks_title": "SPECIAL THANKS",
		"cr_thanks_message": "Thank you to everyone who helped make this project possible.",
		"cr_final_message": "THANK YOU FOR PLAYING!",
	},
}

const BUTTON_PATH := "res://assets/menu/%s/%s.png"


static func has(key: String) -> bool:
	return TEXTS["es"].has(key)


## Texto traducido. Si la clave no existe devuelve la propia clave (así se nota el error).
static func t(key: String, args: Array = []) -> String:
	var table: Dictionary = TEXTS.get(GameSettings.get_language(), TEXTS["es"])
	var text: String = table.get(key, TEXTS["es"].get(key, key))
	if args.is_empty():
		return text
	return text % args


## Igual que t(), pero si la clave no existe devuelve `fallback`.
static func t_or(key: String, fallback: String, args: Array = []) -> String:
	if has(key):
		return t(key, args)
	if args.is_empty():
		return fallback
	return fallback % args


## Imagen de un botón en el idioma actual. name = "Boton_Jugar", etc.
static func btn(name: String, selected: bool = false) -> Texture2D:
	var file := name + ("_sel" if selected else "")
	var path := BUTTON_PATH % [GameSettings.get_language(), file]
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	push_warning("Loc: falta la imagen " + path)
	return null
