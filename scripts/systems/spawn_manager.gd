class_name SpawnManager
extends Node

@export var player_one_path: NodePath
@export var player_two_path: NodePath
@export var spawn_one_path: NodePath
@export var spawn_two_path: NodePath


func _ready() -> void:
	call_deferred("colocar_jugadores")


func colocar_jugadores() -> void:
	var player_one := get_node_or_null(player_one_path) as Node3D
	var player_two := get_node_or_null(player_two_path) as Node3D
	var spawn_one := get_node_or_null(spawn_one_path) as Marker3D
	var spawn_two := get_node_or_null(spawn_two_path) as Marker3D

	if player_one == null:
		push_error("SpawnManager: no se encontró Player1.")
	elif spawn_one == null:
		push_error("SpawnManager: no se encontró SpawnJugador1.")
	else:
		_colocar_jugador(player_one, spawn_one)

	if player_two == null:
		push_error("SpawnManager: no se encontró Player2.")
	elif spawn_two == null:
		push_error("SpawnManager: no se encontró SpawnJugador2.")
	else:
		_colocar_jugador(player_two, spawn_two)


func _colocar_jugador(player: Node3D, spawn_point: Marker3D) -> void:
	var player_scale := player.scale
	player.global_position = spawn_point.global_position
	player.global_rotation = spawn_point.global_rotation
	player.scale = player_scale
