class_name SlipperyFloorMutation
extends Mutation

## Piso resbaloso: los jugadores tienen más inercia y cuesta más
## detenerse/controlarlos. Se reduce la aceleración y desaceleración
## (cuesta arrancar y frenar) y la fricción de los empujes de contacto.

const ACCELERATION_MULTIPLIER := 0.35
const DECELERATION_MULTIPLIER := 0.35
const PUSH_FRICTION_MULTIPLIER := 0.4

func get_id() -> StringName:
	return &"slippery_floor"

func get_display_name() -> String:
	return "Piso resbaloso"

func get_description() -> String:
	return "Los jugadores tienen más inercia y cuesta más detenerse."

func get_stat_multiplier(_player: Node, stat: StringName) -> float:
	if stat == &"acceleration":
		return ACCELERATION_MULTIPLIER
	if stat == &"deceleration":
		return DECELERATION_MULTIPLIER
	if stat == &"body_push_friction":
		return PUSH_FRICTION_MULTIPLIER
	return 1.0
