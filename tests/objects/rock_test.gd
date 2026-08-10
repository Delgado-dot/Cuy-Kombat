extends Node3D

const PlayerScript := preload("res://entities/player/player.gd")

@onready var rock: Rock = $Rock
@onready var player: CharacterBody3D = $Player


func _ready() -> void:
	rock.player_entered_interaction_range.connect(
		_on_player_entered_interaction_range
	)
	rock.player_exited_interaction_range.connect(
		_on_player_exited_interaction_range
	)

	print("[ROCK GRAB TEST] === Protocolo de agarre (Kevin) ===")
	print("[ROCK GRAB TEST] Estado inicial: can_be_grabbed()=%s, player_in_range=%s" % [
		rock.can_be_grabbed(),
		rock.has_player_in_interaction_range(),
	])

	rock.start_being_grabbed(player)
	print("[ROCK GRAB TEST] Despues de start_being_grabbed(): is_grabbed_by(player)=%s, can_be_grabbed()=%s, matching_state=%s, freeze=%s" % [
		rock.is_grabbed_by(player),
		rock.can_be_grabbed(),
		rock.get_player_state() == PlayerScript.PlayerState.GRABBED,
		rock.freeze,
	])

	rock.release_from_being_grabbed()
	print("[ROCK GRAB TEST] Despues de release_from_being_grabbed(): is_grabbed_by(player)=%s, can_be_grabbed()=%s, matching_state=%s, freeze=%s" % [
		rock.is_grabbed_by(player),
		rock.can_be_grabbed(),
		rock.get_player_state() == PlayerScript.PlayerState.NORMAL,
		rock.freeze,
	])

	rock.start_being_grabbed(player)
	rock.throw(player)
	print("[ROCK GRAB TEST] Lanzamiento mas rapido: velocidad_horizontal=%.2f m/s (impulse=%.1f, masa=%.1f)" % [
		Vector3(rock.linear_velocity.x, 0.0, rock.linear_velocity.z).length(),
		rock.throw_impulse,
		rock.mass,
	])


func _on_player_entered_interaction_range(player: CharacterBody3D) -> void:
	print("[ROCK TEST] Player %s entered interaction range" % player.name)


func _on_player_exited_interaction_range(player: CharacterBody3D) -> void:
	print("[ROCK TEST] Player %s exited interaction range" % player.name)