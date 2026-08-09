extends Node3D

@onready var rock: Rock = $Rock


func _ready() -> void:
	rock.player_entered_interaction_range.connect(
		_on_player_entered_interaction_range
	)
	rock.player_exited_interaction_range.connect(
		_on_player_exited_interaction_range
	)
	rock.interaction_requested.connect(_on_interaction_requested)


func _on_player_entered_interaction_range(player: CharacterBody3D) -> void:
	print("[ROCK TEST] Player %s entered interaction range" % player.name)


func _on_player_exited_interaction_range(player: CharacterBody3D) -> void:
	print("[ROCK TEST] Player %s exited interaction range" % player.name)


func _on_interaction_requested(player: CharacterBody3D) -> void:
	print("[ROCK TEST] interaction_requested received: %s" % player.name)