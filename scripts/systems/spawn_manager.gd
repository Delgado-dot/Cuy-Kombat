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
		player_one.global_transform = spawn_one.global_transform

	if player_two == null:
		push_error("SpawnManager: no se encontró Player2.")
	elif spawn_two == null:
		push_error("SpawnManager: no se encontró SpawnJugador2.")
	else:
		player_two.global_transform = spawn_two.global_transform
