extends Node3D

@onready var interactable_object: InteractableObject = $InteractableObject


func _ready() -> void:
	interactable_object.player_entered_interaction_range.connect(
		_on_player_entered_interaction_range
	)
	interactable_object.player_exited_interaction_range.connect(
		_on_player_exited_interaction_range
	)


func _on_player_entered_interaction_range(player: CharacterBody3D) -> void:
	_print_interaction_state("entered", player)

	var current_player := interactable_object.get_interacting_player()
	if current_player != null:
		print("[INTERACTION TEST] Calling interact with current player: %s" % current_player.name)
		interactable_object.interact(current_player)


func _on_player_exited_interaction_range(player: CharacterBody3D) -> void:
	_print_interaction_state("exited", player)
	print("[INTERACTION TEST] Calling interact after exit: %s" % player.name)
	interactable_object.interact(player)


func _print_interaction_state(event: String, player: CharacterBody3D) -> void:
	var current_player := interactable_object.get_interacting_player()
	var current_player_name := "NONE"
	if current_player != null:
		current_player_name = str(current_player.name)

	print("[INTERACTION] Player %s range: %s" % [event, player.name])
	print("[INTERACTION] Current interacting player: %s" % current_player_name)
	print("[INTERACTION] Nearby players: %d" % interactable_object._nearby_players.size())
