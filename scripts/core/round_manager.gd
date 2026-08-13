class_name RoundManager
extends RefCounted

const PLAYER_1 := 1
const PLAYER_2 := 2

static var wins: Array[int] = [0, 0]


static func required_wins() -> int:
	return MatchSettings.max_rounds / 2 + 1


static func get_wins(player_number: int) -> int:
	if player_number < 1 or player_number > wins.size():
		return 0
	return wins[player_number - 1]


static func register_win(player_number: int) -> int:
	if player_number < 1 or player_number > wins.size():
		return 0
	wins[player_number - 1] += 1
	return wins[player_number - 1]


static func reached_goal(player_number: int) -> bool:
	return get_wins(player_number) >= required_wins()


static func reset() -> void:
	wins = [0, 0]
