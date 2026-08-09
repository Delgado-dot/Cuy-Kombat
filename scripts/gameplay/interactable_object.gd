extends RigidBody3D

## Base reusable for physical objects that will support interactions later.
class_name InteractableObject

## Emitted when a player enters this object's interaction range.
signal player_entered_interaction_range(player: CharacterBody3D)

## Emitted when a player leaves this object's interaction range.
signal player_exited_interaction_range(player: CharacterBody3D)

var _nearby_players: Array[CharacterBody3D] = []
var _current_interacting_player: CharacterBody3D


func _ready() -> void:
	$InteractionArea.body_entered.connect(_on_interaction_area_body_entered)
	$InteractionArea.body_exited.connect(_on_interaction_area_body_exited)


## Returns true while at least one CharacterBody3D is inside the interaction area.
func has_player_in_interaction_range() -> bool:
	return not _nearby_players.is_empty()


## Returns the player currently selected to interact with this object.
func get_interacting_player() -> CharacterBody3D:
	return _current_interacting_player


func _on_interaction_area_body_entered(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return

	var player := body as CharacterBody3D
	if player in _nearby_players:
		return

	_nearby_players.append(player)
	if _current_interacting_player == null:
		_current_interacting_player = player

	player_entered_interaction_range.emit(player)


func _on_interaction_area_body_exited(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return

	var player := body as CharacterBody3D
	if player not in _nearby_players:
		return

	_nearby_players.erase(player)
	if _current_interacting_player == player:
		if _nearby_players.is_empty():
			_current_interacting_player = null
		else:
			_current_interacting_player = _nearby_players[0]

	player_exited_interaction_range.emit(player)
