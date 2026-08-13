class_name MatchSettings
extends RefCounted

const VALID_MAX_ROUNDS: Array[int] = [3, 5, 7]
const DEFAULT_MAX_ROUNDS := 3

static var max_rounds: int = DEFAULT_MAX_ROUNDS


static func set_max_rounds(value: int) -> bool:
	if value not in VALID_MAX_ROUNDS:
		return false
	max_rounds = value
	return true


static func get_max_rounds() -> int:
	return max_rounds


static func reset() -> void:
	max_rounds = DEFAULT_MAX_ROUNDS
