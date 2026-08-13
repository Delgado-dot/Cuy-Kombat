class_name PowerfulHitsMutation
extends Mutation

## Golpes potentes: los golpes y cabezazos generan más knockback.
## Se aplica en apply_knockback() del player, que es el punto por el que pasa
## todo el knockback recibido (puños, cabezazos y tackles).

const KNOCKBACK_MULTIPLIER := 1.8

func get_id() -> StringName:
	return &"powerful_hits"

func get_display_name() -> String:
	return "Golpes potentes"

func get_description() -> String:
	return "Los golpes y cabezazos generan más knockback."

func get_stat_multiplier(_player: Node, stat: StringName) -> float:
	if stat == &"knockback":
		return KNOCKBACK_MULTIPLIER
	return 1.0
