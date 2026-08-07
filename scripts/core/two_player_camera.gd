extends Camera3D

@export var player_one_path: NodePath
@export var player_two_path: NodePath
@export var base_offset := Vector3(0.0, 8.0, 11.0)
@export var distance_padding := 0.8
@export var follow_speed := 6.0
@export var look_height := 0.8

@onready var _player_one := get_node_or_null(player_one_path) as Node3D
@onready var _player_two := get_node_or_null(player_two_path) as Node3D

func _ready() -> void:
	current = true

func _process(delta: float) -> void:
	if _player_one == null or _player_two == null:
		return

	var midpoint := (_player_one.global_position + _player_two.global_position) * 0.5
	var separation := _player_one.global_position.distance_to(_player_two.global_position)
	var target_position := midpoint + base_offset + Vector3(0.0, separation * 0.25, separation * distance_padding)

	global_position = global_position.lerp(target_position, clampf(follow_speed * delta, 0.0, 1.0))
	look_at(midpoint + Vector3.UP * look_height, Vector3.UP)
