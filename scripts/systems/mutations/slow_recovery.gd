class_name SlowRecoveryMutation
extends Mutation

## Recuperación lenta: el estado KNOCKED dura más.

const KNOCKED_DURATION_MULTIPLIER := 1.8

func get_id() -> StringName:
	return &"slow_recovery"

func get_display_name() -> String:
	return "Recuperación lenta"

func get_description() -> String:
	return "El estado KNOCKED dura más. Modificador acumulativo junto a otras mutaciones."

func get_stat_multiplier(_player: Node, stat: StringName) -> float:
	if stat == &"knocked_duration":
		return KNOCKED_DURATION_MULTIPLIER
	return 1.0
