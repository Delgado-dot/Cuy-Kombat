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
	for p in [_player_one, _player_two, _player_three, _player_four]:
		if p != null and is_instance_valid(p):
			players.append(p)

	if players.size() < 2:
		return

	var midpoint := Vector3.ZERO
	var max_dist := 0.0
	for p in players:
		midpoint += p.global_position
	midpoint /= players.size()

	for i in range(players.size()):
		for j in range(i + 1, players.size()):
			var dist := players[i].global_position.distance_to(players[j].global_position)
			if dist > max_dist:
				max_dist = dist

	var clamped_separation := minf(max_dist, max_separation)
	var target_position := midpoint + base_offset + Vector3(0.0, clamped_separation * 0.25, clamped_separation * distance_padding)

	global_position = global_position.lerp(target_position, clampf(follow_speed * delta, 0.0, 1.0))
	look_at(midpoint + Vector3.UP * look_height, Vector3.UP)
