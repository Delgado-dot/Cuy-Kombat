class_name GiantCuyMutation
extends Mutation

## Cuy gigante: el jugador crece de tamaño. El multiplicador de escala se
## aplica al visual (CuyModel), al cuerpo de colisión (más fácil de golpear)
## y a las hitboxes de ataque (tacle, puñetazo y agarre alcanzan más lejos).
## Todo es proporcional y se restaura automáticamente al quitar la mutación.

const SCALE_MULTIPLIER := 1.4

func get_id() -> StringName:
	return &"giant_cuy"

func get_display_name() -> String:
	return "Cuy gigante"

func get_description() -> String:
	return "El cuy es más grande: ataca más lejos y es más fácil de golpear."

func get_scale_multiplier(_player: Node) -> float:
	return SCALE_MULTIPLIER
