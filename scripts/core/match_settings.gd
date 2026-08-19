class_name MatchSettings
extends RefCounted

const VALID_MAX_ROUNDS: Array[int] = [3, 5, 7]
const DEFAULT_MAX_ROUNDS := 3

const CHARACTER_PRESETS: Array[Dictionary] = [
	{
		"id": &"conejo_andino",
		"name": "CONEJO ANDINO",
		"scene_path": "res://assets/CUY/personajes_blender/conejo_andino/conejo_andino.glb",
		"scale": Vector3(0.65, 0.65, 0.65),
		"offset": Vector3(0, -0.62, 0)
	},
	{
		"id": &"cuy_poncho",
		"name": "CUY CON PONCHO",
		"scene_path": "res://assets/CUY/personajes_blender/cuy_poncho/cuy_poncho.glb",
		"scale": Vector3(0.9, 0.9, 0.9),
		"offset": Vector3(0, -0.62, 0)
	},
	{
		"id": &"cuy_tricolor",
		"name": "CUY TRICOLOR",
		"scene_path": "res://assets/CUY/personajes_blender/cuy_tricolor/cuy_tricolor_v2.glb",
		"scale": Vector3(0.9, 0.9, 0.9),
		"offset": Vector3(0, -0.62, 0)
	},
	{
		"id": &"cuy_blanco",
		"name": "CUY BLANCO",
		"scene_path": "res://assets/CUY/personajes_blender/cuy_blanco/cuy_blanco.glb",
		"scale": Vector3(0.9, 0.9, 0.9),
		"offset": Vector3(0, -0.62, 0)
	},
	{
		"id": &"cuy_negro",
		"name": "CUY NEGRO",
		"scene_path": "res://assets/CUY/personajes_blender/cuy_negro/cuy_negro.glb",
		"scale": Vector3(0.9, 0.9, 0.9),
		"offset": Vector3(0, -0.62, 0)
	},
	{
		"id": &"conejo_volcanico",
		"name": "CONEJO VOLCÁNICO",
		"scene_path": "res://assets/CUY/personajes_blender/conejo_volcanico/conejo_volcanico.glb",
		"scale": Vector3(0.65, 0.65, 0.65),
		"offset": Vector3(0, -0.62, 0)
	}
]

static var max_rounds: int = DEFAULT_MAX_ROUNDS
static var player_count: int = 2
static var player_characters: Array[int] = [0, 1, 2, 3]
static var player_joypad_devices: Array[int] = [-1, -1, -1, -1]


static func set_max_rounds(value: int) -> bool:
	if value not in VALID_MAX_ROUNDS:
		return false
	max_rounds = value
	return true


static func get_max_rounds() -> int:
	return max_rounds


static func set_player_count(count: int) -> void:
	player_count = clampi(count, 2, 4)


static func get_player_count() -> int:
	return player_count


static func set_player_character(player_number: int, char_idx: int) -> void:
	var idx_in_arr := player_number - 1
	if idx_in_arr >= 0 and idx_in_arr < player_characters.size():
		player_characters[idx_in_arr] = posmod(char_idx, CHARACTER_PRESETS.size())


static func get_player_character(player_number: int) -> Dictionary:
	var idx_in_arr := player_number - 1
	var char_idx := 0
	if idx_in_arr >= 0 and idx_in_arr < player_characters.size():
		char_idx = posmod(player_characters[idx_in_arr], CHARACTER_PRESETS.size())
	return CHARACTER_PRESETS[char_idx]


static func set_player_joypad_device(player_number: int, device: int) -> void:
	var idx := player_number - 1
	if idx >= 0 and idx < player_joypad_devices.size():
		player_joypad_devices[idx] = device


static func get_player_joypad_device(player_number: int) -> int:
	var idx := player_number - 1
	if idx >= 0 and idx < player_joypad_devices.size():
		return player_joypad_devices[idx]
	return -1


static func detect_and_assign_joypads() -> void:
	var joypads := Input.get_connected_joypads()
	player_joypad_devices = [-1, -1, -1, -1]
	for i in range(min(joypads.size(), 4)):
		player_joypad_devices[i] = joypads[i]


static func reset() -> void:
	max_rounds = DEFAULT_MAX_ROUNDS
	player_count = 2
	player_joypad_devices = [-1, -1, -1, -1]

