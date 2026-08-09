extends Node3D

@onready var interactable_object: InteractableObject = $InteractableObject


func _ready() -> void:
	interactable_object.player_entered_interaction_range.connect(
		_on_player_entered_interaction_range
	)
	interactable_object.player_exited_interaction_range.connect(
		_on_player_exited_interaction_range
	)


func _on_player_entered_interaction_range(_player: CharacterBody3D) -> void:
	print("PLAYER ENTERED INTERACTION RANGE")


func _on_player_exited_interaction_range(_player: CharacterBody3D) -> void:
	print("PLAYER EXITED INTERACTION RANGE")
