class_name InclinedArenaMutation
extends Mutation

## Arena inclinada: la arena empuja a los jugadores, que se deslizan hacia
## una dirección fija. Se devuelve una velocidad de deslizamiento constante
## (unidades/s) que el player suma a su velocidad horizontal en el estado
## NORMAL. Modifica la dirección/ fuerza con SLIDE_VELOCITY.

const SLIDE_VELOCITY := Vector3(1.8, 0.0, 0.0)

func get_id() -> StringName:
	return &"inclined_arena"

func get_display_name() -> String:
	return "Arena inclinada"

func get_description() -> String:
	return "Los jugadores se deslizan hacia una dirección."

func get_slide_direction(_player: Node) -> Vector3:
	return SLIDE_VELOCITY
