extends Camera3D

@export var player_one_path: NodePath
@export var player_two_path: NodePath
@export var player_three_path: NodePath
@export var player_four_path: NodePath
@export var base_offset := Vector3(0.0, 8.0, 11.0)
@export var distance_padding := 0.7
@export var max_separation := 32.0
@export var follow_speed := 6.0
@export var look_height := 0.8

@onready var _player_one := get_node_or_null(player_one_path) as Node3D
@onready var _player_two := get_node_or_null(player_two_path) as Node3D
@onready var _player_three := get_node_or_null(player_three_path) as Node3D
@onready var _player_four := get_node_or_null(player_four_path) as Node3D

func _ready() -> void:
	current = true

func _process(delta: float) -> void:
	var players: Array[Node3D] = []
	if _player_one != null and is_instance_valid(_player_one) and _player_one.visible:
		players.append(_player_one)
	if _player_two != null and is_instance_valid(_player_two) and _player_two.visible:
		players.append(_player_two)
	if _player_three != null and is_instance_valid(_player_three) and _player_three.visible:
		players.append(_player_three)
	if _player_four != null and is_instance_valid(_player_four) and _player_four.visible:
		players.append(_player_four)

	if players.is_empty():
		return

	var midpoint := Vector3.ZERO
	for p in players:
		midpoint += p.global_position
	midpoint /= players.size()

	var max_dist := 0.0
	for i in players.size():
		for j in range(i + 1, players.size()):
			var d := players[i].global_position.distance_to(players[j].global_position)
			if d > max_dist:
				max_dist = d

	var clamped_separation := minf(max_dist, max_separation)
	var target_position := midpoint + base_offset + Vector3(0.0, clamped_separation * 0.25, clamped_separation * distance_padding)

	global_position = global_position.lerp(target_position, clampf(follow_speed * delta, 0.0, 1.0))
	look_at(midpoint + Vector3.UP * look_height, Vector3.UP)
