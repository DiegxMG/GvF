class_name SafeArea
extends RefCounted
## Calcula cuánto espacio hay que dejar en cada borde de la pantalla para que la
## interfaz no quede tapada por una muesca, la cámara frontal, las barras del
## sistema o las ESQUINAS REDONDEADAS del celular.
##
## El resultado está en unidades del juego (no en píxeles), así que se puede usar
## directamente como margen de los Controles.
##
## - En celulares usa el área segura que informa el sistema (muescas y barras).
## - Android NO informa cuánto se redondean las esquinas, por eso existen los
##   márgenes mínimos (min_side y min_top): siempre se respetan, aunque el
##   sistema diga que no hay nada que evitar. También valen en PC, para poder
##   probar cómo se verá.

## Devuelve Vector4(izquierda, arriba, derecha, abajo).
static func get_insets(node: Node, min_side: float = 0.0, min_top: float = 0.0, min_bottom: float = 0.0) -> Vector4:
	var left := 0.0
	var top := 0.0
	var right := 0.0
	var bottom := 0.0

	if OS.has_feature("mobile") and node != null and node.is_inside_tree():
		var window := DisplayServer.window_get_size()
		var screen := DisplayServer.screen_get_size()
		var safe := DisplayServer.get_display_safe_area()
		if window.x > 0 and window.y > 0 and safe.size.x > 0 and safe.size.y > 0:
			# Convierte píxeles de la pantalla a unidades del juego.
			var view_size := node.get_viewport().get_visible_rect().size
			var to_units := view_size.x / float(window.x)
			left = maxf(float(safe.position.x), 0.0) * to_units
			top = maxf(float(safe.position.y), 0.0) * to_units
			right = maxf(float(screen.x - safe.end.x), 0.0) * to_units
			bottom = maxf(float(screen.y - safe.end.y), 0.0) * to_units

	return Vector4(maxf(left, min_side), maxf(top, min_top), maxf(right, min_side), maxf(bottom, min_bottom))
