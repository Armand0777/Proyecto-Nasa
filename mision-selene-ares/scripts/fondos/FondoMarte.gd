extends "res://scripts/fondos/FondoPlaneta.gd"
## Marte al atardecer (Cráter Jezero) con la Tierra y la Luna en el cielo.

## Colores de Marte del guion: suelo #C1502E, polvo #E08A5B, sombras #6E2A1A.
const COLOR_SUELO := Color(0.757, 0.314, 0.18)
const COLOR_POLVO := Color(0.878, 0.541, 0.357)
const COLOR_SOMBRA := Color(0.431, 0.165, 0.102)


## Casi plano cerca de la cámara y con colinas lejos (el borde del cráter).
func _altura(x: float, z: float) -> float:
	var lejos := smoothstep(40.0, 320.0, Vector2(x, z).length())
	return _ruido.get_noise_2d(x, z) * (1.5 + 30.0 * lejos) + lejos * 18.0


## Mezcla de óxido y polvo, con una pequeña variación por cara para que se noten las facetas.
func _color_suelo(centro: Vector3, variacion: float) -> Color:
	var mezcla := clampf(_ruido.get_noise_2d(centro.x * 4.0, centro.z * 4.0) * 0.5 + 0.5, 0.0, 1.0)
	return COLOR_SUELO.lerp(COLOR_POLVO, mezcla * 0.7).darkened(variacion * 0.12)


func _color_roca(azar: RandomNumberGenerator) -> Color:
	return COLOR_SOMBRA.lerp(COLOR_SUELO, azar.randf_range(0.25, 0.75))
