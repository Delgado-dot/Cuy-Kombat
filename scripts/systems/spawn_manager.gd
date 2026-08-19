class_name SpawnManager
extends Node

@export var player_one_path: NodePath
@export var player_two_path: NodePath
@export var player_three_path: NodePath
@export var player_four_path: NodePath
@export var spawn_one_path: NodePath
@export var spawn_two_path: NodePath
@export var spawn_three_path: NodePath
@export var spawn_four_path: NodePath


func _ready() -> void:
	call_deferred("colocar_jugadores")


func colocar_jugadores() -> void:
	var active_count := MatchSettings.get_player_count()
	var player_one := get_node_or_null(player_one_path) as Node3D
	var player_two := get_node_or_null(player_two_path) as Node3D
	var player_three := get_node_or_null(player_three_path) as Node3D
	var player_four := get_node_or_null(player_four_path) as Node3D
	var spawn_one := get_node_or_null(spawn_one_path) as Marker3D
	var spawn_two := get_node_or_null(spawn_two_path) as Marker3D
	var spawn_three := get_node_or_null(spawn_three_path) as Marker3D
	var spawn_four := get_node_or_null(spawn_four_path) as Marker3D

	if active_count >= 1:
		if player_one == null:
			push_error("SpawnManager: no se encontró Player1.")
		elif spawn_one == null:
			push_error("SpawnManager: no se encontró SpawnJugador1.")
		else:
			_aplicar_transform(player_one, spawn_one)

	if active_count >= 2:
		if player_two == null:
			push_error("SpawnManager: no se encontró Player2.")
		elif spawn_two == null:
			push_error("SpawnManager: no se encontró SpawnJugador2.")
		else:
			_aplicar_transform(player_two, spawn_two)

	if active_count >= 3:
		if player_three == null:
			push_error("SpawnManager: no se encontró Player3.")
		elif spawn_three == null:
			push_error("SpawnManager: no se encontró SpawnJugador3.")
		else:
			_aplicar_transform(player_three, spawn_three)

	if active_count >= 4:
		if player_four == null:
			push_error("SpawnManager: no se encontró Player4.")
		elif spawn_four == null:
			push_error("SpawnManager: no se encontró SpawnJugador4.")
		else:
			_aplicar_transform(player_four, spawn_four)


# Coloca al jugador en la posición y orientación del SpawnPoint sin copiar su escala.
func _aplicar_transform(player: Node3D, spawn: Node3D) -> void:
	var rotacion := spawn.global_transform.basis.orthonormalized()
	player.global_transform = Transform3D(rotacion, spawn.global_position)
