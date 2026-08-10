extends Node3D

const PlayerScript := preload("res://entities/player/player.gd")

@onready var interactable_object: InteractableObject = $InteractableObject
@onready var player: CharacterBody3D = $Player


func _ready() -> void:
	interactable_object.player_entered_interaction_range.connect(
		_on_player_entered_interaction_range
	)
	interactable_object.player_exited_interaction_range.connect(
		_on_player_exited_interaction_range
	)

	print("[GRAB TEST] === Protocolo de agarre (Kevin) ===")
	print("[GRAB TEST] Estado inicial: can_be_grabbed()=%s, player_in_range=%s" % [
		interactable_object.can_be_grabbed(),
		interactable_object.has_player_in_interaction_range(),
	])

	interactable_object.start_being_grabbed(player)
	print("[GRAB TEST] Despues de start_being_grabbed(): is_grabbed_by(player)=%s, can_be_grabbed()=%s, matching_state=%s, freeze=%s, collision_layer=%d" % [
		interactable_object.is_grabbed_by(player),
		interactable_object.can_be_grabbed(),
		interactable_object.get_player_state() == PlayerScript.PlayerState.GRABBED,
		interactable_object.freeze,
		interactable_object.collision_layer,
	])

	interactable_object.release_from_being_grabbed()
	print("[GRAB TEST] Despues de release_from_being_grabbed(): is_grabbed_by(player)=%s, can_be_grabbed()=%s, matching_state=%s, freeze=%s, collision_layer=%d" % [
		interactable_object.is_grabbed_by(player),
		interactable_object.can_be_grabbed(),
		interactable_object.get_player_state() == PlayerScript.PlayerState.NORMAL,
		interactable_object.freeze,
		interactable_object.collision_layer,
	])


func _on_player_entered_interaction_range(player: CharacterBody3D) -> void:
	print("[INTERACTION TEST] Player %s entered interaction range" % player.name)


func _on_player_exited_interaction_range(player: CharacterBody3D) -> void:
	print("[INTERACTION TEST] Player %s exited interaction range" % player.name)