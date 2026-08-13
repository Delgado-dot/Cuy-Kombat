class_name Mutation
extends RefCounted

## Base de todas las mutaciones.
## Cada mutación es independiente: declara su id, su nombre y qué estadísticas
## modifica. Los sistemas del juego (player, spawner, etc.) consultan al
## MutationManager los multiplicadores agregados; nunca preguntan
## "está activa X" con un if dentro del gameplay.

func get_id() -> StringName:
	return &"mutation"

func get_display_name() -> String:
	return "Mutación"

func get_description() -> String:
	return ""

## Devuelve el multiplicador que esta mutación aplica a una estadística.
## Devuelve 1.0 cuando esta mutación no afecta esa estadística.
func get_stat_multiplier(_player: Node, _stat: StringName) -> float:
	return 1.0

## Velocidad de deslizamiento adicional (unidades/s) que esta mutación aplica
## al jugador (arena inclinada). Vector3.ZERO cuando esta mutación no empuja.
func get_slide_direction(_player: Node) -> Vector3:
	return Vector3.ZERO

func get_arena_tilt_angle() -> float:
	return 0.0

func get_arena_tilt_speed() -> float:
	return 0.0

## Multiplicador de escala (tamaño) que esta mutación aplica al jugador y a
## sus hitboxes (cuy gigante). Devuelve 1.0 cuando no modifica el tamaño.
func get_scale_multiplier(_player: Node) -> float:
	return 1.0
