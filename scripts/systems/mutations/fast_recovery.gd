class_name FastRecoveryMutation
extends Mutation

## Recuperación rápida: el estado KNOCKED dura menos.

const KNOCKED_DURATION_MULTIPLIER := 0.55

func get_id() -> StringName:
	return &"fast_recovery"

func get_display_name() -> String:
	return "Recuperación rápida"

func get_description() -> String:
	return "El estado KNOCKED dura menos. Modificador acumulativo junto a otras mutaciones."

func get_stat_multiplier(_player: Node, stat: StringName) -> float:
	if stat == &"knocked_duration":
		return KNOCKED_DURATION_MULTIPLIER
	return 1.0
