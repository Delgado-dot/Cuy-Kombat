class_name LowGravityMutation
extends Mutation

## Gravedad baja: los jugadores saltan más alto y caen más lento.
## Bajar la gravedad ya hace que el salto sea más alto; además se sube la
## velocidad de salto para que el efecto se note desde el primer salto.

const GRAVITY_MULTIPLIER := 0.55
const JUMP_VELOCITY_MULTIPLIER := 1.3

func get_id() -> StringName:
	return &"low_gravity"

func get_display_name() -> String:
	return "Gravedad baja"

func get_description() -> String:
	return "Los jugadores saltan más y caen más lentamente."

func get_stat_multiplier(_player: Node, stat: StringName) -> float:
	if stat == &"gravity":
		return GRAVITY_MULTIPLIER
	if stat == &"jump_velocity":
		return JUMP_VELOCITY_MULTIPLIER
	return 1.0
