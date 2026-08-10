extends Node3D

const PlayerScript := preload("res://entities/player/player.gd")

@onready var barrel: Barrel = $Barrel
@onready var player: CharacterBody3D = $Player


func _ready() -> void:
	print("[BARREL GRAB TEST] === Protocolo de agarre y lanzamiento (Kevin) ===")
	print("[BARREL GRAB TEST] Estado inicial: can_be_grabbed()=%s, player_in_range=%s" % [
		barrel.can_be_grabbed(),
		barrel.has_player_in_interaction_range(),
	])

	barrel.start_being_grabbed(player)
	print("[BARREL GRAB TEST] Despues de start_being_grabbed(): is_grabbed_by(player)=%s, can_be_grabbed()=%s, matching_state=%s, freeze=%s, collision_layer=%d" % [
		barrel.is_grabbed_by(player),
		barrel.can_be_grabbed(),
		barrel.get_player_state() == PlayerScript.PlayerState.GRABBED,
		barrel.freeze,
		barrel.collision_layer,
	])

	barrel.release_from_being_grabbed()
	print("[BARREL GRAB TEST] Despues de release_from_being_grabbed(): is_grabbed_by(player)=%s, can_be_grabbed()=%s, matching_state=%s, freeze=%s, collision_layer=%d" % [
		barrel.is_grabbed_by(player),
		barrel.can_be_grabbed(),
		barrel.get_player_state() == PlayerScript.PlayerState.NORMAL,
		barrel.freeze,
		barrel.collision_layer,
	])

	barrel.start_being_grabbed(player)
	barrel.throw(player)
	print("[BARREL GRAB TEST] Despues de throw(player): is_grabbed_by(player)=%s, can_be_grabbed()=%s, matching_state=%s, freeze=%s, collision_layer=%d" % [
		barrel.is_grabbed_by(player),
		barrel.can_be_grabbed(),
		barrel.get_player_state() == PlayerScript.PlayerState.NORMAL,
		barrel.freeze,
		barrel.collision_layer,
	])
	print("[BARREL GRAB TEST] Lanzamiento mas rapido: velocidad_horizontal=%.2f m/s (impulse=%.1f, masa=%.1f)" % [
		Vector3(barrel.linear_velocity.x, 0.0, barrel.linear_velocity.z).length(),
		barrel.throw_impulse,
		barrel.mass,
	])
