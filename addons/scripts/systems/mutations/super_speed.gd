class_name SuperSpeedMutation
extends Mutation

## Súper velocidad: todos los jugadores se mueven más rápido.

const MOVE_SPEED_MULTIPLIER := 1.6

func get_id() -> StringName:
	return &"super_speed"

func get_display_name() -> String:
	return "Súper velocidad"

func get_description() -> String:
	return "Todos los jugadores se mueven más rápido."

func get_stat_multiplier(_player: Node, stat: StringName) -> float:
	if stat == &"move_speed":
		return MOVE_SPEED_MULTIPLIER
	return 1.0
